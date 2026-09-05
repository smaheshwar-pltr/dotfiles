#!/usr/bin/env bash

set -euo pipefail

REPOSITORY_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPT="$REPOSITORY_ROOT/codex-overnight"
TEST_ROOT="$(mktemp -d)"

cleanup() {
    rm -rf -- "$TEST_ROOT"
}
trap cleanup EXIT

fail() {
    echo "FAIL: $1" >&2
    exit 1
}

assert_contains() {
    local file="$1"
    local expected="$2"

    grep -Fq -- "$expected" "$file" || fail "expected '$expected' in $file"
}

assert_not_contains() {
    local file="$1"
    local unexpected="$2"

    if grep -Fq -- "$unexpected" "$file"; then
        fail "did not expect '$unexpected' in $file"
    fi
}

make_fake_codex() {
    local path="$1"

    cat >"$path" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

count=0
if [ -f "$FAKE_COUNT_FILE" ]; then
    count="$(<"$FAKE_COUNT_FILE")"
fi
count=$((count + 1))
printf '%s\n' "$count" >"$FAKE_COUNT_FILE"
printf '%s\n' "$@" >>"$FAKE_ARGS_FILE"

case "$FAKE_SCENARIO" in
    limit-then-success)
        if [ "$count" -eq 1 ]; then
            echo "ERROR: You've hit your usage limit. Try again later." >&2
            exit 1
        fi
        echo "Task complete."
        ;;
    approaching-limit)
        echo "You're approaching your usage limit. Switch models?" >&2
        exit 75
        ;;
    *)
        echo "unexpected fake scenario: $FAKE_SCENARIO" >&2
        exit 99
        ;;
esac
EOF
    chmod +x "$path"
}

TARGET_REPOSITORY="$TEST_ROOT/project"
STATE_DIR="$TEST_ROOT/state"
FAKE_CODEX="$TEST_ROOT/codex"
FAKE_COUNT_FILE="$TEST_ROOT/count"
FAKE_ARGS_FILE="$TEST_ROOT/args"

mkdir -p "$TARGET_REPOSITORY"
git -C "$TARGET_REPOSITORY" init -q
make_fake_codex "$FAKE_CODEX"

export CODEX_BIN="$FAKE_CODEX"
export CODEX_OVERNIGHT_RETRY_SECONDS=0
export CODEX_OVERNIGHT_STATE_DIR="$STATE_DIR"
export FAKE_COUNT_FILE FAKE_ARGS_FILE

FAKE_SCENARIO=limit-then-success
export FAKE_SCENARIO

"$SCRIPT" "$TARGET_REPOSITORY" session-123 >"$TEST_ROOT/limit-output"

[ "$(<"$FAKE_COUNT_FILE")" -eq 2 ] || fail "usage limit should retry once"
assert_contains "$FAKE_ARGS_FILE" "workspace-write"
assert_contains "$FAKE_ARGS_FILE" "resume"
assert_contains "$FAKE_ARGS_FILE" "session-123"
assert_not_contains "$FAKE_ARGS_FILE" "--model"
assert_not_contains "$FAKE_ARGS_FILE" "--ask-for-approval"
assert_contains "$TEST_ROOT/limit-output" "Usage limit reached; retrying in 0 seconds."
assert_contains "$TEST_ROOT/limit-output" "Codex completed successfully."

rm -f -- "$FAKE_COUNT_FILE" "$FAKE_ARGS_FILE"
FAKE_SCENARIO=approaching-limit
export FAKE_SCENARIO

set +e
"$SCRIPT" "$TARGET_REPOSITORY" session-456 >"$TEST_ROOT/approaching-output" 2>&1
status=$?
set -e

[ "$status" -eq 75 ] || fail "approaching-limit failure should exit with status 75"
[ "$(<"$FAKE_COUNT_FILE")" -eq 1 ] || fail "approaching-limit warning should not retry"
assert_contains "$TEST_ROOT/approaching-output" "failed without the expected usage-limit message"

echo "PASS: codex-overnight"
