#!/usr/bin/env bats
# test/zsh.bats — Tests for lib/zsh.sh

setup() {
  load 'test_helper/common-setup'
  _common_setup
  source "$LIB_DIR/zsh.sh"

  # Defaults used by the zsh functions
  export OHMYZSH_DIR="$HOME/.oh-my-zsh"
  export OHMYZSH_THEME=""
  export OHMYZSH_PLUGINS="git"
  export P10K_DIR="$HOME/.local/share/powerlevel10k"
  export P10K_REPO="https://github.com/romkatv/powerlevel10k.git"
  export P10K_CONFIG_SRC=""
  export FORCE_P10K=false
  export DO_CHSH=true

  # Mock zsh as available
  cat > "$MOCK_BIN/zsh" << 'MOCK'
#!/bin/bash
exit 0
MOCK
  chmod +x "$MOCK_BIN/zsh"

  # Mock git to succeed silently
  cat > "$MOCK_BIN/git" << 'MOCK'
#!/bin/bash
case "$1" in
  clone)
    # Create the target directory to simulate a clone
    target="${@: -1}"
    mkdir -p "$target/.git"
    ;;
  -C)
    exit 0
    ;;
esac
exit 0
MOCK
  chmod +x "$MOCK_BIN/git"

  # Mock rpm-ostree to report no pending deployment
  cat > "$MOCK_BIN/rpm-ostree" << 'MOCK'
#!/bin/bash
case "$1" in
  status)
    echo "State: idle"
    echo "Deployments:"
    echo "● fedora:fedora/41/x86_64/silverblue"
    ;;
esac
exit 0
MOCK
  chmod +x "$MOCK_BIN/rpm-ostree"
}

# ---------------------------------------------------------------------------
# bootstrap_ohmyzsh
# ---------------------------------------------------------------------------

@test "bootstrap_ohmyzsh: skips when zsh not available" {
  rm -f "$MOCK_BIN/zsh"
  PATH="$MOCK_BIN" run bootstrap_ohmyzsh
  [ "$status" -eq 0 ]
  [[ "$output" == *"zsh not available"* ]]
}

@test "bootstrap_ohmyzsh: installs even with pending deployment" {
  cat > "$MOCK_BIN/rpm-ostree" << 'MOCK'
#!/bin/bash
if [[ "$1" == "status" && "$2" == "--json" ]]; then
  echo '{"deployments":[{"staged":true,"booted":false}]}'
else
  echo "State: idle"
fi
MOCK
  chmod +x "$MOCK_BIN/rpm-ostree"

  run bootstrap_ohmyzsh
  [ "$status" -eq 0 ]
  [ -d "$OHMYZSH_DIR/.git" ]
}

@test "bootstrap_ohmyzsh: clones oh-my-zsh when not present" {
  run bootstrap_ohmyzsh
  [ "$status" -eq 0 ]
  [ -d "$OHMYZSH_DIR/.git" ]
}

@test "bootstrap_ohmyzsh: updates oh-my-zsh when already present" {
  mkdir -p "$OHMYZSH_DIR/.git"
  run bootstrap_ohmyzsh
  [ "$status" -eq 0 ]
  [[ "$output" == *"already present"* ]]
}

@test "bootstrap_ohmyzsh: writes managed block to .zshrc" {
  touch "$HOME/.zshrc"
  run bootstrap_ohmyzsh
  [ "$status" -eq 0 ]
  grep -q '# >>> oh-my-zsh (managed)' "$HOME/.zshrc"
  grep -q '# <<< oh-my-zsh (managed)' "$HOME/.zshrc"
  grep -q 'plugins=(git)' "$HOME/.zshrc"
}

@test "bootstrap_ohmyzsh: includes requested plugins in managed block" {
  touch "$HOME/.zshrc"
  OHMYZSH_PLUGINS="git,zsh-autosuggestions,zsh-syntax-highlighting"
  run bootstrap_ohmyzsh
  [ "$status" -eq 0 ]
  grep -q 'plugins=(git zsh-autosuggestions zsh-syntax-highlighting)' "$HOME/.zshrc"
}

@test "bootstrap_ohmyzsh: dry run does not create files" {
  DRY_RUN=true
  touch "$HOME/.zshrc"
  run bootstrap_ohmyzsh
  [ "$status" -eq 0 ]
  [ ! -d "$OHMYZSH_DIR" ]
}

@test "bootstrap_ohmyzsh: no duplicate zsh-autosuggestions clone" {
  # Track all git clone calls
  cat > "$MOCK_BIN/git" << 'MOCK'
#!/bin/bash
if [[ "$1" == "clone" ]]; then
  echo "GIT_CLONE: ${@: -1}" >> "${HOME}/.git_clone_log"
  target="${@: -1}"
  mkdir -p "$target/.git"
fi
exit 0
MOCK
  chmod +x "$MOCK_BIN/git"

  touch "$HOME/.zshrc"
  OHMYZSH_PLUGINS="git,zsh-autosuggestions"
  run bootstrap_ohmyzsh
  [ "$status" -eq 0 ]

  # Count how many times zsh-autosuggestions was cloned - should be exactly once
  local count
  count=$(grep -c "zsh-autosuggestions" "$HOME/.git_clone_log" 2>/dev/null || echo 0)
  [ "$count" -le 1 ]
}

# ---------------------------------------------------------------------------
# bootstrap_powerlevel10k
# ---------------------------------------------------------------------------

@test "bootstrap_powerlevel10k: clones p10k when not present" {
  touch "$HOME/.zshrc"
  run bootstrap_powerlevel10k
  [ "$status" -eq 0 ]
  [ -d "$P10K_DIR/.git" ]
}

@test "bootstrap_powerlevel10k: writes managed block to .zshrc" {
  touch "$HOME/.zshrc"
  run bootstrap_powerlevel10k
  [ "$status" -eq 0 ]
  grep -q '# >>> powerlevel10k (managed)' "$HOME/.zshrc"
  grep -q '# <<< powerlevel10k (managed)' "$HOME/.zshrc"
}

# ---------------------------------------------------------------------------
# set_shell_zsh
# ---------------------------------------------------------------------------

@test "set_shell_zsh: skips when DO_CHSH is false" {
  DO_CHSH=false
  run set_shell_zsh
  [ "$status" -eq 0 ]
  [[ "$output" == *"Skipping chsh"* ]]
}

@test "set_shell_zsh: skips when zsh not installed" {
  rm -f "$MOCK_BIN/zsh"
  PATH="$MOCK_BIN" run set_shell_zsh
  [ "$status" -eq 0 ]
  [[ "$output" == *"zsh not installed"* ]]
}

@test "set_shell_zsh: skips when already using zsh" {
  export SHELL="/usr/bin/zsh"
  run set_shell_zsh
  [ "$status" -eq 0 ]
  [[ "$output" == *"already set to zsh"* ]]
}

@test "set_shell_zsh: dry run does not call chsh" {
  DRY_RUN=true
  export SHELL="/bin/bash"
  run set_shell_zsh
  [ "$status" -eq 0 ]
  [[ "$output" == *"Dry run"* ]]
}

# ---------------------------------------------------------------------------
# _write_managed_block
# ---------------------------------------------------------------------------

@test "_write_managed_block: appends block when not present" {
  local f="$HOME/.testrc"
  echo "existing content" > "$f"
  local begin="# >>> test (managed)"
  local end="# <<< test (managed)"
  local block="${begin}
some config
${end}"

  run _write_managed_block "$f" "$begin" "$end" "$block"
  [ "$status" -eq 0 ]
  grep -q "existing content" "$f"
  grep -q "# >>> test (managed)" "$f"
  grep -q "some config" "$f"
}

@test "_write_managed_block: replaces existing block" {
  local f="$HOME/.testrc"
  cat > "$f" << 'EOF'
line before
# >>> test (managed)
old config
# <<< test (managed)
line after
EOF
  local begin="# >>> test (managed)"
  local end="# <<< test (managed)"
  local block="${begin}
new config
${end}"

  run _write_managed_block "$f" "$begin" "$end" "$block"
  [ "$status" -eq 0 ]
  grep -q "line before" "$f"
  grep -q "new config" "$f"
  grep -q "line after" "$f"
  ! grep -q "old config" "$f"
}
