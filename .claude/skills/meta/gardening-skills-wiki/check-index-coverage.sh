#!/bin/bash
# Check that all skills are properly listed in INDEX files

SKILLS_DIR="${1:-$HOME/Documents/GitHub/dotfiles/.claude/skills}"

echo "=== Checking INDEX coverage ==="
echo "Skills directory: $SKILLS_DIR"
echo ""

echo "## Checking category INDEX files..."
# For each category with an INDEX
for category_dir in "$SKILLS_DIR"/*/; do
    category=$(basename "$category_dir")

    # Skip if not a directory
    [[ ! -d "$category_dir" ]] && continue

    index_file="$category_dir/INDEX.md"

    # Skip if no INDEX (meta directories might not have one)
    [[ ! -f "$index_file" ]] && continue

    echo "### $category/INDEX.md"

    # Find all SKILL.md files in this category
    skill_count=0
    indexed_count=0
    missing_count=0

    while IFS= read -r skill_file; do
        skill_count=$((skill_count + 1))
        skill_name=$(basename $(dirname "$skill_file"))

        # Check if skill is referenced in INDEX
        if grep -q "@$skill_name/SKILL.md" "$index_file"; then
            indexed_count=$((indexed_count + 1))
        else
            echo "  ❌ NOT INDEXED: $skill_name/SKILL.md"
            missing_count=$((missing_count + 1))
        fi
    done < <(find "$category_dir" -mindepth 2 -type f -name "SKILL.md")

    if [ $skill_count -eq 0 ]; then
        echo "  ℹ️  No skills in this category"
    elif [ $missing_count -eq 0 ]; then
        echo "  ✅ All $skill_count skills indexed"
    else
        echo "  ⚠️  $missing_count/$skill_count skills missing from INDEX"
    fi

    echo ""
done

echo "## Checking main INDEX.md..."
main_index="$SKILLS_DIR/INDEX.md"

if [[ ! -f "$main_index" ]]; then
    echo "  ❌ Main INDEX.md missing!"
else
    # Check that all categories with INDEX files are listed
    for category_dir in "$SKILLS_DIR"/*/; do
        category=$(basename "$category_dir")

        [[ ! -d "$category_dir" ]] && continue

        index_file="$category_dir/INDEX.md"
        [[ ! -f "$index_file" ]] && continue

        if grep -q "@$category/INDEX.md" "$main_index"; then
            echo "  ✅ $category linked in main INDEX"
        else
            echo "  ❌ MISSING: @$category/INDEX.md not in main INDEX"
        fi
    done
fi

echo ""
echo "## Checking for description/when_to_use in INDEX entries..."
# Verify INDEX entries have descriptions
find "$SKILLS_DIR" -type f -name "INDEX.md" | while read -r index_file; do
    category=$(basename $(dirname "$index_file"))

    # Extract skill references
    grep -o '@[a-zA-Z0-9-]*/SKILL\.md' "$index_file" | while read -r ref; do
        skill_name=${ref#@}
        skill_name=${skill_name%/SKILL.md}

        # Get the line with the reference
        line_num=$(grep -n "$ref" "$index_file" | cut -d: -f1)

        # Check if there's a description on the same line or next line
        description=$(sed -n "${line_num}p" "$index_file" | sed "s|.*$ref *- *||")

        if [[ -z "$description" || "$description" == *"$ref"* ]]; then
            # No description on same line, check next line
            next_line=$((line_num + 1))
            description=$(sed -n "${next_line}p" "$index_file")

            if [[ -z "$description" ]]; then
                echo "  ⚠️  NO DESCRIPTION: $category/INDEX.md reference to $skill_name"
            fi
        fi
    done
done

echo ""
echo "=== INDEX coverage check complete ==="
