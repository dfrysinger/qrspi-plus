---
finding_id: R4-F01
severity: low
change_type: clarity
referenced_files: [scripts/round-prepare.sh, tests/unit/test-scope-tagger-dispatch.bats]
---

# F01 — Dead code / redundant I/O + test duplication (non-blocking simplifications)

1. **Dead code / redundant I/O in anchor-shape check** — scripts/round-prepare.sh L192-199.
   `ANCHOR_CONTENT="$(cat "$PRIOR_ANCHOR_PATH" ...)"` is assigned, then the check uses
   `python3 ... < "$PRIOR_ANCHOR_PATH"` (so ANCHOR_CONTENT is never actually used; the file
   redirect supersedes the printf pipe). Simpler: remove ANCHOR_CONTENT and the unused printf
   pipe; validate directly from file once. Convergent with code-simplifier-claude.finding-F01.

2. **Repeated extraction logic in T13 checklist tests** — test-scope-tagger-dispatch.bats L540-575.
   The same `awk '/Between rounds — required sequence/...'` block is repeated across multiple
   tests. Simpler: add one small helper (e.g., between_rounds_block()) and reuse. (Advisory; bats
   idiom favors explicit fixtures — judgment call, not flagged as blocking by claude peer.)
