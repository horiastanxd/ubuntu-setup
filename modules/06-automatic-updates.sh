#!/usr/bin/env bash
# ============================================================================
# 06 — Automatic security updates
# WHAT: Configures 'unattended-upgrades' so security patches install by
#       themselves, even when nobody is logged in.
# WHY:  Most break-ins exploit known bugs that already have fixes. Automatic
#       security updates close that window without you having to remember.
# RISK: Low. By default it installs only SECURITY updates, not risky changes.
# ============================================================================
set -euo pipefail
MODULE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$MODULE_DIR/.." && pwd)"
# shellcheck source=/dev/null
source "$REPO_ROOT/lib/common.sh"
# shellcheck source=/dev/null
source "$REPO_ROOT/lib/checks.sh"
ensure_sudo

step "Enable automatic security updates"
hint "This keeps the machine patched against known security problems"
hint "automatically. Highly recommended for servers that run unattended."

if ! ask_yes_no "Enable automatic security updates?" "yes"; then
  info "Skipped automatic updates."
  exit 0
fi

apt_install unattended-upgrades

# Whether to automatically reboot if an update needs it (e.g. kernel updates).
auto_reboot="false"
reboot_time="02:00"
if ask_yes_no "Allow automatic reboot when an update requires it? (good for servers)" "no"; then
  auto_reboot="true"
  reboot_time="$(ask_value "What time should it reboot if needed? (24h, e.g. 03:30)" "02:00")"
fi

CONF="/etc/apt/apt.conf.d/52-ubuntu-setup-unattended"
backup_file "$CONF"

CONTENT="$(cat <<EOF
// Managed by ubuntu-setup. Automatic update behavior.
Unattended-Upgrade::Allowed-Origins {
    "\${distro_id}:\${distro_codename}";
    "\${distro_id}:\${distro_codename}-security";
    "\${distro_id}ESMApps:\${distro_codename}-apps-security";
    "\${distro_id}ESM:\${distro_codename}-infra-security";
};
Unattended-Upgrade::Remove-Unused-Kernel-Packages "true";
Unattended-Upgrade::Remove-Unused-Dependencies "true";
Unattended-Upgrade::Automatic-Reboot "${auto_reboot}";
Unattended-Upgrade::Automatic-Reboot-Time "${reboot_time}";
EOF
)"

# Turn on the periodic schedule (download + install daily, clean weekly).
PERIODIC="/etc/apt/apt.conf.d/20auto-upgrades"
PERIODIC_CONTENT="$(cat <<'EOF'
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Download-Upgradeable-Packages "1";
APT::Periodic::Unattended-Upgrade "1";
APT::Periodic::AutocleanInterval "7";
EOF
)"

if [[ "$DRY_RUN" == "true" ]]; then
  printf '%s[dry-run]%s would write %s and %s\n' "$C_GRAY" "$C_RESET" "$CONF" "$PERIODIC"
else
  printf '%s\n' "$CONTENT" | $SUDO tee "$CONF" >/dev/null
  backup_file "$PERIODIC"
  printf '%s\n' "$PERIODIC_CONTENT" | $SUDO tee "$PERIODIC" >/dev/null
fi

run $SUDO systemctl enable unattended-upgrades
run $SUDO systemctl restart unattended-upgrades
success "Automatic security updates are enabled."
hint "Dry-run a check anytime with:  sudo unattended-upgrade --dry-run --debug"
