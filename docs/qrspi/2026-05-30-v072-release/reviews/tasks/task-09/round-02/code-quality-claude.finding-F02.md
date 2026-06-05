---
finding_id: F02
severity: low
change_type: style
referenced_files:
  - tests/acceptance/v07-phase1/test-phase1-acceptance.bats
actual_model: claude-opus-4-5
---

## Test quality: AC7 Case 4 is tautological — tests only fixture self-consistency

In the new `[reviewer-model-audit AC7]` test
(`tests/acceptance/v07-phase1/test-phase1-acceptance.bats`, approximately lines
1561–1575 in the worktree), Case 4 ("clean-sentinel WITHOUT actual_model") makes
two assertions:

```bash
  local c2="$tmp/scope-claude.clean.md"
  printf -- '---\nreviewer_tag: scope-claude\n---\nNo findings this round.\n' \
    >"$c2"
  # If the helper were ever wired into clean-sentinel processing, the
  # 'unknown' fallback would apply. Today we just assert no actual_model
  # token is present and the file is well-formed YAML frontmatter.
  if grep -q '^actual_model:' "$c2"; then
    echo "fixture clean-sentinel unexpectedly carries actual_model"; cat "$c2"; return 1
  fi
  [[ "$(grep -c '^---[[:space:]]*$' "$c2")" -eq 2 ]] \
    || { echo "fixture clean-sentinel frontmatter malformed"; cat "$c2"; return 1; }
```

Both assertions verify only that `printf` faithfully wrote what it was instructed to
write: the first asserts the absence of `actual_model:` in content that doesn't
contain `actual_model:`, and the second asserts that two `---` markers appear in
content that was written with exactly two `---` markers. No production code path is
exercised.

The comment is transparent about this limitation: *"Today we just assert no
`actual_model` token is present and the file is well-formed YAML frontmatter."* The
phrase *"If the helper were ever wired into clean-sentinel processing"* signals a
speculative future path that does not currently exist.

### Impact

The assertions will always pass regardless of any change to production code. A
developer reading the test list sees `AC7` described as covering four cases, but Case
4 provides zero coverage — it cannot catch any real regression in the
clean-sentinel `actual_model`-absence path because no production code runs.

### Suggested approaches

**Option A — drop Case 4 entirely.** If clean-sentinel absence-tolerance is not yet
testable without the helper being wired in, document that gap in a comment rather
than writing assertions that trivially pass.

**Option B — test the gap through the fan-in script.** The verifier fan-in script
processes clean-sentinel files. Writing a clean-sentinel without `actual_model:` into
a temp round directory and running the fan-in script would exercise a real code path
and provide a non-tautological assertion.

**Option C — label it informational.** If the intent is purely to document the
expected shape of a clean-sentinel without `actual_model:`, removing the `return 1`
branches and replacing the assertions with a `# DOCUMENTED: field is absent` comment
makes the intent clear without misleading test counts.

The issue is style/quality — it causes no false passes on real bugs, but inflates
the apparent coverage of the AC7 test case and can give false confidence.
