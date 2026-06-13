---
finding_id: R6-F03
severity: high
change_type: correctness
referenced_files: ["/Users/dfrysinger/code/qrspi-plus-v0.7.2/docs/qrspi/2026-06-04-v073-release/plan.md:L875-L884"]
artifact: plan
round: 6
reviewer: security-codex
---

**Missing path-traversal requirement for T37 `!cat` resolution.**  
T37 resolves `!cat` references transitively but its tests only cover unresolvable/cycle/tokenizer cases; the plan explicitly defers repo-boundary/path-escape checks. Without a required guard rejecting absolute paths and `../` escapes, malicious or malformed `!cat` references can cause out-of-scope file reads. This is an input-validation gap with direct filesystem exposure risk.
