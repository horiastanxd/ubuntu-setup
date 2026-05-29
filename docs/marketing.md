# Launch & Growth Playbook

Ready-to-post copy and a launch-day checklist for **ubuntu-setup**. Everything
below is written to be honest, non-spammy, and accurate to what the script
actually does. Swap `<your-username>` for your real handle before posting.

**The one hook to lead with:**
> Set up a fresh Ubuntu box — firewall, Fail2ban, SSH hardening, auto-updates,
> Docker — from one friendly menu that explains every step and won't lock you
> out. Preview everything with `--dry-run` first. Open source, MIT.

---

## GitHub "About" + social preview

**Repository "About" description (short):**
> Friendly, safe, interactive Bash script to set up & harden a fresh Ubuntu
> Server or Desktop. Dry-run, confirmations, backups, no lock-outs. MIT.

**Topics / tags:**
`ubuntu` `bash` `server-setup` `hardening` `ufw` `fail2ban` `ssh` `docker`
`unattended-upgrades` `devops` `cli` `self-hosted`

**Social-preview text (for the repo's social image / Open Graph caption):**
> ubuntu-setup — one menu to install and secure a fresh Ubuntu box. Safe by
> default: dry-run, confirmations, config backups, and SSH lock-out protection.

---

## Hacker News — Show HN

**Title** (keep it factual; HN dislikes hype):
> Show HN: ubuntu-setup – a safe, friendly Bash script to set up and harden Ubuntu

**Body:**
> I kept re-reading the same blog posts every time I provisioned a new Ubuntu
> box — turn on UFW, install Fail2ban, harden SSH, enable unattended security
> updates, add swap, install Docker. So I put it all behind one interactive menu
> that explains *what* each step does, *why* it matters, and the *risk* before it
> touches anything.
>
> The thing I cared most about is not locking myself out of a remote server:
> - `--dry-run` prints every command instead of running it, so you can preview
>   the whole run first.
> - The firewall module detects your live SSH port and allows it *before*
>   enabling UFW.
> - The SSH module checks for working keys before disabling password login, and
>   runs `sshd -t` before restarting.
> - Every edited config is backed up (timestamped) first, and it's idempotent.
>
> It's also automatable: `--yes`, `--profile server|desktop|all`, and
> `--only docker,swap` for cloud-init / Ansible / CI. Each task is a small,
> separate script in `modules/` you can audit in a few seconds or run on its own.
>
> Targets Ubuntu 22.04 / 24.04 LTS on amd64 and arm64. MIT licensed. I'd love
> feedback on the safety model and on which modules to add next.
>
> Repo: https://github.com/<your-username>/ubuntu-setup

**Tips:** Post around 8–10am ET on a weekday. Reply to every comment. Don't ask
for upvotes (it's against the rules and easy to spot). Be upfront about
limitations when asked.

---

## Reddit

> **Read each subreddit's rules first.** Self-promotion norms vary a lot.
> The golden ratio: be a participant, not just a promoter. If your account is
> new or low-karma, comment around the sub for a while before posting a project.

### r/linux
Strict on self-promotion — projects are generally fine if you're the author,
you disclose it, and it's genuinely useful (no affiliate/marketing spam). Flair
the post appropriately.

**Title:**
> I made an open-source Bash script that sets up and hardens a fresh Ubuntu box from one menu (dry-run, no lock-outs)

**Body:**
> I'm the author. It's an interactive script that handles the usual fresh-install
> chores — UFW firewall, Fail2ban, SSH hardening, unattended security updates,
> swap, timezone/NTP, Docker, dev tools, desktop codecs/Flatpak, cleanup — and
> explains each step in plain language.
>
> The focus is safety: `--dry-run` to preview everything, confirmations on
> anything that changes the system, timestamped config backups, and specific
> guards so the firewall/SSH steps don't lock you out of a remote server. Each
> task is a small standalone script you can read and audit.
>
> MIT licensed, runs on 22.04/24.04 (amd64 + arm64). Feedback and PRs welcome.
> Repo: https://github.com/<your-username>/ubuntu-setup

### r/ubuntu
Friendly to Ubuntu-specific tooling. Same disclose-you're-the-author rule.

**Title:**
> Fresh Ubuntu post-install checklist, but as one friendly script you can dry-run first

**Body:**
> After a clean install I always do the same things, so I scripted them with a
> menu that explains each step. Server profile covers firewall, Fail2ban, SSH
> hardening, auto security updates, swap, and a non-root sudo user; desktop
> profile adds codecs, archive support, and Flatpak/Flathub. Everything is
> opt-in with confirmations, and `--dry-run` shows exactly what it would do
> without changing anything. Open source (MIT). Would love to hear what you'd
> add to the defaults. https://github.com/<your-username>/ubuntu-setup

### r/selfhosted
Loves homelab/server provisioning tools. Lead with the self-hosting angle.

**Title:**
> A safe, beginner-friendly script to bootstrap and harden a new self-hosted Ubuntu server

**Body:**
> When spinning up a new box for self-hosting, I wanted one repeatable, safe way
> to get UFW, Fail2ban, SSH hardening, unattended security updates, swap, and
> Docker in place — without the classic "locked myself out over SSH" moment.
>
> So it detects your live SSH port and allows it before enabling the firewall,
> checks for working SSH keys before disabling passwords, validates the SSH
> config before restarting, and backs up every file it edits. `--dry-run` lets
> you preview the entire run. It's also scriptable for cloud-init/Ansible with
> `--profile server --yes`. MIT, idempotent, each module auditable on its own.
> https://github.com/<your-username>/ubuntu-setup

---

## Twitter / X

> New open-source release: **ubuntu-setup** 🐧
>
> One friendly menu to set up & harden a fresh Ubuntu box — UFW, Fail2ban, SSH
> hardening, auto-updates, Docker — that explains every step and won't lock you
> out. Preview it all with `--dry-run`. MIT.
>
> 👉 github.com/<your-username>/ubuntu-setup

## Mastodon

> Just released **ubuntu-setup** — a safe, beginner-friendly Bash script that
> sets up and hardens a fresh Ubuntu Server or Desktop from one interactive menu.
>
> Safe by default: `--dry-run` preview, confirmations, timestamped config
> backups, and SSH/firewall lock-out protection. Idempotent and automatable.
>
> Open source, MIT. Feedback & PRs welcome 🐧
> https://github.com/<your-username>/ubuntu-setup
>
> #Ubuntu #Linux #SelfHosted #OpenSource #DevOps #Bash

## LinkedIn

> I open-sourced a small tool I kept needing: **ubuntu-setup**.
>
> Every time I provision a fresh Ubuntu server or desktop, I run through the same
> checklist — firewall, Fail2ban, SSH hardening, automatic security updates,
> swap, Docker, dev tools. ubuntu-setup puts all of that behind one interactive
> menu that explains each step in plain language, so it's approachable for people
> who aren't full-time sysadmins.
>
> What I'm most proud of is the safety model: a `--dry-run` mode that previews
> everything, confirmations before any change, automatic config backups, and
> specific safeguards so the SSH and firewall steps don't lock you out of a
> remote machine. It's also automatable (`--profile server --yes`) for
> cloud-init, Ansible, or CI.
>
> MIT licensed and open to contributions. If you manage Ubuntu boxes, I'd love
> your feedback. 🔗 https://github.com/<your-username>/ubuntu-setup
>
> #Linux #Ubuntu #DevOps #OpenSource #Security

---

## Dev.to article outline

**Working title:** "Setting up a fresh Ubuntu server safely — without locking
yourself out"

**Suggested tags:** `ubuntu`, `linux`, `devops`, `opensource`

1. **The problem.** The "new box, same 12 blog posts" ritual, and the fear of
   bricking SSH access on a remote server.
2. **The checklist.** What actually matters on a fresh box: updates, firewall,
   Fail2ban, SSH hardening, auto security updates, swap, time sync, a non-root
   user, Docker.
3. **Why a menu, not a one-liner.** Argument against `curl | bash`; the value of
   reading code and confirming each step. Plain-language explanations for
   non-experts.
4. **The safety model (the core of the piece).** Dry-run; confirmations;
   timestamped backups; idempotency; and the concrete lock-out guards
   (firewall detects the live SSH port before enabling; SSH module checks for
   keys and validates `sshd -t` before restart).
5. **Automating it.** `--profile server --yes`, `--only`, and how it fits
   cloud-init / Ansible / CI.
6. **Walkthrough.** A short dry-run transcript, then a real run with screenshots.
7. **Extending it.** How modules are structured and how to add your own.
8. **Call to action.** Link the repo, invite issues/PRs, ask what to add next.

---

## Launch-day checklist

- [ ] Repo is public; README renders with the banner (`assets/banner.svg`).
- [ ] Set the GitHub **About** description, website, and **Topics** (above).
- [ ] Upload a **social preview image** (Settings → General → Social preview).
- [ ] Enable **Discussions** and update the placeholder URLs in
      `.github/ISSUE_TEMPLATE/config.yml` and this file.
- [ ] Tag and publish the **v1.0.0 release** with notes from `CHANGELOG.md`.
- [ ] Verify `./setup.sh --dry-run` runs clean and `--list` works.
- [ ] Confirm LICENSE (MIT), CONTRIBUTING, CODE_OF_CONDUCT, SECURITY are present.
- [ ] Replace every `<your-username>` placeholder across the repo and this doc.
- [ ] Post **Show HN** in the morning (ET); stay available to reply all day.
- [ ] Post to **r/ubuntu**, **r/selfhosted**, then **r/linux** — spaced out, each
      tailored, each disclosing you're the author.
- [ ] Publish the **Dev.to** article; cross-link it from the README.
- [ ] Share on **Mastodon**, **X**, and **LinkedIn**.
- [ ] Respond to every comment, issue, and PR within the first 48 hours.
- [ ] Pin a "Roadmap / what should we add next?" Discussion thread.
