#!/usr/bin/env bash
# lib/flatpaks.sh -- Flatpak installation helpers
[[ -n "${_FLATPAKS_SH_LOADED:-}" ]] && return 0
_FLATPAKS_SH_LOADED=1

source "${LIB_DIR:-$(dirname "${BASH_SOURCE[0]}")}/core.sh"
source "${LIB_DIR:-$(dirname "${BASH_SOURCE[0]}")}/parse.sh"

flatpak_installed() {
  local id="$1"
  flatpak list --app --columns=application 2>/dev/null | grep -Fxq "$id" && return 0
  flatpak list --columns=ref 2>/dev/null | awk '{print $1}' | grep -Fxq "$id"
}

install_flatpaks() {
  if ! have_cmd flatpak; then
    warn "flatpak not found; skipping Flatpak installation."
    return 0
  fi
  if [[ ! -f "$FLATPAK_FILE" ]]; then
    log "No $FLATPAK_FILE found; skipping Flatpak installation."
    return 0
  fi

  local remote_args=()
  if [[ "$FLATPAK_SCOPE" == "user" ]]; then
    remote_args+=(--user)
  elif [[ "$FLATPAK_SCOPE" == "system" ]]; then
    remote_args+=(--system)
  else
    warn "Unknown FLATPAK_SCOPE='$FLATPAK_SCOPE'; defaulting to user."
    remote_args+=(--user)
  fi

  if ! flatpak "${remote_args[@]}" remotes | awk '{print $1}' | grep -qx flathub; then
    log "Adding flathub remote (${FLATPAK_SCOPE})..."
    if ${DRY_RUN:-false}; then
      warn "Dry run: would add flathub remote"
    else
      flatpak "${remote_args[@]}" remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo || warn "Failed to add flathub remote."
    fi
  fi

  mapfile -t refs < <(parse_flatpaks "$FLATPAK_FILE" | awk 'NF')
  if [[ ${#refs[@]} -eq 0 ]]; then
    log "No flatpaks listed in $FLATPAK_FILE."
    return 0
  fi

  for ref in "${refs[@]}"; do
    if flatpak_installed "$ref"; then
      log "Flatpak already installed: $ref"
    else
      if ${DRY_RUN:-false}; then
        warn "Dry run: would install flatpak $ref (${FLATPAK_SCOPE})"
      else
        log "Installing flatpak: $ref (${FLATPAK_SCOPE})"
        flatpak "${remote_args[@]}" install -y --noninteractive flathub "$ref" || warn "flatpak install failed for $ref"
      fi
    fi
  done
}
