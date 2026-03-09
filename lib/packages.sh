#!/usr/bin/env bash
# lib/packages.sh -- RPM package management helpers
[[ -n "${_PACKAGES_SH_LOADED:-}" ]] && return 0
_PACKAGES_SH_LOADED=1

source "${LIB_DIR:-$(dirname "${BASH_SOURCE[0]}")}/core.sh"
source "${LIB_DIR:-$(dirname "${BASH_SOURCE[0]}")}/detect.sh"

have_pkg() {
  rpm -q "$1" >/dev/null 2>&1
}

ensure_repos() {
  local version_id
  version_id=$(. /etc/os-release && echo "$VERSION_ID")

  # RPM Fusion (free + nonfree) for codecs, ffmpeg, etc.
  if have_pkg rpmfusion-free-release; then
    log "RPM Fusion Free already configured."
  elif ${DRY_RUN:-false}; then
    warn "Dry run: would install RPM Fusion Free + Nonfree repos"
  else
    log "Adding RPM Fusion repos..."
    local tmpdir
    tmpdir=$(mktemp -d)
    curl -fsSL --retry 3 --connect-timeout 30 \
      "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-${version_id}.noarch.rpm" \
      -o "${tmpdir}/rpmfusion-free-release.rpm"
    curl -fsSL --retry 3 --connect-timeout 30 \
      "https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-${version_id}.noarch.rpm" \
      -o "${tmpdir}/rpmfusion-nonfree-release.rpm"
    maybe_sudo rpm-ostree install --allow-inactive --idempotent \
      "${tmpdir}/rpmfusion-free-release.rpm" \
      "${tmpdir}/rpmfusion-nonfree-release.rpm"
    rm -rf "$tmpdir"
  fi

  # Ghostty COPR
  local ghostty_repo="/etc/yum.repos.d/_copr:copr.fedorainfracloud.org:scottames:ghostty.repo"
  if [[ -f "$ghostty_repo" ]]; then
    log "Ghostty COPR repo already configured."
  elif ${DRY_RUN:-false}; then
    warn "Dry run: would add Ghostty COPR repo"
  else
    log "Adding Ghostty COPR repo..."
    maybe_sudo curl -fsSL \
      "https://copr.fedorainfracloud.org/coprs/scottames/ghostty/repo/fedora-${version_id}/scottames-ghostty-fedora-${version_id}.repo" \
      -o "$ghostty_repo"
  fi
}

install_packages() {
  # Usage: install_packages pkg1 pkg2 pkg3 ...
  # Filters already-installed, installs missing via rpm-ostree.
  # Respects: DRY_RUN (global)
  local pkgs=("$@")
  local missing=()

  for pkg in "${pkgs[@]}"; do
    if have_pkg "$pkg"; then
      log "Already installed: $pkg"
    else
      missing+=("$pkg")
    fi
  done

  if (( ${#missing[@]} )); then
    log "Missing packages: ${missing[*]}"
    if ${DRY_RUN:-false}; then
      warn "Dry run: would run: rpm-ostree install ${missing[*]}"
    else
      log "Layering packages with rpm-ostree (this may stage a reboot)..."
      maybe_sudo rpm-ostree install "${missing[@]}"
      if pending_deployment; then
        warn "A new deployment is pending. You should reboot to finalize the install."
      else
        log "No pending deployment detected."
      fi
    fi
  else
    log "All dependencies already present. Skipping rpm-ostree install."
  fi
}
