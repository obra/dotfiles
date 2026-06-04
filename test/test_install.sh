#!/bin/sh
set -u
HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)
REPO=$(CDPATH= cd -- "$HERE/.." && pwd -P)
. "$HERE/assert.sh"

# os_name maps uname output to macos/linux/other.
out=$(UNAME_OVERRIDE=Darwin sh "$REPO/install.sh" --print-os)
assert_eq "macos" "$out" "Darwin -> macos"
out=$(UNAME_OVERRIDE=Linux sh "$REPO/install.sh" --print-os)
assert_eq "linux" "$out" "Linux -> linux"

# --- manifest parsing + OS filtering ---
TMP=$(mktempd)
mkdir -p "$TMP/repo" "$TMP/home"
# fake repo files
: > "$TMP/repo/common.conf"
: > "$TMP/repo/maconly.conf"
: > "$TMP/repo/linonly.conf"
cp "$REPO/install.sh" "$TMP/repo/install.sh"
cat > "$TMP/repo/manifest" <<'EOF'
# a comment
common.conf
maconly.conf   macos
linonly.conf   linux
EOF
# Run as macOS against fake HOME; list intended targets via --dry-run
out=$(UNAME_OVERRIDE=Darwin HOME="$TMP/home" sh "$TMP/repo/install.sh" --dry-run)
echo "$out" | grep -q 'common.conf'  && c=yes || c=no
echo "$out" | grep -q 'maconly.conf' && m=yes || m=no
echo "$out" | grep -q 'linonly.conf' && l=yes || l=no
assert_eq "yes" "$c" "common.conf included on macOS"
assert_eq "yes" "$m" "maconly.conf included on macOS"
assert_eq "no"  "$l" "linonly.conf excluded on macOS"
rm -rf "$TMP"

printf 'RESULT run=%s failed=%s\n' "$TESTS_RUN" "$TESTS_FAILED"
