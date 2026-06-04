#!/bin/sh
set -u
HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)
REPO=$(CDPATH= cd -- "$HERE/.." && pwd -P)
. "$HERE/assert.sh"

make_stub() { # dir name body
  mkdir -p "$1"
  printf '#!/bin/sh\n%s\n' "$3" > "$1/$2"
  chmod +x "$1/$2"
}

# Case 1: op present and "signed in" -> uses op
TMP=$(mktempd)
make_stub "$TMP/bin" op 'case "$1" in
  account) exit 0 ;;          # op account list -> signed in
  read) echo "op-value-for-$2" ;;
esac'
out=$(PATH="$TMP/bin:$PATH" sh -c ". \"$REPO/lib/secret.sh\"; secret github-token")
assert_eq "op-value-for-op://Personal/github-token/credential" "$out" "dispatches to op when signed in"
rm -rf "$TMP"

# Case 2: no op, rbw present -> uses rbw
TMP=$(mktempd)
make_stub "$TMP/bin" rbw 'echo "rbw-value-for-$2"'
out=$(PATH="$TMP/bin:/usr/bin:/bin" sh -c ". \"$REPO/lib/secret.sh\"; secret github-token")
assert_eq "rbw-value-for-github-token" "$out" "falls back to rbw when op absent"
rm -rf "$TMP"

printf 'RESULT run=%s failed=%s\n' "$TESTS_RUN" "$TESTS_FAILED"
