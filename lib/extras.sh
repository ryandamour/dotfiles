#!/usr/bin/env bash
# lib/extras.sh -- optional extras (fonts, VSCode integration, etc.)
[[ -n "${_EXTRAS_SH_LOADED:-}" ]] && return 0
_EXTRAS_SH_LOADED=1

source "${LIB_DIR:-$(dirname "${BASH_SOURCE[0]}")}/core.sh"
source "${LIB_DIR:-$(dirname "${BASH_SOURCE[0]}")}/detect.sh"

install_fonts() {
  local font_dir="${HOME}/.local/share/fonts/NerdFonts"
  local font_name="JetBrainsMono"
  local font_url="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/${font_name}.zip"

  # Idempotency: skip if fonts already installed
  if fc-list : family 2>/dev/null | grep -qi "JetBrainsMono"; then
    log "JetBrainsMono Nerd Font already installed; skipping."
    return 0
  fi

  if $DRY_RUN; then
    warn "Dry run: would download and install ${font_name} Nerd Font"
    return 0
  fi

  need_cmd curl
  need_cmd unzip

  local tmpdir
  tmpdir="$(mktemp -d)"
  trap 'rm -rf "$tmpdir"' RETURN

  log "Downloading ${font_name} Nerd Font…"
  curl -fsSL -o "${tmpdir}/${font_name}.zip" "$font_url"

  mkdir -p "$font_dir"
  unzip -o "${tmpdir}/${font_name}.zip" -d "$font_dir"

  # Clean up any zip files that may have landed in font_dir
  rm -f "${font_dir}"/*.zip

  fc-cache -f
  log "Installed ${font_name} Nerd Font."
}

install_vscode_flatpak_integration() {
  local repo_dir="${HOME}/Code/toolbox-vscode"
  local symlink="${HOME}/.local/bin/code"

  # Idempotency: skip if symlink and repo both exist
  if [[ -L "$symlink" && -d "$repo_dir/.git" ]]; then
    log "VSCode flatpak integration already set up; skipping."
    return 0
  fi

  if $DRY_RUN; then
    warn "Dry run: would clone toolbox-vscode and create symlink"
    return 0
  fi

  need_cmd git

  if [[ ! -d "$repo_dir/.git" ]]; then
    mkdir -p "$(dirname "$repo_dir")"
    git clone --depth=1 https://github.com/owtaylor/toolbox-vscode.git "$repo_dir"
  else
    log "toolbox-vscode repo already present; updating…"
    git -C "$repo_dir" pull --ff-only || warn "git pull failed for toolbox-vscode"
  fi

  mkdir -p "$(dirname "$symlink")"
  if [[ ! -L "$symlink" ]]; then
    ln -s "${repo_dir}/code.sh" "$symlink"
    log "Created symlink: $symlink → ${repo_dir}/code.sh"
  fi
}
