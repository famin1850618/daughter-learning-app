#!/bin/bash
# 真题处理流水线编排器
#
# 用法：
#   ./process.sh <真题文件路径>           # 单卷处理
#   ./process.sh --batch <目录>           # 批量
#   ./process.sh --batch --limit N <目录> # 限处理 N 卷（控 token）
#
# 输出：
#   - .cache/realpaper/<sha1>/raw.txt + segments.json + matched.json
#   - 待 Claude 标注（人工触发会话级）
#
# 注意：本脚本仅做提取/切题/答案匹配（python，0 Claude token）。
# 标注/校验/入库需要 Claude 会话级触发，见 .realpaper-spec.md §10。

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# 检查 libreoffice
if ! command -v libreoffice &> /dev/null; then
    echo "ERROR: libreoffice not installed."
    echo "  sudo apt install libreoffice"
    exit 1
fi

if [ "$1" == "--batch" ]; then
    DIR="$2"
    if [ -z "$DIR" ]; then
        echo "Usage: $0 --batch <directory>"
        exit 1
    fi

    echo "=== Step 1: Extract"
    python3 "$SCRIPT_DIR/extract.py" --batch "$DIR"

    EXTRACT_MANIFEST="$PROJECT_ROOT/.cache/realpaper/extract_manifest.json"
    echo ""
    echo "=== Step 2: Segment"
    python3 "$SCRIPT_DIR/segment.py" --batch "$EXTRACT_MANIFEST"

    SEGMENT_MANIFEST="$PROJECT_ROOT/.cache/realpaper/segment_manifest.json"
    echo ""
    echo "=== Step 3: Match Answers"
    python3 "$SCRIPT_DIR/match_ans.py" --batch "$SEGMENT_MANIFEST"

    echo ""
    echo "=== Done. Next step (Claude 会话级):"
    echo "  - 读 .realpaper-spec.md"
    echo "  - 读各 .cache/realpaper/<sha1>/matched.json"
    echo "  - 标注 type/round/chapter/KP/explanation"
    echo "  - 输出 batch JSON → emit + register + commit"
else
    FILE="$1"
    if [ -z "$FILE" ] || [ ! -f "$FILE" ]; then
        echo "Usage: $0 <file_path> | --batch <dir>"
        exit 1
    fi

    echo "=== Step 1: Extract"
    python3 "$SCRIPT_DIR/extract.py" "$FILE"

    SHA1=$(python3 -c "import hashlib; print(hashlib.sha1(open('$FILE','rb').read()).hexdigest())")
    CACHE_DIR="$PROJECT_ROOT/.cache/realpaper/$SHA1"

    if [ ! -f "$CACHE_DIR/raw.txt" ]; then
        echo "ERROR: extraction failed"
        exit 1
    fi

    echo ""
    echo "=== Step 2: Segment"
    python3 "$SCRIPT_DIR/segment.py" "$CACHE_DIR/raw.txt" > "$CACHE_DIR/segments.json"

    echo ""
    echo "=== Step 3: Match Answers"
    python3 "$SCRIPT_DIR/match_ans.py" "$CACHE_DIR/segments.json" --raw "$CACHE_DIR/raw.txt" > "$CACHE_DIR/matched.json"

    QCOUNT=$(python3 -c "import json; print(len(json.load(open('$CACHE_DIR/matched.json'))))")
    echo ""
    echo "=== Done. $QCOUNT questions extracted to $CACHE_DIR/matched.json"
    echo "Next: Claude 会话级标注 → batch JSON"
fi
