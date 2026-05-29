#!/usr/bin/env bash
# ============================================================================
# common.sh — Shared helpers used by every module.
#
# This file is *sourced* (not executed). It gives every module the same
# colored output, logging, confirmation prompts, backup helpers, and a
# "dry run" mode so people can preview changes before anything happens.
#
# Plain-language idea: think of this as the "toolbox" the rest of the
# scripts reach into so they all behave the same way and stay safe.
# ============================================================================

# ----------------------------------------------------------------------------
# Colors (only if the terminal supports them — keeps logs/CI clean).
# ----------------------------------------------------------------------------
if [[ -t 1 ]] && command -v tput >/dev/null 2>&1 && [[ "$(tput colors 2>/dev/null || echo 0)" -ge 8 ]]; then
  C_RESET="$(tput sgr0)"
  C_BOLD="$(tput bold)"
  C_RED="$(tput setaf 1)"
  C_GREEN="$(tput setaf 2)"
  C_YELLOW="$(tput setaf 3)"
  C_BLUE="$(tput setaf 4)"
  C_CYAN="$(tput setaf 6)"
  C_GRAY="$(tput setaf 8)"
else
  C_RESET="" C_BOLD="" C_RED="" C_GREEN="" C_YELLOW="" C_BLUE="" C_CYAN="" C_GRAY=""
fi

# ----------------------------------------------------------------------------
# Global state (with safe defaults so modules can be run standalone too).
# ----------------------------------------------------------------------------
: "${DRY_RUN:=false}"          # When true, we print actions instead of running them.
: "${ASSUME_YES:=false}"       # When true, all confirmations default to "yes".
: "${LOG_FILE:=/tmp/ubuntu-setup-$(date +%Y%m%d-%H%M%S).log}"
: "${BACKUP_DIR:=$HOME/.ubuntu-setup/backups}"

# ----------------------------------------------------------------------------
# Logging helpers. Everything is also appended to the log file for later
# inspection ("what did this script actually change on my machine?").
# ----------------------------------------------------------------------------
_log_to_file() {
  # Strip color codes before writing to the log file.
  printf '%s %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" \
    | sed -r 's/\x1b\[[0-9;]*m//g' >>"$LOG_FILE" 2>/dev/null || true
}

info()    { printf '%s[i]%s %s\n'  "$C_BLUE"   "$C_RESET" "$*"; _log_to_file "[INFO]  $*"; }
success() { printf '%s[✓]%s %s\n'  "$C_GREEN"  "$C_RESET" "$*"; _log_to_file "[OK]    $*"; }
warn()    { printf '%s[!]%s %s\n'  "$C_YELLOW" "$C_RESET" "$*"; _log_to_file "[WARN]  $*"; }
error()   { printf '%s[x]%s %s\n'  "$C_RED"    "$C_RESET" "$*" >&2; _log_to_file "[ERROR] $*"; }
step()    { printf '\n%s==>%s %s%s%s\n' "$C_CYAN" "$C_RESET" "$C_BOLD" "$*" "$C_RESET"; _log_to_file "[STEP]  $*"; }
hint()    { printf '    %s%s%s\n' "$C_GRAY" "$*" "$C_RESET"; }

# ----------------------------------------------------------------------------
# die — print an error and exit. Used for unrecoverable problems.
# ----------------------------------------------------------------------------
die() { error "$*"; exit 1; }

# ----------------------------------------------------------------------------
# command_exists — true if a command is available on this system.
# ----------------------------------------------------------------------------
command_exists() { command -v "$1" >/dev/null 2>&1; }

# ----------------------------------------------------------------------------
# run — the heart of "safe mode". Every command that changes the system
# should go through here. In dry-run mode it only PRINTS what it would do.
#
# Usage:  run apt-get update
#         run "echo something | tee /etc/file"   # use a string for pipes
# ----------------------------------------------------------------------------
run() {
  if [[ "$DRY_RUN" == "true" ]]; then
    printf '%s[dry-run]%s %s\n' "$C_GRAY" "$C_RESET" "$*"
    _log_to_file "[DRY]   $*"
    return 0
  fi
  _log_to_file "[RUN]   $*"
  # If the caller passed a single string with shell operators, run via bash -c.
  if [[ "$#" -eq 1 && "$1" == *[\|\>\<\&\;]* ]]; then
    bash -c "$1"
  else
    "$@"
  fi
}

# ----------------------------------------------------------------------------
# Confirmation prompts. They are deliberately friendly and explain defaults.
#   ask_yes_no "Question?" "yes"   -> returns 0 for yes, 1 for no
# Honors ASSUME_YES (-y / unattended) and DRY_RUN.
# ----------------------------------------------------------------------------
ask_yes_no() {
  local prompt="$1" default="${2:-no}" reply
  local suffix="[y/N]"
  [[ "$default" == "yes" || "$default" == "y" ]] && suffix="[Y/n]"

  if [[ "$ASSUME_YES" == "true" ]]; then
    info "$prompt $suffix -> auto: ${default}"
    [[ "$default" == "yes" || "$default" == "y" ]]
    return
  fi

  while true; do
    printf '%s?%s %s %s ' "$C_YELLOW" "$C_RESET" "$prompt" "$suffix"
    read -r reply </dev/tty || reply=""
    reply="${reply:-$default}"
    case "${reply,,}" in
      y|yes) return 0 ;;
      n|no)  return 1 ;;
      *)     warn "Please answer y (yes) or n (no)." ;;
    esac
  done
}

# ----------------------------------------------------------------------------
# ask_value — ask for a free-text value with an optional default.
#   name=$(ask_value "New username" "deploy")
# ----------------------------------------------------------------------------
ask_value() {
  local prompt="$1" default="${2:-}" reply

  if [[ "$ASSUME_YES" == "true" ]]; then
    printf '%s' "$default"
    return
  fi

  # Show the default in brackets when one is provided, e.g. "Username [deploy]: "
  if [[ -n "$default" ]]; then
    printf '%s?%s %s [%s]: ' "$C_YELLOW" "$C_RESET" "$prompt" "$default" >&2
  else
    printf '%s?%s %s: ' "$C_YELLOW" "$C_RESET" "$prompt" >&2
  fi
  read -r reply </dev/tty || reply=""
  printf '%s' "${reply:-$default}"
}

# ----------------------------------------------------------------------------
# ensure_sudo — make sure we can use sudo for system changes. We do NOT force
# the whole script to run as root; instead each privileged command uses the
# SUDO prefix below, which is empty when already running as root.
# ----------------------------------------------------------------------------
SUDO=""
ensure_sudo() {
  if [[ "$(id -u)" -eq 0 ]]; then
    SUDO=""
  elif command_exists sudo; then
    SUDO="sudo"
    # Prime the sudo timestamp once, with a friendly message.
    if ! sudo -n true 2>/dev/null; then
      info "Some steps need administrator rights. You may be asked for your password."
      sudo -v || die "Could not obtain administrator (sudo) rights."
    fi
  else
    die "This script needs root privileges, but 'sudo' is not installed and you are not root."
  fi
}

# ----------------------------------------------------------------------------
# backup_file — copy a file to the backup dir (timestamped) before editing.
# Returns success even if the file does not exist yet (nothing to back up).
# ----------------------------------------------------------------------------
backup_file() {
  local file="$1"
  [[ -e "$file" ]] || return 0
  run mkdir -p "$BACKUP_DIR"
  local dest
  dest="$BACKUP_DIR/$(basename "$file").$(date +%Y%m%d-%H%M%S).bak"
  if [[ "$DRY_RUN" == "true" ]]; then
    printf '%s[dry-run]%s backup %s -> %s\n' "$C_GRAY" "$C_RESET" "$file" "$dest"
    _log_to_file "[DRY]   backup $file -> $dest"
  else
    $SUDO cp -a "$file" "$dest" && hint "Backup saved: $dest"
  fi
}

# ----------------------------------------------------------------------------
# pkg_installed / apt_install — convenience wrappers that are idempotent
# (they don't reinstall things that are already there).
# ----------------------------------------------------------------------------
pkg_installed() { dpkg -s "$1" >/dev/null 2>&1; }

apt_install() {
  local pkg
  local to_install=()
  for pkg in "$@"; do
    if pkg_installed "$pkg"; then
      hint "Already installed: $pkg"
    else
      to_install+=("$pkg")
    fi
  done
  if [[ "${#to_install[@]}" -gt 0 ]]; then
    info "Installing: ${to_install[*]}"
    run $SUDO DEBIAN_FRONTEND=noninteractive apt-get install -y "${to_install[@]}"
  fi
}

# ----------------------------------------------------------------------------
# pause — wait for the user (skipped in unattended mode).
# ----------------------------------------------------------------------------
pause() {
  [[ "$ASSUME_YES" == "true" ]] && return 0
  printf '\n%sPress Enter to continue...%s' "$C_GRAY" "$C_RESET"
  read -r </dev/tty || true
  printf '\n'
}
