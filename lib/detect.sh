#!/usr/bin/env bash
# lib/detect.sh -- OS / deployment detection helpers
[[ -n "${_DETECT_SH_LOADED:-}" ]] && return 0
_DETECT_SH_LOADED=1

source "${LIB_DIR:-$(dirname "${BASH_SOURCE[0]}")}/core.sh"

is_silverblue() {
  command -v rpm-ostree >/dev/null 2>&1 && rpm-ostree status >/dev/null 2>&1
}

pending_deployment() {
  rpm-ostree status --json 2>/dev/null \
    | python3 -c "import sys,json; sys.exit(0 if any(d.get('staged') for d in json.load(sys.stdin).get('deployments',[])) else 1)"
}
