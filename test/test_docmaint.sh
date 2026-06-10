#!/bin/sh
# test_docmaint.sh — run the maintaining-documentation skill's Python tests.
set -u
HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)
SKILL="$HERE/../.claude/skills/maintaining-documentation"
python3 "$SKILL/scripts/docmaint_test.py" 2>&1
