#!/usr/bin/env python3
"""
真题文件 → 纯文本提取（pipeline step 1）

用 libreoffice headless --convert-to txt 把 .doc/.docx/.pdf 转纯文本。
按 sha1 缓存：同一文件只转一次，结果存 .cache/realpaper/<sha1>/raw.txt

用法：
    python3 extract.py <真题文件路径>
    python3 extract.py --batch <目录>      # 批量处理目录下所有 .doc/.docx/.pdf

输出：缓存路径 + 文本内容长度
"""

import sys
import os
import hashlib
import subprocess
import argparse
import json
from pathlib import Path

# 常量
PROJECT_ROOT = Path(__file__).resolve().parents[2]
CACHE_DIR = PROJECT_ROOT / '.cache' / 'realpaper'
CACHE_DIR.mkdir(parents=True, exist_ok=True)

SUPPORTED_EXT = {'.doc', '.docx', '.pdf'}


def file_sha1(path: Path) -> str:
    h = hashlib.sha1()
    with open(path, 'rb') as f:
        for chunk in iter(lambda: f.read(65536), b''):
            h.update(chunk)
    return h.hexdigest()


def cache_path_for(sha1: str) -> Path:
    d = CACHE_DIR / sha1
    d.mkdir(parents=True, exist_ok=True)
    return d / 'raw.txt'


def pdftotext_convert(src: Path, out_path: Path) -> bool:
    """PDF → txt via poppler pdftotext -layout"""
    cmd = ['pdftotext', '-layout', '-enc', 'UTF-8', str(src), str(out_path)]
    try:
        result = subprocess.run(cmd, capture_output=True, text=True, timeout=120)
        if result.returncode != 0:
            print(f'WARN: pdftotext exit {result.returncode}: {result.stderr[:200]}', file=sys.stderr)
            return False
        return out_path.exists() and out_path.stat().st_size > 0
    except FileNotFoundError:
        print('ERR: pdftotext not installed. sudo apt install poppler-utils', file=sys.stderr)
        return False
    except subprocess.TimeoutExpired:
        print(f'ERR: pdftotext timeout on {src}', file=sys.stderr)
        return False


def libreoffice_convert(src: Path, out_dir: Path) -> bool:
    """.doc/.docx → txt via libreoffice headless"""
    if not src.exists():
        print(f'ERR: file not found {src}', file=sys.stderr)
        return False
    cmd = [
        'libreoffice', '--headless',
        '--convert-to', 'txt:Text (encoded):UTF8',
        '--outdir', str(out_dir),
        str(src),
    ]
    try:
        result = subprocess.run(cmd, capture_output=True, text=True, timeout=120)
        if result.returncode != 0:
            print(f'WARN: libreoffice exit {result.returncode}: {result.stderr[:200]}', file=sys.stderr)
            return False
        return True
    except FileNotFoundError:
        print('ERR: libreoffice not installed. sudo apt install libreoffice', file=sys.stderr)
        return False
    except subprocess.TimeoutExpired:
        print(f'ERR: libreoffice timeout on {src}', file=sys.stderr)
        return False


def extract(file_path: str, force: bool = False) -> dict:
    """
    转换单个文件返回 {ok, sha1, cache_path, text_len, source_file}
    缓存命中时跳过 libreoffice 调用。
    """
    src = Path(file_path).resolve()
    if not src.exists():
        return {'ok': False, 'error': 'file_not_found', 'source_file': str(src)}
    if src.suffix.lower() not in SUPPORTED_EXT:
        return {'ok': False, 'error': 'unsupported_ext', 'source_file': str(src)}

    sha1 = file_sha1(src)
    out_path = cache_path_for(sha1)

    # 缓存命中
    if out_path.exists() and not force:
        text = out_path.read_text(encoding='utf-8', errors='replace')
        return {
            'ok': True, 'sha1': sha1, 'cache_path': str(out_path),
            'text_len': len(text), 'source_file': str(src), 'cached': True,
        }

    # PDF 走 pdftotext，其他走 libreoffice
    out_dir = out_path.parent
    if src.suffix.lower() == '.pdf':
        if not pdftotext_convert(src, out_path):
            return {'ok': False, 'error': 'convert_failed', 'sha1': sha1, 'source_file': str(src)}
    else:
        if not libreoffice_convert(src, out_dir):
            return {'ok': False, 'error': 'convert_failed', 'sha1': sha1, 'source_file': str(src)}
        # libreoffice 输出文件名 = 原文件名换 .txt 后缀
        converted = out_dir / (src.stem + '.txt')
        if not converted.exists():
            candidates = list(out_dir.glob('*.txt'))
            if not candidates:
                return {'ok': False, 'error': 'output_not_found', 'sha1': sha1, 'source_file': str(src)}
            converted = candidates[0]
        if converted != out_path:
            converted.rename(out_path)

    text = out_path.read_text(encoding='utf-8', errors='replace')
    return {
        'ok': True, 'sha1': sha1, 'cache_path': str(out_path),
        'text_len': len(text), 'source_file': str(src), 'cached': False,
    }


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('path', help='真题文件路径或目录')
    ap.add_argument('--batch', action='store_true', help='批量处理目录')
    ap.add_argument('--force', action='store_true', help='忽略缓存重新转换')
    args = ap.parse_args()

    p = Path(args.path)
    if args.batch and p.is_dir():
        results = []
        for ext in SUPPORTED_EXT:
            for f in p.rglob(f'*{ext}'):
                r = extract(str(f), force=args.force)
                results.append(r)
                status = 'CACHED' if r.get('cached') else ('OK' if r.get('ok') else 'FAIL')
                print(f'[{status}] {f.name} → {r.get("cache_path", r.get("error"))}')
        ok = sum(1 for r in results if r.get('ok'))
        print(f'\nBatch done: {ok}/{len(results)} succeeded')
        # 输出 manifest 供下游 pipeline 用
        manifest_path = CACHE_DIR / 'extract_manifest.json'
        manifest_path.write_text(json.dumps(results, ensure_ascii=False, indent=2))
        print(f'Extract manifest: {manifest_path}')
    else:
        r = extract(str(p), force=args.force)
        print(json.dumps(r, ensure_ascii=False, indent=2))
        sys.exit(0 if r.get('ok') else 1)


if __name__ == '__main__':
    main()
