# Secret management

Secrets never live in these repos — not even encrypted. They live in a password manager and are
loaded **lazily, only when the tool that needs them runs**, via [fnox](https://fnox.jdx.dev). A bare
shell — including a remote SSH login — never touches a manager.

## Model

| Layer | What |
|---|---|
| **Storage** | 1Password (`op`) for work, Bitwarden (`rbw` agent) for personal |
| **Mapping** | `~/.config/fnox/config.toml` maps `ENV_VAR → provider + item name` (no values) |
| **Loading** | `fnox exec -- <cmd>` runs a command with its secrets in the environment |
| **Ad-hoc** | `secret <name>` (`lib/secret.sh`) for a quick one-off lookup |

## Storage convention

Store each secret as an item **titled `<name>`** with the value in the **password field** (symmetric
across both managers). Kebab-case, e.g. `fossa-api-key`. Work → 1Password; personal → Bitwarden.

Create the item (one-time, interactive-ish):
- **Bitwarden (`rbw`)** — `rbw add`'s editor hangs when scripted; pipe to stdin instead:
  ```sh
  printf '%s\n' "$THE_VALUE" | rbw add <name>
  ```
- **1Password (`op`)** — `op item create --category login --title <name> --vault <work-vault> "password=$THE_VALUE"`

Read the value from its existing file rather than typing it into shell history.

## Mapping a secret in fnox

`~/.config/fnox/config.toml` (global; found from any directory):
```toml
[providers]
bitwarden = { type = "bitwarden", backend = "rbw" }   # rbw = agent-based, no BW_SESSION
onepassword = { type = "1password" }

[secrets]
FOSSA_API_KEY = { provider = "bitwarden", value = "fossa-api-key" }
SOME_WORK_KEY = { provider = "onepassword", value = "some-work-item" }
```
Items are referenced **by name** (password field by default; `value = "Item/username"` for other fields).

## Loading pattern (lazy — the important part)

Wrap each tool so its secret loads only when you invoke it:
```sh
# in ~/.zshrc
fossa() { fnox exec -- fossa "$@"; }
```
`fnox exec` injects the env var for the lifetime of that process only. Nothing is fetched at shell
start, on `cd`, or on a remote login. For ad-hoc one-offs, `secret <name>` still works.

*(Per-directory project secrets are also possible — drop a `fnox.toml` in the project and
`eval "$(fnox activate zsh)"` — but prefer per-command wrappers for global CLI tokens so bare/remote
shells stay clean.)*

## Adding a new secret — checklist
1. Store the item in the right manager (commands above), titled `<name>`, value in password field.
2. Add a line under `[secrets]` in `~/.config/fnox/config.toml`.
3. Wrap the consuming tool with `fnox exec` (or run it that way ad-hoc).
4. Remove any plaintext copy.

## Bootstrap on a new machine
1. `brew install 1password-cli bitwarden-cli rbw pinentry-mac` (or `mise use -g ubi:jdx/fnox` for fnox).
2. 1Password: enable CLI integration in the app (or `op signin`). Bitwarden: `rbw register` (personal
   API key — bot-detection), `rbw unlock`, `rbw sync`. Set `rbw config set pinentry pinentry-mac`.
3. Run the dotfiles `install.sh`; `~/.config/fnox/config.toml` and `lib/secret.sh` come with it.

## What never enters the repos
- Secret values, in any form.
- Manager session tokens (`BW_SESSION`), agent sockets.
- Only **references** (item names) live in `fnox.toml` — keep that file in the **private** repo.
