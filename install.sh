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
