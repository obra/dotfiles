#!/bin/sh
set -u
HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)
REPO=$(CDPATH= cd -- "$HERE/.." && pwd -P)
. "$HERE/assert.sh"

# os_name maps uname output to macos/linux/other.
out=$(UNAME_OVERRIDE=Darwin sh "$REPO/install.sh" --print-os)
assert_eq "macos" "$out" "Darwin -> macos"
out=$(UNAME_OVERRIDE=Linux sh "$REPO/install.sh" --print-os)
assert_eq "linux" "$out" "Linux -> linux"

# --- manifest parsing + OS filtering ---
TMP=$(mktempd)
mkdir -p "$TMP/repo" "$TMP/home"
# fake repo files
: > "$TMP/repo/common.conf"
: > "$TMP/repo/maconly.conf"
: > "$TMP/repo/linonly.conf"
cp "$REPO/install.sh" "$TMP/repo/install.sh"
cat > "$TMP/repo/manifest" <<'EOF'
# a comment
common.conf
maconly.conf   macos
linonly.conf   linux
EOF
# Run as macOS against fake HOME; list intended targets via --dry-run
out=$(UNAME_OVERRIDE=Darwin HOME="$TMP/home" sh "$TMP/repo/install.sh" --dry-run)
echo "$out" | grep -q 'common.conf'  && c=yes || c=no
echo "$out" | grep -q 'maconly.conf' && m=yes || m=no
echo "$out" | grep -q 'linonly.conf' && l=yes || l=no
assert_eq "yes" "$c" "common.conf included on macOS"
assert_eq "yes" "$m" "maconly.conf included on macOS"
assert_eq "no"  "$l" "linonly.conf excluded on macOS"
rm -rf "$TMP"

# --- dry-run makes no filesystem changes ---
TMP=$(mktempd)
mkdir -p "$TMP/repo" "$TMP/home"
: > "$TMP/repo/common.conf"
cp "$REPO/install.sh" "$TMP/repo/install.sh"
printf 'common.conf\n' > "$TMP/repo/manifest"
UNAME_OVERRIDE=Darwin HOME="$TMP/home" sh "$TMP/repo/install.sh" --dry-run >/dev/null
if [ ! -e "$TMP/home/common.conf" ] && [ ! -L "$TMP/home/common.conf" ]; then
  assert_eq "absent" "absent" "dry-run: target file not created"
else
  assert_eq "absent" "present" "dry-run: target file not created"
fi
rm -rf "$TMP"

# --- real link creation, parent dir stays real ---
TMP=$(mktempd)
mkdir -p "$TMP/repo/sub" "$TMP/home"
echo hello > "$TMP/repo/sub/nested.conf"
cp "$REPO/install.sh" "$TMP/repo/install.sh"
printf 'sub/nested.conf\n' > "$TMP/repo/manifest"
UNAME_OVERRIDE=Darwin HOME="$TMP/home" sh "$TMP/repo/install.sh" >/dev/null
assert_symlink_to "$TMP/home/sub/nested.conf" "$TMP/repo/sub/nested.conf" "nested file linked"
# parent must be a real dir, not a symlink
if [ -d "$TMP/home/sub" ] && [ ! -L "$TMP/home/sub" ]; then p=real; else p=notreal; fi
assert_eq "real" "$p" "parent dir ~/sub is a real directory"
rm -rf "$TMP"

# --- idempotency: second run makes no changes ---
TMP=$(mktempd)
mkdir -p "$TMP/repo" "$TMP/home"
echo x > "$TMP/repo/a.conf"
cp "$REPO/install.sh" "$TMP/repo/install.sh"
printf 'a.conf\n' > "$TMP/repo/manifest"
UNAME_OVERRIDE=Darwin HOME="$TMP/home" sh "$TMP/repo/install.sh" >/dev/null
out2=$(UNAME_OVERRIDE=Darwin HOME="$TMP/home" sh "$TMP/repo/install.sh")
echo "$out2" | grep -q 'linked=0' && z=yes || z=no
assert_eq "yes" "$z" "second run links nothing (idempotent)"
# no backup dir should be created on the clean second run
if [ -d "$TMP/home/.dotfiles-backup" ]; then b=exists; else b=absent; fi
assert_eq "absent" "$b" "no backup created on idempotent re-run"
rm -rf "$TMP"

# --- broken symlink at destination is replaced with correct one ---
TMP=$(mktempd)
mkdir -p "$TMP/repo" "$TMP/home"
echo "repo-content" > "$TMP/repo/x.conf"
cp "$REPO/install.sh" "$TMP/repo/install.sh"
printf 'x.conf\n' > "$TMP/repo/manifest"
# pre-create a broken symlink at the destination
ln -s "$TMP/home/does-not-exist" "$TMP/home/x.conf"
UNAME_OVERRIDE=Darwin HOME="$TMP/home" sh "$TMP/repo/install.sh" >/dev/null
assert_symlink_to "$TMP/home/x.conf" "$TMP/repo/x.conf" "broken symlink replaced with correct one"
rm -rf "$TMP"

# --- conflict: pre-existing real file is backed up ---
TMP=$(mktempd)
mkdir -p "$TMP/repo" "$TMP/home"
echo "from-repo" > "$TMP/repo/c.conf"
echo "pre-existing-user-content" > "$TMP/home/c.conf"   # real file in the way
cp "$REPO/install.sh" "$TMP/repo/install.sh"
printf 'c.conf\n' > "$TMP/repo/manifest"
UNAME_OVERRIDE=Darwin HOME="$TMP/home" sh "$TMP/repo/install.sh" >/dev/null
assert_symlink_to "$TMP/home/c.conf" "$TMP/repo/c.conf" "conflicting file replaced by symlink"
# the original content must survive in the backup dir
found=$(find "$TMP/home/.dotfiles-backup" -name c.conf -exec cat {} \; 2>/dev/null)
assert_eq "pre-existing-user-content" "$found" "original content preserved in backup"
rm -rf "$TMP"

printf 'RESULT run=%s failed=%s\n' "$TESTS_RUN" "$TESTS_FAILED"
