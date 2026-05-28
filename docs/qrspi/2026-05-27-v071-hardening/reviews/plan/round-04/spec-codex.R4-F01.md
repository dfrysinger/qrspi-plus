---
finding_id: R4-F01
severity: medium
change_type: scope
referenced_files: [docs/qrspi/2026-05-27-v071-hardening/plan.md]
artifact: plan
round: 4
reviewer: spec-codex
---

Task 6 is feature-bundled without a sizing exception

Task 6 contains 4 distinct observable behaviors:
1. detect_host env-parsing contract
2. check_codex_available per-host semantics
3. mismatch-policy diagnostic + non-gating continuation
4. dispatch transport trace-marker behavior

Concrete split: 6a (detect_host), 6b (check_codex_available), 6c (mismatch policy + transport markers). Dependency: 6a -> 6b -> 6c.

NOTE FOR FIX-SYNTHESIS: This is borderline. The 4 behaviors all describe THE SAME HOST-DETECTION SUBSYSTEM working as a coherent unit. Task 6 is ~150 LOC. Per OWNS rule "one observable behavior" — the unified behavior is "host-aware Codex dispatch contract for the dispatch helper" — and all 4 sub-behaviors collapse to one observable: "when the dispatch helper runs, it routes Codex correctly per host". Splitting would create cross-task dependencies for a coherent atomic surface. Recommend SET ASIDE on same atomicity rationale used for Task 8.
