#!/bin/bash

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TARGET_BASE="${1:?usage: bash tests/install-package.sh <target-base-dir>}"

fail() {
    echo "FAIL: $1" >&2
    exit 1
}

assert_path_exists() {
    local path="$1"
    [ -e "$path" ] || fail "Expected path to exist: $path"
}

assert_path_not_exists() {
    local path="$1"
    [ ! -e "$path" ] || fail "Expected path to not exist: $path"
}

assert_file_contains() {
    local file="$1"
    local text="$2"
    grep -F -- "$text" "$file" > /dev/null || fail "Expected $file to contain: $text"
}

assert_file_not_contains() {
    local file="$1"
    local text="$2"
    if grep -F -- "$text" "$file" > /dev/null; then
        fail "Expected $file to not contain: $text"
    fi
}

assert_skill_frontmatter_is_minimal() {
    local file="$1"
    assert_file_contains "$file" "name:"
    assert_file_contains "$file" "description:"
    assert_file_not_contains "$file" "allowed-tools:"
}

prepare_target() {
    local dir="$1"
    rm -rf "$dir"
    mkdir -p "$dir"
}

run_install() {
    local platform="$1"
    local repo_dir="$2"

    bash "$REPO_ROOT/install.sh" --platform "$platform" --target-dir "$repo_dir" > /dev/null 2>&1 \
        || fail "install.sh failed for platform $platform"
}

skill_dir_for_platform() {
    local repo_dir="$1"
    local platform="$2"

    case "$platform" in
        claude)
            printf '%s\n' "$repo_dir/.claude/skills/llm-wiki-mini"
            ;;
        codex)
            printf '%s\n' "$repo_dir/.codex/skills/llm-wiki-mini"
            ;;
        *)
            fail "Unknown platform: $platform"
            ;;
    esac
}

assert_common_layout() {
    local repo_dir="$1"
    local platform="$2"
    local skill_dir

    skill_dir="$(skill_dir_for_platform "$repo_dir" "$platform")"

    assert_path_exists "$skill_dir/SKILL.md"
    assert_path_exists "$skill_dir/references/skill-core.md"
    assert_path_exists "$skill_dir/scripts/source-registry.sh"
    assert_path_exists "$skill_dir/templates/schema-template.md"

    assert_path_not_exists "$repo_dir/install.log"
    assert_path_not_exists "$skill_dir/install.sh"
    assert_path_not_exists "$skill_dir/setup.sh"
    assert_path_not_exists "$skill_dir/install.log"
    assert_path_not_exists "$skill_dir/README.md"
    assert_path_not_exists "$skill_dir/CLAUDE.md"
    assert_path_not_exists "$skill_dir/AGENTS.md"
    assert_path_not_exists "$skill_dir/platforms"
    assert_path_not_exists "$skill_dir/tests"

    assert_file_not_contains "$skill_dir/SKILL.md" "CLAUDE.md"
    assert_file_not_contains "$skill_dir/SKILL.md" "AGENTS.md"
    assert_file_contains "$skill_dir/SKILL.md" "references/skill-core.md"
    assert_skill_frontmatter_is_minimal "$skill_dir/SKILL.md"

    assert_file_not_contains "$skill_dir/references/skill-core.md" "/home/"
    assert_file_not_contains "$skill_dir/SKILL.md" "/home/"
}

assert_claude_layout() {
    local repo_dir="$1"
    local skill_dir
    skill_dir="$(skill_dir_for_platform "$repo_dir" claude)"

    assert_common_layout "$repo_dir" claude
    assert_path_exists "$repo_dir/CLAUDE.md"
    assert_path_not_exists "$repo_dir/AGENTS.md"
    assert_file_contains "$repo_dir/CLAUDE.md" ".claude/skills/llm-wiki-mini/SKILL.md"
    assert_path_not_exists "$skill_dir/agents"
    assert_file_contains "$skill_dir/SKILL.md" "Claude Code"
}

assert_codex_layout() {
    local repo_dir="$1"
    local skill_dir
    skill_dir="$(skill_dir_for_platform "$repo_dir" codex)"

    assert_common_layout "$repo_dir" codex
    assert_path_exists "$repo_dir/AGENTS.md"
    assert_path_not_exists "$repo_dir/CLAUDE.md"
    assert_file_contains "$repo_dir/AGENTS.md" ".codex/skills/llm-wiki-mini/SKILL.md"
    assert_path_exists "$skill_dir/agents/openai.yaml"
    assert_file_contains "$skill_dir/SKILL.md" "Codex"
    assert_file_contains "$skill_dir/agents/openai.yaml" "display_name: llm-wiki-mini"
}

assert_reinstall_cleans_old_installer_files() {
    local platform="$1"
    local repo_dir="$2"
    local skill_dir
    skill_dir="$(skill_dir_for_platform "$repo_dir" "$platform")"

    mkdir -p "$skill_dir"
    printf 'legacy\n' > "$skill_dir/install.sh"
    printf 'legacy\n' > "$skill_dir/README.md"
    mkdir -p "$skill_dir/platforms"

    run_install "$platform" "$repo_dir"

    assert_path_not_exists "$skill_dir/install.sh"
    assert_path_not_exists "$skill_dir/README.md"
    assert_path_not_exists "$skill_dir/platforms"
}

CLAUDE_TARGET="$TARGET_BASE/claude-repo"
CODEX_TARGET="$TARGET_BASE/codex-repo"

prepare_target "$CLAUDE_TARGET"
run_install claude "$CLAUDE_TARGET"
assert_claude_layout "$CLAUDE_TARGET"
assert_reinstall_cleans_old_installer_files claude "$CLAUDE_TARGET"

prepare_target "$CODEX_TARGET"
run_install codex "$CODEX_TARGET"
assert_codex_layout "$CODEX_TARGET"
assert_reinstall_cleans_old_installer_files codex "$CODEX_TARGET"

echo "Install package checks passed."
