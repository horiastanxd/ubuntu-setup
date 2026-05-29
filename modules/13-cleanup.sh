#!/usr/bin/env bash
# ============================================================================
# 13 — Cleanup & maintenance
# WHAT: Frees disk space: removes unused packages, old kernels, and trims
#       systemd journal logs.
# WHY:  Over time servers and desktops accumulate cruft. A gentle cleanup
#       reclaims space without removing anything you actually use.
# RISK: Low. We only remove things Ubuntu itself considers safe to remove.
# ============================================================================
set -euo pipefail
MODULE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$MODULE_DIR/.." && pwd)"
# shellcheck source=/dev/null
source "$REPO_ROOT/lib/common.sh"
# shellcheck source=/dev/null
source "$REPO_ROOT/lib/checks.sh"
ensure_sudo

step "Cleanup & maintenance"
hint "This reclaims disk space by removing things Ubuntu no longer needs."

before="$(df -h / | awk 'NR==2 {print $4}')"
hint "Free space on / before: ${before}"

if ask_yes_no "Remove unused packages and dependencies?" "yes"; then
  run $SUDO apt-get autoremove --purge -y
  run $SUDO apt-get autoclean -y
  run $SUDO apt-get clean -y
fi

if command_exists journalctl && ask_yes_no "Trim system logs (keep last 200 MB)?" "yes"; then
  run $SUDO journalctl --vacuum-size=200M
fi

after="$(df -h / | awk 'NR==2 {print $4}')"
success "Cleanup complete. Free space on /: ${before} -> ${after}"
