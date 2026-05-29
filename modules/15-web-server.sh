#!/usr/bin/env bash
# ============================================================================
# 15 — Web server (Caddy or Nginx)
# WHAT: Installs and minimally configures a web server. You choose Caddy
#       (automatic HTTPS, beginner-friendly) or Nginx (the classic, with an
#       optional Certbot setup for free Let's Encrypt certificates).
# WHY:  A web server lets this machine serve websites or sit in front of your
#       apps as a reverse proxy. Caddy gets you HTTPS with almost no effort.
# RISK: Low-medium. Serving on ports 80/443 exposes this machine to the
#       internet. We only open firewall ports if UFW is already active, and we
#       never overwrite an existing site config without backing it up first.
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

step "Install a web server"
hint "Caddy: automatic HTTPS certificates, simplest to run. Recommended."
hint "Nginx: the well-known classic; we can add Certbot for free HTTPS."

if command_exists caddy; then
  success "Caddy is already installed: $(caddy version 2>/dev/null | head -n1)"
  exit 0
fi
if command_exists nginx; then
  success "Nginx is already installed: $(nginx -v 2>&1 | head -n1)"
  exit 0
fi

if ! ask_yes_no "Install a web server now?" "yes"; then
  info "Skipped web server."
  exit 0
fi

CHOICE="caddy"
if ! ask_yes_no "Use Caddy (recommended)? Choose 'no' for Nginx." "yes"; then
  CHOICE="nginx"
fi

# Helper: open a port in UFW only if UFW is installed AND active.
open_port_if_ufw_active() {
  local port="$1"
  if command_exists ufw && $SUDO ufw status 2>/dev/null | grep -q "Status: active"; then
    run $SUDO ufw allow "$port"
    success "Opened firewall port $port (UFW is active)."
  else
    hint "UFW not active — not touching the firewall. If you enable UFW later,"
    hint "remember to allow port $port."
  fi
}

if [[ "$CHOICE" == "caddy" ]]; then
  # ------------------------------------------------------------------ Caddy --
  # Official Caddy apt repository (signed), mirroring Docker's key+repo pattern.
  apt_install ca-certificates curl gnupg debian-keyring debian-archive-keyring apt-transport-https

  KEYRING="/usr/share/keyrings/caddy-stable-archive-keyring.gpg"
  REPO_FILE="/etc/apt/sources.list.d/caddy-stable.list"

  if [[ "$DRY_RUN" == "true" ]]; then
    printf '%s[dry-run]%s would add Caddy GPG key to %s\n' "$C_GRAY" "$C_RESET" "$KEYRING"
    printf '%s[dry-run]%s would add Caddy apt repo to %s\n' "$C_GRAY" "$C_RESET" "$REPO_FILE"
  else
    curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' \
      | $SUDO gpg --batch --yes --dearmor -o "$KEYRING"
    curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' \
      | $SUDO tee "$REPO_FILE" >/dev/null
  fi

  run $SUDO apt-get update
  apt_install caddy
  run $SUDO systemctl enable --now caddy
  success "Caddy installed: $(caddy version 2>/dev/null | head -n1 || echo installed)"

  echo
  hint "Caddy automatically gets and renews HTTPS certificates from Let's Encrypt"
  hint "for any real domain you point at this server. Just edit /etc/caddy/Caddyfile,"
  hint "for example:"
  hint "    example.com {"
  hint "        root * /var/www/html"
  hint "        file_server"
  hint "    }"
  hint "Then run:  sudo systemctl reload caddy"

  open_port_if_ufw_active 80/tcp
  open_port_if_ufw_active 443/tcp

else
  # ------------------------------------------------------------------ Nginx --
  apt_install nginx
  run $SUDO systemctl enable --now nginx
  success "Nginx installed: $(nginx -v 2>&1 | head -n1 || echo installed)"

  open_port_if_ufw_active 'Nginx Full'

  echo
  if ask_yes_no "Install Certbot for free Let's Encrypt HTTPS certificates?" "yes"; then
    apt_install certbot python3-certbot-nginx
    success "Certbot installed."
    echo
    hint "To get an HTTPS certificate for a domain pointed at this server, run:"
    hint "    sudo certbot --nginx -d example.com"
    hint "Certbot will configure Nginx and set up automatic renewal for you."
  else
    info "Skipped Certbot. You can install it later: sudo apt install certbot python3-certbot-nginx"
  fi

  hint "Site configs live in /etc/nginx/sites-available/ (symlink into sites-enabled/)."
  hint "Default web root is /var/www/html. Reload with:  sudo systemctl reload nginx"
fi

echo
success "Web server ready."
warn "If this machine is on the public internet, make sure only the ports you"
warn "intend (80/443) are open and keep the server software updated."
