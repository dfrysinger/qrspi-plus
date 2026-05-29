---
finding: F01
reviewer: gt-claude
round: 8
task: 1
severity: low
change_type: clarity
file: tests/unit/test-run-third-party-llm.bats
lines: 359
persistence_note: orchestrator-persisted (reviewer chat-only fallback; see issue #216)
---

# F01 — Stale "12 bullets" section header comment in test file

Section header at line 359 reads "Covers all 12 Test Expectations bullets from tasks/task-01.md" but the current canonical task-01.md has **14** bullets after R4/R5 amendments added B13 (API key screening) and B14 (api_key_env identifier validation).

B14 test lives in the earlier `# Key resolution` section (line 174), which is organizationally sound but not documented in the comment.

**Required fix**: update section header to reference 14 bullets and note B13/B14 location.
