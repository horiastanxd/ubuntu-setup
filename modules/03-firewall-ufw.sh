#!/usr/bin/env bash
# ============================================================================
# 03 — Firewall (UFW)
# WHAT: Sets up UFW, the "Uncomplicated Firewall", to block unexpected traffic.
# WHY:  By default a server may expose services to the whole internet. A
#       firewall is your front door lock: deny everything inbound, then allow
#       only the doors you actually use (like SSH and a web server).
# RISK: Medium. If you enable the firewall over SSH WITHOUT allowing SSH first,
#       you can lock yourself out. This script allows SSH BEFORE enabling.
# ============================================================================
set -euo pipefail
MODULE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$MODULE_DIR/.." && pwd)"
# shellcheck source=/dev/null
source "$REPO_ROOT/lib/common.sh"
# shellcheck source=/dev/null
source "$REPO_ROOT/lib/checks.sh"
ensure_sudo

step "Configure the firewall (UFW)"
hint "A firewall decides which network connections are allowed in. We'll deny"
hint "everything by default and then open only the ports you choose."

apt_install ufw

# --- Safety first: never lock out the current SSH session. -----------------
# Detect the port the current SSH connection is using, if any.
SSH_PORT="22"
if [[ -n "${SSH_CONNECTION:-}" ]]; then
  SSH_PORT="$(awk '{print $4}' <<<"$SSH_CONNECTION")"
  warn "You appear to be connected over SSH on port ${SSH_PORT}."
  warn "We will ALLOW this port before enabling the firewall to avoid lockout."
fi

run $SUDO ufw default deny incoming
run $SUDO ufw default allow outgoing

# Always allow SSH so remote admins keep access.
if ask_yes_no "Allow SSH on port ${SSH_PORT}? (strongly recommended on servers)" "yes"; then
  run $SUDO ufw allow "${SSH_PORT}/tcp"
  success "SSH (port ${SSH_PORT}) allowed."
fi

# Optional common services, explained in plain words.
if ask_yes_no "Allow HTTP (port 80)? Choose yes if this machine serves websites." "no"; then
  run $SUDO ufw allow 80/tcp
fi
if ask_yes_no "Allow HTTPS (port 443)? Choose yes if this machine serves secure websites." "no"; then
  run $SUDO ufw allow 443/tcp
fi

# Let advanced users add custom ports without editing the script.
while ask_yes_no "Add another custom port to allow?" "no"; do
  port="$(ask_value "Port number (e.g. 3000) — optionally 'PORT/tcp' or 'PORT/udp'" "")"
  if [[ -n "$port" ]]; then
    run $SUDO ufw allow "$port"
    success "Allowed: $port"
  fi
done

# Turn it on. 'ufw enable' normally asks for confirmation; --force skips that
# because we've already gathered the user's intent above.
if ask_yes_no "Enable the firewall now with the rules above?" "yes"; then
  run $SUDO ufw --force enable
  run $SUDO ufw status verbose
  success "Firewall is active."
else
  info "Firewall configured but NOT enabled. Turn it on later with: sudo ufw enable"
fi
