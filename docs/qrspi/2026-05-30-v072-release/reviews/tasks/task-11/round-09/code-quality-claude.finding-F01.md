---
reviewer_tag: code-quality-claude
round: 9
finding_id: R9-F01
severity: low
change_type: clarity
referenced_files: [tests/acceptance/v07-phase1/test-phase1-acceptance.bats]
---

# F01 — ID hygiene: `T11` token in test comment (DUPLICATE of cq-codex F01)

## Finding

Same as code-quality-codex.finding-F01. Comment at ~line 2785: "(T11 spec requires this field; AC2 covers the helper-function path)" — `T11` is a QRSPI-internal task-ID and violates the ID-hygiene rule for shipped code outside `docs/qrspi/`.

Replace with: "(the dispatch-manifest spec requires this field; AC2 covers the helper-function path)".

## Severity

LOW (cq-claude rates Minor; cq-codex rates Medium — splitting at LOW since it's comment-only with no runtime impact).

## Other R9 criteria reviewed

CLEAN on single responsibility, decomposition, structure compliance, file size delta, naming (no [dispatch-manifest AC12] collision with pre-existing [reviewer-model-audit AC12]), DRY (removal of dup absolute-path check is clean), YAGNI (key-count pins are load-bearing), test quality (behavior-focused), mock discipline, self-consistent defenses.
