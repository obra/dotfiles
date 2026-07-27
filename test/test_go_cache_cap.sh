#!/bin/sh
# test_go_cache_cap.sh — verify the Go build cache size cap: reports size and
# leaves the cache alone under the cap, wipes it via `go clean -cache` when
# over, errors usefully without go, and ships a valid LaunchAgent plist.
set -u
HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)
. "$HERE/assert.sh"

SCRIPT="$HERE/../bin/go-cache-cap"
PLIST="$HERE/../Library/LaunchAgents/com.fsck.go-cache-cap.plist"
TMP=$(mktempd)

if ! command -v go >/dev/null 2>&1; then
  printf '  SKIP: go not installed; only static checks run\n'
  have_go=no
else
  have_go=yes
fi

# --- help prints usage and exits 0 -----------------------------------------
if "$SCRIPT" --help 2>&1 | grep -q 'usage'; then
  assert_eq "usage" "usage" "--help prints usage"
else
  assert_eq "usage" "missing" "--help prints usage"
fi

# --- unknown flag is rejected ----------------------------------------------
if "$SCRIPT" --bogus >/dev/null 2>&1; then
  assert_eq "rejects" "accepted" "unknown flag is rejected"
else
  assert_eq "rejects" "rejects" "unknown flag is rejected"
fi

if [ "$have_go" = yes ]; then
  # Cache entries live in two-hex-digit subdirectories; go clean -cache
  # removes subdirectories, so the marker models a real entry.
  mk_cache() {
    rm -rf "$TMP/cache"
    mkdir -p "$TMP/cache/aa"
    echo data > "$TMP/cache/aa/entry"
  }

  # --- under the cap: cache is left alone ----------------------------------
  mk_cache
  out=$(GOCACHE="$TMP/cache" "$SCRIPT" --max-gb 1 2>&1)
  status=$?
  assert_eq "0" "$status" "under cap exits 0"
  assert_file_exists "$TMP/cache/aa/entry" "under cap leaves cache entries alone"
  if printf '%s\n' "$out" | grep -q 'under'; then
    assert_eq "reports" "reports" "under cap reports size is under the cap"
  else
    assert_eq "reports" "$out" "under cap reports size is under the cap"
  fi

  # --- over the cap: cache is wiped ----------------------------------------
  mk_cache
  out=$(GOCACHE="$TMP/cache" "$SCRIPT" --max-gb 0 2>&1)
  status=$?
  assert_eq "0" "$status" "over cap exits 0"
  if [ -e "$TMP/cache/aa/entry" ]; then
    assert_eq "wiped" "still-present" "over cap wipes cache entries"
  else
    assert_eq "wiped" "wiped" "over cap wipes cache entries"
  fi
  if printf '%s\n' "$out" | grep -q 'clean'; then
    assert_eq "reports" "reports" "over cap reports the wipe"
  else
    assert_eq "reports" "$out" "over cap reports the wipe"
  fi

  # --- missing cache dir is a quiet no-op ----------------------------------
  out=$(GOCACHE="$TMP/nonexistent" "$SCRIPT" --max-gb 1 2>&1)
  assert_eq "0" "$?" "missing cache dir exits 0"
fi

# --- go missing from PATH errors usefully ----------------------------------
out=$(PATH=/nonexistent "$SCRIPT" 2>&1)
status=$?
if [ "$status" -ne 0 ]; then
  assert_eq "fails" "fails" "missing go exits nonzero"
else
  assert_eq "fails" "succeeded" "missing go exits nonzero"
fi
if printf '%s\n' "$out" | grep -q 'not found: go'; then
  assert_eq "names go" "names go" "missing-go error names the missing command"
else
  assert_eq "names go" "$out" "missing-go error names the missing command"
fi

# --- LaunchAgent plist is valid and runs the script ------------------------
assert_file_exists "$PLIST" "LaunchAgent plist exists"
if plutil -lint "$PLIST" >/dev/null 2>&1; then
  assert_eq "valid" "valid" "plist passes plutil -lint"
elif ! command -v plutil >/dev/null 2>&1; then
  printf '  SKIP: plutil not available (not macOS)\n'
else
  assert_eq "valid" "invalid" "plist passes plutil -lint"
fi
if grep -q 'go-cache-cap' "$PLIST" 2>/dev/null; then
  assert_eq "runs script" "runs script" "plist invokes go-cache-cap"
else
  assert_eq "runs script" "missing" "plist invokes go-cache-cap"
fi

rm -rf "$TMP"

printf 'RESULT run=%s failed=%s\n' "$TESTS_RUN" "$TESTS_FAILED"
