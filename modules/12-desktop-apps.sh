#!/usr/bin/env bash
# ============================================================================
# 12 — Desktop apps & tweaks (desktop only)
# WHAT: Common applications and quality-of-life tweaks for Ubuntu DESKTOP:
#       browsers, media codecs, archive support, Flatpak, etc.
# WHY:  A fresh desktop is missing a lot of "just works" pieces (like playing
#       common video formats). This fills the gaps with a few clicks.
# RISK: Low. Everything is opt-in.
# ============================================================================
set -euo pipefail
MODULE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$MODULE_DIR/.." && pwd)"
# shellcheck source=/dev/null
source "$REPO_ROOT/lib/common.sh"
# shellcheck source=/dev/null
source "$REPO_ROOT/lib/checks.sh"
ensure_sudo
detect_environment

step "Desktop applications & tweaks"

if [[ "$ENV_TYPE" != "desktop" ]]; then
  warn "This looks like a server (no desktop detected). These steps are for"
  warn "Ubuntu Desktop. You can continue anyway, but most won't be useful."
  ask_yes_no "Continue anyway?" "no" || exit 0
fi

# Media codecs so common audio/video formats just work.
if ask_yes_no "Install media codecs (play common video/audio formats)?" "yes"; then
  # This package may prompt to accept the Microsoft fonts EULA; we pre-accept
  # only when the user is running unattended, otherwise let them see it.
  if [[ "$ASSUME_YES" == "true" && "$DRY_RUN" != "true" ]]; then
    echo "ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula select true" \
      | $SUDO debconf-set-selections
  fi
  apt_install ubuntu-restricted-extras
fi

# Archive formats (rar, 7z, etc.).
if ask_yes_no "Install extra archive support (7z, rar, etc.)?" "yes"; then
  apt_install p7zip-full p7zip-rar unrar
fi

# Flatpak — a popular way to install desktop apps safely & up to date.
if ask_yes_no "Install Flatpak + Flathub (large catalog of desktop apps)?" "yes"; then
  apt_install flatpak
  pkg_installed gnome-software && apt_install gnome-software-plugin-flatpak || true
  run flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
  hint "After a reboot, you can install apps from Flathub via the Software app."
fi

# GNOME tweaks for customizing the desktop.
if ask_yes_no "Install GNOME Tweaks & extensions manager (customize the desktop)?" "no"; then
  apt_install gnome-tweaks gnome-shell-extension-manager
fi

success "Desktop step complete."
