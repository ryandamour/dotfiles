#!/usr/bin/env bash
# lib/parse.sh -- YAML-ish dependency / flatpak list parsers
[[ -n "${_PARSE_SH_LOADED:-}" ]] && return 0
_PARSE_SH_LOADED=1

source "${LIB_DIR:-$(dirname "${BASH_SOURCE[0]}")}/core.sh"

# Emit one package name per line from a deps file.
# Supports YAML-style (dependencies: block) or plain newline / "- " lists.
parse_deps() {
  local file="$1"
  if grep -Eq '^[[:space:]]*dependencies:[[:space:]]*$' "$file"; then
    awk '
      /^[[:space:]]*dependencies:[[:space:]]*$/ { inlist=1; next }
      inlist && /^[[:space:]]*-[[:space:]]*/ {
        gsub(/^[[:space:]]*-[[:space:]]*/, "", $0);
        if ($0 !~ /^[[:space:]]*$/) print $0
      }
      inlist && NF==0 { next }
    ' "$file"
  else
    sed -E 's/^[[:space:]]*-[[:space:]]*//; s/[[:space:]]+$//' "$file" \
      | grep -Ev '^[[:space:]]*(#|$)'
  fi
}

# Emit one flatpak ref per line from a YAML-style flatpaks: block.
parse_flatpaks() {
  local file="$1"
  if [[ ! -f "$file" ]]; then
    return 0
  fi
  awk '
    /^[[:space:]]*#/ { next }
    /^[[:space:]]*flatpaks:[[:space:]]*$/ { inlist=1; next }
    inlist && /^[^[:space:]-][^:]*:/ { inlist=0 }
    inlist && /^[[:space:]]*-[[:space:]]*/ {
      gsub(/^[[:space:]]*-[[:space:]]*/, "", $0)
      gsub(/[[:space:]]+$/, "", $0)
      if ($0 != "") print $0
    }
  ' "$file"
}
