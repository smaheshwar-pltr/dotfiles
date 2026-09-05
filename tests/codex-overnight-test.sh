#!/usr/bin/env bash

set -euo pipefail

REPOSITORY_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPT="$REPOSITORY_ROOT/codex-overnight"
TEST_ROOT="$(mktemp -d)"
DEFAULT_PROMPT="Continue the existing task until it is complete or genuinely blocked. First reconcile the saved session with the repository's current state and preserve correct partial work. Run the relevant tests before finishing."
FIRST_PID=""

cleanup() {
    if [ -n "$FIRST_PID" ]; then
        kill "$FIRST_PID" 2>/dev/null || true
        wait "$FIRST_PID" 2>/dev/null || true
    fi
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

assert_args_repeated() {
    local attempts="$1"
    shift
    local expected=("$@")
    local actual=()
    local expected_count=$((attempts * ${#expected[@]}))
    local index

    mapfile -d '' actual <"$FAKE_ARGS_FILE"
    [ "${#actual[@]}" -eq "$expected_count" ] ||
        fail "expected $expected_count arguments, found ${#actual[@]}"

    for ((index = 0; index < expected_count; index++)); do
        [ "${actual[index]}" = "${expected[index % ${#expected[@]}]}" ] ||
            fail "argument $index: expected '${expected[index % ${#expected[@]}]}', found '${actual[index]}'"
    done
}

reset_fake() {
    rm -f -- "$FAKE_COUNT_FILE" "$FAKE_ARGS_FILE"
}

run_in_target() {
    (cd "$TARGET_REPOSITORY" && "$SCRIPT" "$@")
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
printf '%s\0' "$@" >>"$FAKE_ARGS_FILE"
if [ -e /proc/$$/fd/9 ]; then
    echo "session lock leaked into Codex" >&2
    exit 88
fi

case "$FAKE_SCENARIO" in
    limit-then-success)
        if [ "$count" -eq 1 ]; then
            echo '{"type":"error","message":"You'"'"'ve hit your usage limit. Try again later."}'
            exit 1
        fi
        echo '{"type":"turn.completed","usage":{}}'
        ;;
    turn-failed-then-success)
        if [ "$count" -eq 1 ]; then
            echo '{"type":"turn.failed","error":{"message":"You'"'"'ve hit your usage limit. Try again later."}}'
            exit 1
        fi
        echo '{"type":"turn.completed","usage":{}}'
        ;;
    approaching-limit)
        echo '{"type":"item.completed","item":{"type":"error","message":"Approaching rate limits"}}'
        exit 75
        ;;
    phrase-in-output)
        echo '{"type":"item.completed","item":{"type":"agent_message","text":"You'"'"'ve hit your usage limit"}}'
        exit 76
        ;;
    wait-for-release)
        touch "$FAKE_READY_FILE"
        read -r _ <"$FAKE_RELEASE_FIFO"
        echo '{"type":"turn.completed","usage":{}}'
        ;;
    success)
        echo '{"type":"turn.completed","usage":{}}'
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

mkdir -p "$TARGET_REPOSITORY" "$TEST_ROOT/runtime"
git -C "$TARGET_REPOSITORY" init -q
make_fake_codex "$FAKE_CODEX"

export CODEX_BIN="$FAKE_CODEX"
export CODEX_OVERNIGHT_RETRY_SECONDS=0
export CODEX_OVERNIGHT_STATE_DIR="$STATE_DIR"
export XDG_RUNTIME_DIR="$TEST_ROOT/runtime"
export FAKE_COUNT_FILE FAKE_ARGS_FILE

FAKE_SCENARIO=limit-then-success
CODEX_OVERNIGHT_PROFILE=overnight
export FAKE_SCENARIO CODEX_OVERNIGHT_PROFILE

run_in_target session-123 >"$TEST_ROOT/limit-output"

[ "$(<"$FAKE_COUNT_FILE")" -eq 2 ] || fail "usage limit should retry once"
assert_args_repeated 2 \
    exec --color never --json --profile overnight \
    resume -- session-123 "$DEFAULT_PROMPT"
assert_contains "$TEST_ROOT/limit-output" "Usage limit reached; retrying in 0 seconds."
assert_contains "$TEST_ROOT/limit-output" "Codex completed successfully."

reset_fake
unset CODEX_OVERNIGHT_PROFILE
FAKE_SCENARIO=turn-failed-then-success
export FAKE_SCENARIO

run_in_target turn-failed >"$TEST_ROOT/turn-failed-output"
[ "$(<"$FAKE_COUNT_FILE")" -eq 2 ] || fail "turn.failed usage limit should retry once"
assert_args_repeated 2 exec --color never --json resume -- turn-failed "$DEFAULT_PROMPT"
assert_contains "$TEST_ROOT/turn-failed-output" "Usage limit reached; retrying in 0 seconds."

reset_fake
unset CODEX_OVERNIGHT_PROFILE
FAKE_SCENARIO=approaching-limit
export FAKE_SCENARIO

set +e
run_in_target session-456 >"$TEST_ROOT/approaching-output" 2>&1
status=$?
set -e

[ "$status" -eq 75 ] || fail "approaching-limit failure should exit with status 75"
[ "$(<"$FAKE_COUNT_FILE")" -eq 1 ] || fail "approaching-limit warning should not retry"
assert_args_repeated 1 exec --color never --json resume -- session-456 "$DEFAULT_PROMPT"
assert_contains "$TEST_ROOT/approaching-output" "failed without a usage-limit error event"

reset_fake
FAKE_SCENARIO=phrase-in-output
export FAKE_SCENARIO

set +e
run_in_target session-789 >"$TEST_ROOT/phrase-output" 2>&1
status=$?
set -e

[ "$status" -eq 76 ] || fail "quoted limit text should exit with status 76"
[ "$(<"$FAKE_COUNT_FILE")" -eq 1 ] || fail "quoted limit text should not retry"
assert_contains "$TEST_ROOT/phrase-output" "failed without a usage-limit error event"

reset_fake
FAKE_SCENARIO=success
export FAKE_SCENARIO

run_in_target option-prompt --help >"$TEST_ROOT/option-output"
assert_args_repeated 1 exec --color never --json resume -- option-prompt --help

reset_fake
set +e
CODEX_OVERNIGHT_STATE_DIR=relative-state \
    run_in_target relative-state >"$TEST_ROOT/relative-output" 2>&1
status=$?
set -e
[ "$status" -eq 2 ] || fail "relative state directory should exit with status 2"
assert_contains "$TEST_ROOT/relative-output" "must be an absolute path"
[ ! -e "$TARGET_REPOSITORY/relative-state" ] || fail "relative state directory leaked into target repository"
[ ! -e "$FAKE_COUNT_FILE" ] || fail "Codex should not start with a relative state directory"

reset_fake
touch "$TEST_ROOT/not-a-directory"
set +e
CODEX_OVERNIGHT_STATE_DIR="$TEST_ROOT/not-a-directory" \
    run_in_target invalid-state >"$TEST_ROOT/state-output" 2>&1
status=$?
set -e
[ "$status" -eq 1 ] || fail "invalid state directory should exit with status 1"
assert_contains "$TEST_ROOT/state-output" "cannot create state directory"
[ ! -e "$FAKE_COUNT_FILE" ] || fail "Codex should not start with an invalid state directory"

reset_fake
FULL_STATE_DIR="$TEST_ROOT/full-state"
FULL_SESSION_KEY="$(printf '%s' log-failure | cksum | awk '{print $1}')"
mkdir -p "$FULL_STATE_DIR"
ln -s /dev/full "$FULL_STATE_DIR/session-$FULL_SESSION_KEY.log"
set +e
CODEX_OVERNIGHT_STATE_DIR="$FULL_STATE_DIR" \
    run_in_target log-failure >"$TEST_ROOT/log-output" 2>&1
status=$?
set -e
[ "$status" -eq 1 ] || fail "log write failure should exit with status 1"
assert_contains "$TEST_ROOT/log-output" "cannot write log"
[ ! -e "$FAKE_COUNT_FILE" ] || fail "Codex should not start when logging fails"

if command -v flock >/dev/null 2>&1; then
    reset_fake
    FAKE_SCENARIO=wait-for-release
    FAKE_READY_FILE="$TEST_ROOT/ready"
    FAKE_RELEASE_FIFO="$TEST_ROOT/release"
    export FAKE_SCENARIO FAKE_READY_FILE FAKE_RELEASE_FIFO
    mkfifo "$FAKE_RELEASE_FIFO"

    CODEX_OVERNIGHT_STATE_DIR="$TEST_ROOT/state-a" \
        run_in_target locked-session >"$TEST_ROOT/first-lock-output" 2>&1 &
    FIRST_PID=$!
    for _ in {1..50}; do
        [ -e "$FAKE_READY_FILE" ] && break
        sleep 0.1
    done
    [ -e "$FAKE_READY_FILE" ] || fail "first runner did not start"

    set +e
    CODEX_OVERNIGHT_STATE_DIR="$TEST_ROOT/state-b" \
        run_in_target locked-session >"$TEST_ROOT/second-lock-output" 2>&1
    status=$?
    set -e
    [ "$status" -eq 1 ] || fail "second runner should fail to acquire the session lock"
    assert_contains "$TEST_ROOT/second-lock-output" "another runner is already using this session"

    printf 'continue\n' >"$FAKE_RELEASE_FIFO"
    wait "$FIRST_PID"
    FIRST_PID=""
fi

echo "PASS: codex-overnight"
