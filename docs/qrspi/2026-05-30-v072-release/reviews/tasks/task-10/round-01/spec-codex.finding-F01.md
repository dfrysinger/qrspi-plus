---
finding_id: R1-F01
reviewer_tag: spec-codex
severity: high
change_type: correctness
referenced_files:
  - agents/qrspi-finding-verifier.md#L96-L120
  - tests/unit/test-verified-file-shape.bats#L187-L192
---

Task spec requires `defect_class` to be **REQUIRED on every sidecar**. Current verifier spec text says it is "**Optional ... at-or-above threshold**" (`agents/qrspi-finding-verifier.md:96`), and the **failure-sidecar template omits `defect_class` entirely** (`agents/qrspi-finding-verifier.md:114-120`). Unit coverage only asserts presence in the success template (`tests/unit/test-verified-file-shape.bats:187-192`), so this requirement is not enforced end-to-end.
