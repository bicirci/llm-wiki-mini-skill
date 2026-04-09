#!/bin/bash

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

fail() {
    echo "FAIL: $1" >&2
    exit 1
}

assert_file_contains() {
    local file="$1"
    local text="$2"

    if ! grep -F -- "$text" "$file" > /dev/null; then
        fail "Expected $file to contain: $text"
    fi
}

assert_file_not_contains() {
    local file="$1"
    local text="$2"

    if grep -F -- "$text" "$file" > /dev/null; then
        fail "Expected $file to not contain: $text"
    fi
}

assert_text_contains() {
    local text="$1"
    local expected="$2"

    if ! printf '%s' "$text" | grep -F -- "$expected" > /dev/null; then
        fail "Expected output to contain: $expected"
    fi
}

assert_path_exists() {
    local path="$1"
    [ -e "$path" ] || fail "Expected path to exist: $path"
}

test_install_dry_run_for_claude_repo_level() {
    local output

    output="$(
        bash "$REPO_ROOT/install.sh" --platform claude --dry-run 2>&1
    )" || fail "install.sh dry-run for Claude should succeed"

    assert_text_contains "$output" "平台：claude"
    assert_text_contains "$output" "$REPO_ROOT/.claude/skills/llm-wiki-mini"
}

test_install_for_codex_copies_bundle_to_repo_level() {
    rm -rf "$REPO_ROOT/.codex"

    bash "$REPO_ROOT/install.sh" --platform codex > /dev/null 2>&1 \
        || fail "install.sh should install for Codex"

    assert_path_exists "$REPO_ROOT/.codex/skills/llm-wiki-mini/SKILL.md"
    assert_path_exists "$REPO_ROOT/.codex/skills/llm-wiki-mini/scripts/source-registry.sh"
    assert_path_exists "$REPO_ROOT/.codex/skills/llm-wiki-mini/scripts/adapter-state.sh"
}

test_setup_installs_to_repo_level_claude() {
    rm -rf "$REPO_ROOT/.claude"

    bash "$REPO_ROOT/setup.sh" > /dev/null 2>&1 \
        || fail "setup.sh should install for Claude"

    assert_path_exists "$REPO_ROOT/.claude/skills/llm-wiki-mini/SKILL.md"
}

test_init_fills_language_placeholder() {
    local tmp_dir wiki_root
    tmp_dir="$(mktemp -d)"
    trap 'rm -rf "$tmp_dir"' RETURN

    wiki_root="$tmp_dir/Test Wiki"
    bash "$REPO_ROOT/scripts/init-wiki.sh" "$wiki_root" "测试主题" "English" > /dev/null

    assert_file_contains "$wiki_root/.wiki-schema.md" "- 语言：English"
    assert_file_not_contains "$wiki_root/.wiki-schema.md" "{{LANGUAGE}}"
}

test_docs_are_repo_level_and_offline_only() {
    assert_file_contains "$REPO_ROOT/README.md" ".claude/skills/llm-wiki-mini"
    assert_file_contains "$REPO_ROOT/README.md" ".codex/skills/llm-wiki-mini"
    assert_file_not_contains "$REPO_ROOT/README.md" "~/.claude/skills"
    assert_file_not_contains "$REPO_ROOT/README.md" "~/.codex/skills"
    assert_file_not_contains "$REPO_ROOT/README.md" "wechat-article-to-markdown"
    assert_file_not_contains "$REPO_ROOT/README.md" "youtube-transcript"
    assert_file_not_contains "$REPO_ROOT/README.md" "baoyu-url-to-markdown"
}

test_source_registry_is_offline_plus_manual() {
    local output

    bash "$REPO_ROOT/scripts/source-registry.sh" validate > /dev/null 2>&1 \
        || fail "source-registry validate should succeed"

    output="$(
        bash "$REPO_ROOT/scripts/source-registry.sh" list 2>&1
    )" || fail "source-registry list should succeed"

    assert_text_contains "$output" "manual_only"
    assert_text_contains "$output" "web_article"
    assert_text_contains "$output" "local_pdf"

    output="$(
        bash "$REPO_ROOT/scripts/source-registry.sh" match-url "https://example.com/post" 2>&1
    )" || fail "source-registry should match generic web URLs"
    assert_text_contains "$output" "web_article"

    output="$(
        bash "$REPO_ROOT/scripts/source-registry.sh" match-file "/tmp/example.pdf" 2>&1
    )" || fail "source-registry should match PDFs"
    assert_text_contains "$output" "local_pdf"
}

test_skill_mentions_manual_url_handling() {
    assert_file_contains "$REPO_ROOT/SKILL.md" "mini 版对 URL 一律不自动提取"
    assert_file_contains "$REPO_ROOT/SKILL.md" "scripts/adapter-state.sh"
}

test_install_dry_run_for_claude_repo_level
test_install_for_codex_copies_bundle_to_repo_level
test_setup_installs_to_repo_level_claude
test_init_fills_language_placeholder
test_docs_are_repo_level_and_offline_only
test_source_registry_is_offline_plus_manual
test_skill_mentions_manual_url_handling

bash "$REPO_ROOT/tests/adapter-state.sh" || fail "adapter-state.sh 测试失败"

echo "All regression checks passed."
