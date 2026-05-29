# How ubuntu-setup compares

There's no single "best" way to set up a server — it depends on how many
machines you manage, how repeatable it needs to be, and how comfortable you are
on the command line. This page is an honest look at where **ubuntu-setup** fits,
and when you should reach for something else instead.

**Short version:** ubuntu-setup is for getting *one or a few* fresh Ubuntu boxes
secure and usable quickly, safely, and without deep tooling. If you're managing a
fleet or need declarative, version-controlled infrastructure, a configuration
manager like Ansible is the better long-term home.

---

## At a glance

| | **Doing it manually** | **ubuntu-setup** | **Ansible** | **cloud-init** |
|---|---|---|---|---|
| What it is | You + the docs | Interactive Bash script | Config-management tool | First-boot provisioning |
| Setup cost | None | Clone & run | Install + learn YAML/inventory | Write user-data; provider support |
| Learning curve | High (you need the knowledge) | Very low — explains each step | Moderate–high | Moderate |
| Preview before changes | Manual | **Yes — `--dry-run`** | `--check` (varies by module) | No (runs at boot) |
| Explains *why* each step matters | No | **Yes, in plain language** | No | No |
| Lock-out safeguards (SSH/UFW) | You must remember them | **Built in** | You must script them | You must script them |
| Config backups before edits | Manual | **Yes, timestamped** | Manual / via modules | No |
| Idempotent | Depends on you | **Yes** | **Yes** | Runs once at first boot |
| Repeatable across many hosts | Tedious | OK (`--profile --yes`) | **Excellent** | **Excellent (at provision time)** |
| Best for | Learning, one-offs | 1–few fresh Ubuntu boxes | Fleets, ongoing config | Provisioning new instances |

---

## ubuntu-setup vs. doing it manually

**Pick manual when** you're learning and want to internalize every command, or
your setup is so unusual that no script's defaults fit.

**Pick ubuntu-setup when** you know roughly what you want but don't want to
re-derive it from blog posts each time — and you'd rather not risk a typo that
locks you out of a remote box. It still *shows* you each command (and `--dry-run`
prints all of them), so you keep learning while saving time. Every config it
touches is backed up first.

---

## ubuntu-setup vs. Ansible

Ansible is a mature, declarative configuration manager built for managing many
machines over time from version-controlled playbooks.

**Pick Ansible when** you manage a fleet, need an auditable desired-state
definition in git, want to re-apply config continuously, or already have an
Ansible workflow. It scales far beyond what a single Bash script should.

**Pick ubuntu-setup when** you have one or a handful of fresh boxes and don't
want to stand up inventories, playbooks, and YAML for a one-time bootstrap. It's
runnable in under a minute with nothing to install beyond Bash.

**They're complementary.** ubuntu-setup is automatable
(`./setup.sh --profile server --yes`, `--only docker,swap`), so you can call it
from an Ansible task or a provisioning step to handle the initial hardening, then
let Ansible own ongoing state.

---

## ubuntu-setup vs. cloud-init

cloud-init runs once at first boot to configure a new cloud instance from
user-data your provider passes in.

**Pick cloud-init when** you're spinning up instances programmatically and want
baseline config baked into provisioning. It's the right layer for "every new VM
should start like this."

**Pick ubuntu-setup when** you're working on an already-running machine, want an
interactive/explained experience, or want to preview and confirm changes rather
than apply them blind at boot. It also works on **desktops**, which cloud-init
generally doesn't target.

**They're complementary.** Because ubuntu-setup supports `--yes` and
`--profile`, you can invoke it from a cloud-init `runcmd` to do the heavier
hardening while keeping its safety guards.

---

## Honest limitations of ubuntu-setup

- It's a **Bash script**, not a declarative system — it bootstraps a box well,
  but it isn't a substitute for ongoing fleet management.
- It targets **Ubuntu 22.04 / 24.04 LTS** (amd64/arm64) and is best-effort on
  Debian and Ubuntu-based distros.
- Its value is **opinionated, safe defaults**; very bespoke setups may still need
  manual tweaks or a dedicated config manager.
- It does not manage application deployment or long-lived state — pair it with
  Docker/Compose, Ansible, or your tool of choice for that.

When ubuntu-setup is the right tool, it's the fastest *safe* path from a fresh
Ubuntu install to a secured, usable machine. When it isn't, the tools above are
genuinely better — use them.
