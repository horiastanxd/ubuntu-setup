# ubuntu-setup — Ubuntu Server & Desktop Setup Script (Initial Setup, Security Hardening, Post-Install)

> A friendly, safe, interactive **Bash setup script for Ubuntu** that handles **initial server setup** and **post-install configuration** for you: firewall (UFW), Fail2ban, SSH hardening, automatic security updates, swap, Docker, dev tools, and desktop apps — beginner-friendly, safe by default, idempotent, and fully automatable.

<p align="center">
  <a href="#-quick-start"><img alt="Made with Bash badge" src="https://img.shields.io/badge/Made%20with-Bash-1f425f.svg"></a>
  <a href="LICENSE"><img alt="License: MIT badge" src="https://img.shields.io/badge/License-MIT-green.svg"></a>
  <img alt="Supports Ubuntu 22.04 and 24.04 LTS badge" src="https://img.shields.io/badge/Ubuntu-22.04%20%7C%2024.04-E95420?logo=ubuntu&logoColor=white">
  <img alt="Pull requests welcome badge" src="https://img.shields.io/badge/PRs-welcome-brightgreen.svg">
</p>

**What should you do after installing Ubuntu?** Usually it means hunting through a dozen blog posts to remember how to turn on a firewall, harden SSH, enable automatic security updates, add swap, and install Docker. **ubuntu-setup** does all of that from one friendly menu — whether you're securing a fresh **Ubuntu Server** (VPS, cloud instance, or bare metal) or finishing the setup of **Ubuntu Desktop** — and it **explains every step in plain language**, so you don't need to be a sysadmin to use it safely.

## Table of contents

- [Why you'll like it](#-why-youll-like-it)
- [Quick start](#-quick-start)
- [What it can set up (modules)](#-what-it-can-set-up-modules)
- [Command-line options (automation)](#️-command-line-options-for-power-users--automation)
- [Safety: how it protects you from SSH lock-outs](#-safety--how-it-protects-you-from-ssh-lock-outs)
- [Supported Ubuntu versions](#-supported-systems-ubuntu-versions)
- [Project structure](#-project-structure)
- [FAQ](#-faq)
- [Contributing](#-contributing)
- [License](#-license)

```
==> What would you like to do?
  1) Recommended setup for a SERVER   (safe, sensible defaults)
  2) Recommended setup for a DESKTOP  (safe, sensible defaults)
  3) Custom — pick exactly which steps to run
  4) List all modules
  5) Toggle dry-run
  q) Quit
```

---

## ✨ Why you'll like it

- **🧠 Beginner-friendly.** Every prompt explains *what* it does, *why* it matters, and the *risk* — no jargon required.
- **🛡️ Safe by default.** Nothing changes without your confirmation. Built-in **`--dry-run`** lets you preview *everything* first.
- **💾 Backups before edits.** Every config file is backed up (timestamped) before it's touched.
- **♻️ Idempotent.** Run it as many times as you like — it skips what's already done.
- **🤖 Automatable.** Flags like `--yes` and `--profile server` make it perfect for cloud-init, Ansible, or CI.
- **🧩 Modular.** Each task is a small, readable script you can run on its own and audit in seconds.
- **🚫 No lock-outs.** SSH/firewall steps actively protect you from the classic "I locked myself out" mistakes.

---

## 🚀 Quick start

```bash
# 1) Get the code (reviewing before running is always a good idea!)
git clone https://github.com/<your-username>/ubuntu-setup.git
cd ubuntu-setup

# 2) See exactly what it WOULD do — changes nothing:
./setup.sh --dry-run

# 3) Run the friendly interactive menu:
./setup.sh
```

> 💡 **New to the terminal?** Just run `./setup.sh`, pick option **1** (server) or **2** (desktop), and answer the questions. The recommended defaults are safe.

---

## 📦 What it can set up (modules)

| #  | Module | What it does | Server | Desktop |
|----|--------|--------------|:------:|:-------:|
| 01 | System update | Update & upgrade all packages | ✅ | ✅ |
| 02 | Essentials | curl, git, vim, htop, jq, build tools… | ✅ | ✅ |
| 03 | Firewall (UFW) | Deny-by-default firewall, opens only chosen ports | ✅ | ✅ |
| 04 | Fail2ban | Auto-ban brute-force login attempts | ✅ | — |
| 05 | SSH hardening | Keys over passwords, no root login, safe defaults | ✅ | — |
| 06 | Auto updates | Unattended **security** updates | ✅ | ✅ |
| 07 | Swap | Create a swap file on low-RAM machines | ✅ | — |
| 08 | Timezone & NTP | Correct timezone + automatic clock sync | ✅ | ✅ |
| 09 | Admin user | Create a non-root `sudo` user (+ copy SSH key) | ✅ | — |
| 10 | Docker | Docker Engine + Compose from the official repo | ✅ | ✅ |
| 11 | Dev tools | Node.js (LTS), Python, tmux, fzf, ripgrep… | ✅ | ✅ |
| 12 | Desktop apps | Codecs, archive support, Flatpak/Flathub, Tweaks | — | ✅ |
| 13 | Cleanup | Remove unused packages, trim logs, free disk | ✅ | ✅ |
| 14 | Backups | Scheduled `restic` (encrypted) or `rsync` backups via timer/cron | ✅ | ✅ |
| 15 | Web server | Caddy (automatic HTTPS) or Nginx (+ optional Certbot) | ✅ | — |
| 16 | Tailscale | Mesh VPN for remote access without exposing ports | ✅ | ✅ |
| 17 | Monitoring | Prometheus node_exporter or Netdata (bound to localhost) | ✅ | ✅ |
| 18 | Shell experience | Optional zsh, Starship prompt, fzf, zoxide | ✅ | ✅ |

> Modules 09–18 are **opt-in** (not part of the one-click recommended profiles) — run them from the Custom menu or with `--only`.

---

## 🎛️ Command-line options (for power users & automation)

```text
./setup.sh                       Interactive menu (default)
./setup.sh --dry-run             Preview everything; change nothing
./setup.sh --list                List all modules and exit
./setup.sh --yes                 Unattended; accept recommended defaults
./setup.sh --profile server      Run the recommended SERVER set
./setup.sh --profile desktop     Run the recommended DESKTOP set
./setup.sh --profile all         Offer every module
./setup.sh --only 01,03,05       Run specific modules by number…
./setup.sh --only docker,swap    …or by name
```

**Examples**

```bash
# Provision a server unattended (great for cloud-init / first boot):
./setup.sh --profile server --yes

# Just install Docker, previewing first:
./setup.sh --dry-run --only docker
./setup.sh --only docker
```

Run any module on its own, too:

```bash
sudo ./modules/03-firewall-ufw.sh
```

---

## 🔐 Safety — how it protects you from SSH lock-outs

This script is designed for the real world, where one wrong command can lock you out of a remote server:

- **Dry-run mode** prints every command instead of running it (`--dry-run`).
- **Confirmation prompts** for anything that changes the system; recommended defaults shown in `[Y/n]`.
- **Config backups** are saved to `~/.ubuntu-setup/backups/` before any file is edited.
- **SSH lock-out protection:** the firewall module detects your live SSH port and allows it *before* enabling UFW; the SSH module **checks for working keys before disabling passwords** and validates `sshd -t` before restarting.
- **Full logging** of every action to `/tmp/ubuntu-setup-*.log`.
- **No piping required.** We recommend cloning and reading the code rather than `curl | bash`.

> ⚠️ **Always keep your current SSH session open** until you've confirmed in a *new* terminal that you can still log in after hardening.

---

## ✅ Supported systems (Ubuntu versions)

- **Ubuntu 24.04 LTS (Noble)** and **22.04 LTS (Jammy)** — primary targets.
- Should also work on Debian and Ubuntu-based distros (Mint, Pop!_OS, Zorin) with a warning.
- `amd64` and `arm64`.

---

## 🧱 Project structure

```
ubuntu-setup/
├── setup.sh              # Main interactive entry point
├── lib/
│   ├── common.sh         # Shared helpers: logging, prompts, safe `run`, backups
│   └── checks.sh         # Preflight: OS/arch/server-vs-desktop/internet detection
└── modules/              # One small, auditable script per task
    ├── 01-system-update.sh
    ├── 03-firewall-ufw.sh
    ├── 05-ssh-hardening.sh
    └── … etc.
```

Want to add a step? Drop a script in `modules/`, add one line to the `MODULES=()` registry in `setup.sh`, and you're done. See [CONTRIBUTING.md](CONTRIBUTING.md).

---

## ❓ FAQ

### What should I do after installing Ubuntu?
At minimum: update all packages, turn on a firewall, enable automatic security updates, and (on servers) harden SSH. This script bundles those into the **Recommended setup** option — pick `1` for a server or `2` for a desktop and accept the safe defaults.

### How do I secure a new Ubuntu server?
Run the server profile (`./setup.sh --profile server`). It sets up a deny-by-default **UFW firewall**, **Fail2ban** to ban brute-force login attempts, **SSH hardening** (keys over passwords, no root login), and **unattended security updates**. Each step explains the risk and asks before changing anything.

### Is it safe to run setup scripts from the internet?
You should always review code before running it, which is exactly why this project recommends `git clone` + reading over `curl | bash`. Every change is confirmed by you, config files are backed up before edits, and `--dry-run` prints every command without executing it.

### Will this lock me out of my server over SSH?
It's designed specifically to prevent that. The firewall module detects your live SSH port and **allows it before enabling UFW**; the SSH module **checks for a working key before disabling password login** and validates the config with `sshd -t` before restarting. Still, keep your current session open and confirm login in a new terminal first.

### Does this work on Ubuntu 22.04 and 24.04?
Yes — Ubuntu **24.04 LTS (Noble)** and **22.04 LTS (Jammy)** are the primary targets, on both `amd64` and `arm64`. It also runs on Debian and Ubuntu-based distros (Mint, Pop!_OS, Zorin) with a warning.

### Can I run it unattended for cloud-init or Ansible?
Yes. Use `./setup.sh --profile server --yes` to accept recommended defaults without prompts, or `--only docker,swap` to run specific modules. This makes it easy to drop into cloud-init, Ansible, or CI.

### Can I run just one module, like installing Docker?
Yes. Use `./setup.sh --only docker` (preview with `--dry-run` first), or run the module directly: `sudo ./modules/10-docker.sh`.

### Is it safe to run more than once?
Yes — it's **idempotent**. It detects what's already configured (existing swap, existing firewall rules, installed packages) and skips it, so re-running is harmless.

---

## 🤝 Contributing

Contributions are very welcome — new modules, better explanations, more distros, translations. Please read [CONTRIBUTING.md](CONTRIBUTING.md) and our [Code of Conduct](CODE_OF_CONDUCT.md). Found a security issue? See [SECURITY.md](SECURITY.md).

## 📄 License

[MIT](LICENSE) — free to use, modify, and share. No warranty; review before running on important systems.

---

<sub>Keywords: ubuntu setup script, ubuntu server initial setup, ubuntu post install, what to do after installing ubuntu, ubuntu server hardening, ubuntu security, ufw firewall setup, fail2ban, ssh hardening, unattended-upgrades automatic security updates, swap file, docker install ubuntu, ubuntu desktop after install, ubuntu 22.04 24.04 setup, bash provisioning script, vps initial setup.</sub>
