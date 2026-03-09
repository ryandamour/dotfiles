#!/usr/bin/env bash
# lib/dotfiles.sh -- sync dotfiles into $HOME
[[ -n "${_DOTFILES_SH_LOADED:-}" ]] && return 0
_DOTFILES_SH_LOADED=1

source "${LIB_DIR:-$(dirname "${BASH_SOURCE[0]}")}/core.sh"

sync_dotfiles() {
  local src="${DOTFILES_SRC:?DOTFILES_SRC not set}"

  if [[ ! -d "$src" ]]; then
    warn "Dotfiles dir not found: $src"
    return 0
  fi

  need_cmd rsync

  local rsync_flags=(-aHAX --human-readable)
  if $DRY_RUN; then
    rsync_flags+=(-n -v)
    warn "Dry run: showing what rsync would do:"
  else
    rsync_flags+=(-v)
  fi

  # rsync src/ (with trailing slash) copies CONTENTS of src into dest
  rsync "${rsync_flags[@]}" "${src}/" "${HOME}/"

  log "Dotfiles synced from '$src' to '$HOME'"
}
