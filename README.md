# dotfiles

Symlink-deployed dotfiles. The `manifest` lists every tracked file (one repo-relative path per line,
optional `macos`/`linux` tag). This is a **content repo** for the `homedir-manager` engine — the
`.homedir-manager.conf` marker opts it in, and the engine symlinks each manifest entry into `$HOME`
at the mirrored path.

## Daily use
Edit files in place — they're symlinks into this repo. Then `git commit`. That's it.
Run `homedir-manager install` only on a new machine or after adding a NEW file to the manifest.

## Commands (from the homedir-manager engine)
- `homedir-manager install --dry-run` — preview actions, change nothing.
- `homedir-manager install` — deploy. Idempotent. Pre-existing files are moved to
  `~/.dotfiles-backup/<timestamp>/`, never overwritten.
- `homedir-manager audit` — scan for leaked secrets, deploy drift, and bad perms.
- `sh test/run.sh` — run this repo's own tests.

## Secrets
Secrets never live in this repo. [fnox](https://fnox.jdx.dev) is the single mechanism: each secret is a
declared entry in `~/.config/fnox/config.toml` (a reference, not a value) and is resolved at runtime by
the tool that needs it. Shell config wraps each tool so it runs under `fnox exec`; for a one-off,
`withsecrets <tool>`. General setup, conventions, and patterns are documented with the engine
(`homedir-manager/share/SECRETS.md`).

## Bootstrap a new machine
1. `git clone https://github.com/obra/dotfiles ~/git/dotfiles`
2. Clone the `homedir-manager` engine into `~/git/homedir-manager` and run `~/git/homedir-manager/bootstrap`.
3. `homedir-manager install`
4. Sign in to your password manager (`op signin` or `rbw unlock`).
5. `lock-stray-zshrc` — hold the inert root `~/.zshrc` immutable so editors that don't know about
   z4h can't clobber shell config (real config is `~/.config/zsh/.zshrc` via ZDOTDIR). macOS needs
   no privileges; Linux needs `sudo lock-stray-zshrc`. Run `lock-stray-zshrc unlock` to undo.
