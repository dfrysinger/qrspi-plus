---
finding_id: F02
reviewer: silent-failure-claude
round: 7
severity: medium
change_type: hygiene
referenced_files: [tests/unit/test-detect-interaction-mode.bats]
---
Override-branch output-shape tests assert positive keys (PLATFORM, VERDICT,
DETECTION_TYPE=user-override-only, EVIDENCE) and `! DETECTION_TYPE=llm-context`, but do NOT
assert `INSTRUCTION` key is ABSENT. The protocol distinguishes llm-context (has INSTRUCTION)
from user-override-only (no INSTRUCTION; has VERDICT+EVIDENCE). A regression emitting
INSTRUCTION in the override path would pass all current tests; a consumer distinguishing the
shapes by INSTRUCTION-absence would misclassify. Fix: add `! echo "$output" | grep -q
'^INSTRUCTION='` (preferably via the count idiom) to override output-shape tests.
