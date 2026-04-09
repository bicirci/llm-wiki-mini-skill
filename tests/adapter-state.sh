#!/bin/bash

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

fail() {
    echo "FAIL: $1" >&2
    exit 1
}

assert_text_contains() {
    local text="$1"
    local expected="$2"

    if ! printf '%s' "$text" | grep -F -- "$expected" > /dev/null; then
        fail "Expected output to contain: $expected"
    fi
}

test_core_source_is_available() {
    local output

    output="$(
        bash "$REPO_ROOT/scripts/adapter-state.sh" check local_pdf 2>&1
    )" || fail "adapter-state should support core sources"

    assert_text_contains "$output" "available"
    assert_text_contains "$output" "离线主线可直接进入"
}

test_manual_url_source_is_unsupported() {
    local output

    output="$(
        bash "$REPO_ROOT/scripts/adapter-state.sh" check web_article 2>&1
    )" || fail "adapter-state should mark web URLs as manual-only"

    assert_text_contains "$output" "unsupported"
    assert_text_contains "$output" "请先复制全文"
}

test_classify_run_distinguishes_failed_empty_and_success() {
    local tmp_dir output
    tmp_dir="$(mktemp -d)"
    trap 'rm -rf "$tmp_dir"' RETURN

    : > "$tmp_dir/empty.txt"
    printf 'body\n' > "$tmp_dir/full.txt"

    output="$(
        bash "$REPO_ROOT/scripts/adapter-state.sh" classify-run local_document 1 "$tmp_dir/full.txt" 2>&1
    )" || fail "classify-run should return runtime_failed"
    assert_text_contains "$output" "runtime_failed"

    output="$(
        bash "$REPO_ROOT/scripts/adapter-state.sh" classify-run local_document 0 "$tmp_dir/empty.txt" 2>&1
    )" || fail "classify-run should return empty_result"
    assert_text_contains "$output" "empty_result"

    output="$(
        bash "$REPO_ROOT/scripts/adapter-state.sh" classify-run local_document 0 "$tmp_dir/full.txt" 2>&1
    )" || fail "classify-run should return available"
    assert_text_contains "$output" "available"
}

test_summary_human_mentions_manual_boundary() {
    local output

    output="$(
        bash "$REPO_ROOT/scripts/adapter-state.sh" summary-human 2>&1
    )" || fail "summary-human should succeed"

    assert_text_contains "$output" "网页文章：手动入口"
    assert_text_contains "$output" "PDF / 本地 PDF：可用"
}

test_core_source_is_available
test_manual_url_source_is_unsupported
test_classify_run_distinguishes_failed_empty_and_success
test_summary_human_mentions_manual_boundary

echo "Adapter state checks passed."
