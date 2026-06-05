---
name: managing-dotfiles
description: Use when adding, changing, deploying, onboarding, or auditing Jesse's dotfiles — the symlink-based config system in ~/git/dotfiles (public) and ~/git/dotfiles-private (private), deployed across his Mac + Linux fleet. Covers the update workflow, the manifest, OS-splitting, secrets, new-machine onboarding, and the audit process.
---

# Managing the dotfiles

Two repos, symlink-deployed across a fleet (2 Macs + Linux boxes):

- **`~/git/dotfiles`** — public. Shell, editor, tool configs, `bin/` scripts, `.claude/` (CLAUDE.md,
  commands, standalone skills). **No secrets, ever.**
- **`~/git/dotfiles-private`** — private. ssh config, `fnox` config, `bin/bw-unlock`, work env. Still
  **only references** to secrets, never values.

Each repo has a `manifest` (`<repo-relative path> [macos|linux]`) and a POSIX `install.sh` that
symlinks each entry into `$HOME`, backing up anything it replaces to `~/.dotfiles-backup/<ts>/`.

## Updating (the common case)

Files in `$HOME` are symlinks into the repo, so **edit in place, then `git commit`.** That's it —
the change is already live. You only run `install.sh` after adding a **new** manifest entry or on a
new machine. Commit + push, then `git pull` on the other hosts.

## Adding a new config

1. Move the file into the repo at its `$HOME`-relative path (e.g. `~/.config/foo/bar` →
   `.config/foo/bar`).
2. Add the path to `manifest` — append ` macos` or ` linux` if it's OS-specific.
3. Run `./install.sh` (symlinks it; backs up the original).
4. Commit. `$HOME`-ize any absolute paths inside the file so it's portable.

## OS-specific config

Prefer **separate files** chosen by the manifest tag (`.config/zsh/macos.zsh` vs `linux.zsh`,
`.ssh/config.d/macos.conf`) over in-file `uname` branches. The common file sources the OS file only
if present, so it's a no-op on the other OS. Guard tool integrations with `command -v`.

## Secrets

Never commit a value. Tools get secrets lazily via `fnox` (`docs/SECRETS.md`): `op` (1Password,
work) + `bw` (Bitwarden, personal), with Bitwarden unlocked silently from 1Password via `bw-unlock`.
Headless machines (no 1Password app) use a **service-account token** in `~/.config/op/env` (600,
untracked) — see SECRETS.md "Headless / unattended machines". When handling a secret value in the
shell, only ever pipe it to `wc -c` or `shasum` — never echo it, never `2>&1`/`-v`/`--full`.

## Onboarding a new machine

1. Clone both repos into `~/git`. (Linux/headless: register an ssh key with GitHub if needed.)
2. Install the toolchain: `mise` + `fnox` (`mise use -g ubi:jdx/fnox`), `op`, `bw`, `jq`, `zsh`.
3. `./install.sh` in each repo.
4. Headless secrets: mint a per-box 1Password service account
   (`op service-account create <host> --vault automation:read_items --raw`), drop the token in
   `~/.config/op/env` (route it only through a temp file / `$(cat …)`, never echo), `bw login
   --apikey`, then verify the chain (`fnox get <name> | wc -c`).
5. `chsh` to zsh. First interactive zsh triggers the one-time z4h bootstrap.

`magic-kingdom` (Linux) and `paradise-park` (Mac, SSH-driven) are the worked exemplars.

## Claude config (.claude/)

`CLAUDE.md`, `commands/`, and **standalone** skills under `.claude/skills/` are versioned via
individual manifest entries and symlinked into `~/.claude/`. This keeps host-specific
**project-linked** skills (a `~/.claude/skills/<x>` that symlinks into a project repo) untouched. To
version a new standalone skill: drop it in `.claude/skills/<name>/`, add a manifest line, run
`install.sh`.

## Auditing

Run `dotfiles-audit` before pushing and periodically (leak scan + deploy drift + perms). Full
process and the by-eye checks are in `docs/AUDITING.md`.
