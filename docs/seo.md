# SEO & Discoverability Playbook

A practical guide to making **ubuntu-setup** easy to find on GitHub search and Google. Everything here is tailored to this repo and cross-checked against the actual scripts.

---

## 1. GitHub repository description (the "About" one-liner)

Set this in the repo's **About** panel (gear icon, top-right of the repo page). Keep it under 350 characters, keyword-rich but readable.

**Recommended:**

> Friendly, safe, interactive Bash script for Ubuntu Server & Desktop initial setup and post-install hardening — UFW firewall, Fail2ban, SSH hardening, automatic security updates, swap, Docker, and dev tools. Beginner-friendly, dry-run, idempotent. Works on Ubuntu 22.04 & 24.04 LTS.

**Shorter alternative (if you prefer):**

> Safe, interactive Ubuntu setup script: firewall, SSH hardening, auto security updates, swap, Docker & more. Beginner-friendly, dry-run, idempotent. Ubuntu 22.04/24.04.

Why it works: leads with the two highest-value phrases ("Ubuntu setup", "initial setup / post-install hardening"), names the concrete features people search for, and signals trust ("safe", "dry-run", "idempotent").

---

## 2. GitHub topics

Add these in **About → Topics**. Topics must be lowercase and hyphenated. GitHub allows up to 20; this list is ~18 high-signal terms.

```
ubuntu
ubuntu-server
ubuntu-setup
bash
shell-script
server-setup
initial-server-setup
post-install
security-hardening
ssh-hardening
ufw
firewall
fail2ban
unattended-upgrades
docker
devops
sysadmin
provisioning
```

Optional swaps if you want to test others: `vps`, `cloud-init`, `linux`, `automation`, `self-hosted`.

Pick the topics that most match real searches; `ubuntu`, `ubuntu-server`, `security-hardening`, and `bash` carry the most traffic.

---

## 3. "About" website field

The repo's **Website** field (next to the description). Options, in priority order:

1. Link to the rendered docs / FAQ section: `https://github.com/<your-username>/ubuntu-setup#-faq`
2. If you add a project page (GitHub Pages) later, use that.
3. Otherwise leave blank — do not point it at an unrelated URL.

---

## 4. Keyword map

Where each term should live so it reinforces ranking without keyword stuffing.

### Primary (high intent, high volume)
| Keyword | Placement |
|---|---|
| ubuntu setup script | README H1 title, first paragraph, footer |
| ubuntu server initial setup | README description/subtitle, About description, FAQ |
| ubuntu post install / what to do after installing ubuntu | First paragraph, FAQ H3 |
| ubuntu server hardening / security | "Safety" H2, FAQ H3, topics |

### Secondary (feature-level)
| Keyword | Placement |
|---|---|
| ufw firewall setup | Modules table, topics, FAQ |
| ssh hardening | Modules table, Safety section, topics, FAQ |
| fail2ban | Modules table, topics |
| automatic security updates / unattended-upgrades | Modules table, topics, FAQ |
| install docker ubuntu | Modules table, topics, FAQ ("run just one module") |
| swap file ubuntu | Modules table, FAQ (idempotent) |

### Long-tail (FAQ H3s — these capture Google "question" snippets)
- "What should I do after installing Ubuntu?"
- "How do I secure a new Ubuntu server?"
- "Is it safe to run setup scripts from the internet?"
- "Will this lock me out of my server over SSH?"
- "Does this work on Ubuntu 22.04 and 24.04?"
- "Can I run it unattended for cloud-init or Ansible?"

Each of these is now an H3 in the README so it can match featured-snippet queries verbatim.

---

## 5. README heading strategy

GitHub indexes README headings heavily and they render as the on-page outline. Guidelines applied here:

- **H1** contains the product name + the top search phrases ("Ubuntu Server & Desktop Setup Script", "Initial Setup, Security Hardening, Post-Install").
- **H2s are descriptive, not cute** — "What it can set up (modules)", "Safety — how it protects you from SSH lock-outs", "Supported systems (Ubuntu versions)".
- **FAQ uses question-form H3s** matching real searches.
- A **Table of contents** with anchor links improves dwell time and gives Google jump links.
- Keep the keyword footer (`<sub>` line) — low-cost, harmless, helps long-tail matching.

Avoid: stuffing the same phrase repeatedly, hidden text, or unreadable keyword lists in body copy. Google penalizes that; the natural placements above are enough.

---

## 6. Social preview image (requires a human)

GitHub shows a social preview (Open Graph) card when the repo is shared on X, Slack, LinkedIn, etc. A custom image meaningfully increases click-through.

- Set it in **Settings → Social preview** (upload a PNG, recommended **1280×640**).
- Suggested content: the repo name, the tagline ("Safe Ubuntu setup & hardening"), an Ubuntu-orange accent, and 4–5 feature icons/words (Firewall · SSH · Auto-updates · Docker · Swap).
- Keep text large and legible at thumbnail size.

The marketing-assets agent owns generating this image; this doc just records the spec.

---

## 7. How GitHub ranks repos (and what to act on)

GitHub search relevance and the Explore/Trending surfaces weigh roughly:

1. **Stars (and recent star velocity)** — the biggest factor. Ask early users to star; recency matters more than absolute count.
2. **Topics** — exact-match topic filters are how many users browse; complete the topic list (section 2).
3. **README keyword relevance** — title, headings, and body text matched against the query (handled above).
4. **Recency / activity** — recent commits, releases, and open-then-resolved issues signal a maintained project. Cut periodic releases/tags.
5. **Description match** — the About one-liner is matched directly; keep it keyword-rich (section 1).
6. **Forks, watchers, contributors** — secondary social proof.

### High-impact actions for the maintainer (human)
- [ ] Fill the **About** description and **all topics** (sections 1–2).
- [ ] Upload a **social preview image** (section 6).
- [ ] Enable **Discussions** (more indexable Q&A pages, more long-tail entry points).
- [ ] Cut a tagged **release** (e.g. `v1.0.0`) and tag releases regularly — boosts recency signals and gives a clean install reference.
- [ ] Add the repo to relevant **awesome-* lists** and answer matching questions on forums/Reddit/Stack Exchange with a link (off-site backlinks help Google).
- [ ] Replace `<your-username>` placeholders in README and `setup.sh` once the canonical URL is known.

---

## 8. Off-GitHub (Google) notes

- The README is the page Google indexes for the repo; the question-form FAQ H3s are the most likely to win featured snippets for "what to do after installing ubuntu" style queries.
- Backlinks from blog posts, awesome-lists, and forum answers are the main external ranking lever — encourage them.
- Keep claims truthful and specific; pages that accurately answer the query rank and retain better than keyword-padded ones.
