---
reviewer_tag: silent-failure-claude
round: 1
finding_id: F02
severity: low
change_type: correctness
referenced_files:
  - agents/qrspi-finding-verifier.md:L24-L27
---

The DROP/KEEP boundary in the G14 carve-out has a logical gap: scores 26-49 are neither explicitly kept (≥50) nor explicitly dropped (≤25), leaving disposition undefined in the carve-out prose.

The carve-out: "Informational findings that are structurally real (≥50) keep and are logged to the round artifact; informational findings whose premise is wrong (≤25) drop."

The three anchors are 25/50/75 — making the 26-49 gap theoretical in ideal operation. However, the carve-out explicitly describes a continuous 0-100 scale ("the verifier emits any integer in `0..100`"), so a verifier could legitimately score an informational finding at 30 or 40.

For a score of 30, the fan-in script presumably applies the global ≥50 threshold (drop), but the carve-out's "≤25 drop" language implies the author intended only 0 and 25 to unconditionally drop. A verifier reading literally might interpret 26-49 as "not explicitly dropped" and defer the disposition, creating undefined behavior in the fan-in consumer.

Fix: unify with global threshold by replacing two asymmetric conditions:
"Informational findings that score ≥50 keep and are logged; findings that score <50 drop."

[Materialized from chat-only response by claude-sonnet-4.6.]
