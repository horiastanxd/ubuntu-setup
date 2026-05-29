#!/usr/bin/env bash
# ============================================================================
# 16 — Tailscale (mesh VPN)
# WHAT: Installs Tailscale from its official repository and connects this
#       machine to your private Tailscale network ("tailnet").
# WHY:  Tailscale creates a secure, encrypted mesh VPN between your devices.
#       You can reach this machine (SSH, web UIs, databases) over a private
#       address WITHOUT opening any ports to the public internet — which
#       dramatically reduces your attack surface.
# RISK: Low. Joining a tailnet requires you to authenticate in a browser, so
#       nothing is exposed without your explicit sign-in. It does NOT change
#       your firewall or SSH settings.
# ============================================================================
set -euo pipefail
MODULE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$MODULE_DIR/.." && pwd)"
# shellcheck source=/dev/null
source "$REPO_ROOT/lib/common.sh"
# shellcheck source=/dev/null
source "$REPO_ROOT/lib/checks.sh"
ensure_sudo
detect_os

step "Install Tailscale (secure mesh VPN)"
hint "Tailscale lets your devices talk to each other over a private, encrypted"
hint "network. Great for remote SSH/admin without exposing ports to the world."

if command_exists tailscale; then
  success "Tailscale is already installed: $(tailscale version 2>/dev/null | head -n1)"
else
  if ! ask_yes_no "Install Tailscale from the official repository?" "yes"; then
    info "Skipped Tailscale."
    exit 0
  fi

  apt_install ca-certificates curl gnupg

  # Use the Ubuntu codename Tailscale publishes packages for. Fall back to a
  # widely-supported LTS codename if detection is unavailable.
  codename="${OS_CODENAME:-$(. /etc/os-release && echo "${VERSION_CODENAME:-}")}"
  [[ -z "$codename" || "$codename" == "unknown" ]] && codename="jammy"

  KEYRING="/usr/share/keyrings/tailscale-archive-keyring.gpg"
  REPO_FILE="/etc/apt/sources.list.d/tailscale.list"

  # Add Tailscale's signed GPG key and apt repo (same pattern as Docker module).
  if [[ "$DRY_RUN" == "true" ]]; then
    printf '%s[dry-run]%s would add Tailscale GPG key for %s to %s\n' \
      "$C_GRAY" "$C_RESET" "$codename" "$KEYRING"
    printf '%s[dry-run]%s would add Tailscale apt repo to %s\n' \
      "$C_GRAY" "$C_RESET" "$REPO_FILE"
  else
    curl -fsSL "https://pkgs.tailscale.com/stable/ubuntu/${codename}.noarmor.gpg" \
      | $SUDO tee "$KEYRING" >/dev/null
    curl -fsSL "https://pkgs.tailscale.com/stable/ubuntu/${codename}.tailscale-keyring.list" \
      | $SUDO tee "$REPO_FILE" >/dev/null
  fi

  run $SUDO apt-get update
  apt_install tailscale
  run $SUDO systemctl enable --now tailscaled
  success "Tailscale installed: $(tailscale version 2>/dev/null | head -n1 || echo installed)"
fi

# --- Connect to the tailnet. -----------------------------------------------
echo
# If already connected, don't prompt to re-authenticate.
if [[ "$DRY_RUN" != "true" ]] && tailscale status >/dev/null 2>&1; then
  success "This machine is already connected to a tailnet:"
  tailscale status 2>/dev/null | sed 's/^/    /' | head -n 5
  exit 0
fi

hint "To join your network, 'tailscale up' will print a sign-in URL. Open it in"
hint "any browser and log in with your Tailscale account to authorize this device."

if ask_yes_no "Run 'tailscale up' now to connect this machine?" "yes"; then
  # tailscale up prints an auth URL and waits — run it directly so the user can
  # interact. In dry-run we only show the command.
  run $SUDO tailscale up
  if [[ "$DRY_RUN" != "true" ]]; then
    echo
    success "Connected. This machine's Tailscale addresses:"
    tailscale ip -4 2>/dev/null | sed 's/^/    /' || true
  fi
else
  info "Tailscale installed but not connected."
  hint "Connect later with:  sudo tailscale up"
fi

echo
hint "Tip: once you can reach this box over Tailscale, consider restricting SSH"
hint "in your firewall to the Tailscale network instead of the public internet."
