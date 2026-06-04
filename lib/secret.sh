# secret.sh — `secret <name>` prints a secret value, dispatching to the first
# usable password-manager CLI: 1Password (`op`) if it's installed AND signed in,
# otherwise Bitwarden via `rbw`, otherwise `bw`. `rbw`/`bw` are selected on
# presence alone — `rbw get` unlocks on demand, so a locked vault is fine; `bw`
# expects BW_SESSION to be set.
# Sourced into the interactive shell (zsh). Works in zsh and POSIX sh.
secret() {
  _name=$1
  if [ -z "${_name:-}" ]; then
    printf 'usage: secret <name>\n' >&2
    return 2
  fi
  if command -v op >/dev/null 2>&1 && op account list >/dev/null 2>&1; then
    op read "op://Personal/$_name/credential"
  elif command -v rbw >/dev/null 2>&1; then
    rbw get "$_name"
  elif command -v bw >/dev/null 2>&1; then
    bw get password "$_name"
  else
    printf 'secret: no authenticated secret manager for "%s"\n' "$_name" >&2
    return 1
  fi
}
