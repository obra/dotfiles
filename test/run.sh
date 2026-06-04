#!/bin/sh
# run.sh — run every test/test_*.sh in its own subshell; aggregate results.
set -u
# shellcheck disable=SC1007  # CDPATH= is intentional: suppress cd output by clearing CDPATH as env var
HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)
total=0
failed=0
for t in "$HERE"/test_*.sh; do
  [ -f "$t" ] || continue
  printf '== %s ==\n' "$(basename "$t")"
  # Each test file prints a final "RESULT run=<n> failed=<n>" line.
  result=$(sh "$t" 2>&1)
  exit_status=$?
  printf '%s\n' "$result"
  r=$(printf '%s\n' "$result" | sed -n 's/.*RESULT run=\([0-9]*\) failed=\([0-9]*\).*/\1/p')
  f=$(printf '%s\n' "$result" | sed -n 's/.*RESULT run=\([0-9]*\) failed=\([0-9]*\).*/\2/p')
  if [ "$exit_status" -ne 0 ] || [ -z "$r" ]; then
    printf 'ERROR: %s crashed or printed no RESULT\n' "$(basename "$t")"
    failed=$((failed + 1))
  else
    total=$((total + ${r:-0}))
    failed=$((failed + ${f:-0}))
  fi
done
printf '\nTOTAL run=%s failed=%s\n' "$total" "$failed"
[ "$failed" -eq 0 ]
