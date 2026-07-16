#!/bin/sh
# Verify the Arq snapshot cleaner changes only live Arq snapshots and restores services.
set -u

HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)
. "$HERE/assert.sh"

SCRIPT="$HERE/../bin/arq-clear-snapshots"
TMP=$(mktempd)
trap 'rm -rf "$TMP"' EXIT HUP INT TERM

make_fake_commands() {
  case_dir=$1
  fake_bin="$case_dir/bin"
  state="$case_dir/state"
  mkdir -p "$fake_bin" "$state"
  : >"$state/snapshots"
  : >"$state/services"
  : >"$state/mounts"
  : >"$state/calls"

  cat >"$fake_bin/uname" <<'EOF'
#!/bin/sh
printf 'Darwin\n'
EOF

  cat >"$fake_bin/id" <<'EOF'
#!/bin/sh
[ "${1:-}" = -u ] && printf '501\n'
EOF

  cat >"$fake_bin/df" <<'EOF'
#!/bin/sh
printf 'Filesystem Size Used Avail Capacity Mounted on\n/dev/disk3s5 2Ti 1Ti 1Ti 50%% /System/Volumes/Data\n'
EOF

  cat >"$fake_bin/mount" <<'EOF'
#!/bin/sh
cat "$FAKE_STATE/mounts"
EOF

  cat >"$fake_bin/sudo" <<'EOF'
#!/bin/sh
printf 'sudo %s\n' "$*" >>"$FAKE_STATE/calls"
[ "${1:-}" = -v ] && exit 0
exec "$@"
EOF

  cat >"$fake_bin/launchctl" <<'EOF'
#!/bin/sh
label_from_target() {
  label=${1##*/}
  printf '%s\n' "${label%.plist}"
}

case "${1:-}" in
  print)
    label=$(label_from_target "$2")
    grep -Fxq "$label" "$FAKE_STATE/services"
    ;;
  bootout)
    label=$(label_from_target "$3")
    printf 'launchctl bootout %s\n' "$label" >>"$FAKE_STATE/calls"
    grep -Fxv "$label" "$FAKE_STATE/services" >"$FAKE_STATE/services.next" || true
    mv "$FAKE_STATE/services.next" "$FAKE_STATE/services"
    ;;
  bootstrap)
    label=$(label_from_target "$3")
    printf 'launchctl bootstrap %s\n' "$label" >>"$FAKE_STATE/calls"
    grep -Fxq "$label" "$FAKE_STATE/services" || printf '%s\n' "$label" >>"$FAKE_STATE/services"
    ;;
  *) exit 2 ;;
esac
EOF

  cat >"$fake_bin/diskutil" <<'EOF'
#!/bin/sh
if [ "${1:-}" = info ]; then
  printf '   Device Identifier:         disk3s5\n'
elif [ "${1:-}" = apfs ] && [ "${2:-}" = listSnapshots ]; then
  list_count=$(cat "$FAKE_STATE/list_count" 2>/dev/null || printf '0')
  list_count=$((list_count + 1))
  printf '%s\n' "$list_count" >"$FAKE_STATE/list_count"
  case "${FAKE_LIST_MODE:-list}" in
    fail) exit 1 ;;
    fail_after_first) [ "$list_count" -gt 1 ] && exit 1 ;;
  esac
  while IFS= read -r snapshot; do
    [ -n "$snapshot" ] && printf '    Name:        %s\n' "$snapshot"
  done <"$FAKE_STATE/snapshots"
elif [ "${1:-}" = unmount ]; then
  printf 'diskutil unmount %s\n' "$*" >>"$FAKE_STATE/calls"
elif [ "${1:-}" = apfs ] && [ "${2:-}" = deleteSnapshot ]; then
  snapshot=
  previous=
  for argument in "$@"; do
    [ "$previous" = -name ] && snapshot=$argument
    previous=$argument
  done
  printf 'diskutil delete %s\n' "$snapshot" >>"$FAKE_STATE/calls"
  case "${FAKE_DELETE_MODE:-delete}" in
    fail) exit 1 ;;
    noop) exit 0 ;;
    delete)
      grep -Fxv "$snapshot" "$FAKE_STATE/snapshots" >"$FAKE_STATE/snapshots.next" || true
      mv "$FAKE_STATE/snapshots.next" "$FAKE_STATE/snapshots"
      ;;
  esac
else
  exit 2
fi
EOF

  chmod +x "$fake_bin"/*
}

new_case() {
  case_dir="$TMP/$1"
  make_fake_commands "$case_dir"
  FAKE_STATE="$case_dir/state"
  PATH="$case_dir/bin:/usr/bin:/bin:/usr/sbin:/sbin"
  export FAKE_STATE PATH
}

run_cleaner() {
  output=$("$SCRIPT" "$@" 2>&1)
  status=$?
}

services='com.haystacksoftware.ArqMonitor
com.haystacksoftware.arqagent'

# No matching snapshot is a successful no-op before sudo or service changes.
new_case no_snapshot
printf 'com.apple.os.update-example\n' >"$FAKE_STATE/snapshots"
run_cleaner --yes
assert_eq 0 "$status" "no Arq snapshot is a successful no-op"
assert_eq "" "$(cat "$FAKE_STATE/calls")" "no-op does not acquire sudo or change services"

# Failure to inspect APFS state must never be reported as an empty snapshot set.
new_case list_failure
FAKE_LIST_MODE=fail
export FAKE_LIST_MODE
run_cleaner --yes
unset FAKE_LIST_MODE
assert_eq 1 "$status" "snapshot listing failure exits nonzero"
assert_eq "" "$(cat "$FAKE_STATE/calls")" "listing failure makes no privileged or service changes"

# Exact Arq-prefixed snapshots are removed while unrelated snapshots remain.
new_case happy
cat >"$FAKE_STATE/snapshots" <<'EOF'
com.apple.os.update-example
com_haystacksoftware_arqagent_6565D232-1A34-457F-B2F9-06901BBFF103_1
com_haystacksoftware_arqagent_6565D232-1A34-457F-B2F9-06901BBFF103_2
EOF
printf '%s\n' "$services" >"$FAKE_STATE/services"
printf '/dev/disk9s1 on /Library/Application Support/ArqAgentAPFS.noindex/6565D232-1A34-457F-B2F9-06901BBFF103_1 (apfs, local)\n' >"$FAKE_STATE/mounts"
run_cleaner --yes
assert_eq 0 "$status" "matching snapshots are cleared"
assert_eq "com.apple.os.update-example" "$(cat "$FAKE_STATE/snapshots")" "unrelated snapshot remains"
assert_eq "$services" "$(sort "$FAKE_STATE/services")" "loaded Arq services are restored"
delete_count=$(grep -c '^diskutil delete com_haystacksoftware_arqagent_' "$FAKE_STATE/calls" || true)
assert_eq 2 "$delete_count" "each discovered Arq snapshot is deleted"
os_delete_count=$(grep -c '^diskutil delete com.apple' "$FAKE_STATE/calls" || true)
assert_eq 0 "$os_delete_count" "OS snapshots are never deleted"
unmount_count=$(grep -c '^diskutil unmount ' "$FAKE_STATE/calls" || true)
assert_eq 1 "$unmount_count" "matching Arq mount is unmounted"

# Declining confirmation leaves snapshots and services untouched.
new_case declined
printf 'com_haystacksoftware_arqagent_VOLUME_1\n' >"$FAKE_STATE/snapshots"
printf '%s\n' "$services" >"$FAKE_STATE/services"
output=$(printf 'n\n' | "$SCRIPT" 2>&1)
status=$?
assert_eq 1 "$status" "declined confirmation exits nonzero"
assert_eq "com_haystacksoftware_arqagent_VOLUME_1" "$(cat "$FAKE_STATE/snapshots")" "decline retains snapshot"
assert_eq "" "$(cat "$FAKE_STATE/calls")" "decline makes no privileged or service changes"

# A deletion error still restores every service that was stopped.
new_case delete_failure
printf 'com_haystacksoftware_arqagent_VOLUME_1\n' >"$FAKE_STATE/snapshots"
printf '%s\n' "$services" >"$FAKE_STATE/services"
FAKE_DELETE_MODE=fail run_cleaner --yes
assert_eq 1 "$status" "deletion error exits nonzero"
assert_eq "$services" "$(sort "$FAKE_STATE/services")" "services are restored after deletion error"

# A command that reports deletion but leaves the snapshot is caught by verification.
new_case verification_failure
printf 'com_haystacksoftware_arqagent_VOLUME_1\n' >"$FAKE_STATE/snapshots"
printf '%s\n' "$services" >"$FAKE_STATE/services"
FAKE_DELETE_MODE=noop run_cleaner --yes
assert_eq 1 "$status" "remaining snapshot fails verification"
assert_eq "$services" "$(sort "$FAKE_STATE/services")" "services are restored after verification error"

# Failure to obtain the post-deletion listing must not be reported as verified success.
new_case verification_list_failure
printf 'com_haystacksoftware_arqagent_VOLUME_1\n' >"$FAKE_STATE/snapshots"
printf '%s\n' "$services" >"$FAKE_STATE/services"
FAKE_LIST_MODE=fail_after_first
export FAKE_LIST_MODE
run_cleaner --yes
unset FAKE_LIST_MODE
assert_eq 1 "$status" "verification listing failure exits nonzero"
assert_eq "$services" "$(sort "$FAKE_STATE/services")" "services are restored after listing error"

printf 'RESULT run=%s failed=%s\n' "$TESTS_RUN" "$TESTS_FAILED"
[ "$TESTS_FAILED" -eq 0 ]
