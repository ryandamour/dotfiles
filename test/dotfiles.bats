#!/usr/bin/env bats
# test/dotfiles.bats -- tests for lib/dotfiles.sh

load test_helper/common-setup

setup() {
  TEST_HOME="$(mktemp -d)"
  export HOME="$TEST_HOME"
  export DRY_RUN=false
  MOCK_BIN="$(mktemp -d)"
  export PATH="$MOCK_BIN:$PATH"
  export LIB_DIR

  # Create a temp dotfiles source directory
  DOTFILES_SRC="$(mktemp -d)"
  export DOTFILES_SRC

  source "$LIB_DIR/dotfiles.sh"
  unset _DOTFILES_SH_LOADED _CORE_SH_LOADED
}

teardown() {
  [[ -d "${TEST_HOME:-}" ]] && rm -rf "$TEST_HOME"
  [[ -d "${MOCK_BIN:-}" ]] && rm -rf "$MOCK_BIN"
  [[ -d "${DOTFILES_SRC:-}" ]] && rm -rf "$DOTFILES_SRC"
}

# --- sync_dotfiles: path preservation (the key bug-fix tests) ----------------

@test "sync_dotfiles: .zshrc lands at HOME/.zshrc not HOME/zshrc" {
  echo 'export PATH=/usr/bin' > "$DOTFILES_SRC/.zshrc"

  run bash -c '
    export HOME="'"$TEST_HOME"'"
    export DOTFILES_SRC="'"$DOTFILES_SRC"'"
    export DRY_RUN=false
    export LIB_DIR="'"$LIB_DIR"'"
    source "$LIB_DIR/dotfiles.sh"
    sync_dotfiles
  '
  [[ "$status" -eq 0 ]]
  [[ -f "$TEST_HOME/.zshrc" ]]
  [[ ! -f "$TEST_HOME/zshrc" ]]
  [[ "$(cat "$TEST_HOME/.zshrc")" == "export PATH=/usr/bin" ]]
}

@test "sync_dotfiles: .config/sway/config lands at HOME/.config/sway/config" {
  mkdir -p "$DOTFILES_SRC/.config/sway"
  echo 'set $mod Mod4' > "$DOTFILES_SRC/.config/sway/config"

  run bash -c '
    export HOME="'"$TEST_HOME"'"
    export DOTFILES_SRC="'"$DOTFILES_SRC"'"
    export DRY_RUN=false
    export LIB_DIR="'"$LIB_DIR"'"
    source "$LIB_DIR/dotfiles.sh"
    sync_dotfiles
  '
  [[ "$status" -eq 0 ]]
  [[ -f "$TEST_HOME/.config/sway/config" ]]
  [[ ! -d "$TEST_HOME/config" ]]
  [[ "$(cat "$TEST_HOME/.config/sway/config")" == "set \$mod Mod4" ]]
}

@test "sync_dotfiles: .p10k.zsh lands at HOME/.p10k.zsh" {
  echo 'p10k config' > "$DOTFILES_SRC/.p10k.zsh"

  run bash -c '
    export HOME="'"$TEST_HOME"'"
    export DOTFILES_SRC="'"$DOTFILES_SRC"'"
    export DRY_RUN=false
    export LIB_DIR="'"$LIB_DIR"'"
    source "$LIB_DIR/dotfiles.sh"
    sync_dotfiles
  '
  [[ "$status" -eq 0 ]]
  [[ -f "$TEST_HOME/.p10k.zsh" ]]
  [[ ! -f "$TEST_HOME/p10k.zsh" ]]
}

# --- sync_dotfiles: edge cases -----------------------------------------------

@test "sync_dotfiles: warns on missing DOTFILES_SRC" {
  run bash -c '
    export HOME="'"$TEST_HOME"'"
    export DOTFILES_SRC="/nonexistent/path/dotfiles"
    export DRY_RUN=false
    export LIB_DIR="'"$LIB_DIR"'"
    source "$LIB_DIR/dotfiles.sh"
    sync_dotfiles
  '
  [[ "$status" -eq 0 ]]
  [[ "$output" == *"Dotfiles dir not found"* ]]
}

@test "sync_dotfiles: DRY_RUN shows changes without applying" {
  echo 'test content' > "$DOTFILES_SRC/.zshrc"

  run bash -c '
    export HOME="'"$TEST_HOME"'"
    export DOTFILES_SRC="'"$DOTFILES_SRC"'"
    export DRY_RUN=true
    export LIB_DIR="'"$LIB_DIR"'"
    source "$LIB_DIR/dotfiles.sh"
    sync_dotfiles
  '
  [[ "$status" -eq 0 ]]
  [[ "$output" == *"Dry run"* ]]
  # File should NOT actually be copied in dry-run mode
  [[ ! -f "$TEST_HOME/.zshrc" ]]
}

@test "sync_dotfiles: preserves existing files not in source" {
  # Create a pre-existing file in HOME that is NOT in the dotfiles source
  mkdir -p "$TEST_HOME/.config/nvim"
  echo 'vim config' > "$TEST_HOME/.config/nvim/init.vim"

  # Put something different in dotfiles source
  mkdir -p "$DOTFILES_SRC/.config/sway"
  echo 'sway stuff' > "$DOTFILES_SRC/.config/sway/config"

  run bash -c '
    export HOME="'"$TEST_HOME"'"
    export DOTFILES_SRC="'"$DOTFILES_SRC"'"
    export DRY_RUN=false
    export LIB_DIR="'"$LIB_DIR"'"
    source "$LIB_DIR/dotfiles.sh"
    sync_dotfiles
  '
  [[ "$status" -eq 0 ]]
  # The pre-existing file should still be there
  [[ -f "$TEST_HOME/.config/nvim/init.vim" ]]
  [[ "$(cat "$TEST_HOME/.config/nvim/init.vim")" == "vim config" ]]
  # And the new file should be synced
  [[ -f "$TEST_HOME/.config/sway/config" ]]
}

@test "sync_dotfiles: handles empty dotfiles directory" {
  # DOTFILES_SRC exists but is empty -- rsync should still succeed
  run bash -c '
    export HOME="'"$TEST_HOME"'"
    export DOTFILES_SRC="'"$DOTFILES_SRC"'"
    export DRY_RUN=false
    export LIB_DIR="'"$LIB_DIR"'"
    source "$LIB_DIR/dotfiles.sh"
    sync_dotfiles
  '
  [[ "$status" -eq 0 ]]
  [[ "$output" == *"Dotfiles synced"* ]]
}
