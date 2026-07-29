#!/bin/sh
# Verify bw-paste stages Bitwarden fields on the clipboard one at a time
# without ever writing a secret value to the terminal.
set -u

HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)
. "$HERE/assert.sh"

SCRIPT="$HERE/../bin/bw-paste"
TMP=$(mktempd)
trap 'rm -rf "$TMP"' EXIT HUP INT TERM

make_fake_commands() {
  case_dir=$1
  fake_bin="$case_dir/bin"
  state="$case_dir/state"
  mkdir -p "$fake_bin" "$state"
  : >"$state/calls"
  : >"$state/values"
  printf '0\n' >"$state/clip_count"

  # bw resolves "get FIELD ITEM" from FIELD|ITEM|VALUE lines in the values
  # file and records the session it was invoked with.
  cat >"$fake_bin/bw" <<'EOF'
#!/bin/sh
printf 'bw %s session=%s\n' "$*" "${BW_SESSION:-unset}" >>"$FAKE_STATE/calls"
[ "${1:-}" = get ] || exit 2
line=$(grep "^$2|$3|" "$FAKE_STATE/values") || { printf 'Not found.\n' >&2; exit 1; }
printf '%s' "${line##*|}"
EOF

  cat >"$fake_bin/bw-unlock" <<'EOF'
#!/bin/sh
printf 'bw-unlock\n' >>"$FAKE_STATE/calls"
printf 'fake-session-token\n'
EOF

  # pbcopy snapshots each clipboard write to a numbered file.
  cat >"$fake_bin/pbcopy" <<'EOF'
#!/bin/sh
n=$(cat "$FAKE_STATE/clip_count")
n=$((n + 1))
printf '%s\n' "$n" >"$FAKE_STATE/clip_count"
cat >"$FAKE_STATE/clip.$n"
EOF

  chmod +x "$fake_bin"/*
}

new_case() {
  case_dir="$TMP/$1"
  make_fake_commands "$case_dir"
  FAKE_STATE="$case_dir/state"
  PATH="$case_dir/bin:/usr/bin:/bin"
  export FAKE_STATE PATH
}

clip() { cat "$FAKE_STATE/clip.$1" 2>/dev/null; }
clip_count() { cat "$FAKE_STATE/clip_count"; }
unlock_calls() { grep -c '^bw-unlock$' "$FAKE_STATE/calls" || true; }

unset BW_SESSION

# --- help and argument errors -----------------------------------------------
new_case help
out=$("$SCRIPT" --help 2>&1)
status=$?
assert_eq 0 "$status" "--help exits 0"
case $out in
  *usage:*) assert_eq "usage" "usage" "--help prints usage" ;;
  *) assert_eq "usage" "$out" "--help prints usage" ;;
esac

new_case noargs
out=$("$SCRIPT" 2>&1)
status=$?
assert_eq 1 "$status" "no arguments exits nonzero"
assert_eq 0 "$(clip_count)" "no arguments stages nothing"

new_case badspec
out=$("$SCRIPT" 'passwordArq' 2>&1)
status=$?
assert_eq 1 "$status" "spec without colon exits nonzero"
case $out in
  *passwordArq*) assert_eq "names spec" "names spec" "error names the bad spec" ;;
  *) assert_eq "names spec" "$out" "error names the bad spec" ;;
esac
assert_eq "" "$(cat "$FAKE_STATE/calls")" "bad spec runs neither bw nor bw-unlock"
assert_eq 0 "$(clip_count)" "bad spec stages nothing"

# --- happy path -------------------------------------------------------------
new_case happy
cat >"$FAKE_STATE/values" <<'EOF'
username|Arq key|AKIAFAKE
password|Arq key|sekrit-alpha
EOF
out=$(printf '\n\n' | "$SCRIPT" 'username:Arq key' 'password:Arq key' 2>&1)
status=$?
assert_eq 0 "$status" "happy path exits 0"
assert_eq "AKIAFAKE" "$(clip 1)" "first field staged first"
assert_eq "sekrit-alpha" "$(clip 2)" "second field staged second"
assert_eq "" "$(clip 3)" "clipboard cleared at end"
assert_eq 3 "$(clip_count)" "no clipboard writes beyond fields plus clear"
case $out in
  *'username of "Arq key"'*) assert_eq "prompted" "prompted" "prompt names field and item" ;;
  *) assert_eq "prompted" "$out" "prompt names field and item" ;;
esac
case $out in
  *AKIAFAKE*|*sekrit-alpha*) assert_eq "no secrets" "$out" "secret values never reach the terminal" ;;
  *) assert_eq "no secrets" "no secrets" "secret values never reach the terminal" ;;
esac
assert_eq 1 "$(unlock_calls)" "bw-unlock runs once for the whole walk"
sessions=$(grep -c 'session=fake-session-token$' "$FAKE_STATE/calls" || true)
assert_eq 2 "$sessions" "every bw get reuses the unlocked session"

# --- an existing BW_SESSION is reused ---------------------------------------
new_case session
printf 'username|Arq key|AKIAFAKE\n' >"$FAKE_STATE/values"
out=$(printf '\n' | BW_SESSION=preset "$SCRIPT" 'username:Arq key' 2>&1)
status=$?
assert_eq 0 "$status" "preset session exits 0"
assert_eq 0 "$(unlock_calls)" "preset session skips bw-unlock"
sessions=$(grep -c 'session=preset$' "$FAKE_STATE/calls" || true)
assert_eq 1 "$sessions" "bw get uses the preset session"

# --- a fetch failure names the spec and still clears the clipboard ----------
new_case fetch_failure
printf 'username|Arq key|AKIAFAKE\n' >"$FAKE_STATE/values"
out=$(printf '\n\n' | "$SCRIPT" 'username:Arq key' 'password:Arq key' 2>&1)
status=$?
assert_eq 1 "$status" "fetch failure exits nonzero"
case $out in
  *'password'*'Arq key'*) assert_eq "names spec" "names spec" "failure names the missing field" ;;
  *) assert_eq "names spec" "$out" "failure names the missing field" ;;
esac
assert_eq 2 "$(clip_count)" "failure clears the clipboard after staging"
assert_eq "" "$(clip 2)" "clipboard is empty after failure"

# --- missing pbcopy is reported before anything runs ------------------------
new_case nopbcopy
rm "$case_dir/bin/pbcopy"
out=$(PATH="$case_dir/bin:/bin" "$SCRIPT" 'username:Arq key' 2>&1)
status=$?
assert_eq 1 "$status" "missing pbcopy exits nonzero"
case $out in
  *pbcopy*) assert_eq "names pbcopy" "names pbcopy" "error names pbcopy" ;;
  *) assert_eq "names pbcopy" "$out" "error names pbcopy" ;;
esac
assert_eq "" "$(cat "$FAKE_STATE/calls")" "missing pbcopy runs neither bw nor bw-unlock"

printf 'RESULT run=%s failed=%s\n' "$TESTS_RUN" "$TESTS_FAILED"
[ "$TESTS_FAILED" -eq 0 ]
