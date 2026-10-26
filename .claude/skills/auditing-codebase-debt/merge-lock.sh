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
# The lock is a directory (atomic mkdir) holding an "owner" file. Waiters
# queue first-come-first-served: acquire leaves a ticket (named by owner,
# holding its first arrival time) in a queue directory beside the lock, and
# only the oldest live ticket may take the lock. A ticket is live while its
# owner keeps polling; one untouched for 300s is dropped, so a waiter that
# gives up does not block the queue. Re-running acquire with the same owner
# keeps its place. acquire polls every 30s until it gets the lock or --wait
# expires (default 14400s, exit 1). A lock older than --stale seconds (default 5400) is taken
# over, since its holder has likely died. release refuses to remove a lock
# held by someone else (exit 1). Override the location with MERGE_LOCK_DIR.

set -euo pipefail

LOCK="${MERGE_LOCK_DIR:-/tmp/claude-$(id -u)/merge-lock.d}"
QUEUE="$LOCK.queue"
TICKET_LIVE=300

usage() { sed -n '2,28p' "$0" | sed 's/^# \{0,1\}//'; exit 2; }

age_of_lock() {
  local m
  m=$(stat -c %Y "$LOCK" 2>/dev/null) || { echo 0; return; }
  echo $(( $(date +%s) - m ))
}

# first_in_queue prints the owner of the oldest live ticket, dropping dead ones.
first_in_queue() {
  local now t best="" best_at=""
  now=$(date +%s)
  for t in "$QUEUE"/*; do
    [ -f "$t" ] || continue
    if [ $(( now - $(stat -c %Y "$t" 2>/dev/null || echo 0) )) -gt "$TICKET_LIVE" ]; then
      rm -f "$t"
      continue
    fi
    at=$(cat "$t" 2>/dev/null || echo "$now")
    if [ -z "$best" ] || [ "$at" -lt "$best_at" ]; then
      best=$(basename "$t"); best_at=$at
    fi
  done
  echo "$best"
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
    case "$owner" in */*|.*) echo "MERGELOCK owner may not contain / or start with ."; exit 2 ;; esac
    # A repo that moved to a merge queue retires the lock: the notice file
    # tells every waiting agent how to merge instead.
    if [ -f "$LOCK.retired" ]; then
      rm -f "$QUEUE/$owner"
      echo "MERGELOCK retired, do not retry. $(cat "$LOCK.retired")"
      exit 3
    fi
    mkdir -p "$(dirname "$LOCK")" "$QUEUE"
    ticket="$QUEUE/$owner"
    [ -f "$ticket" ] || date +%s > "$ticket"
    deadline=$(( $(date +%s) + wait ))
    announced=""
    while :; do
      touch "$ticket"
      holder=$(cat "$LOCK/owner" 2>/dev/null || echo "")
      if [ -n "$holder" ] && [ "${holder%% *}" = "$owner" ]; then
        rm -f "$ticket"
        echo "MERGELOCK already held by $owner"
        exit 0
      fi
      if [ "$(first_in_queue)" = "$owner" ] && mkdir "$LOCK" 2>/dev/null; then
        echo "$owner $(date -u +%FT%TZ)" > "$LOCK/owner"
        rm -f "$ticket"
        echo "MERGELOCK acquired by $owner"
        exit 0
      fi
      [ -n "$holder" ] || holder="none (queue ahead: $(first_in_queue))"
      if [ -d "$LOCK" ] && [ "$(age_of_lock)" -gt "$stale" ]; then
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
    rm -f "$QUEUE/$owner"
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
    q=$(ls -1 "$QUEUE" 2>/dev/null | wc -l)
    echo "MERGELOCK queue: $q waiting; next: $(first_in_queue)"
    ;;
  *) usage ;;
esac
