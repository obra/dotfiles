# Secret management

Secrets never live in these repos — not even encrypted. Tracked config reaches secrets
indirectly through the `secret` helper, which reads them from a password manager at runtime.

## Model

| Where | What | How it's reached |
|---|---|---|
| 1Password (`op`) | work secrets | `secret <name>` → finds item by title |
| Bitwarden (`bw`/`rbw`) | personal secrets | `secret <name>` → falls through to Bitwarden |
| the repos | **nothing secret** | — |

`lib/secret.sh` defines `secret <name>`. It looks the secret up **by item title**, trying
1Password first (any vault you can read), then Bitwarden. So a work secret in 1Password and a
personal secret in Bitwarden both resolve through the same `secret foo` call, and no vault is ever
hardcoded in config.

## Storage convention

Store each secret as an item **titled exactly `<name>`** with the value in the item's **password
field** (a Login or Password item works; the password field is symmetric across both managers).
Use kebab-case names that read well in config, e.g. `fossa-api-key`, `tailscale-api-key`.

- **Work** → 1Password (put it in your work vault; the helper finds it by title regardless).
- **Personal** → Bitwarden.

## Adding a secret

1. Create the item in the right manager: title = `<name>`, value in the password field.
2. Reference it from config via `secret <name>` (never paste the value).
3. Remove any plaintext copy once the reference works.

Verify a name resolves:
```sh
secret fossa-api-key   # prints the value if found, errors if not
```

## Two usage patterns

**Environment-variable secrets** — keep them out of tracked shell config:
```sh
# in shell rc (tracked) — no value here, just the reference:
export FOSSA_API_KEY="$(secret fossa-api-key)"
```
For many secrets, prefer **session materialization** over a `secret` call per shell start (which
re-hits the manager and can prompt repeatedly): fetch them once per login into a gitignored file
and source it.
```sh
# build ~/.cache/secrets.env once per session, then source it:
{ printf 'export FOSSA_API_KEY=%s\n' "$(secret fossa-api-key)"
  printf 'export OPENROUTER_API_KEY=%s\n' "$(secret openrouter-api-key)"
} > ~/.cache/secrets.env
[ -f ~/.cache/secrets.env ] && . ~/.cache/secrets.env
```
The list of `VAR=name` pairs can be tracked (it carries no values); the rendered
`~/.cache/secrets.env` is gitignored and never committed.

**Config-file secrets** — a tool that reads a credential from its own config file (e.g. a CLI that
reads `~/.its-rc`): track a template with a placeholder and render the real file on demand:
```sh
# templated config (tracked): api-key: __SECRET__
sed "s|__SECRET__|$(secret the-api-key)|" ~/.its-rc.tmpl > ~/.its-rc
```

## Bootstrap on a new machine

1. Install a manager CLI: `brew install 1password-cli` (work boxes) and/or `brew install bitwarden-cli` (personal).
2. Sign in:
   - 1Password: enable the CLI in the 1Password app (Settings → Developer → "Integrate with 1Password CLI"), or `op signin`.
   - Bitwarden: `bw login`, then `bw unlock` (exports `BW_SESSION`). *(Optional: `rbw` gives agent-based unlock-on-demand and is auto-preferred by the helper if present.)*
3. Run the dotfiles `install.sh` so `lib/secret.sh` is sourced by your shell.

## What never enters the repos
- Secret values, in any form (plaintext or encrypted).
- Rendered secret files (`~/.cache/secrets.env`, materialized config) — gitignore them.
- Manager session tokens (`BW_SESSION`, `op` daemon sockets).
