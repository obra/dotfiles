# secret.sh — `secret <name>` prints a secret value, looked up BY ITEM TITLE in
# whichever password manager holds it: 1Password (`op`) first, then Bitwarden
# (`rbw`, else `bw`). This makes the mixed fleet work transparently — a work
# secret lives in 1Password and is found there; a personal secret lives in
# Bitwarden and is found there when op doesn't have it.
#
# Convention: store each secret as an item TITLED <name> with the value in the
# item's PASSWORD field (works for Login/Password items and is symmetric across
# both managers). No vault is hardcoded — op searches all vaults you can read.
#
# Sourced into the interactive shell (zsh). Works in zsh and POSIX sh.
secret() {
  _name=$1
  if [ -z "${_name:-}" ]; then
    printf 'usage: secret <name>\n' >&2
    return 2
  fi
  # 1Password: find by title across all vaults, read the password field.
  if command -v op >/dev/null 2>&1; then
    _v=$(op item get "$_name" --fields label=password --reveal 2>/dev/null) || _v=
    if [ -n "$_v" ]; then
      printf '%s\n' "$_v"
      return 0
    fi
  fi
  # Bitwarden: rbw preferred (unlocks on demand); else bw (needs BW_SESSION).
  if command -v rbw >/dev/null 2>&1; then
    rbw get "$_name" 2>/dev/null && return 0
  fi
  if command -v bw >/dev/null 2>&1; then
    bw get password "$_name" 2>/dev/null && return 0
  fi
  printf 'secret: no manager has an item titled "%s"\n' "$_name" >&2
  return 1
}
