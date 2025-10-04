#!/bin/bash
# Master gardening script for skills wiki maintenance

SKILLS_DIR="${1:-$HOME/Documents/GitHub/dotfiles/.claude/skills}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=== Skills Wiki Health Check ==="
echo ""

# Make scripts executable if not already
chmod +x "$SCRIPT_DIR"/*.sh 2>/dev/null

# Run all checks
bash "$SCRIPT_DIR/check-naming.sh" "$SKILLS_DIR"
echo ""

bash "$SCRIPT_DIR/check-links.sh" "$SKILLS_DIR"
echo ""

bash "$SCRIPT_DIR/check-index-coverage.sh" "$SKILLS_DIR"

echo ""
echo "=== Health Check Complete ==="
echo ""
echo "Fix: ❌ errors (broken/missing) | Consider: ⚠️  warnings | ✅ = correct"
