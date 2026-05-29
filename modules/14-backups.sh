#!/usr/bin/env bash
# ============================================================================
# 14 — Scheduled backups
# WHAT: Sets up simple, reliable, automatic backups of folders you choose,
#       using either 'restic' (encrypted, deduplicated snapshots) or a plain
#       'rsync' mirror. A systemd timer (or cron) runs them on a schedule.
# WHY:  The cheapest insurance you'll ever buy. Hardware fails, files get
#       deleted by accident, ransomware happens. Backups let you recover.
# RISK: Low. We NEVER delete your source data. We only READ your chosen folders
#       and WRITE copies to a destination you pick. For restic we generate a
#       repository password and loudly tell you to save it — without it the
#       encrypted backup cannot be restored.
# ============================================================================
set -euo pipefail
MODULE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$MODULE_DIR/.." && pwd)"
# shellcheck source=/dev/null
source "$REPO_ROOT/lib/common.sh"
# shellcheck source=/dev/null
source "$REPO_ROOT/lib/checks.sh"
ensure_sudo

step "Set up scheduled backups"
hint "We'll back up folders you choose to a destination you choose, on a"
hint "schedule. Your original files are only ever read, never deleted."

if ! ask_yes_no "Configure automatic backups now?" "yes"; then
  info "Skipped backups."
  exit 0
fi

TARGET_USER="${SUDO_USER:-$USER}"
TARGET_HOME="$(getent passwd "$TARGET_USER" | cut -d: -f6)"

# --- Choose the backup engine. ---------------------------------------------
echo
hint "restic: encrypted + deduplicated snapshots, supports many backends,"
hint "        can keep a history of versions. Recommended."
hint "rsync:  a simple, readable 1:1 mirror of your files to another folder."
ENGINE="restic"
if ! ask_yes_no "Use restic (recommended)? Choose 'no' for a simple rsync mirror." "yes"; then
  ENGINE="rsync"
fi

# --- Collect one or more source directories. -------------------------------
echo
SOURCES=()
default_src="$TARGET_HOME"
while true; do
  src="$(ask_value "Folder to back up (absolute path)" "$default_src")"
  default_src=""
  if [[ -z "$src" ]]; then
    warn "Empty path ignored."
  elif [[ "$src" != /* ]]; then
    warn "Please give an absolute path (starting with '/')."
  else
    SOURCES+=("$src")
    success "Will back up: $src"
  fi
  ask_yes_no "Add another folder to back up?" "no" || break
done

if [[ "${#SOURCES[@]}" -eq 0 ]]; then
  warn "No source folders given — nothing to back up. Skipping."
  exit 0
fi

# --- Destination directory. ------------------------------------------------
echo
hint "The destination should be on a DIFFERENT disk than your data if possible"
hint "(e.g. an external drive or a mounted network share)."
DEST="$(ask_value "Backup destination folder (absolute path)" "/var/backups/ubuntu-setup")"
if [[ "$DEST" != /* ]]; then
  die "Destination must be an absolute path."
fi
run $SUDO mkdir -p "$DEST"

# --- Schedule. -------------------------------------------------------------
echo
hint "How often should the backup run?"
hint "  daily  = once a day (recommended)   weekly = once a week"
SCHEDULE="$(ask_value "Schedule (daily/weekly)" "daily")"
case "$SCHEDULE" in
  daily|weekly) : ;;
  *) warn "Unknown schedule '$SCHEDULE', defaulting to daily."; SCHEDULE="daily" ;;
esac

# Paths for the generated runner script and systemd unit.
RUNNER="/usr/local/bin/ubuntu-setup-backup.sh"
SERVICE="/etc/systemd/system/ubuntu-setup-backup.service"
TIMER="/etc/systemd/system/ubuntu-setup-backup.timer"

if [[ "$ENGINE" == "restic" ]]; then
  # ---------------------------------------------------------------- restic --
  apt_install restic

  RESTIC_REPO="$DEST/restic-repo"
  PASS_FILE="/etc/ubuntu-setup/restic-password"

  echo
  if [[ -f "$PASS_FILE" ]]; then
    success "Existing restic password file found at $PASS_FILE — reusing it."
  else
    info "Generating a strong random password for the encrypted backup repo."
    run $SUDO mkdir -p /etc/ubuntu-setup
    if [[ "$DRY_RUN" == "true" ]]; then
      printf '%s[dry-run]%s would generate password into %s\n' "$C_GRAY" "$C_RESET" "$PASS_FILE"
    else
      umask 077
      openssl rand -base64 32 | $SUDO tee "$PASS_FILE" >/dev/null
      $SUDO chmod 600 "$PASS_FILE"
    fi
    echo
    warn "================ SAVE YOUR BACKUP PASSWORD ================"
    warn "Your encrypted backups CANNOT be restored without this password."
    warn "It is stored at: $PASS_FILE"
    warn "Copy it somewhere safe and OFF this machine (a password manager)."
    warn "=========================================================="
    if [[ "$DRY_RUN" != "true" ]]; then
      hint "Your password is:"
      $SUDO cat "$PASS_FILE" | sed 's/^/    /'
    fi
  fi

  # Initialise the repository if it doesn't exist yet (safe / idempotent).
  if [[ "$DRY_RUN" == "true" ]]; then
    printf '%s[dry-run]%s would init restic repo at %s if missing\n' "$C_GRAY" "$C_RESET" "$RESTIC_REPO"
  else
    if ! $SUDO restic -r "$RESTIC_REPO" -p "$PASS_FILE" snapshots >/dev/null 2>&1; then
      info "Initialising restic repository at $RESTIC_REPO ..."
      $SUDO restic -r "$RESTIC_REPO" -p "$PASS_FILE" init
    else
      hint "restic repository already initialised — reusing it."
    fi
  fi

  # Build the runner script. 'forget --prune' only trims OLD SNAPSHOTS in the
  # backup repo (never your source files), keeping a generous history.
  RUNNER_BODY="#!/usr/bin/env bash
set -euo pipefail
export RESTIC_REPOSITORY='$RESTIC_REPO'
export RESTIC_PASSWORD_FILE='$PASS_FILE'
restic backup ${SOURCES[*]} --verbose
# Keep a sensible history of snapshots in the backup repo.
restic forget --keep-daily 7 --keep-weekly 4 --keep-monthly 6 --prune
"
else
  # ----------------------------------------------------------------- rsync --
  apt_install rsync

  MIRROR="$DEST/mirror"
  run $SUDO mkdir -p "$MIRROR"

  # -a archive, --delete keeps the mirror in sync. This deletes files in the
  # DESTINATION mirror only (so it matches the source) — never the source.
  RSYNC_LINES=""
  for s in "${SOURCES[@]}"; do
    RSYNC_LINES+="rsync -aH --delete --numeric-ids '$s' '$MIRROR/'
"
  done
  RUNNER_BODY="#!/usr/bin/env bash
set -euo pipefail
$RSYNC_LINES"
fi

# --- Write the runner script. ----------------------------------------------
backup_file "$RUNNER"
if [[ "$DRY_RUN" == "true" ]]; then
  printf '%s[dry-run]%s would write runner script %s:\n' "$C_GRAY" "$C_RESET" "$RUNNER"
  printf '%s\n' "$RUNNER_BODY" | sed 's/^/    /'
else
  printf '%s' "$RUNNER_BODY" | $SUDO tee "$RUNNER" >/dev/null
  $SUDO chmod 755 "$RUNNER"
fi
success "Backup runner script written to $RUNNER"

# --- Schedule via systemd timer (preferred) or cron fallback. --------------
echo
USE_SYSTEMD="false"
if command_exists systemctl; then
  USE_SYSTEMD="true"
fi

if [[ "$USE_SYSTEMD" == "true" ]]; then
  SERVICE_BODY="[Unit]
Description=ubuntu-setup scheduled backup

[Service]
Type=oneshot
ExecStart=$RUNNER
"
  TIMER_BODY="[Unit]
Description=Run ubuntu-setup backup on a schedule

[Timer]
OnCalendar=$SCHEDULE
Persistent=true

[Install]
WantedBy=timers.target
"
  if [[ "$DRY_RUN" == "true" ]]; then
    printf '%s[dry-run]%s would write %s and %s, then enable the timer\n' \
      "$C_GRAY" "$C_RESET" "$SERVICE" "$TIMER"
  else
    printf '%s' "$SERVICE_BODY" | $SUDO tee "$SERVICE" >/dev/null
    printf '%s' "$TIMER_BODY"   | $SUDO tee "$TIMER" >/dev/null
  fi
  run $SUDO systemctl daemon-reload
  run $SUDO systemctl enable --now ubuntu-setup-backup.timer
  success "Backup scheduled ($SCHEDULE) via systemd timer 'ubuntu-setup-backup.timer'."
  hint "Run it once now with:  sudo systemctl start ubuntu-setup-backup.service"
  hint "Check schedule with:   systemctl list-timers ubuntu-setup-backup.timer"
else
  # cron fallback
  CRON_TIME="0 2 * * *"
  [[ "$SCHEDULE" == "weekly" ]] && CRON_TIME="0 2 * * 0"
  CRON_LINE="$CRON_TIME root $RUNNER"
  CRON_FILE="/etc/cron.d/ubuntu-setup-backup"
  if [[ "$DRY_RUN" == "true" ]]; then
    printf '%s[dry-run]%s would write cron entry to %s: %s\n' \
      "$C_GRAY" "$C_RESET" "$CRON_FILE" "$CRON_LINE"
  else
    printf '%s\n' "$CRON_LINE" | $SUDO tee "$CRON_FILE" >/dev/null
  fi
  success "Backup scheduled ($SCHEDULE) via cron at $CRON_FILE."
fi

echo
success "Backups configured."
warn "Test your backups regularly — an untested backup is just a hope."
if [[ "$ENGINE" == "restic" ]]; then
  hint "List snapshots:  sudo restic -r '$DEST/restic-repo' -p /etc/ubuntu-setup/restic-password snapshots"
  hint "Restore example: sudo restic -r '$DEST/restic-repo' -p /etc/ubuntu-setup/restic-password restore latest --target /tmp/restore"
fi
