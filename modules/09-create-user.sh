#!/usr/bin/env bash
# ============================================================================
# 09 — Create an admin (sudo) user
# WHAT: Creates a new non-root user with sudo rights — optionally copying your
#       SSH key so you can log in as them right away.
# WHY:  Working as root all the time is risky. Best practice is a normal user
#       who can "sudo" when needed. This is especially useful on fresh servers
#       that only gave you root.
# RISK: Low. We never delete users; we only create one if you ask.
# ============================================================================
set -euo pipefail
MODULE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$MODULE_DIR/.." && pwd)"
# shellcheck source=/dev/null
source "$REPO_ROOT/lib/common.sh"
# shellcheck source=/dev/null
source "$REPO_ROOT/lib/checks.sh"
ensure_sudo

step "Create an administrator (sudo) user"
hint "It's safer to use a normal user with 'sudo' than to log in as root."

if ! ask_yes_no "Create a new sudo user?" "no"; then
  info "Skipped user creation."
  exit 0
fi

username="$(ask_value "New username (lowercase letters/numbers, e.g. deploy)" "")"
if [[ -z "$username" ]]; then
  warn "No username given — skipping."
  exit 0
fi
if ! [[ "$username" =~ ^[a-z_][a-z0-9_-]*$ ]]; then
  die "Invalid username '$username'. Use lowercase letters, numbers, - and _."
fi
if id "$username" >/dev/null 2>&1; then
  warn "User '$username' already exists."
  if ask_yes_no "Ensure they have sudo rights?" "yes"; then
    run $SUDO usermod -aG sudo "$username"
    success "'$username' is in the sudo group."
  fi
  exit 0
fi

# Create the user with a home directory and bash as the shell.
run $SUDO adduser --disabled-password --gecos "" "$username"
run $SUDO usermod -aG sudo "$username"
success "Created sudo user '$username'."

# Set a password (so they can use sudo). adduser --disabled-password leaves it
# unset; we let the admin set one interactively unless in unattended mode.
if [[ "$ASSUME_YES" != "true" ]] && ask_yes_no "Set a password for '$username' now?" "yes"; then
  run $SUDO passwd "$username"
fi

# Offer to copy the current user's SSH key so key-based login works immediately.
TARGET_USER="${SUDO_USER:-$USER}"
TARGET_HOME="$(getent passwd "$TARGET_USER" | cut -d: -f6)"
if [[ -s "$TARGET_HOME/.ssh/authorized_keys" ]] \
   && ask_yes_no "Copy your existing SSH keys to '$username' (recommended)?" "yes"; then
  run $SUDO mkdir -p "/home/$username/.ssh"
  run "$SUDO cp '$TARGET_HOME/.ssh/authorized_keys' '/home/$username/.ssh/authorized_keys'"
  run $SUDO chown -R "$username:$username" "/home/$username/.ssh"
  run $SUDO chmod 700 "/home/$username/.ssh"
  run $SUDO chmod 600 "/home/$username/.ssh/authorized_keys"
  success "SSH keys copied — '$username' can log in with your key."
fi

hint "Switch to the new user with:  su - $username   (or log in over SSH)"
