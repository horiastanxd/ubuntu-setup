# New modules — registry entries

These modules were added to `modules/`. To make `setup.sh` aware of them, append
the matching lines below to the `MODULES=()` array in `setup.sh`, keeping the
existing format: `"filename|description|profiles|recommended-default"`.

- 3rd field (`profiles`): comma-separated `server` and/or `desktop`.
- 4th field (`recommended-default`): `yes` only if it belongs in the default
  recommended profile. All five new modules are optional, so they use `no`.

## Registry lines (append to MODULES=())

```bash
"14-backups.sh|Scheduled encrypted (restic) or rsync backups via systemd timer/cron|server,desktop|no"
"15-web-server.sh|Install a web server: Caddy (auto-HTTPS) or Nginx (+ optional Certbot)|server|no"
"16-tailscale.sh|Tailscale mesh VPN for secure remote access without exposing ports|server,desktop|no"
"17-monitoring.sh|Lightweight monitoring: Prometheus node_exporter or Netdata (localhost)|server,desktop|no"
"18-shell-experience.sh|Optional shell upgrades: zsh, starship, fzf, zoxide|server,desktop|no"
```

## Notes per module

- **14-backups.sh** — `server,desktop`. Broadly useful everywhere. Optional
  (`no`) because it needs the user to pick source/destination folders
  interactively; not safe to run unattended in a default profile. Never deletes
  source data; restic password is generated and the user is warned to save it.

- **15-web-server.sh** — **server-only**. Serving websites/reverse-proxying is a
  server task; not appropriate to push onto desktops by default. Optional
  (`no`). Only opens firewall ports if UFW is already active.

- **16-tailscale.sh** — `server,desktop`. Valuable on both (remote access from a
  laptop, secure admin of a server). Optional (`no`) because joining a tailnet
  requires interactive browser sign-in.

- **17-monitoring.sh** — `server,desktop`. Useful on both, though most valuable
  on servers. Optional (`no`). Defaults to the safer/simpler node_exporter and
  binds Netdata to localhost only.

- **18-shell-experience.sh** — `server,desktop`. Quality-of-life for desktops
  and dev servers alike. Optional (`no`) — purely a preference; never changes
  the default shell without explicit confirmation.
