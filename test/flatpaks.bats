#!/usr/bin/env bats
# test/flatpaks.bats -- tests for lib/flatpaks.sh

load test_helper/common-setup

setup() {
  TEST_HOME="$(mktemp -d)"
  export HOME="$TEST_HOME"
  export DRY_RUN=false
  MOCK_BIN="$(mktemp -d)"
  export PATH="$MOCK_BIN:$PATH"
  export LIB_DIR

  source "$LIB_DIR/flatpaks.sh"
}

teardown() {
  [[ -d "${TEST_HOME:-}" ]] && rm -rf "$TEST_HOME"
  [[ -d "${MOCK_BIN:-}" ]] && rm -rf "$MOCK_BIN"
}

@test "flatpak_installed returns 0 for installed app" {
  cat > "$MOCK_BIN/flatpak" << 'MOCK'
#!/bin/bash
if [[ "$1" == "list" && "$2" == "--app" ]]; then
  echo "com.example.Installed"
  exit 0
fi
echo ""
MOCK
  chmod +x "$MOCK_BIN/flatpak"

  run flatpak_installed "com.example.Installed"
  [ "$status" -eq 0 ]
}

@test "flatpak_installed returns 1 for missing app" {
  cat > "$MOCK_BIN/flatpak" << 'MOCK'
#!/bin/bash
echo ""
exit 0
MOCK
  chmod +x "$MOCK_BIN/flatpak"

  run flatpak_installed "com.example.Missing"
  [ "$status" -eq 1 ]
}

@test "install_flatpaks skips when flatpak not found" {
  # Remove any flatpak mock
  rm -f "$MOCK_BIN/flatpak"

  run bash -c '
    export PATH="'"$MOCK_BIN"'"
    export LIB_DIR="'"$LIB_DIR"'"
    export DRY_RUN=false
    export FLATPAK_FILE="'"$TEST_HOME"'/flatpak.yaml"
    export FLATPAK_SCOPE="user"
    source "$LIB_DIR/flatpaks.sh"
    install_flatpaks
  '
  [ "$status" -eq 0 ]
  [[ "$output" == *"flatpak not found"* ]]
}

@test "install_flatpaks skips when FLATPAK_FILE missing" {
  cat > "$MOCK_BIN/flatpak" << 'MOCK'
#!/bin/bash
exit 0
MOCK
  chmod +x "$MOCK_BIN/flatpak"

  export FLATPAK_FILE="$TEST_HOME/nonexistent.yaml"
  export FLATPAK_SCOPE="user"

  run install_flatpaks
  [ "$status" -eq 0 ]
  [[ "$output" == *"No $FLATPAK_FILE found"* ]]
}

@test "install_flatpaks installs missing flatpaks" {
  cat > "$MOCK_BIN/flatpak" << 'MOCK'
#!/bin/bash
case "$1" in
  list)
    echo ""
    ;;
  remotes)
    echo "flathub"
    ;;
  install)
    echo "flatpak-install-called: $*"
    ;;
esac
exit 0
MOCK
  chmod +x "$MOCK_BIN/flatpak"

  export FLATPAK_FILE="$TEST_HOME/flatpak.yaml"
  export FLATPAK_SCOPE="user"
  cat > "$FLATPAK_FILE" << 'YAML'
flatpaks:
  - com.example.NewApp
YAML

  run install_flatpaks
  [ "$status" -eq 0 ]
  [[ "$output" == *"Installing flatpak: com.example.NewApp"* ]]
}

@test "install_flatpaks skips installed flatpaks" {
  cat > "$MOCK_BIN/flatpak" << 'MOCK'
#!/bin/bash
case "$1" in
  list)
    if [[ "$2" == "--app" ]]; then
      echo "com.example.AlreadyInstalled"
    fi
    ;;
  remotes)
    echo "flathub"
    ;;
esac
exit 0
MOCK
  chmod +x "$MOCK_BIN/flatpak"

  export FLATPAK_FILE="$TEST_HOME/flatpak.yaml"
  export FLATPAK_SCOPE="user"
  cat > "$FLATPAK_FILE" << 'YAML'
flatpaks:
  - com.example.AlreadyInstalled
YAML

  run install_flatpaks
  [ "$status" -eq 0 ]
  [[ "$output" == *"Flatpak already installed: com.example.AlreadyInstalled"* ]]
}

@test "install_flatpaks respects DRY_RUN" {
  cat > "$MOCK_BIN/flatpak" << 'MOCK'
#!/bin/bash
case "$1" in
  list)
    echo ""
    ;;
  remotes)
    echo "flathub"
    ;;
esac
exit 0
MOCK
  chmod +x "$MOCK_BIN/flatpak"

  export FLATPAK_FILE="$TEST_HOME/flatpak.yaml"
  export FLATPAK_SCOPE="user"
  export DRY_RUN=true
  cat > "$FLATPAK_FILE" << 'YAML'
flatpaks:
  - com.example.DryRunApp
YAML

  run install_flatpaks
  [ "$status" -eq 0 ]
  [[ "$output" == *"Dry run: would install flatpak com.example.DryRunApp"* ]]
}
