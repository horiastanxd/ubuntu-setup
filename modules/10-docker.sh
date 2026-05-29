#!/usr/bin/env bash
# ============================================================================
# 10 — Docker Engine
# WHAT: Installs Docker (containers) from Docker's official repository, plus
#       the Compose plugin.
# WHY:  Docker is the standard way to run apps in isolated, reproducible
#       containers. Installing from the official repo gives you up-to-date,
#       trusted builds (the version in Ubuntu's repo is often older).
# RISK: Low-medium. Adding your user to the 'docker' group grants root-equiv
#       power on the host — we explain this and ask first.
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
check_arch

step "Install Docker (containers)"
hint "Docker lets you run applications in lightweight, isolated 'containers'."

if command_exists docker; then
  success "Docker is already installed: $(docker --version 2>/dev/null)"
  exit 0
fi

if ! ask_yes_no "Install Docker Engine + Compose from Docker's official repo?" "yes"; then
  info "Skipped Docker."
  exit 0
fi

# Remove old/conflicting packages that Ubuntu may ship.
for old in docker.io docker-doc docker-compose podman-docker containerd runc; do
  pkg_installed "$old" && run $SUDO apt-get remove -y "$old" || true
done

# 1) Prerequisites and Docker's signing key (verifies the packages are genuine).
apt_install ca-certificates curl
run $SUDO install -m 0755 -d /etc/apt/keyrings
if [[ "$DRY_RUN" != "true" ]]; then
  $SUDO curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
  $SUDO chmod a+r /etc/apt/keyrings/docker.asc
fi

# 2) Add Docker's apt repository for this Ubuntu codename + architecture.
codename="${OS_CODENAME:-$(. /etc/os-release && echo "$VERSION_CODENAME")}"
REPO_LINE="deb [arch=${ARCH} signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu ${codename} stable"
if [[ "$DRY_RUN" != "true" ]]; then
  echo "$REPO_LINE" | $SUDO tee /etc/apt/sources.list.d/docker.list >/dev/null
fi

# 3) Install Docker Engine, CLI, containerd, Buildx and Compose plugins.
run $SUDO apt-get update
apt_install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

run $SUDO systemctl enable --now docker
success "Docker installed: $(docker --version 2>/dev/null || echo 'installed')"

# Optionally let the current user run docker without sudo.
TARGET_USER="${SUDO_USER:-$USER}"
echo
warn "Adding a user to the 'docker' group lets them run containers without sudo,"
warn "which is effectively root access on this host. Only do this for trusted users."
if ask_yes_no "Add '$TARGET_USER' to the docker group?" "no"; then
  run $SUDO usermod -aG docker "$TARGET_USER"
  success "'$TARGET_USER' added to docker group."
  hint "Log out and back in (or run 'newgrp docker') for this to take effect."
fi

hint "Test it with:  docker run --rm hello-world"
