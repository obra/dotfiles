# assert.sh — minimal assertions for the plain-sh test harness.
# Each assert prints PASS/FAIL and increments globals TESTS_RUN / TESTS_FAILED.
TESTS_RUN=0
TESTS_FAILED=0

assert_eq() { # expected actual message
  TESTS_RUN=$((TESTS_RUN + 1))
  if [ "$1" = "$2" ]; then
    printf '  PASS: %s\n' "$3"
  else
    printf '  FAIL: %s\n    expected: [%s]\n    actual:   [%s]\n' "$3" "$1" "$2"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
}

assert_symlink_to() { # link target message
  TESTS_RUN=$((TESTS_RUN + 1))
  if [ -L "$1" ] && [ "$(readlink "$1")" = "$2" ]; then
    printf '  PASS: %s\n' "$3"
  else
    printf '  FAIL: %s\n    %s is not a symlink to %s (readlink: %s)\n' \
      "$3" "$1" "$2" "$(readlink "$1" 2>/dev/null)"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
}

assert_file_exists() { # path message
  TESTS_RUN=$((TESTS_RUN + 1))
  if [ -e "$1" ]; then
    printf '  PASS: %s\n' "$2"
  else
    printf '  FAIL: %s\n    expected file to exist: %s\n' "$2" "$1"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
}

# mktempd — make a temp dir and return its PHYSICAL path, so symlink assertions
# don't trip over macOS /var -> /private/var (install.sh resolves repo dir with pwd -P).
mktempd() { d=$(mktemp -d); (CDPATH= cd -- "$d" && pwd -P); }
