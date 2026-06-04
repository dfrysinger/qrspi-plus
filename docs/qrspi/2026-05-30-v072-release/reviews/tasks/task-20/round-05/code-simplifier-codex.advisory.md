---
reviewer: code-simplifier-codex
round: 5
status: advisory
findings: 2
---

# Advisory simplifications (non-blocking — duplicates of cq-claude R5 findings)

**F01:** Duplicate wrapper rc/stderr-capture block at L1138-1155 and L1222-1238 of test-dispatch-agent.bats. Extract `run_wrapper_or_fail <round_dir>` helper. **Same as cq-claude R5-F01** — already accepted-with-issues, deferred to v0.7.3 backlog.

**F02:** Unnecessary intermediate `await_stderr_content` variable + `[ -f ]` guard at L1261-1263. Print stderr on failure direct from file: `if [ rc -ne 0 ]; then cat "$file" >&2; fi`. **Same as cq-claude R5-F02** — already accepted-with-issues.

cs-reviewer findings are advisory per skill design; no action.
