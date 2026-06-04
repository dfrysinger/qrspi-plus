---
finding_id: F01
reviewer_tag: security-codex
round: 3
severity: medium
change_type: design-contract
referenced_files: [scripts/detect-interaction-mode.sh]
---
Spoofable auto-mode detection via untrusted context markers. The script emits instructions to detect mode by searching plain-text markers (`Autopilot mode is currently active.`, `## Auto Mode Active`) anywhere in active context; user-controlled content can include those exact strings → false auto-mode detection. NOTE: this is the design-locked script-returns-instructions contract (design.md I.7); marker-based detection is the specified approach, not a T24 implementation defect. Surfaced as a design/process observation for v0.7.3, not an in-scope T24 code fix.
