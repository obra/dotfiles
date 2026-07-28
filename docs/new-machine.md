# Setting up a new Mac

One command turns a fresh Mac into a managed dev workstation. Everything it
installs comes from version-controlled artifacts in this repo, so machines stay
reproducible: packages from `.config/homebrew/Brewfile`, config from the
`manifest`, runtimes from `.config/mise/config.toml`.

Linux and headless machines use the manual steps in the README plus the
"Onboarding a new machine" notes in the managing-homedir skill instead.

## Run the bootstrap

Prerequisites on the new machine: your user account exists, Remote Login is on,
and your SSH key is in `~/.ssh/authorized_keys`.

First give the machine its own GitHub key — the `dotfiles-private` clone needs
it, and agent forwarding won't carry Secretive-held keys (`-A` forwards the
empty Apple agent instead). From an existing machine with `gh`:

```sh
ssh jesse@NEWHOST 'ssh-keygen -t ed25519 -N "" -C "jesse@NEWHOST" -f ~/.ssh/id_ed25519 && cat ~/.ssh/id_ed25519.pub' \
  | gh ssh-key add - --title "NEWHOST machine key"
```

Then run the bootstrap (you'll type the machine's sudo password once, for the
Xcode Command Line Tools and Homebrew installs):

```sh
ssh -t jesse@NEWHOST 'sh -c "$(curl -fsSL https://raw.githubusercontent.com/obra/dotfiles/main/bin/mac-bootstrap)"'
```

The script (`bin/mac-bootstrap`) is idempotent — rerun it anytime, locally or
over ssh. It does, skipping whatever is already done:

1. Xcode Command Line Tools (`softwareupdate`, sudo)
2. Homebrew (official installer, sudo)
3. Clones `homedir-manager`, `dotfiles`, `dotfiles-private` into `~/git`
4. `homedir-manager` bootstrap, then `homedir-manager install` (symlink deploy)
5. `brew bundle` from the curated Brewfile
6. `mise install` (fnox and friends)
7. Claude Code via its native installer (lands in `~/.local/bin`)

## Interactive logins (at the machine or via Screen Sharing)

Nothing here is scriptable; it's all GUI sign-ins and OAuth:

1. **1Password**: sign in, then Settings → Developer → enable CLI integration
   so `op` works.
2. **Tailscale**: open the app, log in, verify the machine joins the tailnet.
3. **Secretive** (optional upgrade): create a hardware-backed key, add it to
   GitHub, and retire the bootstrap-era `~/.ssh/id_ed25519` machine key.
4. **CLI logins**: `gh auth login`, `claude` (prompts on first run), `codex`,
   `bw login`.
5. Grant TCC prompts as they appear. Caution: don't give Terminal a
   Documents-folder grant on top of Full Disk Access — the redundant grant can
   drift to deny in the TCC cache and mask FDA
   (fix: `sudo tccutil reset SystemPolicyDocumentsFolder com.apple.Terminal`).

## Finish

1. `lock-stray-zshrc` — see README.
2. `homedir-manager defaults apply` — curated macOS settings from
   `.config/macos-defaults/desired.tsv`.
3. `homedir-manager audit` — confirm clean deploy, no drift.
4. Verify the secrets chain: `withsecrets` on something that needs `op`, and
   `bw-unlock` for the Bitwarden side.

## Adding software later

Add it to `.config/homebrew/Brewfile` (a symlink into this repo), run
`brew bundle --global`, commit. Ad-hoc `brew install` works but leaves the
machine unreproducible — the Brewfile is the record.
