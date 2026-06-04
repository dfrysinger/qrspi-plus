---
finding_id: code-quality-claude.finding-F03
severity: low
change_type: style
reviewer: code-quality-claude
round: 4
file: tests/acceptance/v07-phase1/test-phase1-acceptance.bats
line: 1099-1105
at_cap: true
---

# Orphaned mid-sentence comment preceding the `dispatch-manifest AC5` test

## Location

`tests/acceptance/v07-phase1/test-phase1-acceptance.bats`, the comment block
immediately before the `@test "[dispatch-manifest AC5] ..."` test
(two blank lines after the AC6 test body close, then the comment block).

## Description

The comment block reads:

```bash
# script, stdout carries a DISPATCH_FILE= reference, and the manifest records a
# first_party entry whose dispatch_spec.prompt_file matches the stdout reference.
# This tests the dispatch entry point (not just the manifest-emission helper)
# and verifies the orchestrator-facing payload stays a prompt-file reference.
# Requires a trusted gh binary (same precondition as detect_host returning
# 'copilot-cli') — skips when gh is absent or not in a trusted prefix.
```

The comment begins mid-sentence with "# script, stdout carries …" — there is
no opening phrase or subject.  The full leading sentence was accidentally
truncated, leaving the comment disorienting for a reader who encounters it
without surrounding context.

Compare with the analogous comment block immediately above the `TE10` test,
which starts with a complete orientation sentence:
"T7 / TE10: Copilot CLI (first-party) path — dispatch exits 0, stdout carries
a DISPATCH_FILE= reference pointing at the assembled prompt file, and the
manifest records a first_party entry whose dispatch_spec.prompt_file matches
the stdout DISPATCH_FILE= value."

The AC5 block is likely the tail half of a similar sentence whose opening was
dropped during the R3→R4 edit cycle.

Additionally there are two consecutive blank lines between the closing `}` of
the AC6 test and this comment block (single blank line is the established
convention in this file), which slightly amplifies the orphaned appearance.

## Fix (if user authorizes cap-bend)

Restore the opening orientation line, e.g.:

```bash
# ---------------------------------------------------------------------------
# dispatch-manifest AC5: first-party dispatch path end-to-end — Copilot CLI
# script, stdout carries a DISPATCH_FILE= reference, and the manifest records a
# first_party entry whose dispatch_spec.prompt_file matches the stdout reference.
...
```

And collapse the double blank line to a single blank line for style
consistency.

## At-cap escalation note

This is a cycle-3-of-3 at-cap finding.  No R5 fix-cycle fires automatically.
The fix is a comment-only edit.  User must explicitly authorize a cap-bend to
address it, or carry it forward as a polish item in a future task.
