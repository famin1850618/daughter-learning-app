#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PLANNING_DIR="${PLANNING_DIR:-/mnt/d/AI_Workspace/Planning}"
DEEPSEEK_FILE="${DEEPSEEK_FILE:-$PLANNING_DIR/deepseek.txt}"
QWEN_FILE="${QWEN_FILE:-$PLANNING_DIR/qwen.txt}"
JAVA_HOME="${JAVA_HOME:-/usr/lib/jvm/java-17-openjdk-amd64}"
export JAVA_HOME

read_key() {
  local file="$1"
  local kind="$2"
  local raw

  if [[ ! -s "$file" ]]; then
    echo "Missing or empty key file: $file" >&2
    exit 1
  fi

  raw="$(tr -d '\r\n' < "$file" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
  case "$kind" in
    deepseek)
      raw="${raw#DEEPSEEK_KEY=}"
      raw="${raw#deepseek_api_key=}"
      ;;
    qwen)
      raw="${raw#QWEN_KEY=}"
      raw="${raw#qwen_vl_api_key=}"
      ;;
  esac

  if [[ -z "$raw" ]]; then
    echo "Key file did not contain a usable value: $file" >&2
    exit 1
  fi
  printf '%s' "$raw"
}

version="$(awk '/^version:/ {print $2; exit}' "$ROOT_DIR/pubspec.yaml")"
version_name="${version%%+*}"
version_slug="${version_name//./_}"
output_apk="${OUTPUT_APK:-$PLANNING_DIR/planning_v${version_slug}_debug.apk}"

define_file="$(mktemp)"
trap 'rm -f "$define_file"' EXIT
chmod 600 "$define_file"

{
  printf 'DEEPSEEK_KEY=%s\n' "$(read_key "$DEEPSEEK_FILE" deepseek)"
  printf 'QWEN_KEY=%s\n' "$(read_key "$QWEN_FILE" qwen)"
} > "$define_file"

cd "$ROOT_DIR"
flutter build apk --debug --dart-define-from-file="$define_file"
cp build/app/outputs/flutter-apk/app-debug.apk "$output_apk"

echo "Built keyed debug APK: $output_apk"
sha256sum "$output_apk"
