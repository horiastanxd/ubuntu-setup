# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- (Nothing yet — open a PR or issue to suggest the next module!)

## [1.0.0] - 2026-05-29

Initial public release. A friendly, safe, interactive Bash script that installs
and configures the essential and security settings on a fresh Ubuntu Server or
Ubuntu Desktop — beginner-friendly and fully automatable.

### Added
- **Interactive menu** with recommended SERVER and DESKTOP profiles, a custom
  pick-your-steps mode, a module list, and a dry-run toggle.
- **13 modular tasks**, each a small, auditable script you can run on its own:
  - `01` System update — update & upgrade all packages.
  - `02` Essentials — curl, git, vim, htop, jq, build tools, and more.
  - `03` Firewall (UFW) — deny-by-default firewall; detects your live SSH port
    and allows it *before* enabling, to prevent lock-outs.
  - `04` Fail2ban — auto-ban brute-force login attempts (server).
  - `05` SSH hardening — keys over passwords, no root login, sane defaults;
    checks for working keys and validates `sshd -t` before restarting (server).
  - `06` Automatic updates — unattended **security** updates.
  - `07` Swap — create a swap file on low-RAM machines (server).
  - `08` Timezone & NTP — correct timezone + automatic clock sync.
  - `09` Admin user — create a non-root `sudo` user and copy your SSH key (server).
  - `10` Docker — Docker Engine + Compose from the official repo.
  - `11` Dev tools — Node.js (LTS), Python, tmux, fzf, ripgrep, and more.
  - `12` Desktop apps — codecs, archive support, Flatpak/Flathub, Tweaks (desktop).
  - `13` Cleanup — remove unused packages, trim logs, free disk.
- **Safety-first design:**
  - `--dry-run` mode that prints every command instead of running it.
  - Confirmation prompts for anything that changes the system, with safe
    recommended defaults.
  - Timestamped config backups saved to `~/.ubuntu-setup/backups/` before any
    file is edited.
  - SSH lock-out protection across the firewall and SSH modules.
  - Full logging of every action to `/tmp/ubuntu-setup-*.log`.
- **Idempotent** runs — re-run any time; it skips what's already done.
- **Automation flags:** `--yes`, `--list`, `--profile server|desktop|all`, and
  `--only <modules>` (by number or name) for cloud-init, Ansible, or CI.
- **Supported systems:** Ubuntu 24.04 LTS (Noble) and 22.04 LTS (Jammy) on
  `amd64` and `arm64`; best-effort support for Debian and Ubuntu-based distros.
- **Project docs:** README, CONTRIBUTING, CODE_OF_CONDUCT, SECURITY, MIT LICENSE,
  and GitHub issue/PR templates.

[Unreleased]: https://github.com/<your-username>/ubuntu-setup/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/<your-username>/ubuntu-setup/releases/tag/v1.0.0
