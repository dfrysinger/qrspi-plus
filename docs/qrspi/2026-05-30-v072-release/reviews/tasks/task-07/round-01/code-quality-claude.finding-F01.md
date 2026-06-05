---
finding_id: R1-F01
severity: low
change_type: style
referenced_files:
  - tests/unit/test-verifier-agent-file.bats:L184
  - tests/unit/test-verifier-agent-file.bats:L186
  - tests/unit/test-verifier-agent-file.bats:L197
  - tests/unit/test-verifier-agent-file.bats:L203
  - tests/unit/test-verifier-agent-file.bats:L211
  - tests/unit/test-verifier-agent-file.bats:L224
  - tests/unit/test-verifier-agent-file.bats:L232
  - tests/unit/test-verifier-agent-file.bats:L248
  - tests/unit/test-verifier-agent-file.bats:L250
  - tests/unit/test-verifier-agent-file.bats:L255
  - tests/unit/test-verifier-agent-file.bats:L266
  - tests/unit/test-verifier-agent-file.bats:L274
  - tests/unit/test-verifier-agent-file.bats:L280
  - tests/unit/test-verifier-agent-file.bats:L289
  - tests/unit/test-verifier-agent-file.bats:L297
  - tests/unit/test-verifier-agent-file.bats:L303
  - tests/unit/test-verifier-agent-file.bats:L316
artifact: code
round: 1
reviewer: code-quality-claude
---

All 15 new `@test` names and 2 section-banner comments in
`tests/unit/test-verifier-agent-file.bats` embed the QRSPI-internal goal
ID `G14`. Per the reviewer-protocol ID-hygiene rule (§ 11 of the
code-quality checklist): QRSPI-internal IDs — G/R/D/T/Q-prefixed numeric
tokens — are forbidden in test names, `describe`/`it` blocks, and code
comments outside `docs/qrspi/`, regardless of how scoped the comment is.
The test file lives at `tests/unit/`, well outside that exemption.

**Affected lines (new diff additions only):**

Section-banner comments:
- L184: `# ── G14 Informational-carve-out rubric assertions (verifier agent file) ───────`
- L248: `# ── G14 reviewer-protocol section assertions ──────────────────────────────────`

Test names (representative — all 15 follow the same pattern):
- L186: `@test "G14 carve-out: verifier body contains literal case-sensitive Informational: token"`
- L197: `@test "G14 carve-out: documents case-sensitive detection rule"`
- L203: `@test "G14 carve-out: documents first-non-blank-line detection rule on message body"`
- L211: `@test "G14 carve-out: precedes the false-positive-pattern list"`
- L224: `@test "G14 carve-out: explicitly disables false-positive scoring on Informational findings"`
- L232: `@test "G14 carve-out: scores on structural confidence (75/50/25 anchors)"`
- L250: `@test "G14 reviewer-protocol: '## Informational Findings' section exists"`
- … (9 more `G14 reviewer-protocol:` tests follow the same pattern through L316)

**Why it matters.** A future verifier or orchestrator subagent that reads
bats test output (e.g. a failing assertion message relaying the test name)
encounters `G14` as a bare tracking token with no meaning outside the
QRSPI project's own internal planning files. More concretely, the rule
exists to prevent run-specific tokens from leaking from task specs into
durable production artifacts — and bats test names are as durable as any
other code identifier.

**Suggested fix.** Rename using the feature name rather than the goal ID:

- `"G14 carve-out: ..."` → `"informational-carve-out: ..."`
- `"G14 reviewer-protocol: ..."` → `"informational-findings-protocol: ..."`
- Banner comments: strip `G14` from the label, e.g.
  `# ── Informational-carve-out rubric assertions (verifier agent file) ───`
  `# ── Informational Findings reviewer-protocol section assertions ─────────`

The test logic, awk selectors, and grep patterns are all correct and
require no changes — only the names and banners need the token removed.
