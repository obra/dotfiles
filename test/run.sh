#!/bin/sh
# run.sh — run every test/test_*.sh in its own subshell; aggregate results.
set -u
HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)
total=0
failed=0
for t in "$HERE"/test_*.sh; do
  [ -f "$t" ] || continue
  printf '== %s ==\n' "$(basename "$t")"
  # Each test file prints a final "RESULT run=<n> failed=<n>" line.
  result=$(sh "$t")
  printf '%s\n' "$result"
  r=$(printf '%s\n' "$result" | sed -n 's/.*RESULT run=\([0-9]*\) failed=\([0-9]*\).*/\1/p')
  f=$(printf '%s\n' "$result" | sed -n 's/.*RESULT run=\([0-9]*\) failed=\([0-9]*\).*/\2/p')
  total=$((total + ${r:-0}))
  failed=$((failed + ${f:-0}))
done
printf '\nTOTAL run=%s failed=%s\n' "$total" "$failed"
[ "$failed" -eq 0 ]
