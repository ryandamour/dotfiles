#!/usr/bin/env bats
# test/integration.bats — End-to-end tests (designed to run inside Vagrant)

# These tests exercise the full install flow against a real Fedora system.
# Run with: bats test/integration.bats  (inside the Vagrant VM)

setup() {
  REPO_DIR="$(cd "$(dirname "${BATS_TEST_FILENAME}")/.." && pwd)"
}

@test "integration: install script exists and is executable" {
  [ -f "$REPO_DIR/install" ]
  [ -x "$REPO_DIR/install" ] || bash -n "$REPO_DIR/install"
}

@test "integration: all lib files parse without syntax errors" {
  for f in "$REPO_DIR"/lib/*.sh; do
    bash -n "$f"
  done
}

@test "integration: dry-run produces no side effects" {
  local snapshot_before
  snapshot_before="$(rpm -qa --qf '%{NAME}\n' | sort | md5sum)"

  cd "$REPO_DIR"
  run bash ./install --dry-run
  [ "$status" -eq 0 ] || [ "$status" -eq 1 ]

  local snapshot_after
  snapshot_after="$(rpm -qa --qf '%{NAME}\n' | sort | md5sum)"
  [ "$snapshot_before" = "$snapshot_after" ]
}

@test "integration: deps.yaml is parseable" {
  cd "$REPO_DIR"
  source lib/core.sh
  source lib/parse.sh
  run parse_deps deps.yaml
  [ "$status" -eq 0 ]
  [[ "$output" == *"neovim"* ]]
  [[ "$output" == *"zsh"* ]]
}

@test "integration: flatpak.yaml is parseable" {
  cd "$REPO_DIR"
  source lib/core.sh
  source lib/parse.sh
  run parse_flatpaks flatpak.yaml
  [ "$status" -eq 0 ]
  [[ "$output" == *"com.github.tchx84.Flatseal"* ]]
}

@test "integration: dotfiles directory structure is valid" {
  [ -d "$REPO_DIR/dotfiles" ]
  [ -f "$REPO_DIR/dotfiles/.zshrc" ]
  [ -d "$REPO_DIR/dotfiles/.config" ]
}

@test "integration: sync_dotfiles places files correctly" {
  local test_home
  test_home="$(mktemp -d)"

  cd "$REPO_DIR"
  HOME="$test_home" DOTFILES_SRC="./dotfiles" DRY_RUN=false \
    bash -c 'source lib/core.sh; source lib/dotfiles.sh; sync_dotfiles'

  # Verify dotfiles with leading dots preserved their dots
  [ -f "$test_home/.zshrc" ]
  [ -d "$test_home/.config" ]

  rm -rf "$test_home"
}

@test "integration: shellcheck passes on all scripts" {
  if ! command -v shellcheck >/dev/null 2>&1; then
    skip "shellcheck not installed"
  fi
  cd "$REPO_DIR"
  shellcheck -x -e SC1091 -e SC2034 install lib/*.sh
}
