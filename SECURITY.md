# Security Policy

## Reporting a vulnerability

If you find a security problem in this project, please report it **privately**:

- Use GitHub's **"Report a vulnerability"** (Security → Advisories) on the repo, or
- Open a minimal issue asking maintainers to contact you (don't post exploit details publicly).

Please include:
- What the issue is and the potential impact.
- Steps to reproduce (Ubuntu version, command, expected vs. actual).
- Any suggested fix.

We aim to acknowledge reports within a few days.

## Scope & expectations

`ubuntu-setup` changes system configuration (firewall, SSH, users, packages).
Because of that:

- **Review the code before running it on important systems.** It's short and
  commented for exactly this reason.
- Use `--dry-run` to preview every action.
- The script is provided under the MIT License **without warranty**. You are
  responsible for what you run on your machines.

## What we consider a security bug

- A module that can **lock a user out** of a remote machine under normal use.
- A change applied **without confirmation** (outside of `--yes`).
- Downloading or executing code from a **non-official / unverifiable** source.
- A config file edited **without a backup**.
- Leaking secrets (passwords, keys) to logs or world-readable files.
