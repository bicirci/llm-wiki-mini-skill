#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SOURCE_REGISTRY_SCRIPT="$SCRIPT_DIR/source-registry.sh"

usage() {
  cat <<'EOF'
用法：
  bash scripts/adapter-state.sh check <source_id>
  bash scripts/adapter-state.sh summary
  bash scripts/adapter-state.sh summary-human
  bash scripts/adapter-state.sh classify-run <source_id> <exit_code> <output_path>
EOF
}

print_header() {
  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
    "source_id" \
    "source_label" \
    "state" \
    "state_label" \
    "detail" \
    "recovery_action" \
    "install_hint" \
    "fallback_hint"
}

state_label() {
  case "$1" in
    available) printf '%s\n' "可用" ;;
    unsupported) printf '%s\n' "手动入口" ;;
    runtime_failed) printf '%s\n' "运行失败" ;;
    empty_result) printf '%s\n' "结果为空" ;;
    *) printf '%s\n' "$1" ;;
  esac
}

emit_state_row() {
  local source_id="$1"
  local source_label="$2"
  local state="$3"
  local detail="$4"
  local recovery_action="$5"
  local install_hint="$6"
  local fallback_hint="$7"

  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
    "$source_id" \
    "$source_label" \
    "$state" \
    "$(state_label "$state")" \
    "$detail" \
    "$recovery_action" \
    "$install_hint" \
    "$fallback_hint"
}

resolve_preflight_state() {
  local source_id="$1"
  local record
  local source_label source_category input_mode match_rule raw_dir adapter_name dependency_name dependency_type fallback_hint

  record="$(bash "$SOURCE_REGISTRY_SCRIPT" get "$source_id")" || {
    echo "未知来源：$source_id" >&2
    exit 1
  }

  IFS=$'\t' read -r source_id source_label source_category input_mode match_rule raw_dir adapter_name dependency_name dependency_type fallback_hint <<EOF
$record
EOF

  case "$source_category" in
    core_builtin)
      emit_state_row "$source_id" "$source_label" "available" "离线主线可直接进入，不依赖外挂" "直接继续主线" "-" "$fallback_hint"
      ;;
    manual_only)
      emit_state_row "$source_id" "$source_label" "unsupported" "mini 版不自动提取该来源" "请用户手动提供正文或本地文件" "-" "$fallback_hint"
      ;;
    *)
      echo "未知来源分类：$source_category" >&2
      exit 1
      ;;
  esac
}

classify_run() {
  local source_id="$1"
  local exit_code="$2"
  local output_path="$3"
  local row source_label fallback_hint

  row="$(bash "$SOURCE_REGISTRY_SCRIPT" get "$source_id")" || {
    echo "未知来源：$source_id" >&2
    exit 1
  }

  IFS=$'\t' read -r _ source_label _ _ _ _ _ _ _ fallback_hint <<EOF
$row
EOF

  if [ "$exit_code" -ne 0 ]; then
    emit_state_row "$source_id" "$source_label" "runtime_failed" "本次处理失败" "修复输入后重试，或改走手动整理" "-" "$fallback_hint"
    return 0
  fi

  if [ ! -s "$output_path" ]; then
    emit_state_row "$source_id" "$source_label" "empty_result" "输出为空" "请手动补全文本后继续" "-" "$fallback_hint"
    return 0
  fi

  emit_state_row "$source_id" "$source_label" "available" "输出有效" "继续主线" "-" "$fallback_hint"
}

summary() {
  local source_id

  print_header
  while IFS=$'\t' read -r source_id _; do
    [ "$source_id" = "source_id" ] && continue
    resolve_preflight_state "$source_id"
  done < <(bash "$SOURCE_REGISTRY_SCRIPT" list)
}

summary_human() {
  local row

  while IFS= read -r row; do
    [ -n "$row" ] || continue
    IFS=$'\t' read -r source_id source_label state state_label_text detail recovery_action install_hint fallback_hint <<EOF
$row
EOF
    [ "$source_id" = "source_id" ] && continue
    printf '%s：%s\n' "$source_label" "$state_label_text"
    printf '  说明：%s\n' "$detail"
    printf '  下一步：%s\n' "$recovery_action"
    printf '  回退：%s\n' "$fallback_hint"
  done < <(summary)
}

command_name="${1:-}"

case "$command_name" in
  check)
    [ "$#" -eq 2 ] || { usage; exit 1; }
    print_header
    resolve_preflight_state "$2"
    ;;
  summary)
    [ "$#" -eq 1 ] || { usage; exit 1; }
    summary
    ;;
  summary-human)
    [ "$#" -eq 1 ] || { usage; exit 1; }
    summary_human
    ;;
  classify-run)
    [ "$#" -eq 4 ] || { usage; exit 1; }
    print_header
    classify_run "$2" "$3" "$4"
    ;;
  *)
    usage
    exit 1
    ;;
esac
