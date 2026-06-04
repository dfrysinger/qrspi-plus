---
finding_id: F02
reviewer: silent-failure-claude
severity: high
change_type: scope
referenced_files: [scripts/dispatch-agent.sh:703-708]
disposition: DEFER-v0.7.3
---
**Batch mode silently assembles incomplete prompt when REVIEWER_PROTOCOL_ABS / EMISSION_OVERRIDE_ABS missing**; single mode fail-loud asserts (L921-925). Same operational event (missing shared skill file) → hard error single, invisible degraded prompt batch. Pre-existing; not introduced by R4→R5 diff. **DEFER** — these are repo-internal skill files (REPO_ROOT-derived), not user-input path boundary; out of T21 spec line 19 scope. Tracked v0.7.3 batch-asymmetry hardening.
