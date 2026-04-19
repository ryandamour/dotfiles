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

bootstrap_rofi() {
  local repo_dir="${HOME}/.local/share/rofi-dracula"
  local repo_url="https://github.com/dracula/rofi.git"
  local themes_dir="${HOME}/.config/rofi/themes"
  local theme_link="${themes_dir}/dracula.rasi"
  local theme_src="${repo_dir}/theme/config1.rasi"

  if ! have_cmd rofi; then
    warn "rofi not installed; skipping rofi theme bootstrap."
    return 0
  fi
  need_cmd git

  if [[ -d "$repo_dir/.git" ]]; then
    log "Dracula rofi theme already present at '$repo_dir'; updating…"
    if $DRY_RUN; then
      warn "Dry run: would 'git -C \"$repo_dir\" pull --ff-only'"
    else
      git -C "$repo_dir" pull --ff-only || warn "dracula/rofi: git pull failed; continuing."
    fi
  else
    log "Cloning Dracula rofi theme into '$repo_dir'…"
    if $DRY_RUN; then
      warn "Dry run: would 'git clone --depth=1 \"$repo_url\" \"$repo_dir\"'"
    else
      mkdir -p "$(dirname "$repo_dir")"
      git clone --depth=1 "$repo_url" "$repo_dir"
    fi
  fi

  if $DRY_RUN; then
    warn "Dry run: would symlink '$theme_src' → '$theme_link'"
    return 0
  fi

  mkdir -p "$themes_dir"
  if [[ -L "$theme_link" && "$(readlink "$theme_link")" == "$theme_src" ]]; then
    log "Dracula rofi theme symlink already in place."
  else
    ln -sfn "$theme_src" "$theme_link"
    log "Linked $theme_link → $theme_src"
  fi
}

install_user_bins() {
  local bin_dir="${HOME}/bin"

  if $DRY_RUN; then
    warn "Dry run: would ensure $bin_dir exists"
  else
    mkdir -p "$bin_dir"
  fi

  _install_terraform "$bin_dir"
  _install_kubectl "$bin_dir"
}

_install_terraform() {
  local bin_dir="$1"
  local target="${bin_dir}/terraform"
  local want="${TERRAFORM_VERSION:-}"

  if [[ -z "$want" ]]; then
    warn "TERRAFORM_VERSION not set; skipping terraform install."
    return 0
  fi

  if [[ -x "$target" ]]; then
    local have
    have="$("$target" version 2>/dev/null | head -n1 | awk '{print $2}' | sed 's/^v//')"
    if [[ "$have" == "$want" ]]; then
      log "terraform ${want} already installed at ${target}; skipping."
      return 0
    fi
    log "terraform ${have:-unknown} found; updating to ${want}…"
  fi

  if $DRY_RUN; then
    warn "Dry run: would install terraform ${want} to ${target}"
    return 0
  fi

  need_cmd curl
  need_cmd unzip
  local tmpdir
  tmpdir="$(mktemp -d)"

  local url="https://releases.hashicorp.com/terraform/${want}/terraform_${want}_linux_amd64.zip"
  log "Downloading terraform ${want}…"
  curl -fsSL -o "${tmpdir}/terraform.zip" "$url"
  unzip -o "${tmpdir}/terraform.zip" -d "$tmpdir" >/dev/null
  install -m 0755 "${tmpdir}/terraform" "$target"
  rm -rf "$tmpdir"
  log "Installed terraform ${want} → ${target}"
}

_install_kubectl() {
  local bin_dir="$1"
  local target="${bin_dir}/kubectl"

  if [[ -x "$target" ]]; then
    log "kubectl already installed at ${target}; delete to refresh."
    return 0
  fi

  if $DRY_RUN; then
    warn "Dry run: would install latest kubectl to ${target}"
    return 0
  fi

  need_cmd curl
  local stable
  stable="$(curl -fsSL https://dl.k8s.io/release/stable.txt)"
  log "Downloading kubectl ${stable}…"
  curl -fsSL -o "$target" "https://dl.k8s.io/release/${stable}/bin/linux/amd64/kubectl"
  chmod +x "$target"
  log "Installed kubectl ${stable} → ${target}"
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
