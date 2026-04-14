#!/usr/bin/env bash
# Validate all skills/*/SKILL.md files for required frontmatter and constraints.
# Exit code 1 if any skill fails validation.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SKILL_PATTERN="$REPO_ROOT/skills/*/SKILL.md"
FAILED=0
CHECKED=0

for skill_file in $SKILL_PATTERN; do
  [ -f "$skill_file" ] || continue
  CHECKED=$((CHECKED + 1))

  # Derive expected name from parent directory
  dir_name="$(basename "$(dirname "$skill_file")")"
  errors=""

  # ---------- Extract YAML frontmatter ----------
  # Frontmatter is between the first two "---" lines
  first_line=$(head -1 "$skill_file")
  if [ "$first_line" != "---" ]; then
    errors="${errors}  - Missing YAML frontmatter opening ---\n"
    echo "FAIL  $dir_name"
    echo -e "$errors"
    FAILED=$((FAILED + 1))
    continue
  fi

  # Extract frontmatter (lines between first and second ---)
  frontmatter=$(awk 'BEGIN{found=0} /^---$/{found++; next} found==1{print} found>=2{exit}' "$skill_file")

  if [ -z "$frontmatter" ]; then
    errors="${errors}  - Empty or missing YAML frontmatter\n"
    echo "FAIL  $dir_name"
    echo -e "$errors"
    FAILED=$((FAILED + 1))
    continue
  fi

  # ---------- Extract name field ----------
  # Handle simple "name: value" (not multiline)
  name_value=$(echo "$frontmatter" | awk '/^name:/{gsub(/^name:[[:space:]]*/, ""); print; exit}')

  if [ -z "$name_value" ]; then
    errors="${errors}  - Missing required field: name\n"
  else
    # Check lowercase-hyphenated pattern
    if ! echo "$name_value" | grep -qE -- '^[a-z][a-z0-9-]*$'; then
      errors="${errors}  - name '$name_value' does not match ^[a-z][a-z0-9-]*$ (must be lowercase-hyphenated)\n"
    fi
    # Check name matches directory
    if [ "$name_value" != "$dir_name" ]; then
      errors="${errors}  - name '$name_value' does not match directory name '$dir_name'\n"
    fi
  fi

  # ---------- Extract description field ----------
  # Description can be a single line or a YAML multiline block (>- or |-)
  desc_value=$(awk '
    BEGIN { in_desc=0; desc="" }
    /^description:/ {
      # Check for inline value
      sub(/^description:[[:space:]]*/, "")
      if ($0 != "" && $0 !~ /^[>|]-?$/) {
        desc = $0
      }
      in_desc = 1
      next
    }
    in_desc == 1 {
      # If line starts with a non-space char (new key), stop
      if ($0 ~ /^[a-zA-Z]/) { exit }
      # Accumulate continuation lines
      gsub(/^[[:space:]]+/, "")
      if (desc != "") desc = desc " "
      desc = desc $0
    }
    END { print desc }
  ' <<< "$frontmatter")

  if [ -z "$desc_value" ]; then
    errors="${errors}  - Missing required field: description\n"
  else
    desc_len=${#desc_value}
    if [ "$desc_len" -gt 1024 ]; then
      errors="${errors}  - description is $desc_len chars (max 1024)\n"
    fi
  fi

  # ---------- Check body line count ----------
  total_lines=$(wc -l < "$skill_file" | tr -d ' ')
  # Body starts after the second ---
  frontmatter_end=$(awk '/^---$/{count++; if(count==2){print NR; exit}}' "$skill_file")
  if [ -n "$frontmatter_end" ]; then
    body_lines=$((total_lines - frontmatter_end))
  else
    body_lines=$total_lines
  fi

  if [ "$body_lines" -gt 500 ]; then
    errors="${errors}  - Body is $body_lines lines (max 500)\n"
  fi

  # ---------- Report ----------
  if [ -n "$errors" ]; then
    echo "FAIL  $dir_name"
    echo -e "$errors"
    FAILED=$((FAILED + 1))
  else
    echo "PASS  $dir_name"
  fi
done

echo ""
echo "Checked $CHECKED skill(s): $((CHECKED - FAILED)) passed, $FAILED failed."

if [ "$FAILED" -gt 0 ]; then
  exit 1
fi
