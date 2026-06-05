---
finding_id: F02
reviewer_tag: code-simplifier-claude
round: 4
severity: suggestion
category: verbose-patterns / duplication
files:
  - tests/unit/test-verified-file-shape.bats
---

# Two field-order tests repeat identical frontmatter-extraction logic

## What's happening

`test-verified-file-shape.bats` contains two new `@test` blocks that both
extract the YAML frontmatter from a sidecar template block and then assert
`defect_class:` is the last field:

**"sidecar field-order: success template has defect_class: as the LAST
frontmatter field"** (lines ~236–261) — does extra work (score_line /
defect_line comparison) then shares:

```bash
local fm
fm=$(echo "$block" | awk '/^[[:space:]]*---[[:space:]]*$/{n++; next} n==1{print}')
[ -n "$fm" ] || { echo "could not extract success-template frontmatter"; return 1; }
local last_field
last_field=$(echo "$fm" | grep -E '^[[:space:]]*[a-z_]+:' | tail -1 \
             | sed -E 's/^[[:space:]]*([a-z_]+):.*/\1/')
[ "$last_field" = "defect_class" ] \
  || { echo "..."; return 1; }
```

**"sidecar field-order: failure template has defect_class: as the LAST
frontmatter field"** (lines ~263–281) — differs only in the `awk` that
produces `$block`, then has *exactly the same* `fm`/`last_field` logic:

```bash
local fm
fm=$(echo "$block" | awk '/^[[:space:]]*---[[:space:]]*$/{n++; next} n==1{print}')
[ -n "$fm" ] || { echo "could not extract failure-template frontmatter"; return 1; }
local last_field
last_field=$(echo "$fm" | grep -E '^[[:space:]]*[a-z_]+:' | tail -1 \
             | sed -E 's/^[[:space:]]*([a-z_]+):.*/\1/')
[ "$last_field" = "defect_class" ] \
  || { echo "..."; return 1; }
```

The only differences are (a) the `awk` block that produces `$block` from the
agent file, and (b) the error messages.

## Suggested simplification

Extract a BATS helper that takes a pre-extracted `block` variable and asserts
`defect_class:` is the last frontmatter field, reducing the repeated 7-line
sequence to a single call in each test:

```bash
# Helper: assert defect_class: is the last frontmatter field in a block.
# Usage: _assert_defect_class_last "$block" "success"
_assert_defect_class_last() {
  local block="$1" label="$2"
  local fm
  fm=$(echo "$block" | awk '/^[[:space:]]*---[[:space:]]*$/{n++; next} n==1{print}')
  [ -n "$fm" ] || { echo "could not extract $label-template frontmatter"; return 1; }
  local last_field
  last_field=$(echo "$fm" | grep -E '^[[:space:]]*[a-z_]+:' | tail -1 \
               | sed -E 's/^[[:space:]]*([a-z_]+):.*/\1/')
  [ "$last_field" = "defect_class" ] \
    || { echo "$label template's last frontmatter field is '$last_field'" \
              "— must be 'defect_class' per the load-bearing field-ordering invariant"; \
         echo "frontmatter:"; echo "$fm"; return 1; }
}
```

Each test then shrinks to extracting its specific `$block` and calling
`_assert_defect_class_last "$block" "success"` (or `"failure"`).

The success-path test keeps its unique score_line/defect_line ordering check
before the call. No logic changes; no coverage lost.
