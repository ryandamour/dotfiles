#!/usr/bin/env bash
# lib/zsh.sh — Oh My Zsh, Powerlevel10k bootstrap, and shell switching
[[ -n "${_ZSH_SH_LOADED:-}" ]] && return 0
_ZSH_SH_LOADED=1

source "${LIB_DIR:-$(dirname "${BASH_SOURCE[0]}")}/core.sh"
source "${LIB_DIR:-$(dirname "${BASH_SOURCE[0]}")}/detect.sh"

# ---------------------------------------------------------------------------
# bootstrap_ohmyzsh
#   Idempotent Oh My Zsh setup; integrates with Powerlevel10k if present.
#   Globals: OHMYZSH_DIR, OHMYZSH_THEME, OHMYZSH_PLUGINS, P10K_DIR,
#            P10K_REPO, DRY_RUN
# ---------------------------------------------------------------------------
bootstrap_ohmyzsh() {
  local zshrc="${HOME}/.zshrc"

  if ! have_cmd zsh; then
    warn "zsh not available; skipping Oh My Zsh."
    return 0
  fi
  need_cmd git

  # --- Install or update oh-my-zsh -----------------------------------------
  if [[ -d "$OHMYZSH_DIR/.git" ]]; then
    log "Oh My Zsh already present at '$OHMYZSH_DIR'; updating…"
    if $DRY_RUN; then
      warn "Dry run: would 'git -C \"$OHMYZSH_DIR\" pull --ff-only'"
    else
      git -C "$OHMYZSH_DIR" pull --ff-only || warn "oh-my-zsh: git pull failed; continuing."
    fi
  else
    log "Installing Oh My Zsh into '$OHMYZSH_DIR'…"
    if $DRY_RUN; then
      warn "Dry run: would 'git clone --depth=1 https://github.com/ohmyzsh/ohmyzsh.git \"$OHMYZSH_DIR\"'"
    else
      git clone --depth=1 https://github.com/ohmyzsh/ohmyzsh.git "$OHMYZSH_DIR"
    fi
  fi

  # --- Resolve theme default -----------------------------------------------
  local theme="$OHMYZSH_THEME"
  if [[ -z "$theme" ]]; then
    if [[ -d "$P10K_DIR" || -d "$OHMYZSH_DIR/custom/themes/powerlevel10k" ]]; then
      theme="powerlevel10k/powerlevel10k"
    else
      theme="robbyrussell"
    fi
  fi

  # --- Ensure P10K theme available in OMZ if selected ----------------------
  if [[ "$theme" == "powerlevel10k/powerlevel10k" ]]; then
    local omz_p10k="$OHMYZSH_DIR/custom/themes/powerlevel10k"
    if [[ ! -d "$omz_p10k" ]]; then
      if [[ -d "$P10K_DIR" ]]; then
        if $DRY_RUN; then
          warn "Dry run: would symlink '$P10K_DIR' → '$omz_p10k'"
        else
          mkdir -p "$(dirname "$omz_p10k")"
          ln -s "$P10K_DIR" "$omz_p10k"
        fi
      else
        log "Fetching Powerlevel10k theme into Oh My Zsh custom themes…"
        if $DRY_RUN; then
          warn "Dry run: would 'git clone --depth=1 https://github.com/romkatv/powerlevel10k.git \"$omz_p10k\"'"
        else
          git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$omz_p10k"
        fi
      fi
    fi
  fi

  # --- Install third-party plugins ----------------------------------------
  IFS=',' read -r -a _req_plugins <<< "$OHMYZSH_PLUGINS"
  declare -A plugin_repo=(
    [zsh-autosuggestions]=https://github.com/zsh-users/zsh-autosuggestions.git
    [zsh-syntax-highlighting]=https://github.com/zsh-users/zsh-syntax-highlighting.git
    [zsh-completions]=https://github.com/zsh-users/zsh-completions.git
  )
  for p in "${_req_plugins[@]}"; do
    p="${p//[[:space:]]/}"
    [[ -z "$p" || "$p" == "git" ]] && continue
    local target="$OHMYZSH_DIR/custom/plugins/$p"
    local url="${plugin_repo[$p]:-}"
    if [[ -n "$url" ]]; then
      if [[ -d "$target/.git" ]]; then
        if $DRY_RUN; then warn "Dry run: would update plugin '$p'"; else git -C "$target" pull --ff-only || true; fi
      else
        if $DRY_RUN; then warn "Dry run: would clone plugin '$p' → '$target'"; else mkdir -p "$(dirname "$target")"; git clone --depth=1 "$url" "$target"; fi
      fi
    fi
  done

  # NOTE: The duplicate `git clone zsh-autosuggestions` that was at line 406
  #       of the original install script has been intentionally removed.
  #       Plugin installation is fully handled by the loop above.

  # --- Managed block in ~/.zshrc ------------------------------------------
  local begin="# >>> oh-my-zsh (managed)"
  local end="# <<< oh-my-zsh (managed)"
  local plist="git"
  for p in "${_req_plugins[@]}"; do
    p="${p//[[:space:]]/}"
    [[ -z "$p" || "$p" == "git" ]] && continue
    plist="$plist $p"
  done
  local block="${begin}
export ZSH=\"${OHMYZSH_DIR}\"
ZSH_THEME=\"${theme}\"
plugins=(${plist})
source \"\${ZSH}/oh-my-zsh.sh\"
${end}"

  _write_managed_block "$zshrc" "$begin" "$end" "$block"

  log "Oh My Zsh bootstrap step complete."
}

# ---------------------------------------------------------------------------
# bootstrap_powerlevel10k
#   Idempotent Powerlevel10k setup (standalone, no OMZ required).
#   Globals: P10K_DIR, P10K_REPO, P10K_CONFIG_SRC, FORCE_P10K,
#            OHMYZSH_DIR, DRY_RUN
# ---------------------------------------------------------------------------
bootstrap_powerlevel10k() {
  local zshrc="${HOME}/.zshrc"
  local p10k_file="${HOME}/.p10k.zsh"

  if ! have_cmd zsh; then
    warn "zsh is not available; skipping Powerlevel10k."
    return 0
  fi
  need_cmd git

  # --- Clone or update the theme repo --------------------------------------
  if [[ -d "$P10K_DIR/.git" ]]; then
    log "Powerlevel10k already present at '$P10K_DIR'; updating…"
    if $DRY_RUN; then
      warn "Dry run: would 'git -C \"$P10K_DIR\" pull --ff-only'"
    else
      git -C "$P10K_DIR" pull --ff-only || warn "git pull failed; continuing."
    fi
  else
    log "Installing Powerlevel10k into '$P10K_DIR'…"
    if $DRY_RUN; then
      warn "Dry run: would 'git clone --depth=1 \"$P10K_REPO\" \"$P10K_DIR\"'"
    else
      mkdir -p "$(dirname "$P10K_DIR")"
      git clone --depth=1 "$P10K_REPO" "$P10K_DIR"
    fi
  fi

  # --- Optional user config overlay ----------------------------------------
  if [[ -n "${P10K_CONFIG_SRC:-}" ]]; then
    if [[ -f "$P10K_CONFIG_SRC" ]]; then
      if [[ -f "$p10k_file" && "${FORCE_P10K:-false}" == false ]]; then
        log "Existing $p10k_file detected; leaving as-is (use --force-p10k to overwrite)."
      else
        local bak
        bak="$(backup_dirname "$p10k_file")"
        if $DRY_RUN; then
          [[ -f "$p10k_file" ]] && warn "Dry run: would move '$p10k_file' → '$bak'"
          warn "Dry run: would copy '$P10K_CONFIG_SRC' → '$p10k_file'"
        else
          [[ -f "$p10k_file" ]] && { log "Backing up $p10k_file → $bak"; mv "$p10k_file" "$bak"; }
          log "Placing Powerlevel10k config at $p10k_file"
          install -Dm644 "$P10K_CONFIG_SRC" "$p10k_file"
        fi
      fi
    else
      warn "Provided --p10k-config not found: '$P10K_CONFIG_SRC' (skipping config overlay)."
    fi
  fi

  # --- Managed block in .zshrc --------------------------------------------
  local begin="# >>> powerlevel10k (managed)"
  local end="# <<< powerlevel10k (managed)"
  local block
  if [[ -d "${OHMYZSH_DIR:-}" ]]; then
    block="${begin}
[[ -r \"${p10k_file}\" ]] && source \"${p10k_file}\"
${end}"
  else
    block="${begin}
[[ -r \"${p10k_file}\" ]] && source \"${p10k_file}\"
[[ -d \"${P10K_DIR}\" ]] && source \"${P10K_DIR}/powerlevel10k.zsh-theme\"
${end}"
  fi

  _write_managed_block "$zshrc" "$begin" "$end" "$block"

  log "Powerlevel10k bootstrap step complete."
}

# ---------------------------------------------------------------------------
# set_shell_zsh
#   Change login shell to zsh if not already set.
#   Globals: DO_CHSH, DRY_RUN
# ---------------------------------------------------------------------------
set_shell_zsh() {
  if ! ${DO_CHSH:-true}; then
    log "Skipping chsh to zsh (per flag)."
    return 0
  fi
  if ! command -v zsh >/dev/null 2>&1; then
    warn "zsh not installed yet; skipping chsh."
    return 0
  fi
  local target="/usr/bin/zsh"
  if [[ "$SHELL" == "$target" ]]; then
    log "Login shell already set to zsh."
    return 0
  fi
  if $DRY_RUN; then
    warn "Dry run: would run 'chsh -s $target $USER'"
  else
    log "Setting default shell to zsh…"
    if chsh -s "$target" "$USER" 2>/dev/null; then
      log "Shell changed to zsh."
    elif maybe_sudo usermod -s "$target" "$USER" 2>/dev/null; then
      log "Shell changed to zsh (via usermod)."
    else
      warn "chsh failed (non-interactive env?). You can run: chsh -s $target"
    fi
  fi
}

# ---------------------------------------------------------------------------
# _write_managed_block (internal helper)
#   Insert or replace a begin/end delimited block in a file.
# ---------------------------------------------------------------------------
_write_managed_block() {
  local file="$1" begin="$2" end="$3" block="$4"

  if grep -qF "$begin" "$file" 2>/dev/null; then
    if $DRY_RUN; then
      warn "Dry run: would update managed block in $file"
    else
      awk -v b="$begin" -v e="$end" -v repl="$block" '
        BEGIN{inb=0}
        $0==b{print repl; inb=1; next}
        $0==e{inb=0; next}
        !inb{print}
      ' "$file" > "${file}.tmp" && mv "${file}.tmp" "$file"
    fi
  else
    ensure_line_in_file "$file" ""
    if $DRY_RUN; then
      warn "Dry run: would append managed block to $file"
    else
      printf "\n%s\n" "$block" >> "$file"
    fi
  fi
}
