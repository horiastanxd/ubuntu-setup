#!/usr/bin/env bash
# ============================================================================
# 07 — Swap file
# WHAT: Creates a swap file (disk used as overflow memory) if you don't have
#       one. Helps small machines avoid crashing when they run out of RAM.
# WHY:  Cheap VPS/cloud servers often ship with no swap. A little swap can be
#       the difference between "slows down briefly" and "process killed".
# RISK: Low. We never touch an existing swap; we only ADD a file if none.
# ============================================================================
set -euo pipefail
MODULE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$MODULE_DIR/.." && pwd)"
# shellcheck source=/dev/null
source "$REPO_ROOT/lib/common.sh"
# shellcheck source=/dev/null
source "$REPO_ROOT/lib/checks.sh"
ensure_sudo

step "Configure swap (overflow memory)"

# Already have swap? Then leave it alone.
if [[ "$(swapon --show --noheadings 2>/dev/null | wc -l)" -gt 0 ]]; then
  success "Swap is already configured:"
  run swapon --show
  exit 0
fi

total_ram_mb="$(awk '/MemTotal/ {printf "%d", $2/1024}' /proc/meminfo)"
hint "Detected about ${total_ram_mb} MB of RAM and no swap."
hint "A common rule of thumb: swap = same size as RAM (up to ~4 GB) for small servers."

# Suggest a sensible default size.
suggest_gb=2
(( total_ram_mb <= 2048 )) && suggest_gb=2
(( total_ram_mb > 2048 && total_ram_mb <= 8192 )) && suggest_gb=4
(( total_ram_mb > 8192 )) && suggest_gb=4

if ! ask_yes_no "Create a swap file?" "yes"; then
  info "Skipped swap."
  exit 0
fi

size_gb="$(ask_value "Swap size in GB" "$suggest_gb")"
if ! [[ "$size_gb" =~ ^[0-9]+$ ]] || (( size_gb < 1 )); then
  die "Invalid size: '$size_gb'. Please use a whole number of GB (e.g. 2)."
fi

# Check there is enough free disk space before allocating.
free_mb="$(df --output=avail -m / | tail -1 | tr -d ' ')"
need_mb=$(( size_gb * 1024 ))
if (( free_mb < need_mb + 512 )); then
  die "Not enough free disk space: need ~${need_mb} MB, have ${free_mb} MB."
fi

SWAPFILE="/swapfile"
info "Creating ${size_gb} GB swap file at ${SWAPFILE}..."
# fallocate is fast; fall back to dd if the filesystem doesn't support it.
if ! run $SUDO fallocate -l "${size_gb}G" "$SWAPFILE"; then
  run $SUDO dd if=/dev/zero of="$SWAPFILE" bs=1M count="$need_mb" status=progress
fi
run $SUDO chmod 600 "$SWAPFILE"
run $SUDO mkswap "$SWAPFILE"
run $SUDO swapon "$SWAPFILE"

# Make it permanent across reboots.
if ! grep -q "^$SWAPFILE" /etc/fstab 2>/dev/null; then
  backup_file /etc/fstab
  run "echo '$SWAPFILE none swap sw 0 0' | $SUDO tee -a /etc/fstab"
fi

# Gentle 'swappiness': prefer RAM, use swap only when needed (good for servers).
SYSCTL="/etc/sysctl.d/99-ubuntu-setup-swap.conf"
if [[ "$DRY_RUN" != "true" ]]; then
  printf 'vm.swappiness=10\nvm.vfs_cache_pressure=50\n' | $SUDO tee "$SYSCTL" >/dev/null
  $SUDO sysctl --system >/dev/null 2>&1 || true
fi

success "Swap is active:"
run swapon --show
