#!/bin/bash
# Check for broken or invalid links in skills wiki

SKILLS_DIR="${1:-$HOME/Documents/GitHub/dotfiles/.claude/skills}"

echo "## Links & References"
broken_refs=0

while IFS= read -r file; do
    # Extract @ references - must start line, be after space/paren/dash, or be standalone
    # Exclude: emails, decorators, code examples with @staticmethod/@example, paths in code blocks
    grep -E '(^|[ \(>-])@[a-zA-Z0-9._/-]+\.(md|sh|ts|js|py)' "$file" | \
        grep -v '@[a-zA-Z0-9._%+-]*@' | \
        grep -v 'email.*@' | \
        grep -o '@[a-zA-Z0-9._/-]+\.(md|sh|ts|js|py)' | while read -r ref; do
        # Remove leading @
        ref_path="${ref#@}"

        # Handle different reference types
        if [[ "$ref_path" == ../* ]]; then
            # Relative reference - resolve from file's directory
            file_dir=$(dirname "$file")
            full_path="$file_dir/$ref_path"
        elif [[ "$ref_path" == ~/* ]]; then
            # Home directory reference
            full_path="${ref_path/#\~/$HOME}"
        else
            # Assume relative to current file's directory
            file_dir=$(dirname "$file")
            full_path="$file_dir/$ref_path"
        fi

        # Normalize path
        full_path=$(cd "$(dirname "$full_path")" 2>/dev/null && pwd)/$(basename "$full_path") 2>/dev/null

        # Check if target exists
        if [[ ! -e "$full_path" ]]; then
            echo "  ❌ BROKEN: $ref in $(basename $(dirname "$file"))/$(basename "$file")"
            echo "     Target: $full_path"
            broken_refs=$((broken_refs + 1))
        fi
    done
done < <(find "$SKILLS_DIR" -type f -name "*.md")

[ $broken_refs -eq 0 ] && echo "  ✅ @ references OK" || echo "  ⚠️  $broken_refs broken references"

echo ""
# Verify all skills mentioned in INDEX files exist
find "$SKILLS_DIR" -type f -name "INDEX.md" | while read -r index_file; do
    index_dir=$(dirname "$index_file")

    # Extract skill references (format: @skill-name/SKILL.md)
    grep -o '@[a-zA-Z0-9-]*/SKILL\.md' "$index_file" | while read -r skill_ref; do
        skill_path="$index_dir/${skill_ref#@}"

        if [[ ! -f "$skill_path" ]]; then
            echo "  ❌ BROKEN: $skill_ref in $(basename "$index_dir")/INDEX.md"
            echo "     Expected: $skill_path"
        fi
    done
done

echo ""
find "$SKILLS_DIR" -type f -path "*/*/SKILL.md" | while read -r skill_file; do
    skill_dir=$(basename $(dirname "$skill_file"))
    category_dir=$(dirname $(dirname "$skill_file"))
    index_file="$category_dir/INDEX.md"

    if [[ -f "$index_file" ]]; then
        if ! grep -q "@$skill_dir/SKILL.md" "$index_file"; then
            echo "  ⚠️  ORPHANED: $skill_dir/SKILL.md not in $(basename "$category_dir")/INDEX.md"
        fi
    fi
done
