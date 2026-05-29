#!/usr/bin/env bash
# ============================================================================
#  ubuntu-setup — friendly, safe post-install setup for Ubuntu server & desktop
#
#  Repo:    https://github.com/<your-username>/ubuntu-setup
#  License: MIT
#
#  This is the main entry point. It runs a friendly interactive menu, or, with
#  flags, runs unattended for automation. It does NOT make any change without
#  either your confirmation or an explicit --yes.
#
#  Quick start:
#      git clone https://github.com/<your-username>/ubuntu-setup.git
#      cd ubuntu-setup
#      ./setup.sh
#
#  Useful flags:
#      ./setup.sh --dry-run        Preview everything; change nothing.
#      ./setup.sh --list           List available modules and exit.
#      ./setup.sh --only 01,03,05  Run only specific modules, non-interactively.
#      ./setup.sh --yes            Accept recommended defaults (unattended).
# ============================================================================
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODULES_DIR="$REPO_ROOT/modules"

# Defaults; exported so child module processes inherit safe-mode settings.
export DRY_RUN="false"
export ASSUME_YES="false"
export LOG_FILE="${LOG_FILE:-/tmp/ubuntu-setup-$(date +%Y%m%d-%H%M%S).log}"
export BACKUP_DIR="${BACKUP_DIR:-$HOME/.ubuntu-setup/backups}"

# shellcheck source=/dev/null
source "$REPO_ROOT/lib/common.sh"
# shellcheck source=/dev/null
source "$REPO_ROOT/lib/checks.sh"

# ----------------------------------------------------------------------------
# Module registry. Order = recommended run order. Each entry is:
#   "file|Short description|server,desktop|recommended"
# 'recommended' marks modules included in the one-click profiles.
# ----------------------------------------------------------------------------
MODULES=(
  "01-system-update.sh|Update & upgrade the whole system|server,desktop|yes"
  "02-essentials.sh|Install essential command-line tools|server,desktop|yes"
  "03-firewall-ufw.sh|Set up the firewall (UFW)|server,desktop|yes"
  "04-fail2ban.sh|Brute-force protection (Fail2ban)|server|yes"
  "05-ssh-hardening.sh|Harden SSH remote login|server|yes"
  "06-automatic-updates.sh|Automatic security updates|server,desktop|yes"
  "07-swap.sh|Create a swap file (overflow memory)|server|yes"
  "08-timezone-ntp.sh|Set timezone & sync the clock|server,desktop|yes"
  "09-create-user.sh|Create an admin (sudo) user|server|no"
  "10-docker.sh|Install Docker + Compose|server,desktop|no"
  "11-developer-tools.sh|Developer tools (Node, Python, CLI)|server,desktop|no"
  "12-desktop-apps.sh|Desktop apps, codecs & Flatpak|desktop|no"
  "13-cleanup.sh|Cleanup & reclaim disk space|server,desktop|yes"
  "14-backups.sh|Scheduled backups (restic or rsync)|server,desktop|no"
  "15-web-server.sh|Web server (Caddy or Nginx)|server|no"
  "16-tailscale.sh|Tailscale mesh VPN (remote access)|server,desktop|no"
  "17-monitoring.sh|Monitoring (node_exporter/Netdata)|server,desktop|no"
  "18-shell-experience.sh|Shell upgrades (zsh, starship, fzf)|server,desktop|no"
)

# mod_field ENTRY N — extract the Nth pipe-delimited field (1-based) from a
# module registry string. Pure Bash; no subprocess fork.
mod_field() {
  local _entry="$1" _n="$2" _f1 _f2 _f3 _f4
  # Split on '|' using a temporary IFS — avoids cut(1) subprocess.
  IFS='|' read -r _f1 _f2 _f3 _f4 <<<"$_entry"
  case "$_n" in
    1) printf '%s' "$_f1" ;;
    2) printf '%s' "$_f2" ;;
    3) printf '%s' "$_f3" ;;
    4) printf '%s' "$_f4" ;;
  esac
}

print_banner() {
  printf '%s' "$C_CYAN"
  cat <<'BANNER'
   _   _ _                 _              ____       _
  | | | | |__  _   _ _ __ | |_ _   _    / ___|  ___| |_ _   _ _ __
  | | | | '_ \| | | | '_ \| __| | | |   \___ \ / _ \ __| | | | '_ \
  | |_| | |_) | |_| | | | | |_| |_| |    ___) |  __/ |_| |_| | |_) |
   \___/|_.__/ \__,_|_| |_|\__|\__,_|   |____/ \___|\__|\__,_| .__/
                                                             |_|
BANNER
  printf '%s' "$C_RESET"
  printf '  %sFriendly, safe post-install setup for Ubuntu%s\n\n' "$C_GRAY" "$C_RESET"
}

usage() {
  cat <<EOF
Usage: ./setup.sh [options]

Options:
  -h, --help        Show this help and exit.
  -l, --list        List available modules and exit.
  -n, --dry-run     Preview all actions without changing anything.
  -y, --yes         Run unattended, accepting recommended defaults.
      --only LIST   Run only these modules (comma-separated numbers or names),
                    e.g. --only 01,03,05  or  --only docker,swap
      --profile P   Run a preset: 'server', 'desktop', or 'all'.

Examples:
  ./setup.sh                     Interactive menu (recommended for first use).
  ./setup.sh --dry-run           See exactly what it would do.
  ./setup.sh --profile server -y Set up a server unattended.
EOF
}

list_modules() {
  step "Available modules"
  local i=1 entry file desc envs rec tag
  for entry in "${MODULES[@]}"; do
    # Split the entry once — avoids four separate mod_field / cut calls.
    IFS='|' read -r file desc envs rec <<<"$entry"
    tag="" ; [[ "$rec" == "yes" ]] && tag="${C_GREEN}[recommended]${C_RESET}"
    printf '  %s%2d%s) %-36s %s(%s)%s %b\n' \
      "$C_BOLD" "$i" "$C_RESET" "$desc" "$C_GRAY" "$envs" "$C_RESET" "$tag"
    i=$((i+1))
  done
}

# run_module FILE — execute one module as its own process, inheriting env.
run_module() {
  local file="$1"
  local path="$MODULES_DIR/$file"
  [[ -f "$path" ]] || { error "Module not found: $file"; return 1; }
  chmod +x "$path" 2>/dev/null || true
  if bash "$path"; then
    return 0
  else
    local rc=$?
    error "Module '$file' exited with status $rc."
    return $rc
  fi
}

# run_selected — run a list of module files, tracking successes/failures.
run_selected() {
  local files=("$@")
  local ok=0 fail=0 file
  for file in "${files[@]}"; do
    echo
    printf '%s────────────────────────────────────────────────────────%s\n' "$C_GRAY" "$C_RESET"
    if run_module "$file"; then
      ok=$((ok+1))
    else
      fail=$((fail+1))
      if [[ "$ASSUME_YES" != "true" ]]; then
        ask_yes_no "A step failed. Continue with the remaining steps?" "yes" || break
      fi
    fi
  done
  echo
  step "Done"
  success "Completed: $ok"
  [[ "$fail" -gt 0 ]] && warn "Failed: $fail"
  hint "Full log saved to: $LOG_FILE"
  if [[ -f /var/run/reboot-required ]]; then
    warn "A reboot is recommended to finish applying some changes."
  fi
}

# resolve_only — turn "01,docker,swap" into matching module filenames.
resolve_only() {
  local spec="$1" token entry file desc envs rec out=()
  IFS=',' read -ra tokens <<<"$spec"
  for token in "${tokens[@]}"; do
    # Trim leading/trailing whitespace with pure Bash parameter expansion —
    # avoids the echo "$token" | xargs subshell pipeline.
    token="${token#"${token%%[![:space:]]*}"}"
    token="${token%"${token##*[![:space:]]}"}"
    for entry in "${MODULES[@]}"; do
      # Split entry once instead of calling mod_field (cut) per field.
      IFS='|' read -r file desc envs rec <<<"$entry"
      if [[ "$file" == "$token"* || "$file" == *"$token"* ]]; then
        out+=("$file"); break
      fi
    done
  done
  printf '%s\n' "${out[@]}"
}

# profile_files PROFILE — list module files for a preset profile.
profile_files() {
  local profile="$1" entry file desc envs rec out=()
  for entry in "${MODULES[@]}"; do
    # Split the entry once — avoids three separate mod_field / cut calls.
    IFS='|' read -r file desc envs rec <<<"$entry"
    case "$profile" in
      all) out+=("$file") ;;
      server)  [[ "$rec" == "yes" && "$envs" == *server*  ]] && out+=("$file") ;;
      desktop) [[ "$rec" == "yes" && "$envs" == *desktop* ]] && out+=("$file") ;;
    esac
  done
  printf '%s\n' "${out[@]}"
}

# interactive_menu — the friendly default experience.
interactive_menu() {
  while true; do
    echo
    step "What would you like to do?"
    cat <<EOF
  ${C_BOLD}1${C_RESET}) Recommended setup for a ${C_CYAN}SERVER${C_RESET}   (safe, sensible defaults)
  ${C_BOLD}2${C_RESET}) Recommended setup for a ${C_CYAN}DESKTOP${C_RESET}  (safe, sensible defaults)
  ${C_BOLD}3${C_RESET}) ${C_CYAN}Custom${C_RESET} — pick exactly which steps to run
  ${C_BOLD}4${C_RESET}) List all modules
  ${C_BOLD}5${C_RESET}) Toggle ${C_CYAN}dry-run${C_RESET} (currently: ${DRY_RUN})
  ${C_BOLD}q${C_RESET}) Quit
EOF
    local choice
    choice="$(ask_value "Choose" "1")"
    case "$choice" in
      1) mapfile -t files < <(profile_files server)
         confirm_and_run "${files[@]}"; break ;;
      2) mapfile -t files < <(profile_files desktop)
         confirm_and_run "${files[@]}"; break ;;
      3) custom_select; break ;;
      4) list_modules ;;
      5) [[ "$DRY_RUN" == "true" ]] && export DRY_RUN=false || export DRY_RUN=true
         info "Dry-run is now: $DRY_RUN" ;;
      q|Q) info "Bye!"; exit 0 ;;
      *) warn "Please choose 1-5 or q." ;;
    esac
  done
}

confirm_and_run() {
  local files=("$@")
  [[ "${#files[@]}" -eq 0 ]] && { warn "Nothing selected."; return; }
  echo
  info "These steps will run, in order:"
  local f
  for f in "${files[@]}"; do
    local desc; desc="$(get_desc "$f")"
    printf '   • %s\n' "$desc"
  done
  [[ "$DRY_RUN" == "true" ]] && hint "DRY RUN: nothing will actually change."
  echo
  if ask_yes_no "Proceed?" "yes"; then
    run_selected "${files[@]}"
  else
    info "Cancelled."
  fi
}

get_desc() {
  local file="$1" entry _file _desc _envs _rec
  for entry in "${MODULES[@]}"; do
    # Split entry once; avoids two separate mod_field / cut calls per check.
    IFS='|' read -r _file _desc _envs _rec <<<"$entry"
    if [[ "$_file" == "$file" ]]; then
      printf '%s' "$_desc"
      return
    fi
  done
  printf '%s' "$file"
}

custom_select() {
  list_modules
  echo
  hint "Enter numbers separated by spaces or commas (e.g. 1 3 5), or 'all'."
  local raw; raw="$(ask_value "Which steps?" "")"
  local files=()
  if [[ "$raw" == "all" ]]; then
    mapfile -t files < <(profile_files all)
  else
    raw="${raw//,/ }"
    local n
    for n in $raw; do
      if [[ "$n" =~ ^[0-9]+$ ]] && (( n >= 1 && n <= ${#MODULES[@]} )); then
        # Extract just field 1 (filename) with pure Bash — avoids cut subprocess.
        local _sel_file _rest
        IFS='|' read -r _sel_file _rest <<<"${MODULES[$((n-1))]}"
        files+=("$_sel_file")
      else
        warn "Ignoring invalid choice: '$n'"
      fi
    done
  fi
  confirm_and_run "${files[@]}"
}

# ----------------------------------------------------------------------------
# Argument parsing.
# ----------------------------------------------------------------------------
ONLY="" ; PROFILE=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)    print_banner; usage; exit 0 ;;
    -l|--list)    list_modules; exit 0 ;;
    -n|--dry-run) export DRY_RUN="true" ;;
    -y|--yes)     export ASSUME_YES="true" ;;
    --only)       ONLY="${2:-}"; shift ;;
    --only=*)     ONLY="${1#*=}" ;;
    --profile)    PROFILE="${2:-}"; shift ;;
    --profile=*)  PROFILE="${1#*=}" ;;
    *) error "Unknown option: $1"; usage; exit 1 ;;
  esac
  shift
done

# ----------------------------------------------------------------------------
# Main.
# ----------------------------------------------------------------------------
print_banner

# Don't allow running the whole thing as root by accident on desktops: it's
# fine on a root-only fresh server, but warn so files don't end up root-owned.
if [[ "$(id -u)" -eq 0 && -n "${SUDO_USER:-}" ]]; then
  warn "You ran this with sudo. That's okay, but prefer running it as your normal"
  warn "user — the script asks for sudo only when needed."
fi

preflight

if [[ -n "$PROFILE" ]]; then
  case "$PROFILE" in
    server|desktop|all) ;;
    *) die "Unknown profile '$PROFILE'. Use: server, desktop, or all." ;;
  esac
  mapfile -t files < <(profile_files "$PROFILE")
  confirm_and_run "${files[@]}"
  exit 0
fi

if [[ -n "$ONLY" ]]; then
  mapfile -t files < <(resolve_only "$ONLY")
  [[ "${#files[@]}" -eq 0 ]] && die "No modules matched '--only $ONLY'. Try --list."
  confirm_and_run "${files[@]}"
  exit 0
fi

# No flags that pick work for us → friendly interactive menu.
interactive_menu
