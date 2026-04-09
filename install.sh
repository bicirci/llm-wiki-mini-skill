#!/bin/bash
set -euo pipefail

SKILL_NAME="llm-wiki-mini"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SOURCE_REGISTRY_SCRIPT="$SCRIPT_DIR/scripts/source-registry.sh"
ADAPTER_STATE_SCRIPT="$SCRIPT_DIR/scripts/adapter-state.sh"
PLATFORM=""
DRY_RUN=0
TARGET_DIR=""

MANAGED_ITEMS=(
  "README.md"
  "CLAUDE.md"
  "AGENTS.md"
  "SKILL.md"
  "install.sh"
  "setup.sh"
  "scripts"
  "templates"
  "platforms"
)

info()  { printf '\033[36m[信息]\033[0m %s\n' "$1"; }
ok()    { printf '\033[32m[完成]\033[0m %s\n' "$1"; }
warn()  { printf '\033[33m[警告]\033[0m %s\n' "$1"; }
err()   { printf '\033[31m[错误]\033[0m %s\n' "$1" >&2; }

usage() {
  cat <<'EOF'
用法：
  bash install.sh --platform <claude|codex> [--dry-run] [--target-dir <dir>]

说明：
  这是仓库级安装器，不会写入 ~/.claude 或 ~/.codex。
EOF
}

run_cmd() {
  if [ "$DRY_RUN" -eq 1 ]; then
    printf '[dry-run] %s\n' "$*"
    return 0
  fi
  "$@"
}

copy_item() {
  local source_path="$1"
  local target_path="$2"

  if [ "$DRY_RUN" -eq 1 ]; then
    printf '[dry-run] copy %s -> %s\n' "$source_path" "$target_path"
    return 0
  fi

  rm -rf "$target_path"
  cp -R "$source_path" "$target_path"
}

resolve_skill_root() {
  case "$1" in
    claude)
      printf '%s\n' "$SCRIPT_DIR/.claude/skills"
      ;;
    codex)
      printf '%s\n' "$SCRIPT_DIR/.codex/skills"
      ;;
    *)
      err "不支持的平台：$1"
      exit 1
      ;;
  esac
}

install_bundle() {
  local target_dir="$1"
  local item source_path target_path

  for item in "${MANAGED_ITEMS[@]}"; do
    source_path="$SCRIPT_DIR/$item"
    target_path="$target_dir/$item"

    if [ ! -e "$source_path" ]; then
      warn "$item：安装源文件缺失，跳过"
      continue
    fi

    if [ "$source_path" = "$target_path" ] && [ -e "$target_path" ]; then
      continue
    fi

    copy_item "$source_path" "$target_path"
  done
}

join_source_labels() {
  local category="$1"

  bash "$SOURCE_REGISTRY_SCRIPT" list-by-category "$category" \
    | awk -F '\t' '
      BEGIN { separator = "" }
      NF {
        printf "%s%s", separator, $2
        separator = "、"
      }
      END {
        if (separator == "") {
          printf "-"
        }
        printf "\n"
      }
    '
}

print_source_boundary() {
  local core_sources manual_sources

  core_sources="$(join_source_labels core_builtin)"
  manual_sources="$(join_source_labels manual_only)"

  echo ""
  echo "================================"
  echo "  来源边界"
  echo "================================"
  echo ""
  echo "离线主线：$core_sources"
  echo "手动入口：$manual_sources"
}

print_environment() {
  echo ""
  echo "================================"
  echo "  环境说明"
  echo "================================"
  echo ""
  echo "这个 mini skill 不会安装任何第三方联网提取器。"
  echo "支持的主线输入：本地 PDF、本地 Markdown/文本/HTML、纯文本粘贴。"
  echo "URL 输入统一改为手动入口：请复制正文，或先保存为本地文件再 ingest。"
}

print_adapter_states() {
  echo ""
  echo "================================"
  echo "  来源状态"
  echo "================================"
  echo ""

  bash "$ADAPTER_STATE_SCRIPT" summary-human
}

while [ $# -gt 0 ]; do
  case "$1" in
    --platform)
      [ $# -ge 2 ] || { err "--platform 需要一个值"; usage; exit 1; }
      PLATFORM="$2"
      shift 2
      ;;
    --dry-run)
      DRY_RUN=1
      shift
      ;;
    --target-dir)
      [ $# -ge 2 ] || { err "--target-dir 需要一个值"; usage; exit 1; }
      TARGET_DIR="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      err "未知参数：$1"
      usage
      exit 1
      ;;
  esac
done

[ -n "$PLATFORM" ] || {
  err "必须显式传入 --platform claude 或 --platform codex"
  usage
  exit 1
}

SKILL_ROOT="$(resolve_skill_root "$PLATFORM")"
if [ -n "$TARGET_DIR" ]; then
  TARGET_SKILL_DIR="$TARGET_DIR"
else
  TARGET_SKILL_DIR="$SKILL_ROOT/$SKILL_NAME"
fi

echo ""
echo "================================"
echo "  llm-wiki-mini 安装"
echo "================================"
echo ""
echo "平台：$PLATFORM"
echo "仓库目录：$SCRIPT_DIR"
echo "技能根目录：$SKILL_ROOT"
echo "目标目录：$TARGET_SKILL_DIR"

run_cmd mkdir -p "$SKILL_ROOT"
run_cmd mkdir -p "$TARGET_SKILL_DIR"
install_bundle "$TARGET_SKILL_DIR"

print_source_boundary
print_environment
print_adapter_states

echo ""
ok "llm-wiki-mini 已准备完成"
