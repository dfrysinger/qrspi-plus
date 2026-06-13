---
finding_id: R4-F03
severity: medium
change_type: correctness
referenced_files:
  - docs/qrspi/2026-06-04-v073-release/plan.md
artifact: plan
round: 4
reviewer: security-codex
---

Missing invalid-input rejection tests for `--step` in T03/T04a. These tasks accept external `--step` input and build step-scoped paths/behavior, but test expectations only cover known valid steps and do not require explicit rejection of malformed/unknown step values for this path (L657–L675, L691–L697). Unvalidated step values can trigger undefined control flow/path construction and create silent misrouting or unsafe file-path behavior instead of deterministic fail-closed errors.
