#!/usr/bin/env bash
# merge-lock.sh: serialize the final "merge main, push, wait for CI, merge"
# step across parallel cleanup agents that share one strict-up-to-date branch.
#
# When to use: a workflow runs many PR agents against a base branch that
# requires branches to be up to date. Without a lock, each merge makes every
# other open PR stale and agents loop on merge-main-and-wait. With it, only
# the lock holder does its final up-to-date round; everyone else keeps working
# on review rounds and queues for the lock when ready.
#
# Usage:
#   merge-lock.sh acquire <owner> [--wait SECONDS] [--stale SECONDS]
#   merge-lock.sh release <owner>
#   merge-lock.sh status
#
# The lock is a directory (atomic mkdir) holding an "owner" file.
# acquire polls every 30s until it gets the lock or --wait expires (default
# 14400s, exit 1). A lock older than --stale seconds (default 5400) is taken
# over, since its holder has likely died. release refuses to remove a lock
# held by someone else (exit 1). Override the location with MERGE_LOCK_DIR.

set -euo pipefail

LOCK="${MERGE_LOCK_DIR:-/tmp/claude-$(id -u)/merge-lock.d}"

usage() { sed -n '2,23p' "$0" | sed 's/^# \{0,1\}//'; exit 2; }

age_of_lock() {
  local m
  m=$(stat -c %Y "$LOCK" 2>/dev/null) || { echo 0; return; }
  echo $(( $(date +%s) - m ))
}

cmd="${1:-}"; shift || true
case "$cmd" in
  acquire)
    owner="${1:-}"; [ -n "$owner" ] || usage; shift
    wait=14400; stale=5400
    while [ $# -gt 0 ]; do
      case "$1" in
        --wait) wait="$2"; shift 2 ;;
        --stale) stale="$2"; shift 2 ;;
        *) usage ;;
      esac
    done
    mkdir -p "$(dirname "$LOCK")"
    deadline=$(( $(date +%s) + wait ))
    announced=""
    while :; do
      if mkdir "$LOCK" 2>/dev/null; then
        echo "$owner $(date -u +%FT%TZ)" > "$LOCK/owner"
        echo "MERGELOCK acquired by $owner"
        exit 0
      fi
      holder=$(cat "$LOCK/owner" 2>/dev/null || echo unknown)
      if [ "${holder%% *}" = "$owner" ]; then
        echo "MERGELOCK already held by $owner"
        exit 0
      fi
      if [ "$(age_of_lock)" -gt "$stale" ]; then
        echo "MERGELOCK taking over stale lock from: $holder"
        rm -rf "$LOCK"
        continue
      fi
      if [ "$holder" != "$announced" ]; then
        echo "MERGELOCK waiting; held by: $holder"
        announced="$holder"
      fi
      [ "$(date +%s)" -lt "$deadline" ] || { echo "MERGELOCK timed out waiting; held by: $holder"; exit 1; }
      sleep 30
    done
    ;;
  release)
    owner="${1:-}"; [ -n "$owner" ] || usage
    [ -d "$LOCK" ] || { echo "MERGELOCK not held"; exit 0; }
    holder=$(cat "$LOCK/owner" 2>/dev/null || echo unknown)
    if [ "${holder%% *}" != "$owner" ]; then
      echo "MERGELOCK refusing release; held by: $holder"
      exit 1
    fi
    rm -rf "$LOCK"
    echo "MERGELOCK released by $owner"
    ;;
  status)
    if [ -d "$LOCK" ]; then
      echo "MERGELOCK held by: $(cat "$LOCK/owner" 2>/dev/null || echo unknown) (age $(age_of_lock)s)"
    else
      echo "MERGELOCK free"
    fi
    ;;
  *) usage ;;
esac
