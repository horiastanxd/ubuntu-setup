#!/usr/bin/env bash
# ============================================================================
# 05 — SSH hardening
# WHAT: Makes remote login (SSH) much safer: optionally disable root login and
#       password logins (in favor of SSH keys), and apply sane defaults.
# WHY:  SSH is the main door into a server. Keys are far stronger than
#       passwords, and disabling root login removes the most-attacked account.
# RISK: HIGH if misused. Disabling password login WITHOUT a working SSH key
#       installed can lock you out permanently. This script checks for keys
#       and refuses to do dangerous things without explicit confirmation.
# ============================================================================
set -euo pipefail
MODULE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$MODULE_DIR/.." && pwd)"
# shellcheck source=/dev/null
source "$REPO_ROOT/lib/common.sh"
# shellcheck source=/dev/null
source "$REPO_ROOT/lib/checks.sh"
ensure_sudo

step "Harden SSH (secure remote login)"

if ! pkg_installed openssh-server; then
  if ask_yes_no "OpenSSH server is not installed. Install it?" "no"; then
    apt_install openssh-server
  else
    info "SSH not installed and not requested — nothing to harden. Skipping."
    exit 0
  fi
fi

# We use a drop-in file in /etc/ssh/sshd_config.d/ — the modern, update-safe
# way to override SSH settings on Ubuntu without editing the main config.
DROPIN_DIR="/etc/ssh/sshd_config.d"
DROPIN="$DROPIN_DIR/99-ubuntu-setup-hardening.conf"
run $SUDO mkdir -p "$DROPIN_DIR"

# --- Detect whether the invoking user has any authorized SSH keys. ----------
TARGET_USER="${SUDO_USER:-$USER}"
TARGET_HOME="$(getent passwd "$TARGET_USER" | cut -d: -f6)"
HAS_KEYS="false"
if [[ -s "$TARGET_HOME/.ssh/authorized_keys" ]]; then
  HAS_KEYS="true"
fi

settings=()

# Root login: almost everyone should disable direct root SSH login.
if ask_yes_no "Disable direct SSH login as 'root'? (recommended)" "yes"; then
  settings+=("PermitRootLogin no")
fi

# Password authentication: the big one. Guard heavily.
disable_passwords="no"
echo
hint "Key-based login is much safer than passwords. But if you disable password"
hint "login without a working key, you could be LOCKED OUT of this machine."
if [[ "$HAS_KEYS" == "true" ]]; then
  success "Found SSH keys for user '$TARGET_USER' — disabling passwords is safe."
  if ask_yes_no "Disable password login and require SSH keys? (recommended)" "yes"; then
    disable_passwords="yes"
  fi
else
  warn "No SSH keys found for user '$TARGET_USER' in ~/.ssh/authorized_keys."
  warn "Disabling passwords now would likely lock you out."
  if ask_yes_no "I understand the risk. Disable password login ANYWAY?" "no"; then
    disable_passwords="yes"
  fi
fi
if [[ "$disable_passwords" == "yes" ]]; then
  settings+=("PasswordAuthentication no")
  settings+=("KbdInteractiveAuthentication no")
else
  settings+=("PasswordAuthentication yes")
fi

# Sensible universal defaults.
settings+=("PubkeyAuthentication yes")
settings+=("X11Forwarding no")
settings+=("MaxAuthTries 4")
settings+=("LoginGraceTime 30")
settings+=("ClientAliveInterval 300")
settings+=("ClientAliveCountMax 2")

# Build the config file.
CONTENT="# Managed by ubuntu-setup. SSH hardening overrides."$'\n'
for line in "${settings[@]}"; do
  CONTENT+="$line"$'\n'
done

echo
info "The following SSH settings will be applied:"
printf '%s\n' "$CONTENT" | sed 's/^/    /'

if ! ask_yes_no "Apply these SSH settings?" "yes"; then
  info "Skipped SSH hardening."
  exit 0
fi

backup_file "$DROPIN"
if [[ "$DRY_RUN" == "true" ]]; then
  printf '%s[dry-run]%s would write %s\n' "$C_GRAY" "$C_RESET" "$DROPIN"
else
  printf '%s' "$CONTENT" | $SUDO tee "$DROPIN" >/dev/null
fi

# --- Validate config BEFORE restarting, so we never break a live service. ---
if [[ "$DRY_RUN" != "true" ]]; then
  if $SUDO sshd -t; then
    success "SSH configuration is valid."
  else
    error "SSH config test FAILED — reverting to avoid lockout."
    $SUDO rm -f "$DROPIN"
    die "Did not change SSH. Please review and try again."
  fi
fi

run $SUDO systemctl restart ssh 2>/dev/null || run $SUDO systemctl restart sshd
success "SSH hardened. Your current session stays connected."
warn "IMPORTANT: open a NEW terminal and confirm you can still log in BEFORE"
warn "closing this one. That way, if anything is wrong, you can still fix it."
