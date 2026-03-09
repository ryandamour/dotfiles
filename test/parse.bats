#!/usr/bin/env bats
# test/parse.bats -- tests for lib/parse.sh

load test_helper/common-setup

setup() {
  TEST_HOME="$(mktemp -d)"
  export HOME="$TEST_HOME"
  export DRY_RUN=false
  MOCK_BIN="$(mktemp -d)"
  export PATH="$MOCK_BIN:$PATH"
  export LIB_DIR
  source "$LIB_DIR/parse.sh"
  unset _PARSE_SH_LOADED _CORE_SH_LOADED
}

teardown() {
  [[ -d "${TEST_HOME:-}" ]] && rm -rf "$TEST_HOME"
  [[ -d "${MOCK_BIN:-}" ]] && rm -rf "$MOCK_BIN"
}

# --- parse_deps (YAML format) -----------------------------------------------

@test "parse_deps extracts packages from YAML format" {
  local f="$TEST_HOME/deps.yaml"
  cat > "$f" <<'EOF'
--
dependencies:
  - neovim
  - alacritty
  - zsh
EOF
  run parse_deps "$f"
  [[ "$status" -eq 0 ]]
  [[ "${lines[0]}" == "neovim" ]]
  [[ "${lines[1]}" == "alacritty" ]]
  [[ "${lines[2]}" == "zsh" ]]
  [[ "${#lines[@]}" -eq 3 ]]
}

@test "parse_deps handles YAML with blank lines" {
  local f="$TEST_HOME/deps.yaml"
  cat > "$f" <<'EOF'
dependencies:

  - pkg1

  - pkg2
EOF
  run parse_deps "$f"
  [[ "$status" -eq 0 ]]
  [[ "${lines[0]}" == "pkg1" ]]
  [[ "${lines[1]}" == "pkg2" ]]
}

# --- parse_deps (plain format) -----------------------------------------------

@test "parse_deps extracts packages from plain list" {
  local f="$TEST_HOME/deps.txt"
  cat > "$f" <<'EOF'
- neovim
- alacritty
zsh
EOF
  run parse_deps "$f"
  [[ "$status" -eq 0 ]]
  [[ "${lines[0]}" == "neovim" ]]
  [[ "${lines[1]}" == "alacritty" ]]
  [[ "${lines[2]}" == "zsh" ]]
}

@test "parse_deps skips comments and empty lines in plain format" {
  local f="$TEST_HOME/deps.txt"
  cat > "$f" <<'EOF'
# this is a comment
neovim

alacritty
# another comment
EOF
  run parse_deps "$f"
  [[ "$status" -eq 0 ]]
  [[ "${lines[0]}" == "neovim" ]]
  [[ "${lines[1]}" == "alacritty" ]]
  [[ "${#lines[@]}" -eq 2 ]]
}

@test "parse_deps works with real deps.yaml from repo" {
  local repo_deps
  repo_deps="$(cd "$(dirname "${BATS_TEST_FILENAME}")/.." && pwd)/deps.yaml"
  if [[ ! -f "$repo_deps" ]]; then
    skip "deps.yaml not found in repo root"
  fi
  run parse_deps "$repo_deps"
  [[ "$status" -eq 0 ]]
  [[ "${lines[0]}" == "neovim" ]]
  [[ "${#lines[@]}" -gt 5 ]]
}

# --- parse_flatpaks ----------------------------------------------------------

@test "parse_flatpaks extracts refs from YAML" {
  local f="$TEST_HOME/flatpak.yaml"
  cat > "$f" <<'EOF'
flatpaks:
  - com.github.tchx84.Flatseal
  - org.mozilla.firefox
  - com.google.Chrome
EOF
  run parse_flatpaks "$f"
  [[ "$status" -eq 0 ]]
  [[ "${lines[0]}" == "com.github.tchx84.Flatseal" ]]
  [[ "${lines[1]}" == "org.mozilla.firefox" ]]
  [[ "${lines[2]}" == "com.google.Chrome" ]]
  [[ "${#lines[@]}" -eq 3 ]]
}

@test "parse_flatpaks returns 0 for missing file" {
  run parse_flatpaks "$TEST_HOME/no_such_file.yaml"
  [[ "$status" -eq 0 ]]
  [[ -z "$output" ]]
}

@test "parse_flatpaks handles empty flatpaks list" {
  local f="$TEST_HOME/flatpak.yaml"
  cat > "$f" <<'EOF'
flatpaks:
other_key:
  - something
EOF
  run parse_flatpaks "$f"
  [[ "$status" -eq 0 ]]
  [[ -z "$output" ]]
}
