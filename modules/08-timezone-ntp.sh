#!/usr/bin/env bash
# ============================================================================
# 08 — Timezone & clock sync
# WHAT: Sets the system timezone and turns on automatic time syncing (NTP).
# WHY:  A correct clock matters more than people think: TLS certificates,
#       logs, backups, and scheduled jobs all rely on accurate time.
# RISK: Low.
# ============================================================================
set -euo pipefail
MODULE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$MODULE_DIR/.." && pwd)"
# shellcheck source=/dev/null
source "$REPO_ROOT/lib/common.sh"
# shellcheck source=/dev/null
source "$REPO_ROOT/lib/checks.sh"
ensure_sudo

step "Set timezone and enable automatic time sync"

current_tz="$(timedatectl show -p Timezone --value 2>/dev/null || echo 'unknown')"
hint "Current timezone: ${current_tz}"

if ask_yes_no "Change the timezone?" "no"; then
  hint "Examples: Europe/Bucharest, Europe/London, America/New_York, UTC"
  hint "List all options with:  timedatectl list-timezones"
  tz="$(ask_value "Enter timezone" "$current_tz")"
  if timedatectl list-timezones 2>/dev/null | grep -qx "$tz"; then
    run $SUDO timedatectl set-timezone "$tz"
    success "Timezone set to $tz."
  else
    warn "'$tz' is not a recognized timezone — leaving it unchanged."
  fi
fi

# Enable network time synchronization (systemd-timesyncd is built in).
if ask_yes_no "Enable automatic clock synchronization (NTP)?" "yes"; then
  run $SUDO timedatectl set-ntp true
  success "Automatic time sync enabled."
fi

run timedatectl status
