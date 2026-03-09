#!/usr/bin/env bash
# lib/core.sh -- shared helpers for the dotfiles bootstrapper
[[ -n "${_CORE_SH_LOADED:-}" ]] && return 0
_CORE_SH_LOADED=1

log()  { printf "\033[1;34m[INFO]\033[0m %s\n" "$*"; }
warn() { printf "\033[1;33m[WARN]\033[0m %s\n" "$*"; }
err()  { printf "\033[1;31m[ERR]\033[0m  %s\n" "$*" >&2; }

have_cmd() {
  command -v "$1" >/dev/null 2>&1
}

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || { err "Missing required command: $1"; exit 1; }
}

# Deduplicate array items while preserving order.
# Usage: dedupe out_array_name "${in[@]}"
dedupe() {
  local -n _out="$1"; shift
  local -A seen=()
  local x
  for x in "$@"; do
    [[ -n "${seen[$x]:-}" ]] && continue
    seen["$x"]=1; _out+=("$x")
  done
}

maybe_sudo() {
  if [[ $EUID -ne 0 ]]; then
    sudo "$@"
  else
    "$@"
  fi
}

# Generate a timestamped backup path for the given path.
# Usage: backup_dirname "/some/path" -> /some/path.bak.YYYYMMDD-HHMMSS
backup_dirname() {
  printf '%s.bak.%s\n' "$1" "$(date +%Y%m%d-%H%M%S)"
}

# Append a line to a file if not already present. Respects DRY_RUN.
ensure_line_in_file() {
  local file="$1"; shift
  local line="$*"
  [[ -f "$file" ]] || touch "$file"
  if grep -Fxq "$line" "$file"; then
    return 0
  fi
  if ${DRY_RUN:-false}; then
    warn "Dry run: would append to $file: $line"
  else
    printf "%s\n" "$line" >> "$file"
  fi
}
