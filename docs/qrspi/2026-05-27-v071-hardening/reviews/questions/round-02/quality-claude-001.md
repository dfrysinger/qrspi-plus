---
id: quality-claude-001
artifact: questions
severity: MEDIUM
check: comprehensiveness
---

## Finding

**G5 violation-enumeration research task is absent from the question set.**

Q7 covers the *mechanism* of `test-evergreen-markdown.bats` (what token patterns it enforces, which paths are exempted, and how exemptions are declared). It does not ask the researcher to enumerate the **current live violations** that would surface if carve-outs were disabled — the specific action the goals flag as priority for G5.

### Goals text (G5, emphasis added)

> **Status-check priority:** of the G1-G5 set, this one is the most likely to be partially or fully closed by intervening work, because evergreen-prose hardening has continued on `main` since the audit. **Research should re-run the carve-out-disabled scan first and report the current violation count before Design opens**, and flag any that are already resolved, partially resolved, or have shifted scope.

> **Exact paths must be enumerated by running the scan with the carve-outs disabled.**

### Why the gap matters

A researcher can answer Q7 completely by reading the BATS file and the exemption table — without ever executing the scan against live prose. The result would be a correct structural description of the test framework, but Design would receive no signal on:

- whether G5 is already closed (violation count = 0)
- how many lines across how many files remain to fix (violation count N > 0)
- whether the violation set spans AGENTS.md, README.md, skills files, or a subset

G5 explicitly states that this status check must precede Design. If the question set does not ask for it, the researcher has no prompt to produce it, and Design will open with an unquantified G5 scope — or will need to loop back to Research at cost.

### Affected question

Q7 as currently written:

> What token patterns does `tests/unit/test-evergreen-markdown.bats` enforce, what file paths are currently exempted via carve-outs or inline markers, and what is the exact syntax used to declare those exemptions?

### Suggested addition

Add a companion codebase question, e.g.:

> **[codebase]** When `tests/unit/test-evergreen-markdown.bats` is run with all current path-level carve-outs and inline `<!-- evergreen-exempt -->` markers disabled, what violations are currently present across `skills/**`, `agents/**`, `AGENTS.md`, `README.md`, and `docs/` — specifically: which file paths contain violations, which token pattern each violation matches, and what is the total violation count?

This is a `[codebase]` + runtime-execution question (run the scan, capture output), distinct from Q7's structural survey of the test definition. It directly produces the sizing data G5 requires before Design opens.
