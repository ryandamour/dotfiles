#!/usr/bin/env bats
# test/core.bats -- tests for lib/core.sh

load test_helper/common-setup

setup() {
  TEST_HOME="$(mktemp -d)"
  export HOME="$TEST_HOME"
  export DRY_RUN=false
  MOCK_BIN="$(mktemp -d)"
  export PATH="$MOCK_BIN:$PATH"
  source "$LIB_DIR/core.sh"
  unset _CORE_SH_LOADED  # allow re-sourcing in subshells
}

teardown() {
  [[ -d "${TEST_HOME:-}" ]] && rm -rf "$TEST_HOME"
  [[ -d "${MOCK_BIN:-}" ]] && rm -rf "$MOCK_BIN"
}

# --- log / warn / err --------------------------------------------------------

@test "log prints [INFO] to stdout" {
  run log "hello world"
  [[ "$status" -eq 0 ]]
  [[ "$output" == *"[INFO]"* ]]
  [[ "$output" == *"hello world"* ]]
}

@test "warn prints [WARN] to stdout" {
  run warn "caution"
  [[ "$status" -eq 0 ]]
  [[ "$output" == *"[WARN]"* ]]
  [[ "$output" == *"caution"* ]]
}

@test "err prints [ERR] to stderr" {
  run bash -c 'source "'"$LIB_DIR"'/core.sh"; err "bad thing" 2>&1'
  [[ "$status" -eq 0 ]]
  [[ "$output" == *"[ERR]"* ]]
  [[ "$output" == *"bad thing"* ]]
}

# --- have_cmd ----------------------------------------------------------------

@test "have_cmd succeeds for existing command" {
  run have_cmd bash
  [[ "$status" -eq 0 ]]
}

@test "have_cmd fails for missing command" {
  run have_cmd __no_such_command_xyz__
  [[ "$status" -ne 0 ]]
}

# --- need_cmd ----------------------------------------------------------------

@test "need_cmd succeeds for existing command" {
  run need_cmd bash
  [[ "$status" -eq 0 ]]
}

@test "need_cmd exits 1 for missing command" {
  run bash -c 'source "'"$LIB_DIR"'/core.sh"; need_cmd __no_such_command_xyz__'
  [[ "$status" -eq 1 ]]
  [[ "$output" == *"Missing required command"* ]]
}

# --- dedupe ------------------------------------------------------------------

@test "dedupe removes duplicates preserving order" {
  local result=()
  dedupe result a b c b a d
  [[ "${result[*]}" == "a b c d" ]]
}

@test "dedupe handles empty input" {
  local result=()
  dedupe result
  [[ "${#result[@]}" -eq 0 ]]
}

# --- backup_dirname ----------------------------------------------------------

@test "backup_dirname generates correct format" {
  run backup_dirname "/home/user/.config/nvim"
  [[ "$status" -eq 0 ]]
  [[ "$output" =~ ^/home/user/.config/nvim\.bak\.[0-9]{8}-[0-9]{6}$ ]]
}

# --- ensure_line_in_file -----------------------------------------------------

@test "ensure_line_in_file creates file and appends line" {
  local f="$TEST_HOME/testfile"
  ensure_line_in_file "$f" "hello"
  [[ -f "$f" ]]
  run grep -Fxc "hello" "$f"
  [[ "$output" == "1" ]]
}

@test "ensure_line_in_file is idempotent" {
  local f="$TEST_HOME/testfile"
  ensure_line_in_file "$f" "hello"
  ensure_line_in_file "$f" "hello"
  run grep -Fxc "hello" "$f"
  [[ "$output" == "1" ]]
}

@test "ensure_line_in_file respects DRY_RUN" {
  local f="$TEST_HOME/dryfile"
  export DRY_RUN=true
  run bash -c '
    source "'"$LIB_DIR"'/core.sh"
    export DRY_RUN=true
    ensure_line_in_file "'"$f"'" "should not appear"
  '
  [[ "$output" == *"Dry run"* ]]
  # File may be created (touch) but line must not be appended
  if [[ -f "$f" ]]; then
    run grep -Fxc "should not appear" "$f"
    [[ "$output" == "0" ]]
  fi
}
