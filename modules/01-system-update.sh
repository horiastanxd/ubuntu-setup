#!/usr/bin/env bash
# ============================================================================
# 01 — System update
# WHAT: Refreshes the package list and upgrades all installed software.
# WHY:  Outdated software is the #1 source of security holes. Always do this
#       first so the rest of the setup builds on a current system.
# RISK: Low. Upgrades are the normal, expected thing on any machine.
# ============================================================================
set -euo pipefail
MODULE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$MODULE_DIR/.." && pwd)"
# shellcheck source=/dev/null
source "$REPO_ROOT/lib/common.sh"
# shellcheck source=/dev/null
source "$REPO_ROOT/lib/checks.sh"
ensure_sudo

step "Update & upgrade the system"
hint "This refreshes the catalog of available software and installs the latest"
hint "security and bug-fix updates for everything already on the machine."

run $SUDO apt-get update
run $SUDO DEBIAN_FRONTEND=noninteractive apt-get -y upgrade
run $SUDO DEBIAN_FRONTEND=noninteractive apt-get -y dist-upgrade
run $SUDO apt-get -y autoremove
run $SUDO apt-get -y autoclean

success "System is up to date."

if [[ -f /var/run/reboot-required ]]; then
  warn "A reboot is required to finish applying updates (e.g. a new kernel)."
fi
