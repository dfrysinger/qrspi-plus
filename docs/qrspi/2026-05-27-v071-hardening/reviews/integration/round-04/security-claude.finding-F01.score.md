---
finding_id: R4-F01
score: 70
threshold: 70
disposition: KEEP
reviewer: security-claude
round: 4
---

## Score: 70 / 100 — KEEP (at threshold)

### Scoring rationale

**Severity dimension (medium, capped):**
- Reopens the G7b/#204 silent-fallback class that this hardening release exists to close (goals.md G7b) — direct collision with a load-bearing release goal. +
- Configuration-controlled (repo maintainer sets `trusted_path:`); not user-controllable at runtime. − (caps severity)
- Not strictly access control — the "access control = High minimum" rule from the review-criteria guidance does not apply. (no floor pin)

**Cross-task emergence (high):**
- Visible only by tracing the trusted_path: short-circuit across the T9 (model: deletion) → T10 (fail-loud paragraph scope) boundary.
- Neither per-task review (T9 or T10) could have caught this in isolation: T9 had no trusted_path: surface; T10 had no agents-frontmatter surface; the contradiction lives at the seam.
- Vocab pins added by T10 extract only the model_routing: H4 body, so the gap is invisible to the new test suite.

**Concreteness (high):**
- Specific file:line citations across SKILL.md:470 / :486 / :506 / :508 demonstrating the on-page contradiction.
- Two plausible implementer interpretations (b, c) both reproduce the forbidden silent-fallback; only interpretation (a) closes it, and (a) is not pinned.
- One-paragraph SKILL.md edit + one new vocab pin closes the gap without schema change.

**Actionability (high):**
- Fix is mechanical: append one sentence to the trusted_path: H4 (mirroring the R2 fail-loud wording), and add one BATS pin extracting the trusted_path: H4 body with the same `halts and reports` / `never (falls|fall) back silently` substring asserts.
- No code change, no T9 revert, no schema rework.

### Threshold position

Score **70**, threshold **70**, disposition **KEEP** (at threshold, finding-verifier eligible).

### Why not higher

- Trust-routing gap, not direct privilege escalation: an attacker cannot reach `trusted_path:` without repo-write access.
- No live runtime exploitation path in this release (the SKILL.md is a contract document; downstream implementer must still choose an interpretation).
- Both (b) and (c) silent-fallback outcomes are "wrong tier" / "wrong model" — not "unauthorized access to a protected resource".

### Why not lower

- This is precisely the class of cross-task seam the integration-security pass exists to catch.
- The release's stated security goal (close the G7b/#204 silent-fallback class) is not fully achieved if the trusted_path: branch reopens it — even if no other reviewer notices, this gap will surface as soon as a dispatcher implementer reads both sections.
- The vocab-pin coverage gap means the issue is structurally invisible to the new test suite, so it survives merge with no CI signal.
