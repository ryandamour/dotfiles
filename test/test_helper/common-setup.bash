# test/test_helper/common-setup.bash -- shared BATS helpers

# Resolve LIB_DIR to the project's lib/ directory
LIB_DIR="$(cd "$(dirname "${BATS_TEST_FILENAME}")/../lib" && pwd)"

_common_setup() {
  TEST_HOME="$(mktemp -d)"
  export HOME="$TEST_HOME"
  export DRY_RUN=false

  # Mock bin directory
  MOCK_BIN="$(mktemp -d)"
  export PATH="$MOCK_BIN:$PATH"
}

setup() {
  _common_setup
}

teardown() {
  [[ -d "${TEST_HOME:-}" ]] && rm -rf "$TEST_HOME"
  [[ -d "${MOCK_BIN:-}" ]] && rm -rf "$MOCK_BIN"
}
