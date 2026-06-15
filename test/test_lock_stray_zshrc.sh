#!/bin/sh
# test_lock_stray_zshrc.sh — verify the stray-~/.zshrc locker creates a
# self-documenting placeholder and makes it immutable, with unlock/status/help.
set -u
HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)
. "$HERE/assert.sh"

SCRIPT="$HERE/../bin/lock-stray-zshrc"
TMP=$(mktempd)
ZF="$TMP/.zshrc"

# Immutability is enforced by chflags (macOS) / chattr (Linux). The behavioral
# lock checks only run where they don't need root: macOS chflags. Elsewhere we
# still test content/status/help/idempotency and SKIP the write-blocking asserts.
can_test_lock=no
[ "$(uname -s)" = "Darwin" ] && command -v chflags >/dev/null 2>&1 && can_test_lock=yes

# --- lock creates a self-documenting placeholder ---------------------------
HOME="$TMP" "$SCRIPT" lock >/dev/null 2>&1
assert_file_exists "$ZF" "lock creates ~/.zshrc"
if grep -q 'ZDOTDIR' "$ZF" 2>/dev/null; then
  assert_eq "explains" "explains" "placeholder explains the ZDOTDIR redirect"
else
  assert_eq "explains" "missing" "placeholder explains the ZDOTDIR redirect"
fi

# --- status reports LOCKED -------------------------------------------------
out=$(HOME="$TMP" "$SCRIPT" status 2>&1)
if printf '%s\n' "$out" | grep -q 'LOCKED'; then
  assert_eq "LOCKED" "LOCKED" "status reports LOCKED after lock"
else
  assert_eq "LOCKED" "$out" "status reports LOCKED after lock"
fi

# --- the lock actually blocks writes (macOS only) --------------------------
if [ "$can_test_lock" = yes ]; then
  if ( echo clobber >>"$ZF" ) 2>/dev/null; then
    assert_eq "blocked" "written" "locked file rejects appends"
  else
    assert_eq "blocked" "blocked" "locked file rejects appends"
  fi
else
  printf '  SKIP: write-blocking asserts (no rootless immutable flag here)\n'
fi

# --- lock is idempotent ----------------------------------------------------
if HOME="$TMP" "$SCRIPT" lock >/dev/null 2>&1; then
  assert_eq "ok" "ok" "lock is idempotent (re-run succeeds)"
else
  assert_eq "ok" "failed" "lock is idempotent (re-run succeeds)"
fi

# --- unlock clears the flag; writes succeed again --------------------------
HOME="$TMP" "$SCRIPT" unlock >/dev/null 2>&1
out=$(HOME="$TMP" "$SCRIPT" status 2>&1)
if printf '%s\n' "$out" | grep -q 'UNLOCKED'; then
  assert_eq "UNLOCKED" "UNLOCKED" "status reports UNLOCKED after unlock"
else
  assert_eq "UNLOCKED" "$out" "status reports UNLOCKED after unlock"
fi
if [ "$can_test_lock" = yes ]; then
  if ( echo ok >>"$ZF" ) 2>/dev/null; then
    assert_eq "writable" "writable" "unlocked file accepts appends"
  else
    assert_eq "writable" "blocked" "unlocked file accepts appends"
  fi
fi

# --- help prints usage and exits 0 -----------------------------------------
if HOME="$TMP" "$SCRIPT" help 2>&1 | grep -q 'usage'; then
  assert_eq "usage" "usage" "help prints usage"
else
  assert_eq "usage" "missing" "help prints usage"
fi

# --- unknown subcommand errors (non-zero) ----------------------------------
if HOME="$TMP" "$SCRIPT" bogus >/dev/null 2>&1; then
  assert_eq "rejects" "accepted" "unknown subcommand is rejected"
else
  assert_eq "rejects" "rejects" "unknown subcommand is rejected"
fi

# cleanup: clear any immutable flag before removing the temp tree
chflags -R nouchg "$TMP" 2>/dev/null || true
rm -rf "$TMP"

printf 'RESULT run=%s failed=%s\n' "$TESTS_RUN" "$TESTS_FAILED"
