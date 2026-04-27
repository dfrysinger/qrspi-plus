#!/usr/bin/env bash
set -euo pipefail

# validate-config-field.sh
# Usage: validate-config-field.sh {field} {artifact_dir}
# Reads config.md from {artifact_dir}, validates {field}, and exits 1 with a
# numbered menu if the field is missing or invalid. Exits 0 with no output if valid.

FIELD="${1:-}"
ARTIFACT_DIR="${2:-}"

if [[ -z "$FIELD" || -z "$ARTIFACT_DIR" ]]; then
  echo "Usage: $0 {field} {artifact_dir}" >&2
  exit 2
fi

CONFIG="$ARTIFACT_DIR/config.md"

if [[ ! -f "$CONFIG" ]]; then
  echo "config.md not found in the artifact directory."
  echo ""
  echo "  1) Re-run Goals to create config.md and set the pipeline mode"
  echo "  2) Abort"
  exit 1
fi

# Extract frontmatter value for a given key from config.md
# Reads lines between the first two --- markers
extract_field() {
  local key="$1"
  local in_frontmatter=0
  local found=0
  while IFS= read -r line; do
    if [[ "$line" == "---" ]]; then
      if [[ "$in_frontmatter" -eq 0 ]]; then
        in_frontmatter=1
        continue
      else
        break
      fi
    fi
    if [[ "$in_frontmatter" -eq 1 ]]; then
      if [[ "$line" =~ ^[[:space:]]*"$key":[[:space:]]*(.*) ]]; then
        echo "${BASH_REMATCH[1]}"
        found=1
        break
      fi
    fi
  done < "$CONFIG"
  return 0
}

# Check if a field key is present (even if empty) in frontmatter
field_present() {
  local key="$1"
  local in_frontmatter=0
  while IFS= read -r line; do
    if [[ "$line" == "---" ]]; then
      if [[ "$in_frontmatter" -eq 0 ]]; then
        in_frontmatter=1
        continue
      else
        break
      fi
    fi
    if [[ "$in_frontmatter" -eq 1 ]]; then
      if [[ "$line" =~ ^[[:space:]]*"$key": ]]; then
        return 0
      fi
    fi
  done < "$CONFIG"
  return 1
}

# Check if route is a YAML list (next lines after route: start with -)
route_has_list() {
  local in_frontmatter=0
  local after_route=0
  while IFS= read -r line; do
    if [[ "$line" == "---" ]]; then
      if [[ "$in_frontmatter" -eq 0 ]]; then
        in_frontmatter=1
        continue
      else
        break
      fi
    fi
    if [[ "$in_frontmatter" -eq 1 ]]; then
      if [[ "$after_route" -eq 1 ]]; then
        if [[ "$line" =~ ^[[:space:]]*- ]]; then
          return 0
        else
          return 1
        fi
      fi
      if [[ "$line" =~ ^[[:space:]]*route: ]]; then
        after_route=1
      fi
    fi
  done < "$CONFIG"
  return 1
}

case "$FIELD" in
  route)
    if ! field_present "route"; then
      echo "config.md has no \`route\` field."
      echo ""
      echo "  1) Re-run Goals to regenerate config.md with the correct route"
      echo "  2) Manually add a \`route:\` list to config.md"
      echo "  3) Abort"
      exit 1
    fi
    if ! route_has_list; then
      echo "config.md has no \`route\` field."
      echo ""
      echo "  1) Re-run Goals to regenerate config.md with the correct route"
      echo "  2) Manually add a \`route:\` list to config.md"
      echo "  3) Abort"
      exit 1
    fi
    ;;

  pipeline)
    if ! field_present "pipeline"; then
      echo "config.md has no \`pipeline\` field."
      echo ""
      echo "  1) Re-run Goals to regenerate config.md with the pipeline field set"
      echo "  2) Manually add \`pipeline: full\` or \`pipeline: quick\` to config.md"
      echo "  3) Abort"
      exit 1
    fi
    VALUE="$(extract_field pipeline)"
    if [[ "$VALUE" != "full" && "$VALUE" != "quick" ]]; then
      echo "config.md has an invalid value for \`pipeline\`: $VALUE"
      echo "Expected: \`full\` or \`quick\`"
      echo ""
      echo "  1) Edit config.md and set \`pipeline: full\` or \`pipeline: quick\`"
      echo "  2) Re-run Goals to regenerate config.md"
      echo "  3) Abort"
      exit 1
    fi
    ;;

  codex_reviews)
    if ! field_present "codex_reviews"; then
      echo "config.md has no \`codex_reviews\` field."
      echo ""
      echo "  1) Add \`codex_reviews: true\` to config.md (Codex second reviews enabled)"
      echo "  2) Add \`codex_reviews: false\` to config.md (Codex second reviews disabled)"
      echo "  3) Re-run Goals to regenerate config.md"
      echo "  4) Abort"
      exit 1
    fi
    VALUE="$(extract_field codex_reviews)"
    if [[ "$VALUE" != "true" && "$VALUE" != "false" ]]; then
      echo "config.md has an invalid value for \`codex_reviews\`: $VALUE"
      echo "Expected: \`true\` or \`false\`"
      echo ""
      echo "  1) Edit config.md and set \`codex_reviews: true\` or \`codex_reviews: false\`"
      echo "  2) Re-run Goals to regenerate config.md"
      echo "  3) Abort"
      exit 1
    fi
    ;;

  *)
    echo "Unknown field: $FIELD" >&2
    exit 2
    ;;
esac

exit 0
