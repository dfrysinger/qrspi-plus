---
finding_id: F01
severity: minor
category: id-hygiene
files:
  - tools/build-plugin.mjs
  - .github/workflows/ci.yml
---

# F01 — QRSPI-internal IDs in code comments

The implementation embeds QRSPI-internal task/goal IDs in code comments in both
shipped artifacts. Per the ID Hygiene rule "**QRSPI-internal IDs** — G/R/D/T/Q-prefixed
numeric tokens: forbidden in code comments…regardless of how scoped the comment is",
these are flagged.

**Occurrences (non-exhaustive):**

`tools/build-plugin.mjs`
- Line 4: `// G32 plugin build pipeline (Task 39).`
- Line 19: `// T21's symlink-out-of-repo guard with the audit-friendly diagnostic`
- Line 56: `// `docs/`, `tools/`, `tests/`, `reviews/` are explicit dev-only roots per` / `// task-39 §Definition of done.`
- Line 203: `// Outside-root guard for non-.md files. Mirrors T21's`
- Line 252: `// (the symlink-escape regression fixture).` — implicit reference fine on its own, but combined with surrounding T21 mentions it's the same surface.

`.github/workflows/ci.yml`
- Line 113: `# T39 / G32: walk tests/ recursively …`
- Line 119: `# T39 / G32: rebuild the committed `build/` plugin tree …`
- Line 124: `# T39 / G32: PR-blocking failure mode …`

Note: `D3` and `D1`–`D3` references in the resolver-grammar comment block are
**exempt** (reserved framework vocabulary per the rule's exclusion list), and
the `${CLAUDE_SKILL_DIR}` token is the literal string the resolver guards
against, not an ID.

**Suggested remediation:** Replace each `T21 / T39 / G32 / Task 39 / task-39`
reference with prose that names the behavior or invariant ("repo-root
canonicalization guard", "build-sync gate", "G32 plugin build pipeline" →
"plugin build pipeline"). The comments remain useful — the IDs add no signal
the surrounding text doesn't already carry. The `tools/build-plugin.mjs`
header is the most efficient place to scrub: drop "(Task 39)" from line 4,
and rephrase the T21 cross-references to "mirrors the dispatch-agent
canonicalization guard" without the ID.

**Why minor:** No correctness or behavior impact, and these IDs are
unambiguously meaningful to anyone with repo context. But the rule is
unconditional ("regardless of how scoped"), and the failure mode it guards
against (run-specific tokens copied from the task spec into shipped code)
is exactly what happened here.
