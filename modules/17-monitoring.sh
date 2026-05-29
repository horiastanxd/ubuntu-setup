#!/usr/bin/env bash
# ============================================================================
# 17 — Lightweight system monitoring
# WHAT: Installs a way to see how your machine is doing (CPU, memory, disk,
#       network). Choose Netdata (rich real-time dashboard) or the minimal
#       Prometheus node_exporter (metrics endpoint for an existing setup).
# WHY:  Monitoring tells you when a disk is filling up, RAM is exhausted, or a
#       service is misbehaving — ideally BEFORE it takes the machine down.
# RISK: Low-medium. A monitoring dashboard can leak system details if exposed
#       to the internet. We default to binding to localhost only and explain
#       how to view it safely (e.g. via an SSH tunnel or Tailscale).
# ============================================================================
set -euo pipefail
MODULE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$MODULE_DIR/.." && pwd)"
# shellcheck source=/dev/null
source "$REPO_ROOT/lib/common.sh"
# shellcheck source=/dev/null
source "$REPO_ROOT/lib/checks.sh"
ensure_sudo

step "Set up lightweight system monitoring"
hint "node_exporter: tiny, from Ubuntu's repos. Just exposes metrics for an"
hint "               existing Prometheus/Grafana. Simplest and safest default."
hint "netdata:       a full real-time dashboard in your browser. Richer, but"
hint "               you must keep it private (don't expose it to the internet)."

if ! ask_yes_no "Set up monitoring now?" "yes"; then
  info "Skipped monitoring."
  exit 0
fi

# Default to the simpler/safer option (node_exporter).
CHOICE="node_exporter"
if ask_yes_no "Install the full Netdata dashboard instead of minimal node_exporter?" "no"; then
  CHOICE="netdata"
fi

if [[ "$CHOICE" == "node_exporter" ]]; then
  # ------------------------------------------------------ node_exporter -----
  # prometheus-node-exporter is packaged in Ubuntu's official repositories.
  apt_install prometheus-node-exporter
  run $SUDO systemctl enable --now prometheus-node-exporter
  success "Prometheus node_exporter installed and running."
  echo
  hint "It exposes metrics on port 9100 (http://localhost:9100/metrics)."
  hint "Point your Prometheus server at this host:9100 to scrape it."
  warn "Port 9100 should NOT be open to the public internet. Keep it on a"
  warn "private network (e.g. Tailscale) or behind your firewall."

  if command_exists ufw && $SUDO ufw status 2>/dev/null | grep -q "Status: active"; then
    warn "UFW is active. Port 9100 is left CLOSED by default (recommended)."
    hint "If your Prometheus runs elsewhere on a trusted network, allow it with:"
    hint "    sudo ufw allow from <prometheus-ip> to any port 9100 proto tcp"
  fi

else
  # ---------------------------------------------------------------- netdata --
  echo
  hint "Netdata will be installed via its official kickstart script and, by"
  hint "default here, configured to listen on localhost only for safety."

  if ! ask_yes_no "Download and run Netdata's official installer?" "yes"; then
    info "Skipped Netdata."
    exit 0
  fi

  apt_install curl ca-certificates

  # Official Netdata kickstart. --stable-channel for predictable releases,
  # --disable-telemetry to avoid anonymous stats, --non-interactive for scripts.
  KICKSTART_CMD="curl -fsSL https://get.netdata.cloud/kickstart.sh | $SUDO sh -s -- --stable-channel --disable-telemetry --non-interactive"
  if [[ "$DRY_RUN" == "true" ]]; then
    printf '%s[dry-run]%s would run: %s\n' "$C_GRAY" "$C_RESET" "$KICKSTART_CMD"
  else
    run "$KICKSTART_CMD"
  fi

  # Bind Netdata to localhost only, via a drop-in config (backed up if present).
  NETDATA_CONF_DIR="/etc/netdata"
  BIND_CONF="$NETDATA_CONF_DIR/netdata.conf"
  if [[ "$DRY_RUN" == "true" ]]; then
    printf '%s[dry-run]%s would set Netdata to bind to 127.0.0.1 in %s\n' \
      "$C_GRAY" "$C_RESET" "$BIND_CONF"
  else
    $SUDO mkdir -p "$NETDATA_CONF_DIR"
    backup_file "$BIND_CONF"
    printf '%s\n' "[web]" "    bind to = 127.0.0.1" | $SUDO tee "$BIND_CONF" >/dev/null
    $SUDO systemctl restart netdata 2>/dev/null || true
  fi

  success "Netdata installed and bound to localhost (127.0.0.1:19999)."
  echo
  warn "Netdata is NOT exposed to the network. To view the dashboard safely from"
  warn "your laptop, open an SSH tunnel, then browse to http://localhost:19999 :"
  hint "    ssh -L 19999:localhost:19999 user@this-server"
  hint "Or reach it over Tailscale. Do NOT open port 19999 to the public internet."
fi

echo
success "Monitoring configured."
