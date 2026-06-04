#!/bin/sh
# test_runner_guard.sh — verify run.sh detects a crashed test file as a failure.
set -u
HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)
. "$HERE/assert.sh"

# Build a temp dir that mimics a mini test suite:
#   - a crashing fake test (exits 1 before printing RESULT)
#   - copies of run.sh and assert.sh so we can run run.sh in isolation
TMP=$(mktempd)

# Crashing test: exits non-zero before any RESULT line.
cat > "$TMP/test_crash.sh" <<'EOF'
#!/bin/sh
exit 1
EOF
chmod +x "$TMP/test_crash.sh"

# run.sh discovers test_*.sh in its own directory, so copy both harness files.
cp "$HERE/run.sh"    "$TMP/run.sh"
cp "$HERE/assert.sh" "$TMP/assert.sh"

runner_out=$(sh "$TMP/run.sh" 2>&1)
runner_exit=$?

# The runner must exit non-zero.
if [ "$runner_exit" -ne 0 ]; then
  assert_eq "nonzero" "nonzero" "runner exits non-zero when a test crashes"
else
  assert_eq "nonzero" "zero" "runner exits non-zero when a test crashes"
fi

# The runner output must contain the ERROR marker.
if printf '%s\n' "$runner_out" | grep -q 'ERROR:'; then
  assert_eq "has-ERROR" "has-ERROR" "runner output contains ERROR marker for crashed file"
else
  assert_eq "has-ERROR" "no-ERROR" "runner output contains ERROR marker for crashed file"
fi

rm -rf "$TMP"

printf 'RESULT run=%s failed=%s\n' "$TESTS_RUN" "$TESTS_FAILED"
