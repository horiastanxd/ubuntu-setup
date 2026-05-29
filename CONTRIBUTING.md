# Contributing to ubuntu-setup

Thanks for helping make Ubuntu setup easier and safer for everyone! 🎉
You don't need to be an expert — better explanations, typo fixes, and testing
on real machines are all genuinely valuable.

## Ways to contribute

- 🐛 **Report bugs** — open an issue with your Ubuntu version and the command you ran.
- 💡 **Suggest a module** — a new "essential" task many people need.
- 📝 **Improve explanations** — make a prompt clearer for non-technical users.
- 🌍 **Add translations** — help reach more people.
- ✅ **Test** — try it on a fresh VM and tell us what happened.

## Ground rules for code

This project's whole value is being **safe and easy to trust**, so:

1. **Safety first.** Never make a change without a confirmation prompt *or* `--yes`.
   Always route system-changing commands through the `run` helper so `--dry-run` works.
2. **Explain in plain language.** Every prompt should say *what*, *why*, and the *risk*.
3. **Be idempotent.** Running twice must be safe — check before you change.
4. **Back up before editing** any existing file (`backup_file /path`).
5. **No hidden network calls.** Anything downloaded must be obvious and from an
   official, verifiable source (use signed apt repos / GPG keys where possible).

## Adding a new module

1. Copy an existing module from `modules/` as a starting point — they share a
   small bootstrap header that sources `lib/common.sh` and `lib/checks.sh`.
2. Keep it focused on **one** task. Name it `NN-short-name.sh`.
3. Start with a comment block: **WHAT / WHY / RISK**.
4. Register it: add one line to the `MODULES=()` array in `setup.sh`:
   ```
   "NN-short-name.sh|Short human description|server,desktop|yes-or-no"
   ```
   The last field (`yes`/`no`) decides whether it's part of the recommended profiles.
5. Make it executable: `chmod +x modules/NN-short-name.sh`.

## Before you open a pull request

```bash
# Syntax check everything:
for f in setup.sh lib/*.sh modules/*.sh; do bash -n "$f" || echo "FAIL: $f"; done

# Lint with shellcheck (please fix warnings):
shellcheck setup.sh lib/*.sh modules/*.sh

# Prove it's safe: a dry run must show your commands but change nothing:
./setup.sh --dry-run --only your-module
```

Then open a PR describing **what** changed and **why**, and how you tested it.

## Code style

- `bash` with `set -euo pipefail`.
- Use the shared helpers (`info`, `warn`, `success`, `step`, `ask_yes_no`,
  `ask_value`, `run`, `apt_install`, `backup_file`) — don't reinvent them.
- 2-space indentation. Keep lines readable.

Thank you! 💛
