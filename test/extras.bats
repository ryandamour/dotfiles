#!/usr/bin/env bats
# test/extras.bats -- tests for lib/extras.sh

load test_helper/common-setup

setup() {
  TEST_HOME="$(mktemp -d)"
  export HOME="$TEST_HOME"
  export DRY_RUN=false
  MOCK_BIN="$(mktemp -d)"
  export PATH="$MOCK_BIN:$PATH"
  export LIB_DIR

  source "$LIB_DIR/extras.sh"
  unset _EXTRAS_SH_LOADED _CORE_SH_LOADED
}

teardown() {
  [[ -d "${TEST_HOME:-}" ]] && rm -rf "$TEST_HOME"
  [[ -d "${MOCK_BIN:-}" ]] && rm -rf "$MOCK_BIN"
}

# --- install_fonts -----------------------------------------------------------

@test "install_fonts: skips when font already installed" {
  # Mock fc-list to report JetBrainsMono as installed
  cat > "$MOCK_BIN/fc-list" <<'MOCK'
#!/usr/bin/env bash
echo "JetBrainsMono Nerd Font"
MOCK
  chmod +x "$MOCK_BIN/fc-list"

  run bash -c '
    export HOME="'"$TEST_HOME"'"
    export DRY_RUN=false
    export PATH="'"$MOCK_BIN"':$PATH"
    export LIB_DIR="'"$LIB_DIR"'"
    source "$LIB_DIR/extras.sh"
    install_fonts
  '
  [[ "$status" -eq 0 ]]
  [[ "$output" == *"already installed"* ]]
}

@test "install_fonts: respects DRY_RUN" {
  # Mock fc-list to report no matching fonts
  cat > "$MOCK_BIN/fc-list" <<'MOCK'
#!/usr/bin/env bash
echo "DejaVu Sans"
MOCK
  chmod +x "$MOCK_BIN/fc-list"

  run bash -c '
    export HOME="'"$TEST_HOME"'"
    export DRY_RUN=true
    export PATH="'"$MOCK_BIN"':$PATH"
    export LIB_DIR="'"$LIB_DIR"'"
    source "$LIB_DIR/extras.sh"
    install_fonts
  '
  [[ "$status" -eq 0 ]]
  [[ "$output" == *"Dry run"* ]]
  # No font files should exist
  [[ ! -d "$TEST_HOME/.local/share/fonts/NerdFonts" ]]
}

@test "install_fonts: downloads and installs font" {
  # Mock fc-list: no JetBrainsMono
  cat > "$MOCK_BIN/fc-list" <<'MOCK'
#!/usr/bin/env bash
echo "DejaVu Sans"
MOCK
  chmod +x "$MOCK_BIN/fc-list"

  # Mock curl: create a small zip file
  cat > "$MOCK_BIN/curl" <<'MOCK'
#!/usr/bin/env bash
# Parse -o flag to find output path
out=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    -o) out="$2"; shift 2 ;;
    *) shift ;;
  esac
done
# Create a minimal zip with a dummy font file
tmpfont="$(mktemp -d)"
echo "fake font" > "$tmpfont/JetBrainsMono-Regular.ttf"
(cd "$tmpfont" && zip -q "$out" JetBrainsMono-Regular.ttf)
rm -rf "$tmpfont"
MOCK
  chmod +x "$MOCK_BIN/curl"

  # Mock fc-cache: no-op
  cat > "$MOCK_BIN/fc-cache" <<'MOCK'
#!/usr/bin/env bash
exit 0
MOCK
  chmod +x "$MOCK_BIN/fc-cache"

  run bash -c '
    export HOME="'"$TEST_HOME"'"
    export DRY_RUN=false
    export PATH="'"$MOCK_BIN"':$PATH"
    export LIB_DIR="'"$LIB_DIR"'"
    source "$LIB_DIR/extras.sh"
    install_fonts
  '
  [[ "$status" -eq 0 ]]
  [[ -d "$TEST_HOME/.local/share/fonts/NerdFonts" ]]
  [[ -f "$TEST_HOME/.local/share/fonts/NerdFonts/JetBrainsMono-Regular.ttf" ]]
  [[ "$output" == *"Installed"* ]]
}

@test "install_fonts: cleans up temp files" {
  # Mock fc-list: no JetBrainsMono
  cat > "$MOCK_BIN/fc-list" <<'MOCK'
#!/usr/bin/env bash
echo "DejaVu Sans"
MOCK
  chmod +x "$MOCK_BIN/fc-list"

  # Mock curl: create a zip
  cat > "$MOCK_BIN/curl" <<'MOCK'
#!/usr/bin/env bash
out=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    -o) out="$2"; shift 2 ;;
    *) shift ;;
  esac
done
tmpfont="$(mktemp -d)"
echo "fake font" > "$tmpfont/Test.ttf"
(cd "$tmpfont" && zip -q "$out" Test.ttf)
rm -rf "$tmpfont"
MOCK
  chmod +x "$MOCK_BIN/curl"

  # Mock fc-cache
  cat > "$MOCK_BIN/fc-cache" <<'MOCK'
#!/usr/bin/env bash
exit 0
MOCK
  chmod +x "$MOCK_BIN/fc-cache"

  run bash -c '
    export HOME="'"$TEST_HOME"'"
    export DRY_RUN=false
    export PATH="'"$MOCK_BIN"':$PATH"
    export LIB_DIR="'"$LIB_DIR"'"
    source "$LIB_DIR/extras.sh"
    install_fonts
  '
  [[ "$status" -eq 0 ]]
  # No zip files should remain in the font directory
  local zips
  zips=$(find "$TEST_HOME/.local/share/fonts/NerdFonts" -name '*.zip' 2>/dev/null | wc -l)
  [[ "$zips" -eq 0 ]]
  # No leftover temp directories from mktemp (can't easily check, but function should succeed cleanly)
}

# --- install_vscode_flatpak_integration --------------------------------------

@test "install_vscode_flatpak_integration: skips when already set up" {
  # Create the repo dir with .git and the symlink
  local repo_dir="$TEST_HOME/Code/toolbox-vscode"
  mkdir -p "$repo_dir/.git"
  echo '#!/bin/bash' > "$repo_dir/code.sh"

  mkdir -p "$TEST_HOME/.local/bin"
  ln -s "$repo_dir/code.sh" "$TEST_HOME/.local/bin/code"

  run bash -c '
    export HOME="'"$TEST_HOME"'"
    export DRY_RUN=false
    export PATH="'"$MOCK_BIN"':$PATH"
    export LIB_DIR="'"$LIB_DIR"'"
    source "$LIB_DIR/extras.sh"
    install_vscode_flatpak_integration
  '
  [[ "$status" -eq 0 ]]
  [[ "$output" == *"already set up"* ]]
}

@test "install_vscode_flatpak_integration: respects DRY_RUN" {
  run bash -c '
    export HOME="'"$TEST_HOME"'"
    export DRY_RUN=true
    export PATH="'"$MOCK_BIN"':$PATH"
    export LIB_DIR="'"$LIB_DIR"'"
    source "$LIB_DIR/extras.sh"
    install_vscode_flatpak_integration
  '
  [[ "$status" -eq 0 ]]
  [[ "$output" == *"Dry run"* ]]
  # Nothing should have been created
  [[ ! -d "$TEST_HOME/Code/toolbox-vscode" ]]
  [[ ! -L "$TEST_HOME/.local/bin/code" ]]
}

@test "install_vscode_flatpak_integration: clones and creates symlink" {
  # Mock git to simulate clone
  cat > "$MOCK_BIN/git" <<'MOCK'
#!/usr/bin/env bash
if [[ "$1" == "clone" ]]; then
  # Find the target directory (last argument)
  target="${@: -1}"
  mkdir -p "$target/.git"
  echo '#!/bin/bash' > "$target/code.sh"
  chmod +x "$target/code.sh"
  exit 0
fi
exit 0
MOCK
  chmod +x "$MOCK_BIN/git"

  run bash -c '
    export HOME="'"$TEST_HOME"'"
    export DRY_RUN=false
    export PATH="'"$MOCK_BIN"':$PATH"
    export LIB_DIR="'"$LIB_DIR"'"
    source "$LIB_DIR/extras.sh"
    install_vscode_flatpak_integration
  '
  [[ "$status" -eq 0 ]]
  [[ -d "$TEST_HOME/Code/toolbox-vscode/.git" ]]
  [[ -L "$TEST_HOME/.local/bin/code" ]]
  [[ "$output" == *"Created symlink"* ]]
}
