---
finding_id: R2-F01
reviewer_tag: silent-failure-claude
round: 2
task: 1
severity: medium
change_type: correctness
referenced_files: [skills/_shared/verifier-filter-rule.md]
---

## F01 — "halt or surface the error" disjunction permits log-and-continue silent clean-pass

**Quoted text under review:**
> consumers must halt or surface the error rather than treat absent as empty

**What can go wrong:**

The `or` makes both branches independently sufficient. A consumer that:
1. logs `"WARN: kept-findings.txt absent — no findings to process"`, then
2. continues execution with an empty kept set,

has satisfied the literal rule ("surfaced the error" ✓, "not treated absent as empty" ✓) while producing exactly the same downstream outcome as an empty file: zero findings forwarded, pipeline continues, review appears clean. This is the canonical log-and-continue silent failure pattern.

**Fix proposal:**

Replace the disjunction with a conjunction:
> consumers must halt with a pipeline error — and surface the condition — rather than treat absent as empty

Or with explicit continuation prohibition:
> consumers must not continue past an absent `kept-findings.txt`; they must halt and surface a pipeline error rather than treat absent as empty
