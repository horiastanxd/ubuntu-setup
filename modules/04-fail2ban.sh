#!/usr/bin/env bash
# ============================================================================
# 04 — Fail2ban (brute-force protection)
# WHAT: Installs Fail2ban, which watches logs and temporarily bans IPs that
#       repeatedly fail to log in (e.g. password-guessing bots on SSH).
# WHY:  Any server on the internet gets thousands of automated login attempts.
#       Fail2ban makes those attacks far slower and less effective.
# RISK: Low. Worst case you ban yourself briefly by mistyping your password;
#       the ban is temporary and you can whitelist your own IP.
# ============================================================================
set -euo pipefail
MODULE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$MODULE_DIR/.." && pwd)"
# shellcheck source=/dev/null
source "$REPO_ROOT/lib/common.sh"
# shellcheck source=/dev/null
source "$REPO_ROOT/lib/checks.sh"
ensure_sudo

step "Install brute-force protection (Fail2ban)"
hint "Fail2ban automatically blocks IP addresses that fail to log in too many"
hint "times in a row — a simple, effective shield against password-guessing bots."

if ! ask_yes_no "Install and enable Fail2ban?" "yes"; then
  info "Skipped Fail2ban."
  exit 0
fi

apt_install fail2ban

# We write a 'jail.local' instead of editing 'jail.conf'. Ubuntu treats
# jail.local as the user-owned override file, so package updates won't wipe it.
JAIL_LOCAL="/etc/fail2ban/jail.local"
backup_file "$JAIL_LOCAL"

bantime="$(ask_value "How long to ban an attacker (e.g. 1h, 10m, 1d)?" "1h")"
maxretry="$(ask_value "How many failed tries before a ban?" "5")"
ignoreip="$(ask_value "IPs to NEVER ban (space-separated, keep your own IP safe)" "127.0.0.1/8 ::1")"

JAIL_CONTENT="$(cat <<EOF
# Managed by ubuntu-setup. Safe to edit; package updates won't overwrite this.
[DEFAULT]
bantime  = ${bantime}
findtime = 10m
maxretry = ${maxretry}
ignoreip = ${ignoreip}

# Protect SSH out of the box. Ubuntu's modern sshd logs to the systemd journal.
[sshd]
enabled = true
backend = systemd
EOF
)"

if [[ "$DRY_RUN" == "true" ]]; then
  printf '%s[dry-run]%s would write %s:\n%s\n' "$C_GRAY" "$C_RESET" "$JAIL_LOCAL" "$JAIL_CONTENT"
else
  printf '%s\n' "$JAIL_CONTENT" | $SUDO tee "$JAIL_LOCAL" >/dev/null
fi

run $SUDO systemctl enable fail2ban
run $SUDO systemctl restart fail2ban
success "Fail2ban is active and protecting SSH."
hint "Check status anytime with:  sudo fail2ban-client status sshd"
