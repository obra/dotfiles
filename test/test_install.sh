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

printf 'RESULT run=%s failed=%s\n' "$TESTS_RUN" "$TESTS_FAILED"
