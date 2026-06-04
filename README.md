# dotfiles

Symlink-deployed dotfiles. The `manifest` lists every tracked file (one repo-relative path per line,
optional `macos`/`linux` tag); `install.sh` symlinks each into `$HOME` at the mirrored path.

## Daily use
Edit files in place — they're symlinks into this repo. Then `git commit`. That's it.
Run `./install.sh` only on a new machine or after adding a NEW file to the manifest.

## Commands
- `./install.sh --dry-run` — preview actions, change nothing.
- `./install.sh` — deploy. Idempotent. Pre-existing files are moved to `~/.dotfiles-backup/<timestamp>/`,
  never overwritten.
- `sh test/run.sh` — run the test suite.

## Secrets
Secrets never live in this repo. Shell config calls `secret <name>` (see `lib/secret.sh`), which reads
from 1Password (`op`) or Bitwarden (`rbw`/`bw`), whichever is authenticated on the machine.

## Bootstrap a new machine
1. `git clone https://github.com/obra/dotfiles ~/git/dotfiles`
2. `cd ~/git/dotfiles && ./install.sh`
3. Sign in to your password manager (`op signin` or `rbw unlock`).
