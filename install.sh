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

link_one() { printf 'WOULD LINK  %s\n' "$1"; }   # replaced in Task 4
process_manifest
