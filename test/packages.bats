#!/usr/bin/env bats
# test/packages.bats -- tests for lib/packages.sh

load test_helper/common-setup

setup() {
  TEST_HOME="$(mktemp -d)"
  export HOME="$TEST_HOME"
  export DRY_RUN=false
  MOCK_BIN="$(mktemp -d)"
  export PATH="$MOCK_BIN:$PATH"
  export LIB_DIR

  # Mock rpm-ostree for pending_deployment (default: no pending)
  cat > "$MOCK_BIN/rpm-ostree" << 'MOCK'
#!/bin/bash
echo "State: idle"
exit 0
MOCK
  chmod +x "$MOCK_BIN/rpm-ostree"

  source "$LIB_DIR/packages.sh"
}

teardown() {
  [[ -d "${TEST_HOME:-}" ]] && rm -rf "$TEST_HOME"
  [[ -d "${MOCK_BIN:-}" ]] && rm -rf "$MOCK_BIN"
}

@test "have_pkg returns 0 for installed package" {
  cat > "$MOCK_BIN/rpm" << 'MOCK'
#!/bin/bash
if [[ "$1" == "-q" && "$2" == "installed-pkg" ]]; then
  exit 0
fi
exit 1
MOCK
  chmod +x "$MOCK_BIN/rpm"

  run have_pkg "installed-pkg"
  [ "$status" -eq 0 ]
}

@test "have_pkg returns 1 for missing package" {
  cat > "$MOCK_BIN/rpm" << 'MOCK'
#!/bin/bash
exit 1
MOCK
  chmod +x "$MOCK_BIN/rpm"

  run have_pkg "missing-pkg"
  [ "$status" -eq 1 ]
}

@test "install_packages skips already-installed packages" {
  cat > "$MOCK_BIN/rpm" << 'MOCK'
#!/bin/bash
if [[ "$1" == "-q" ]]; then
  exit 0
fi
MOCK
  chmod +x "$MOCK_BIN/rpm"

  run install_packages "already-here" "also-here"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Already installed: already-here"* ]]
  [[ "$output" == *"Already installed: also-here"* ]]
  [[ "$output" == *"All dependencies already present"* ]]
}

@test "install_packages calls rpm-ostree for missing packages" {
  cat > "$MOCK_BIN/rpm" << 'MOCK'
#!/bin/bash
exit 1
MOCK
  chmod +x "$MOCK_BIN/rpm"

  cat > "$MOCK_BIN/rpm-ostree" << 'MOCK'
#!/bin/bash
if [[ "$1" == "install" ]]; then
  echo "rpm-ostree-called: $*"
  exit 0
fi
if [[ "$1" == "status" ]]; then
  echo "no pending"
  exit 0
fi
MOCK
  chmod +x "$MOCK_BIN/rpm-ostree"

  cat > "$MOCK_BIN/sudo" << 'MOCK'
#!/bin/bash
"$@"
MOCK
  chmod +x "$MOCK_BIN/sudo"

  run install_packages "new-pkg1" "new-pkg2"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Missing packages: new-pkg1 new-pkg2"* ]]
  [[ "$output" == *"rpm-ostree-called: install new-pkg1 new-pkg2"* ]]
}

@test "install_packages respects DRY_RUN" {
  cat > "$MOCK_BIN/rpm" << 'MOCK'
#!/bin/bash
exit 1
MOCK
  chmod +x "$MOCK_BIN/rpm"

  export DRY_RUN=true

  run install_packages "new-pkg"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Dry run: would run: rpm-ostree install new-pkg"* ]]
}
