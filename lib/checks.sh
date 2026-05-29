#!/usr/bin/env bash
# ============================================================================
# checks.sh — "Preflight" checks. We run these before touching anything so we
# fail early with a clear message instead of half-configuring a machine.
# ============================================================================

# ----------------------------------------------------------------------------
# detect_os — confirm we're on Ubuntu (or a close Debian relative) and read
# version info into globals: OS_ID, OS_VERSION, OS_CODENAME, OS_PRETTY.
# ----------------------------------------------------------------------------
detect_os() {
  if [[ ! -r /etc/os-release ]]; then
    die "Cannot read /etc/os-release — this does not look like a standard Linux distro."
  fi
  # shellcheck disable=SC1091
  . /etc/os-release
  OS_ID="${ID:-unknown}"
  OS_VERSION="${VERSION_ID:-unknown}"
  OS_CODENAME="${VERSION_CODENAME:-unknown}"
  OS_PRETTY="${PRETTY_NAME:-$OS_ID $OS_VERSION}"

  case "$OS_ID" in
    ubuntu) : ;; # perfect
    debian|linuxmint|pop|elementary|zorin)
      warn "Detected '$OS_PRETTY'. This is Ubuntu/Debian-based and should work,"
      warn "but the project is primarily tested on Ubuntu."
      ;;
    *)
      die "Unsupported OS: '$OS_PRETTY'. This tool targets Ubuntu (and Debian-based distros)."
      ;;
  esac
}

# ----------------------------------------------------------------------------
# detect_environment — server vs desktop. We look for a graphical session or
# desktop packages. Result goes into ENV_TYPE (server|desktop).
# ----------------------------------------------------------------------------
detect_environment() {
  if [[ -n "${XDG_CURRENT_DESKTOP:-}" ]] \
     || pkg_installed ubuntu-desktop \
     || pkg_installed gnome-shell \
     || [[ -d /usr/share/xsessions ]]; then
    ENV_TYPE="desktop"
  else
    ENV_TYPE="server"
  fi
}

# ----------------------------------------------------------------------------
# check_arch — record CPU architecture (some apps differ on arm64 vs amd64).
# ----------------------------------------------------------------------------
check_arch() { ARCH="$(dpkg --print-architecture 2>/dev/null || uname -m)"; }

# ----------------------------------------------------------------------------
# run_quiet — like run, but silences all output; used for connectivity probes.
# ----------------------------------------------------------------------------
run_quiet() { "$@" >/dev/null 2>&1; }

# ----------------------------------------------------------------------------
# check_internet — many steps need to download packages. Warn (don't die) if
# we cannot reach the network, since a few modules work offline.
# ----------------------------------------------------------------------------
check_internet() {
  if run_quiet ping -c1 -W2 8.8.8.8 || run_quiet ping -c1 -W2 1.1.1.1; then
    HAS_INTERNET="true"
  else
    HAS_INTERNET="false"
    warn "No internet connection detected. Steps that download packages will fail."
  fi
}

# ----------------------------------------------------------------------------
# preflight — run all checks and print a tidy summary.
# ----------------------------------------------------------------------------
preflight() {
  detect_os
  detect_environment
  check_arch
  check_internet
  step "System summary"
  hint "OS:           $OS_PRETTY"
  hint "Codename:     $OS_CODENAME"
  hint "Architecture: $ARCH"
  hint "Environment:  $ENV_TYPE"
  hint "Internet:     $HAS_INTERNET"
  hint "Log file:     $LOG_FILE"
  [[ "$DRY_RUN" == "true" ]] && hint "Mode:         DRY RUN (no changes will be made)"
  # Always succeed: with `set -e`, a non-zero exit from the && above would abort
  # the whole script before the interactive menu ever runs.
  return 0
}
