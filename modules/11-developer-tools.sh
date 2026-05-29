#!/usr/bin/env bash
# ============================================================================
# 11 — Developer tools (optional)
# WHAT: Quality-of-life tools for people who write code or run servers:
#       modern CLI utilities, plus optional language runtimes (Node, Python).
# WHY:  Saves time setting up a comfortable, productive environment.
# RISK: Low. Everything is opt-in via prompts.
# ============================================================================
set -euo pipefail
MODULE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$MODULE_DIR/.." && pwd)"
# shellcheck source=/dev/null
source "$REPO_ROOT/lib/common.sh"
# shellcheck source=/dev/null
source "$REPO_ROOT/lib/checks.sh"
ensure_sudo

step "Developer tools (optional)"

# Modern, friendly CLI tools available in Ubuntu's repos.
if ask_yes_no "Install handy modern CLI tools (tmux, fzf, ripgrep, bat, etc.)?" "yes"; then
  run $SUDO apt-get update
  apt_install tmux fzf ripgrep fd-find bat git-lfs shellcheck
  hint "Note: on Ubuntu 'bat' runs as 'batcat' and 'fd' as 'fdfind' (naming clash)."
fi

# Git identity — pleasant to set once.
if ask_yes_no "Set your global Git name and email now?" "no"; then
  gname="$(ask_value "Git user.name" "")"
  gmail="$(ask_value "Git user.email" "")"
  [[ -n "$gname" ]] && run git config --global user.name "$gname"
  [[ -n "$gmail" ]] && run git config --global user.email "$gmail"
  run git config --global init.defaultBranch main
  success "Git identity configured."
fi

# Node.js via NodeSource (gives a current LTS rather than an old repo version).
if ask_yes_no "Install Node.js (JavaScript runtime, current LTS)?" "no"; then
  if command_exists node; then
    success "Node.js already installed: $(node --version)"
  else
    if [[ "$DRY_RUN" != "true" ]]; then
      curl -fsSL https://deb.nodesource.com/setup_lts.x | $SUDO -E bash -
    else
      hint "[dry-run] would add NodeSource LTS repo"
    fi
    apt_install nodejs
    command_exists node && success "Node.js installed: $(node --version)"
  fi
fi

# Python tooling (Python 3 ships with Ubuntu; add pip + venv).
if ask_yes_no "Install Python developer tools (pip, venv)?" "no"; then
  apt_install python3-pip python3-venv python3-dev pipx
  command_exists pipx && run pipx ensurepath || true
  success "Python tooling installed."
fi

success "Developer tools step complete."
