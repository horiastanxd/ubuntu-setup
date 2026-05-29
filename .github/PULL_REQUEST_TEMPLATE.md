## What does this PR do?

Briefly describe the change and the motivation.

## Type of change
- [ ] Bug fix
- [ ] New module
- [ ] Improved explanation / docs
- [ ] Translation
- [ ] Other:

## Safety checklist (required)
- [ ] System-changing commands go through the `run` helper (so `--dry-run` works).
- [ ] Any change is behind a confirmation prompt or `--yes`.
- [ ] Existing config files are backed up before editing (`backup_file`).
- [ ] The step is idempotent (safe to run twice).
- [ ] Prompts explain *what*, *why*, and the *risk* in plain language.

## How did you test it?
- [ ] `bash -n` passes on changed files
- [ ] `shellcheck` passes
- [ ] `./setup.sh --dry-run --only <module>` shows expected actions
- [ ] Tested on a real/VM Ubuntu (version: ____)
