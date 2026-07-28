#!/bin/sh
# test_mac_bootstrap.sh — verify the new-Mac bootstrap: installs CLT, Homebrew,
# clones the content repos, deploys symlinks, runs brew bundle / mise / the
# Claude Code installer on a fresh machine; skips every installer when already
# satisfied; refuses non-macOS; errors usefully when a clone fails.
set -u
HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)
. "$HERE/assert.sh"

SCRIPT="$HERE/../bin/mac-bootstrap"
TMP=$(mktempd)
trap 'rm -rf "$TMP"' EXIT HUP INT TERM

# Each case gets fake commands on PATH that append to $FAKE_STATE/calls, plus a
# fake $HOME. The repo-clone fake materializes a homedir-manager bootstrap that
# "installs" a fake homedir-manager; fake installers create the tools they claim
# to install, so the script's end-of-run verification sees a coherent world.
make_case() {
  case_dir=$1
  fake_bin="$case_dir/bin"
  state="$case_dir/state"
  home="$case_dir/home"
  mkdir -p "$fake_bin" "$state" "$home"
  : >"$state/calls"

  cat >"$state/homedir-manager.tmpl" <<'EOF'
#!/bin/sh
printf 'homedir-manager %s\n' "$*" >>"$FAKE_STATE/calls"
if [ "${1:-}" = install ]; then
  mkdir -p "$HOME/.config/homebrew"
  : >"$HOME/.config/homebrew/Brewfile"
fi
EOF

  cat >"$state/mise.tmpl" <<'EOF'
#!/bin/sh
printf 'mise %s\n' "$*" >>"$FAKE_STATE/calls"
EOF

  cat >"$fake_bin/uname" <<'EOF'
#!/bin/sh
cat "$FAKE_STATE/uname"
EOF
  printf 'Darwin\n' >"$state/uname"

  cat >"$fake_bin/xcode-select" <<'EOF'
#!/bin/sh
[ -e "$FAKE_STATE/clt-installed" ]
EOF

  cat >"$fake_bin/softwareupdate" <<'EOF'
#!/bin/sh
printf 'softwareupdate %s\n' "$*" >>"$FAKE_STATE/calls"
[ "${1:-}" = -l ] && printf '* Label: Command Line Tools for Xcode-16.0\n'
exit 0
EOF

  cat >"$fake_bin/sudo" <<'EOF'
#!/bin/sh
printf 'sudo %s\n' "$*" >>"$FAKE_STATE/calls"
[ "${1:-}" = -v ] && exit 0
exec "$@"
EOF

  # Emits installer stubs: the Homebrew one drops a fake brew, the Claude one a
  # fake claude, both logging that they ran.
  cat >"$fake_bin/curl" <<'EOF'
#!/bin/sh
for last; do :; done
printf 'curl %s\n' "$last" >>"$FAKE_STATE/calls"
case "$last" in
  *Homebrew*)
    printf '%s\n' \
      'printf "brew-installer-ran\n" >>"$FAKE_STATE/calls"' \
      'cp "$FAKE_STATE/brew.tmpl" "$FAKE_BIN/brew"; chmod +x "$FAKE_BIN/brew"'
    ;;
  *claude*)
    printf '%s\n' \
      'printf "claude-installer-ran\n" >>"$FAKE_STATE/calls"' \
      'printf "#!/bin/sh\ntrue\n" >"$FAKE_BIN/claude"; chmod +x "$FAKE_BIN/claude"'
    ;;
esac
EOF

  cat >"$state/brew.tmpl" <<'EOF'
#!/bin/sh
printf 'brew %s\n' "$*" >>"$FAKE_STATE/calls"
if [ "${1:-}" = bundle ] && [ ! -e "$FAKE_BIN/mise" ]; then
  cp "$FAKE_STATE/mise.tmpl" "$FAKE_BIN/mise"; chmod +x "$FAKE_BIN/mise"
fi
EOF

  cat >"$fake_bin/git" <<'EOF'
#!/bin/sh
printf 'git %s\n' "$*" >>"$FAKE_STATE/calls"
[ "${1:-}" = clone ] || exit 0
[ -e "$FAKE_STATE/fail-clone" ] && { echo "fatal: could not read from remote" >&2; exit 128; }
mkdir -p "$3/.git"
case "$2" in
  *homedir-manager*)
    cat >"$3/bootstrap" <<'B'
#!/bin/sh
printf 'homedir-manager-bootstrap\n' >>"$FAKE_STATE/calls"
cp "$FAKE_STATE/homedir-manager.tmpl" "$FAKE_BIN/homedir-manager"
chmod +x "$FAKE_BIN/homedir-manager"
B
    chmod +x "$3/bootstrap"
    ;;
esac
EOF

  chmod +x "$fake_bin"/*
}

run_case() { # case_dir args...
  d=$1; shift
  # HOMEBREW_PREFIX points at an empty dir so the dev machine's real
  # /opt/homebrew can't leak into the test.
  env -i HOME="$d/home" PATH="$d/bin:/usr/bin:/bin" \
    FAKE_STATE="$d/state" FAKE_BIN="$d/bin" HOMEBREW_PREFIX="$d/no-homebrew" \
    sh "$SCRIPT" "$@" 2>&1
}

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

# --- non-macOS is refused ---------------------------------------------------
make_case "$TMP/linux"
printf 'Linux\n' >"$TMP/linux/state/uname"
out=$(run_case "$TMP/linux")
status=$?
assert_eq 1 "$status" "non-macOS exits nonzero"
if printf '%s\n' "$out" | grep -qi 'macos'; then
  assert_eq "names macos" "names macos" "non-macOS error mentions macOS"
else
  assert_eq "names macos" "$out" "non-macOS error mentions macOS"
fi

# --- fresh machine: everything installs, in order ---------------------------
make_case "$TMP/fresh"
out=$(run_case "$TMP/fresh")
status=$?
calls="$TMP/fresh/state/calls"
assert_eq 0 "$status" "fresh machine bootstrap exits 0"
for want in \
  'softwareupdate -i Command Line Tools for Xcode-16.0' \
  'brew-installer-ran' \
  'homedir-manager-bootstrap' \
  'homedir-manager install' \
  'claude-installer-ran'
do
  if grep -Fq "$want" "$calls"; then
    assert_eq "called" "called" "fresh run performs: $want"
  else
    assert_eq "called" "missing" "fresh run performs: $want"
  fi
done
if grep -Eq '^brew bundle' "$calls" && grep -Eq '^mise install' "$calls"; then
  assert_eq "called" "called" "fresh run performs: brew bundle + mise install"
else
  assert_eq "called" "missing" "fresh run performs: brew bundle + mise install"
fi
for repo in homedir-manager dotfiles dotfiles-private; do
  if grep -q "clone git@github.com:obra/$repo" "$calls"; then
    assert_eq "cloned" "cloned" "fresh run clones $repo"
  else
    assert_eq "cloned" "missing" "fresh run clones $repo"
  fi
done
# CLT must precede the Homebrew installer, which must precede brew bundle.
clt_line=$(grep -n 'softwareupdate -i' "$calls" | head -1 | cut -d: -f1)
brewinst_line=$(grep -n 'brew-installer-ran' "$calls" | head -1 | cut -d: -f1)
bundle_line=$(grep -n '^brew bundle' "$calls" | head -1 | cut -d: -f1)
if [ "$clt_line" -lt "$brewinst_line" ] && [ "$brewinst_line" -lt "$bundle_line" ]; then
  assert_eq "ordered" "ordered" "CLT -> Homebrew -> brew bundle order"
else
  assert_eq "ordered" "$clt_line/$brewinst_line/$bundle_line" "CLT -> Homebrew -> brew bundle order"
fi

# --- already-bootstrapped machine: no installers re-run ---------------------
make_case "$TMP/idem"
: >"$TMP/idem/state/clt-installed"
cp "$TMP/idem/state/brew.tmpl" "$TMP/idem/bin/brew"
cp "$TMP/idem/state/mise.tmpl" "$TMP/idem/bin/mise"
cp "$TMP/idem/state/homedir-manager.tmpl" "$TMP/idem/bin/homedir-manager"
printf '#!/bin/sh\ntrue\n' >"$TMP/idem/bin/claude"
chmod +x "$TMP/idem/bin/brew" "$TMP/idem/bin/mise" "$TMP/idem/bin/homedir-manager" "$TMP/idem/bin/claude"
for repo in homedir-manager dotfiles dotfiles-private; do
  mkdir -p "$TMP/idem/home/git/$repo/.git"
done
out=$(run_case "$TMP/idem")
status=$?
calls="$TMP/idem/state/calls"
assert_eq 0 "$status" "already-bootstrapped run exits 0"
for absent in 'softwareupdate' 'curl' 'homedir-manager-bootstrap' 'git clone'; do
  if grep -q "$absent" "$calls"; then
    assert_eq "skipped" "ran" "already-bootstrapped run skips: $absent"
  else
    assert_eq "skipped" "skipped" "already-bootstrapped run skips: $absent"
  fi
done
for want in 'homedir-manager install' 'brew bundle' 'mise install'; do
  if grep -q "^$want" "$calls"; then
    assert_eq "called" "called" "already-bootstrapped run still performs: $want"
  else
    assert_eq "called" "missing" "already-bootstrapped run still performs: $want"
  fi
done

# --- clone failure errors usefully ------------------------------------------
make_case "$TMP/badclone"
: >"$TMP/badclone/state/clt-installed"
cp "$TMP/badclone/state/brew.tmpl" "$TMP/badclone/bin/brew"
chmod +x "$TMP/badclone/bin/brew"
: >"$TMP/badclone/state/fail-clone"
out=$(run_case "$TMP/badclone")
status=$?
assert_eq 1 "$status" "clone failure exits nonzero"
if printf '%s\n' "$out" | grep -q 'homedir-manager'; then
  assert_eq "names repo" "names repo" "clone failure names the repo"
else
  assert_eq "names repo" "$out" "clone failure names the repo"
fi

printf 'RESULT run=%s failed=%s\n' "$TESTS_RUN" "$TESTS_FAILED"
[ "$TESTS_FAILED" -eq 0 ]
