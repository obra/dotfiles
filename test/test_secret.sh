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

# Case 1: op HAS an item titled the name -> returns its password field.
# helper calls: op item get <name> --fields label=password --reveal
TMP=$(mktempd)
make_stub "$TMP/bin" op 'case "$1 $2" in
  "item get") echo "op-value-for-$3" ;;
  *) exit 1 ;;
esac'
out=$(PATH="$TMP/bin:$PATH" sh -c ". \"$REPO/lib/secret.sh\"; secret github-token")
assert_eq "op-value-for-github-token" "$out" "dispatches to op when op has the item (by title)"
rm -rf "$TMP"

# Case 2: op present but does NOT have the item -> falls through to rbw.
TMP=$(mktempd)
make_stub "$TMP/bin" op 'exit 1'   # op item get -> not found
make_stub "$TMP/bin" rbw 'echo "rbw-value-for-$2"'
out=$(PATH="$TMP/bin:/usr/bin:/bin" sh -c ". \"$REPO/lib/secret.sh\"; secret github-token")
assert_eq "rbw-value-for-github-token" "$out" "falls through to rbw when op lacks the item"
rm -rf "$TMP"

# Case 3: op absent, bw present -> uses bw (bw get password <name>).
TMP=$(mktempd)
make_stub "$TMP/bin" bw 'echo "bw-value-for-$3"'
out=$(PATH="$TMP/bin:/usr/bin:/bin" sh -c ". \"$REPO/lib/secret.sh\"; secret github-token")
assert_eq "bw-value-for-github-token" "$out" "falls back to bw when op absent"
rm -rf "$TMP"

printf 'RESULT run=%s failed=%s\n' "$TESTS_RUN" "$TESTS_FAILED"
