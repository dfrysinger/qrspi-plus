# Spec Review — Task 34 Round 4 — CLEAN

Reviewer: spec-claude  
Round: 4  
Artifact: skills/plan/post-approval-split-contract.md + tests/unit/test-plan-post-approval-split.bats

## Result: No findings. Implementation matches spec exactly.

### Completeness

All six required sections are present in `skills/plan/post-approval-split-contract.md`:
- `## Block-Hash Header Format` — position, syntax (`# block-hash: <sha256-hex>`), SHA-256 hex no-salt algorithm, normalization rule, and trailing-newline rule all documented.
- `## Idempotent Split Contract` — three-case decision table (absent→dispatch, matching→safe-skip, mismatching→HALT) with prose for each case, partial-crash recovery, and complete-set re-run.
- `## HALT Diagnostic` — exact mismatch diagnostic text word-for-word as required by spec.
- `## Pre-G5 Migration Diagnostic` — exact missing-header diagnostic text word-for-word as required; `malformed block-hash header` named explicitly.
- `## Sub-Subagent Dispatch Contract` — `block_hash: <sha256-hex>` field documented; sub-subagent obligation to emit verbatim immediately after frontmatter close stated.
- `## Quick-Fix N=1 Path` — all five audit sub-cases (absent, matching, mismatching, missing-header, malformed-header) listed.

### Test Coverage

All nine test expectations from the spec are covered by non-vacuous tests:

1. Single `# block-hash:` line immediately after frontmatter `---` — locked by `sed -n '4p'` position check and 64-char hex regex.
2. Hash = sha256 hex no-salt over normalized block — verified by asserting `raw_hash != normalized_hash` when trailing whitespace differs.
3. Partial-crash: only missing files dispatched, existing files not rewritten, exact-set passes — `dispatch_count==1` assertion; `content_before==content_after` assertion.
4. Complete re-run: zero dispatches, approval-state completion — `dispatch_count==0`; `status: approved` and 40-char SHA in plan.md asserted.
5. Hand-edit preserved when stored hash matches — stored==recomputed hash; hand-edit text survives grep.
6. Mismatch HALT: halts, file untouched, exact diagnostic — `decision=halt` asserted; `content_before==content_after`; exact diagnostic text pinned by doc-audit tests.
7. Missing header halts with exact diagnostic — `decision=halt-missing-header`; content unchanged; doc-audit for exact phrase.
8. Malformed header halts naming `malformed block-hash header`, no rewrite — `decision=halt-malformed-header`; `content_before==content_after`; doc-audit.
9. Quick-fix N=1 emits same header, applies same five audit rules — behavioral test plus doc-audit test extracting `absent`, `matches`, `mismatch`, `missing block-hash header`, `malformed block-hash header` from the `## Quick-Fix N=1 Path` section.
10. Grep-based doc audit confirms all six required section anchors — all six `grep -F "## ..."` checks present.

### Scope

Two supplementary sections were added beyond the spec's six required sections (`## Task-ID Validation`, `## Security Scope`) plus an explicit trailing-newline paragraph inside `## Block-Hash Header Format`. These are additions within the two owned target files and are directly related to the G5 post-approval split surface. They do not displace, contradict, or overlap any required content. The spec's Definition of Done is a "must contain" list, not an exhaustive constraint.

Both target files (`skills/plan/post-approval-split-contract.md`, `tests/unit/test-plan-post-approval-split.bats`) match the spec's Target files list exactly. No other files were modified.
