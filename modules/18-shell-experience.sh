#!/usr/bin/env bash
# ============================================================================
# 18 — Shell experience (quality-of-life upgrades)
# WHAT: Optional, friendly upgrades to your command-line: the Zsh shell, the
#       Starship prompt, fzf (fuzzy finder), and zoxide (smarter 'cd').
# WHY:  These make day-to-day terminal work faster and more pleasant —
#       great on both desktops and dev servers. All are widely-used, open tools.
# RISK: Low. We back up any dotfile before editing, append clearly-marked
#       managed blocks (never blindly overwrite), and we NEVER change your
#       default login shell without explicit confirmation.
# ============================================================================
set -euo pipefail
MODULE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$MODULE_DIR/.." && pwd)"
# shellcheck source=/dev/null
source "$REPO_ROOT/lib/common.sh"
# shellcheck source=/dev/null
source "$REPO_ROOT/lib/checks.sh"
ensure_sudo

step "Improve your shell experience (optional)"
hint "Pick and choose: a nicer shell (Zsh), a fast prompt (Starship), fuzzy"
hint "search (fzf), and smarter directory jumping (zoxide). All optional."

if ! ask_yes_no "Set up shell quality-of-life tools?" "yes"; then
  info "Skipped shell experience."
  exit 0
fi

TARGET_USER="${SUDO_USER:-$USER}"
TARGET_HOME="$(getent passwd "$TARGET_USER" | cut -d: -f6)"

# Marker used so we only ever add our managed block once (idempotent).
MARK_BEGIN="# >>> ubuntu-setup shell-experience >>>"
MARK_END="# <<< ubuntu-setup shell-experience <<<"

# append_managed_block FILE CONTENT
# Backs up the file, then appends a clearly-marked block — but only if our
# block isn't already present. Writes as the target user (not root).
append_managed_block() {
  local file="$1" content="$2"
  if [[ -f "$file" ]] && grep -qF "$MARK_BEGIN" "$file" 2>/dev/null; then
    hint "Managed block already present in $(basename "$file") — leaving it."
    return 0
  fi
  backup_file "$file"
  if [[ "$DRY_RUN" == "true" ]]; then
    printf '%s[dry-run]%s would append managed block to %s\n' "$C_GRAY" "$C_RESET" "$file"
    return 0
  fi
  {
    printf '\n%s\n' "$MARK_BEGIN"
    printf '%s\n' "$content"
    printf '%s\n' "$MARK_END"
  } | $SUDO -u "$TARGET_USER" tee -a "$file" >/dev/null
  hint "Updated $file"
}

# --- fzf (fuzzy finder) -----------------------------------------------------
echo
if ask_yes_no "Install fzf (fuzzy finder for files/history)?" "yes"; then
  apt_install fzf
  success "fzf installed. Try Ctrl-R for fuzzy history search in bash/zsh."
fi

# --- zoxide (smarter cd) ----------------------------------------------------
echo
INSTALL_ZOXIDE="no"
if ask_yes_no "Install zoxide (jump to dirs by name, e.g. 'z projects')?" "yes"; then
  # zoxide is in Ubuntu's repos on recent releases.
  if apt_install zoxide; then
    INSTALL_ZOXIDE="yes"
    success "zoxide installed."
  fi
fi

# --- Starship prompt --------------------------------------------------------
echo
INSTALL_STARSHIP="no"
if ask_yes_no "Install the Starship prompt (fast, informative prompt)?" "yes"; then
  apt_install curl ca-certificates
  STARSHIP_CMD="curl -fsSL https://starship.rs/install.sh | $SUDO sh -s -- --yes"
  if [[ "$DRY_RUN" == "true" ]]; then
    printf '%s[dry-run]%s would run: %s\n' "$C_GRAY" "$C_RESET" "$STARSHIP_CMD"
    INSTALL_STARSHIP="yes"
  else
    if run "$STARSHIP_CMD"; then
      INSTALL_STARSHIP="yes"
      success "Starship installed."
    else
      warn "Starship install failed — skipping its shell config."
    fi
  fi
fi

# --- Build the shell init snippet for the tools chosen. ---------------------
BASH_SNIPPET=""
ZSH_SNIPPET=""
if [[ "$INSTALL_ZOXIDE" == "yes" ]]; then
  BASH_SNIPPET+='command -v zoxide >/dev/null 2>&1 && eval "$(zoxide init bash)"'$'\n'
  ZSH_SNIPPET+='command -v zoxide >/dev/null 2>&1 && eval "$(zoxide init zsh)"'$'\n'
fi
if [[ "$INSTALL_STARSHIP" == "yes" ]]; then
  BASH_SNIPPET+='command -v starship >/dev/null 2>&1 && eval "$(starship init bash)"'$'\n'
  ZSH_SNIPPET+='command -v starship >/dev/null 2>&1 && eval "$(starship init zsh)"'$'\n'
fi

# Always wire these into .bashrc (the default shell) if there's anything to add.
if [[ -n "$BASH_SNIPPET" ]]; then
  append_managed_block "$TARGET_HOME/.bashrc" "${BASH_SNIPPET%$'\n'}"
fi

# --- Zsh (optional shell) ---------------------------------------------------
echo
if ask_yes_no "Install the Zsh shell (an enhanced alternative to bash)?" "no"; then
  apt_install zsh

  # Provide a sane starter .zshrc only if the user doesn't already have one.
  ZSHRC="$TARGET_HOME/.zshrc"
  if [[ ! -f "$ZSHRC" ]]; then
    STARTER="# Starter .zshrc created by ubuntu-setup
HISTSIZE=10000
SAVEHIST=10000
HISTFILE=~/.zsh_history
setopt SHARE_HISTORY HIST_IGNORE_DUPS
autoload -Uz compinit && compinit
alias ll='ls -alh --color=auto'
alias la='ls -A --color=auto'"
    if [[ "$DRY_RUN" == "true" ]]; then
      printf '%s[dry-run]%s would create starter %s\n' "$C_GRAY" "$C_RESET" "$ZSHRC"
    else
      printf '%s\n' "$STARTER" | $SUDO -u "$TARGET_USER" tee "$ZSHRC" >/dev/null
      hint "Created a starter $ZSHRC"
    fi
  fi
  # Add our tool inits to .zshrc too.
  if [[ -n "$ZSH_SNIPPET" ]]; then
    append_managed_block "$ZSHRC" "${ZSH_SNIPPET%$'\n'}"
  fi

  # Changing the default shell is a notable change — confirm explicitly.
  echo
  warn "Changing your DEFAULT login shell affects every new session. If a"
  warn "config is broken it can make logins annoying. Zsh is installed either way."
  if ask_yes_no "Make Zsh the DEFAULT shell for '$TARGET_USER'?" "no"; then
    ZSH_PATH="$(command -v zsh || echo /usr/bin/zsh)"
    run $SUDO chsh -s "$ZSH_PATH" "$TARGET_USER"
    success "Default shell for '$TARGET_USER' set to Zsh ($ZSH_PATH)."
    hint "Log out and back in for it to take effect. Switch back anytime with:"
    hint "    chsh -s \$(command -v bash)"
  else
    info "Zsh installed but NOT set as default. Try it anytime by running: zsh"
  fi
fi

echo
success "Shell experience set up."
hint "Open a new terminal (or run 'exec \$SHELL') to see the changes."
