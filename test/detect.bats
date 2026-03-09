#!/usr/bin/env bats
# test/detect.bats -- tests for lib/detect.sh

load test_helper/common-setup

setup() {
  TEST_HOME="$(mktemp -d)"
  export HOME="$TEST_HOME"
  export DRY_RUN=false
  MOCK_BIN="$(mktemp -d)"
  export PATH="$MOCK_BIN:$PATH"
  export LIB_DIR
  source "$LIB_DIR/detect.sh"
  unset _DETECT_SH_LOADED _CORE_SH_LOADED
}

teardown() {
  [[ -d "${TEST_HOME:-}" ]] && rm -rf "$TEST_HOME"
  [[ -d "${MOCK_BIN:-}" ]] && rm -rf "$MOCK_BIN"
}

# --- is_silverblue -----------------------------------------------------------

@test "is_silverblue returns true when rpm-ostree works" {
  # Create a mock rpm-ostree that succeeds
  cat > "$MOCK_BIN/rpm-ostree" <<'MOCK'
#!/usr/bin/env bash
exit 0
MOCK
  chmod +x "$MOCK_BIN/rpm-ostree"

  run bash -c 'export PATH="'"$MOCK_BIN"':$PATH"; export LIB_DIR="'"$LIB_DIR"'"; source "$LIB_DIR/detect.sh"; is_silverblue'
  [[ "$status" -eq 0 ]]
}

@test "is_silverblue returns false when rpm-ostree missing" {
  # Ensure no rpm-ostree is on PATH (MOCK_BIN is empty, but system might have it)
  run bash -c 'export PATH="'"$MOCK_BIN"'"; export LIB_DIR="'"$LIB_DIR"'"; source "$LIB_DIR/detect.sh"; is_silverblue'
  [[ "$status" -ne 0 ]]
}

# --- pending_deployment ------------------------------------------------------

@test "pending_deployment returns true when staged deployment present" {
  cat > "$MOCK_BIN/rpm-ostree" <<'MOCK'
#!/usr/bin/env bash
if [[ "$1" == "status" && "$2" == "--json" ]]; then
  echo '{"deployments":[{"staged":true,"booted":false},{"staged":false,"booted":true}]}'
else
  echo "State: idle"
fi
MOCK
  chmod +x "$MOCK_BIN/rpm-ostree"

  run bash -c 'export PATH="'"$MOCK_BIN"':$PATH"; export LIB_DIR="'"$LIB_DIR"'"; source "$LIB_DIR/detect.sh"; pending_deployment'
  [[ "$status" -eq 0 ]]
}

@test "pending_deployment returns false when no PendingDeployment" {
  cat > "$MOCK_BIN/rpm-ostree" <<'MOCK'
#!/usr/bin/env bash
if [[ "$1" == "status" && "$2" == "--json" ]]; then
  echo '{"deployments":[{"staged":false,"booted":true}]}'
else
  echo "State: idle"
fi
MOCK
  chmod +x "$MOCK_BIN/rpm-ostree"

  run bash -c 'export PATH="'"$MOCK_BIN"':$PATH"; export LIB_DIR="'"$LIB_DIR"'"; source "$LIB_DIR/detect.sh"; pending_deployment'
  [[ "$status" -ne 0 ]]
}
