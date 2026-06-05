# Secret management

Secrets never live in these repos — not even encrypted. They live in a password manager and are
loaded **lazily, only when the tool that needs them runs**, via [fnox](https://fnox.jdx.dev). A bare
shell — including a remote SSH login — never touches a manager.

## Model

| Layer | What |
|---|---|
| **Storage** | 1Password (`op`) for work, Bitwarden (`bw`) for personal |
| **Unlock** | 1Password's biometric is the only gate. Bitwarden unlocks *silently* from it — its master password is stored in 1Password and pulled by `bw-unlock` |
| **Mapping** | `~/.config/fnox/config.toml` maps `ENV_VAR → provider + item name` (no values) |
| **Loading** | a tool wrapper sets `BW_SESSION` (via `bw-unlock`) then runs `fnox exec -- <cmd>` |
| **Ad-hoc** | `secret <name>` (`lib/secret.sh`) for a quick one-off lookup |

## Storage convention

Store each secret as an item **titled `<name>`** with the value in the **password field**. Kebab-case,
e.g. `some-api-key`. Work → 1Password; personal → Bitwarden.

Create the item (one-time):
- **1Password (`op`)** — fully scriptable:
  ```sh
  op item create --category login --title <name> --vault <work-vault> "password=$THE_VALUE"
  ```
- **Bitwarden (`bw`)** — needs a session (`bw-unlock` gives one); `bw create` reads JSON from stdin:
  ```sh
  S=$(bw-unlock)
  bw get template item --session "$S" \
    | jq --arg n <name> --arg p "$THE_VALUE" '.type=1|.name=$n|.login={password:$p}' \
    | bw encode | bw create item --session "$S"
  ```
  (Avoid `rbw add` — its editor flow hangs when scripted.)

Read the value from its existing file rather than typing it into shell history.

## Mapping a secret in fnox

`~/.config/fnox/config.toml` (global; found from any directory; lives in the **private** repo):
```toml
[providers]
bitwarden   = { type = "bitwarden", backend = "bw" }   # uses BW_SESSION from the environment
onepassword = { type = "1password" }

[secrets]
MY_API_KEY = { provider = "bitwarden", value = "my-api-key" }
SOME_WORK_KEY = { provider = "onepassword", value = "some-work-item" }
```
Items are referenced **by name** (password field by default).

## Silent Bitwarden unlock

`bw-unlock` (in the private repo's `bin/`, on `PATH`) prints a `BW_SESSION` by reading the Bitwarden
master password from 1Password — so `op`'s biometric is the only prompt you ever see:
```sh
BW_PW="$(op read 'op://<vault>/bitwarden-cli/password')" bw unlock --passwordenv BW_PW --raw
```

## Loading pattern (lazy — the important part)

In `~/.zshrc`, a helper sets `BW_SESSION` on first use, and each tool is wrapped:
```sh
_bw_session() { [ -n "${BW_SESSION:-}" ] || export BW_SESSION="$(bw-unlock 2>/dev/null)"; }
withsecrets() { _bw_session; fnox exec -- "$@"; }      # run any tool with its secrets
mytool()      { _bw_session; fnox exec -- mytool "$@"; }
othertool()   { fnox exec -- othertool "$@"; }
```
`fnox exec` injects the env vars for that process only. Nothing is fetched at shell start, on `cd`, or
on a remote login — `_bw_session` runs only inside a wrapper, and degrades gracefully (empty session)
where `op`/`bw` aren't present. For a one-off: `withsecrets <tool>`. For ad-hoc values: `secret <name>`.

## Adding a new secret — checklist
1. Store the item in the right manager (commands above), titled `<name>`, value in password field.
2. Add a line under `[secrets]` in `~/.config/fnox/config.toml`.
3. Wrap the consuming tool (or run it via `withsecrets <tool>`).
4. Quarantine/remove any plaintext copy.

## Bootstrap on a new machine
1. `brew install 1password-cli bitwarden-cli jq` and `mise use -g ubi:jdx/fnox`.
2. 1Password: enable CLI integration in the app (Settings → Developer). It holds a `bitwarden-cli` item
   with the Bitwarden **master password** + API key (`client_id`/`client_secret`).
3. Bitwarden: `BW_CLIENTID=$(op read …/client_id) BW_CLIENTSECRET=$(op read …/client_secret) bw login --apikey`.
4. Run the dotfiles `install.sh`; `~/.config/fnox/config.toml`, `bin/bw-unlock`, and `lib/secret.sh` come with it.

## Headless / unattended machines (no 1Password app)

A server has no desktop app, so `op`'s normal biometric integration is unavailable — and 1Password
**service accounts cannot read your personal/Employee vault** by design. The fix is to root the box in
a **service-account token**, the same "one local root credential, everything else fetched at runtime"
model a CI runner uses:

1. **Put the work secrets in a service-account-reachable vault.** Create a vault (e.g. `automation`)
   shared with only you, and move the items the box needs there:
   ```sh
   op vault create automation
   op item move bitwarden-cli   --current-vault Employee --destination-vault automation
   op item move tailscale-api-key --current-vault Employee --destination-vault automation
   ```
   Repoint the `op://Employee/…` references in `config.toml` + `bin/bw-unlock` to `op://automation/…`
   (still resolves on your Mac — the app sees every vault).
2. **Mint a read-only service account** scoped to that vault, and save the token (it prints once):
   ```sh
   op service-account create <box-name> --vault automation:read_items --raw
   ```
   Back it up as a 1Password item too, so it's recoverable.
3. **Drop the token on the box** in a local file the shell sources — never tracked, `chmod 600`:
   ```sh
   printf 'export OP_SERVICE_ACCOUNT_TOKEN=%s\n' "$TOKEN" > ~/.config/op/env   # 600
   ```
   `linux.zsh` sources `~/.config/op/env`, so `op` runs unattended → `bw login --apikey` + `bw-unlock`
   + `fnox` all work with no prompt. Personal (Bitwarden) secrets ride along, since the bw master
   password lives in the `automation` vault too.

## What never enters the repos
- Secret values, in any form.
- Manager session tokens (`BW_SESSION`), agent sockets.
- Only **references** (item names, the `op://…` path in `bw-unlock`) live in config — in the **private** repo.
