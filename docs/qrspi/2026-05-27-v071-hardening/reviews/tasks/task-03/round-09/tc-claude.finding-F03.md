---
finding: F03
round: 9
reviewer: tc-claude
severity: medium
change_type: missing_test
status: open
---

# F03 — No test exercises `extract_section_fence_aware` with an H2 (`## `) anchor

## Location

- **Production code:** `tests/helpers/skill-markdown.bash` lines 259, 263, 270
- **Test file:** `tests/unit/test-helpers-skill-markdown.bats` — all 14 fence-aware
  tests use `### ` (H3) anchors exclusively

## Description

The task spec states (plan.md task-03, test-expectation 2):

> A `### ` or `## ` heading line that appears inside an open code fence is not
> treated as a section boundary and does not terminate the extraction.

The production awk rules treat both `## ` and `### ` lines as section
boundaries when outside a fence:

```awk
in_b && !fence && (/^## / || /^### /) {
  exit
}
```

And the anchor-matching rule is a plain string equality check:

```awk
!in_b && !fence && $0 == anchor {
  in_b = 1; found = 1; print; next
}
```

A caller can therefore legitimately pass `"## My Section"` as the anchor.  If
the caller does, an `## ` line inside a fence would still not act as a
boundary (because `fence=1`) but every test in the suite uses `### ` anchors.
No test verifies that:

1. The function successfully locates an `## ` anchor and extracts its content.
2. An `## ` heading-shaped line inside a fence does not prematurely terminate
   extraction when the anchor is itself an H2 heading.
3. A real `## ` following the section correctly terminates extraction when the
   anchor is H2 (i.e. the boundary rule and the anchor rule coexist correctly
   for H2-anchored sections).

A latent bug (e.g. accidentally matching the anchor line as a boundary before
`!in_b` is evaluated) would go undetected.

## Suggested fix

Add at least one happy-path and one fence-suppression test with an H2 anchor:

```bats
@test "[fence-aware-extractor] H2 anchor: extracts content, bounded by next H2 or H3" {
  cat > "$FIXTURE_DIR/h2-anchor.md" <<'EOF'
## Target Section
Content line one
Content line two

## Next H2 Section
Should not appear
EOF
  out="$(extract_section_fence_aware "$FIXTURE_DIR/h2-anchor.md" "## Target Section")"
  [ "$?" -eq 0 ]
  [[ "$out" == *"## Target Section"* ]]
  [[ "$out" == *"Content line one"* ]]
  [[ "$out" != *"## Next H2 Section"* ]]
  [[ "$out" != *"Should not appear"* ]]
}

@test "[fence-aware-extractor] H2 anchor: fenced H2/H3 lines do not act as boundaries" {
  cat > "$FIXTURE_DIR/h2-fence.md" <<'EOF'
## Target Section
Before fence
\`\`\`
## Fenced H2
### Fenced H3
\`\`\`
After fence

## Real Boundary
Should not appear
EOF
  out="$(extract_section_fence_aware "$FIXTURE_DIR/h2-fence.md" "## Target Section")"
  [ "$?" -eq 0 ]
  [[ "$out" == *"## Fenced H2"* ]]
  [[ "$out" == *"After fence"* ]]
  [[ "$out" != *"## Real Boundary"* ]]
}
```
