---
finding_id: R3-F01
severity: high
change_type: correctness
referenced_files:
  - scripts/codex-finding-splitter.sh:L42-L47
  - scripts/codex-finding-splitter.sh:L95-L99
  - scripts/run-codex-review.sh:L284-L285
  - skills/reviewer-protocol/first-party-emission.md:L70
  - skills/reviewer-protocol/third-party-emission.md:L49
artifact: task-03
round: 3
reviewer: security-codex
---

The new `reviewer_tag` charset rule is documented, but not enforced at the actual path-construction sinks.
`codex-finding-splitter.sh` writes to `"$round_subdir/${tag}.clean.md"` and `"$round_subdir/${tag}.finding-F${num}.md"` with no regex validation, and `run-codex-review.sh` only checks `--reviewer-tag` is non-empty.

**Concrete attack scenario:** an attacker who can influence CLI invocation (e.g., compromised CI wrapper, malicious automation change, or untrusted integration caller) passes `--reviewer-tag ../../../../.git/hooks/post-commit`. The splitter then writes outside `round_subdir`, enabling arbitrary file write in the repository (or other writable paths), which can be used for persistence or code execution on later git operations.

The docs now claim hard-gate validation (`^[a-z0-9-]+$`), but implementation still allows traversal. Enforce the regex in runtime code before any path construction (both caller and splitter), and fail closed on mismatch.

---

**Orchestrator disposition (R3, budget exhausted):** ACCEPTED-WITH-ISSUES. The finding is legitimate — documentation without enforcement is a silent-failure-equivalent surface. T03 was scoped to add the charset rule to the spec/docs (and the test pin in test-per-finding-file-emission.bats verifies the docs carry the regex). Runtime enforcement in `scripts/codex-finding-splitter.sh` and `scripts/run-codex-review.sh` is OUT of T03's Target files and OUT of round budget. Captured for v0.7.3 task: "Enforce reviewer_tag charset at script entry points (codex-finding-splitter.sh, run-codex-review.sh) — fail closed on mismatch".
