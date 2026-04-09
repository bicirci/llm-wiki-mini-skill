#!/bin/bash
set -euo pipefail

WIKI_ROOT="${1:-$HOME/Documents/我的知识库}"
TOPIC="${2:-我的知识库}"
LANGUAGE="${3:-中文}"
DATE="$(date +%Y-%m-%d)"
SKILL_DIR="$(cd "$(dirname "$0")/.." && pwd)"

replace_vars() {
    local input_file="$1"
    local output_file="$2"

    TOPIC_VALUE="$TOPIC" \
    DATE_VALUE="$DATE" \
    WIKI_ROOT_VALUE="$WIKI_ROOT" \
    LANGUAGE_VALUE="$LANGUAGE" \
    perl -pe '
        s/\{\{TOPIC\}\}/$ENV{TOPIC_VALUE}/g;
        s/\{\{DATE\}\}/$ENV{DATE_VALUE}/g;
        s/\{\{WIKI_ROOT\}\}/$ENV{WIKI_ROOT_VALUE}/g;
        s/\{\{LANGUAGE\}\}/$ENV{LANGUAGE_VALUE}/g;
    ' "$input_file" > "$output_file"
}

echo "正在创建知识库..."
echo "   路径：$WIKI_ROOT"
echo "   主题：$TOPIC"
echo "   语言：$LANGUAGE"
echo ""

mkdir -p "$WIKI_ROOT"/raw/{articles,tweets,wechat,xiaohongshu,zhihu,pdfs,notes,assets}
mkdir -p "$WIKI_ROOT"/wiki/{entities,topics,sources,comparisons,synthesis}

replace_vars "$SKILL_DIR/templates/schema-template.md" "$WIKI_ROOT/.wiki-schema.md"
replace_vars "$SKILL_DIR/templates/index-template.md" "$WIKI_ROOT/index.md"
replace_vars "$SKILL_DIR/templates/log-template.md" "$WIKI_ROOT/log.md"
replace_vars "$SKILL_DIR/templates/overview-template.md" "$WIKI_ROOT/wiki/overview.md"

echo "[完成] 知识库已初始化"
echo ""
echo "下一步："
echo "1. 给我一个本地文件路径"
echo "2. 或直接粘贴正文内容"
echo "3. 如果是 URL，请先复制正文或保存为本地文件"
