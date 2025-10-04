#!/bin/bash
# Master gardening script for skills wiki maintenance

SKILLS_DIR="${1:-$HOME/Documents/GitHub/dotfiles/.claude/skills}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "╔════════════════════════════════════════════════╗"
echo "║     Skills Wiki Gardening - Health Check      ║"
echo "╚════════════════════════════════════════════════╝"
echo ""
echo "Skills directory: $SKILLS_DIR"
echo ""

# Make scripts executable if not already
chmod +x "$SCRIPT_DIR"/*.sh 2>/dev/null

# Run all checks
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
bash "$SCRIPT_DIR/check-naming.sh" "$SKILLS_DIR"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
bash "$SCRIPT_DIR/check-links.sh" "$SKILLS_DIR"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
bash "$SCRIPT_DIR/check-index-coverage.sh" "$SKILLS_DIR"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "╔════════════════════════════════════════════════╗"
echo "║            Gardening Complete                  ║"
echo "╚════════════════════════════════════════════════╝"
echo ""
echo "Summary of issues to address:"
echo "  - Review any ❌ errors (broken references, missing skills)"
echo "  - Consider ⚠️  warnings (naming, empty directories)"
echo "  - ✅ marks indicate things are correct"
echo ""
echo "To fix issues:"
echo "  1. Broken links: Update @ references to correct paths"
echo "  2. Orphaned skills: Add to category INDEX.md"
echo "  3. Naming issues: Rename directories to kebab-case"
echo "  4. Empty dirs: Remove with 'rm -rf <dir>'"
echo "  5. Missing descriptions: Add to INDEX.md entries"
echo ""
