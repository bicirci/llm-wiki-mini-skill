#!/bin/bash
set -euo pipefail

SKILL_NAME="llm-wiki-mini"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SOURCE_REGISTRY_SCRIPT="$SCRIPT_DIR/scripts/source-registry.sh"
ADAPTER_STATE_SCRIPT="$SCRIPT_DIR/scripts/adapter-state.sh"
PLATFORM=""
DRY_RUN=0
TARGET_DIR=""
TARGET_REPO_DIR=""
LOG_DIR="$SCRIPT_DIR/.install-logs"
LOG_FILE=""

COMMON_ITEMS=(
  "scripts"
  "templates"
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
  这是 repo 级安装器，会把 skill 安装到目标 repo 下的平台标准目录。
  --target-dir 指向目标 repo 目录。
  未传参数时，会先交互式询问 platform 和目标 repo 目录。
EOF
}

setup_logging() {
  local timestamp

  timestamp="$(date +%Y%m%d-%H%M%S)"
  LOG_FILE="$LOG_DIR/install-${timestamp}-${PLATFORM:-unknown}-$$.log"
  mkdir -p "$LOG_DIR"

  if [ "$DRY_RUN" -eq 1 ]; then
    exec > >(tee -a "$LOG_FILE") 2>&1
  else
    exec > >(tee -a "$LOG_FILE") 2>&1
  fi
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

prompt_platform() {
  local answer=""

  printf '请选择平台 [claude/codex]: ' >&2
  IFS= read -r answer || true

  case "$answer" in
    claude|codex)
      printf '%s\n' "$answer"
      ;;
    *)
      err "平台必须是 claude 或 codex"
      exit 1
      ;;
  esac
}

prompt_target_repo_dir() {
  local default_target_repo_dir="$1"
  local answer=""

  printf '请输入目标 repo 目录 [%s]: ' "$default_target_repo_dir" >&2
  IFS= read -r answer || true

  if [ -n "$answer" ]; then
    printf '%s\n' "$answer"
  else
    printf '%s\n' "$default_target_repo_dir"
  fi
}

resolve_skill_root() {
  local repo_dir="$1"
  local platform="$2"

  case "$platform" in
    claude)
      printf '%s\n' "$repo_dir/.claude/skills"
      ;;
    codex)
      printf '%s\n' "$repo_dir/.codex/skills"
      ;;
    *)
      err "不支持的平台：$platform"
      exit 1
      ;;
  esac
}

resolve_skill_dir() {
  local skill_root="$1"
  printf '%s\n' "$skill_root/$SKILL_NAME"
}

install_common_bundle() {
  local target_dir="$1"
  local item source_path target_path

  for item in "${COMMON_ITEMS[@]}"; do
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

install_platform_skill_entry() {
  local platform="$1"
  local target_dir="$2"
  local source_path="$SCRIPT_DIR/platforms/$platform/SKILL.md"
  local target_path="$target_dir/SKILL.md"

  if [ ! -f "$source_path" ]; then
    err "缺少平台 skill 入口：$source_path"
    exit 1
  fi

  copy_item "$source_path" "$target_path"
}

install_platform_extras() {
  local platform="$1"
  local target_dir="$2"

  case "$platform" in
    claude)
      return 0
      ;;
    codex)
      copy_item "$SCRIPT_DIR/agents" "$target_dir/agents"
      ;;
    *)
      err "不支持的平台：$platform"
      exit 1
      ;;
  esac
}

install_references() {
  local target_dir="$1"
  local source_path="$SCRIPT_DIR/shared/skill-core.md"
  local target_path="$target_dir/references/skill-core.md"

  if [ ! -f "$source_path" ]; then
    err "缺少共享 skill 内容：$source_path"
    exit 1
  fi

  run_cmd mkdir -p "$target_dir/references"
  copy_item "$source_path" "$target_path"
}

write_repo_entry() {
  local platform="$1"
  local target_repo_dir="$2"
  local entry_path skill_rel_path

  case "$platform" in
    claude)
      entry_path="$target_repo_dir/CLAUDE.md"
      skill_rel_path=".claude/skills/$SKILL_NAME/SKILL.md"
      if [ "$DRY_RUN" -eq 1 ]; then
        printf '[dry-run] write %s\n' "$entry_path"
        return 0
      fi
      cat > "$entry_path" <<EOF
# CLAUDE.md

This repository uses the repo-level \`$SKILL_NAME\` skill.

Start here:

- \`$skill_rel_path\`
EOF
      ;;
    codex)
      entry_path="$target_repo_dir/AGENTS.md"
      skill_rel_path=".codex/skills/$SKILL_NAME/SKILL.md"
      if [ "$DRY_RUN" -eq 1 ]; then
        printf '[dry-run] write %s\n' "$entry_path"
        return 0
      fi
      cat > "$entry_path" <<EOF
# AGENTS.md

This repository uses the repo-level \`$SKILL_NAME\` skill.

Start here:

- \`$skill_rel_path\`
EOF
      ;;
    *)
      err "不支持的平台：$platform"
      exit 1
      ;;
  esac
}

remove_legacy_artifacts() {
  local target_dir="$1"
  local legacy_path
  local legacy_items=(
    "install.sh"
    "setup.sh"
    "README.md"
    "CLAUDE.md"
    "AGENTS.md"
    "platforms"
    "tests"
  )

  for legacy_path in "${legacy_items[@]}"; do
    if [ "$DRY_RUN" -eq 1 ]; then
      printf '[dry-run] remove %s\n' "$target_dir/$legacy_path"
      continue
    fi

    rm -rf "$target_dir/$legacy_path"
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

if [ -z "$PLATFORM" ]; then
  PLATFORM="$(prompt_platform)"
fi

setup_logging

if [ -n "$TARGET_DIR" ]; then
  TARGET_REPO_DIR="$TARGET_DIR"
else
  TARGET_REPO_DIR="$(prompt_target_repo_dir "$PWD")"
fi

SKILL_ROOT="$(resolve_skill_root "$TARGET_REPO_DIR" "$PLATFORM")"
TARGET_SKILL_DIR="$(resolve_skill_dir "$SKILL_ROOT")"
SKILL_ROOT="$(dirname "$TARGET_SKILL_DIR")"

echo ""
echo "================================"
echo "  llm-wiki-mini 安装"
echo "================================"
echo ""
echo "平台：$PLATFORM"
echo "仓库目录：$SCRIPT_DIR"
echo "目标 repo 目录：$TARGET_REPO_DIR"
echo "技能根目录：$SKILL_ROOT"
echo "目标目录：$TARGET_SKILL_DIR"

run_cmd mkdir -p "$TARGET_REPO_DIR"
run_cmd mkdir -p "$SKILL_ROOT"
run_cmd mkdir -p "$TARGET_SKILL_DIR"
remove_legacy_artifacts "$TARGET_SKILL_DIR"
install_common_bundle "$TARGET_SKILL_DIR"
install_references "$TARGET_SKILL_DIR"
install_platform_skill_entry "$PLATFORM" "$TARGET_SKILL_DIR"
install_platform_extras "$PLATFORM" "$TARGET_SKILL_DIR"
write_repo_entry "$PLATFORM" "$TARGET_REPO_DIR"

print_source_boundary
print_environment
print_adapter_states

echo ""
echo "日志文件：$LOG_FILE"
ok "llm-wiki-mini 已准备完成"
