---
finding_id: R6-F01
severity: high
change_type: correctness
referenced_files: ["/Users/dfrysinger/code/qrspi-plus-v0.7.2/docs/qrspi/2026-06-04-v073-release/plan.md:L181-L186"]
artifact: plan
round: 6
reviewer: security-codex
---

**Fail-open on invalid `--step` in T01.**  
T01 explicitly requires unknown step names to return success (`exit 0`) with a partial default path set instead of failing. That is a security-significant fail-open behavior: callers cannot distinguish "valid empty/minimal case" from "invalid step input," so upstream dispatch can silently proceed with missing context and produce false-clean review outcomes.

