#!/usr/bin/env bash
# ============================================================================
# 02 — Essential packages
# WHAT: Installs the everyday tools almost every machine ends up needing.
# WHY:  A fresh Ubuntu is intentionally minimal. These are the "you'll want
#       these eventually" basics: editors, network tools, archives, git, etc.
# RISK: Low. Just installing well-known, widely-used packages.
# ============================================================================
set -euo pipefail
MODULE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$MODULE_DIR/.." && pwd)"
# shellcheck source=/dev/null
source "$REPO_ROOT/lib/common.sh"
# shellcheck source=/dev/null
source "$REPO_ROOT/lib/checks.sh"
ensure_sudo

step "Install essential command-line tools"

# Curated, conservative list. Everything here is in the official repos.
ESSENTIALS=(
  curl wget git                # download files & version control
  ca-certificates gnupg        # for verifying & adding software sources safely
  vim nano                     # text editors (pick your favorite)
  htop                         # interactive process/resource viewer
  net-tools dnsutils           # ping/ifconfig/dig and friends
  unzip zip tar                # archive handling
  build-essential              # compilers (gcc/make) for building software
  software-properties-common   # manage extra software sources (PPAs)
  apt-transport-https          # fetch packages over HTTPS
  tree less rsync              # navigation & file sync
  jq                           # read/transform JSON on the command line
)

info "About to install ${#ESSENTIALS[@]} common packages."
hint "These are standard, trusted tools from Ubuntu's official repositories."

if ask_yes_no "Install the recommended essentials?" "yes"; then
  run $SUDO apt-get update
  apt_install "${ESSENTIALS[@]}"
  success "Essential tools installed."
else
  info "Skipped essential packages."
fi
