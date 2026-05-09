#!/usr/bin/env python3
"""extract_math_from_image.py — V3.12.22 算式图 OCR 工具（A2 立项）

输入: <image_path> 或 <docx_cache_dir>（批量处理）
输出: 算式 → LaTeX 转换结果 + cache JSON

用途:
  深圳真题 docx 内嵌大量"直接写得数 / 解方程 / 比大小 / 互化"题，
  题面文字层只有"4．（8分）直接写得数。"，具体算式（$\frac{1}{3}+\frac{1}{6}=$ 等）
  以图嵌入 docx。V3.12.21 worker 整题跳过（导致数学入库率仅 78/150）。

  V3.12.22 A2 立项：调用 Claude Vision API 识别算式图 → LaTeX → 替换 image_data
  → 算式题不再跳过，入库率从 78 提升到接近 150。

工作模式:
  python3 extract_math_from_image.py <image.png>
  → 输出: {"latex": "$\\frac{1}{3}+\\frac{1}{6}=$",
           "confidence": 0.95,
           "image_path": "...",
           "fallback": "如算式图很复杂，给原图 base64"}

  python3 extract_math_from_image.py --docx-cache <docx_sha1_dir>
  → 批量处理 cache 目录里所有 image*.png
  → 输出 cache/{sha1}/math_latex_map.json
       {"image2.png": {"latex": "...", "confidence": 0.95},
        "image5.png": {"latex": "...", "confidence": 0.7, "warning": "..."}}

API 选择:
  - Claude Sonnet/Opus Vision API（首选，识别中文数学公式精准）
  - 阈值: confidence < 0.7 → 标 warning，agent 入库时人工核对

V3.12.22 状态: SKELETON 框架（API 集成由 worker 实施）
TODO worker:
  1. pip install anthropic + 配置 API key（ANTHROPIC_API_KEY env 或 ~/.anthropic/api_key）
  2. 实现 call_vision_api(image_bytes) -> latex
  3. prompt 设计: "识别这张算式图，输出 LaTeX 公式（用 $...$ 包裹），
                   如题面是'1/3 + 1/6 = '，输出 '$\\frac{1}{3}+\\frac{1}{6}=$'。
                   仅输出 LaTeX 不解释。多个算式用 \\n 分隔。"
  4. 测试集: deep圳数学样本 image*.png 抽 10 张验证准确率
  5. 集成到 extract_docx.py: process_docx 加 step 1.6 调本工具，输出 math_latex_map.json
  6. 4a annotate 阶段 agent 用 math_latex_map.json 替换图 ID → LaTeX 入 content
"""
import argparse
import base64
import json
import os
import sys
from pathlib import Path
from typing import Optional


# ============================================================
# Phase 1: SKELETON（V3.12.22 立项，待 worker 实施 API 集成）
# ============================================================

def call_vision_api_skeleton(image_bytes: bytes, prompt: str = None) -> dict:
    """SKELETON：待 worker 替换为真实 Claude Vision API 调用

    返回示例:
    {"latex": "$\\frac{1}{3}+\\frac{1}{6}=$",
     "confidence": 0.95,
     "raw_response": "...",
     "warning": null}
    """
    # TODO worker: 实现以下步骤
    # 1. import anthropic
    # 2. client = anthropic.Anthropic(api_key=os.environ.get('ANTHROPIC_API_KEY'))
    # 3. msg = client.messages.create(
    #        model="claude-sonnet-4-6",
    #        max_tokens=512,
    #        messages=[{"role":"user","content":[
    #            {"type":"image","source":{"type":"base64","media_type":"image/png","data":base64.b64encode(image_bytes).decode()}},
    #            {"type":"text","text": DEFAULT_PROMPT or prompt}
    #        ]}]
    #    )
    # 4. parse msg.content[0].text 为 LaTeX
    # 5. confidence 启发式（看 LaTeX 是否合法 + 长度合理）
    return {
        'latex': '[SKELETON: 待 worker 集成 Claude Vision API]',
        'confidence': 0.0,
        'raw_response': None,
        'warning': 'V3.12.22 A2 SKELETON 框架，未实施 API 调用。',
    }


DEFAULT_PROMPT = """你是数学题图识别专家。请把图中的算式（数字、运算符、分数、根式、上下标、π、几何图形旁的数据等）识别为 LaTeX 公式。

输出格式:
- 用 $...$ 包裹（行内公式语法），不要 $$...$$
- 多个独立算式用 \\n 分隔
- 分数用 \\frac{a}{b}
- π 用 \\pi
- 上下标用 ^{} _{}
- 比例用 :（如 a:b）不用 \\colon
- 单位（cm m kg 等）原样保留 ASCII

例:
- 图: "1/3 + 1/6 = " → 输出: $\\frac{1}{3}+\\frac{1}{6}=$
- 图: "求 r=10cm 圆面积" → 输出: $r=10$ cm 圆面积

特殊处理:
- 几何图（含三角形/圆等图形 + 标注尺寸）: 优先识别图中的尺寸文字标注
- 图过于复杂无法用 LaTeX 表达: 输出 [COMPLEX_DIAGRAM] 标记
- 图模糊看不清: 输出 [UNRECOGNIZABLE]

仅输出 LaTeX，不解释。"""


def process_image(image_path: Path, prompt: Optional[str] = None) -> dict:
    """处理单张图：识别算式 → LaTeX"""
    if not image_path.exists():
        return {'error': f'image not found: {image_path}'}
    image_bytes = image_path.read_bytes()
    result = call_vision_api_skeleton(image_bytes, prompt)
    result['image_path'] = str(image_path)
    result['image_size_kb'] = len(image_bytes) // 1024
    return result


def process_docx_cache(cache_dir: Path) -> dict:
    """批量处理 docx cache 目录中所有 image*.png"""
    media_dir = cache_dir / 'media'
    if not media_dir.exists():
        return {'error': f'media dir not found: {media_dir}'}
    out_path = cache_dir / 'math_latex_map.json'
    results = {}
    for img in sorted(media_dir.glob('image*.png')):
        print(f'  · {img.name}')
        result = process_image(img)
        # 仅记 LaTeX 关键字段（不存大 raw_response）
        results[img.name] = {
            'latex': result.get('latex'),
            'confidence': result.get('confidence'),
            'warning': result.get('warning'),
        }
    out_path.write_text(json.dumps(results, ensure_ascii=False, indent=2), encoding='utf-8')
    print(f'\n→ {out_path} ({len(results)} 张图处理完)')
    return {'count': len(results), 'output': str(out_path)}


def main():
    ap = argparse.ArgumentParser(description='V3.12.22 算式图 OCR (SKELETON)')
    ap.add_argument('input', help='图片路径 或 docx cache 目录')
    ap.add_argument('--docx-cache', action='store_true', help='输入是 docx cache dir，批处理')
    ap.add_argument('--prompt', help='自定义 Vision prompt (默认用 DEFAULT_PROMPT)')
    args = ap.parse_args()

    p = Path(args.input).expanduser()
    if args.docx_cache:
        result = process_docx_cache(p)
    else:
        result = process_image(p, args.prompt)
    print(json.dumps(result, ensure_ascii=False, indent=2))


if __name__ == '__main__':
    main()
