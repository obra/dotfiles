#!/bin/sh
# install.sh — deploy dotfiles from this repo into $HOME per the manifest.
set -eu

REPO_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)

os_name() {
  case "${UNAME_OVERRIDE:-$(uname -s)}" in
    Darwin) echo macos ;;
    Linux)  echo linux ;;
    *)      echo other ;;
  esac
}

if [ "${1:-}" = "--print-os" ]; then
  os_name
  exit 0
fi

MANIFEST="${MANIFEST:-$REPO_DIR/manifest}"
OS=$(os_name)
DRY_RUN=0
[ "${1:-}" = "--dry-run" ] && DRY_RUN=1

process_manifest() {
  set -f  # no globbing of manifest tokens
  while IFS= read -r line || [ -n "$line" ]; do
    line=${line%%#*}                      # strip comments
    # shellcheck disable=SC2086
    set -- $line                          # split on whitespace
    [ "$#" -eq 0 ] && continue
    rel=$1
    tag=${2:-}
    if [ -n "$tag" ] && [ "$tag" != "$OS" ]; then
      continue
    fi
    link_one "$rel"
  done < "$MANIFEST"
  set +f
}

TS=$(date +%Y%m%d-%H%M%S)

BACKUP_DIR="$HOME/.dotfiles-backup/$TS"
n_linked=0; n_skipped=0; n_backed=0; n_missing=0

link_one() {
  rel=$1
  src="$REPO_DIR/$rel"
  dest="$HOME/$rel"
  if [ ! -e "$src" ] && [ ! -L "$src" ]; then
    printf 'MISSING  %s (not in repo)\n' "$rel"
    n_missing=$((n_missing + 1))
    return
  fi
  # Already correct? Use -ef (same file) so an existing link counts as correct even if it
  # points via a different path (e.g. ~/git -> ~/Documents/GitHub). -ef works on macOS sh
  # (bash) and Linux (dash/bash); it is false for a broken symlink, which then gets relinked.
  if [ -L "$dest" ] && [ "$dest" -ef "$src" ]; then
    n_skipped=$((n_skipped + 1))
    return
  fi
  if [ "$DRY_RUN" = 1 ]; then
    if [ -e "$dest" ] || [ -L "$dest" ]; then
      printf 'WOULD BACKUP+LINK  %s\n' "$rel"
    else
      printf 'WOULD LINK  %s\n' "$rel"
    fi
    return
  fi
  mkdir -p "$(dirname "$dest")"
  if [ -e "$dest" ] || [ -L "$dest" ]; then
    mkdir -p "$(dirname "$BACKUP_DIR/$rel")"
    mv "$dest" "$BACKUP_DIR/$rel"
    n_backed=$((n_backed + 1))
    printf 'BACKUP   %s -> %s\n' "$rel" "$BACKUP_DIR/$rel"
  fi
  ln -s "$src" "$dest"
  n_linked=$((n_linked + 1))
  printf 'LINK     %s\n' "$rel"
}

process_manifest
printf '\nlinked=%s skipped=%s backed_up=%s missing=%s\n' \
  "$n_linked" "$n_skipped" "$n_backed" "$n_missing"
