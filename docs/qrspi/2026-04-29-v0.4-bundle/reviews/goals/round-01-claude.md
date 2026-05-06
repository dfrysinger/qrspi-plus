---
artifact: goals
round: 01
reviewer: code-reviewer (Sonnet)
---

# Round 1 — Claude code-reviewer findings (goals.md)

Reviewed: docs/qrspi/2026-04-29-v0.4-bundle/goals.md
Reviewer: pr-review-toolkit:code-reviewer (Sonnet)
Date: 2026-05-03

## Summary

- Total findings: 6
- Severity: high=0, medium=4, low=2
- Auto-apply (style/clarity/correctness): 4
- Paused (scope/intent): 2

## Findings

### R1-F01 — G1 missing test-debt candidate from #26

- **finding_id:** R1-F01
- **severity:** medium
- **change_type:** correctness
- **referenced_files:** [docs/qrspi/2026-04-29-v0.4-bundle/goals.md]

Issue #26 (G1 source) contains an explicit **Test debt** line: "bats integration test dispatching a fake per-task orchestrator, asserting it can dispatch a fake implementer subagent." Per checklist B4, test-debt items from the source issue must appear in the goal's What we know so far as candidates Design should weigh. G1's What we know so far lists Candidates A, B, and C (the three dispatch-architecture candidates) but omits any mention of the integration-test candidate.

**Fix:** Add a bullet under G1's What we know so far, e.g.: "Candidate D — Design should weigh: a skill-verification e2e covering the per-task orchestrator dispatch contract (fake orchestrator asserts it can dispatch a fake implementer subagent), to make the dispatch-collapse failure mode detectable in CI rather than only in production runs."

---

### R1-F02 — G5 missing test-debt candidate from #55

- **finding_id:** R1-F02
- **severity:** medium
- **change_type:** correctness
- **referenced_files:** [docs/qrspi/2026-04-29-v0.4-bundle/goals.md]

Issue #55 (G5 source) contains a **Test debt** entry: "test asserting that on a machine where the hardcoded path doesn't exist but `${HOME}/.claude/plugins/cache/openai-codex/codex/*/scripts/codex-companion.mjs` does exist, the wrapper resolves to the latter." G5's What we know so far lists Candidates A, B, and C (resolution strategies) but contains no test-coverage candidate. Per B4, this omission is a finding.

**Fix:** Add a bullet under G5's What we know so far, e.g.: "Candidate D — Design should weigh: a portability test asserting that, when the hardcoded operator path is absent but the glob-resolved path exists, the wrapper selects the glob-resolved path. This catches regression on Candidate A's glob-resolution logic."

---

### R1-F03 — G11 missing test-update item from #96

- **finding_id:** R1-F03
- **severity:** medium
- **change_type:** correctness
- **referenced_files:** [docs/qrspi/2026-04-29-v0.4-bundle/goals.md]

Issue #96 (G11 source) includes a concrete test-update obligation: "Update `tests/acceptance/test-hardening-skills.bats:[M26][Obs19]` to reflect the new directive shape." G11's What we know so far describes the prompt surfaces and candidates but makes no mention of the acceptance-test update that the directive change implies. Per B4, this test-debt item must appear as a candidate Design should weigh.

**Fix:** Add a note or candidate bullet under G11's What we know so far that the WHY-not-WHAT directive change carries a corresponding acceptance-test update obligation (the existing directive-shape tests will need to track the new language), and that Design should weigh how thoroughly to re-specify the test assertions given G9's lightweight-path landing.

---

### R1-F04 — G8 expands scope beyond #93 to cover external task-tracker IDs

- **finding_id:** R1-F04
- **severity:** medium
- **change_type:** scope
- **referenced_files:** [docs/qrspi/2026-04-29-v0.4-bundle/goals.md]

Issue #93's stated problem and recommended fix are scoped exclusively to **QRSPI-internal IDs** (goal IDs `**G07**`, `**M24**`, `U\d+`, F-numbers, task IDs). The issue's grep pattern proposals are `\*\*G\d{2}\*\*`, `\*\*M\d{2}\*\*`, `\*\*U\d+\*\*` — no mention of GitHub issue numbers or external trackers.

G8 adds a second class ("External task-tracker IDs — GitHub issue numbers, JIRA-style tickets, etc.") that is not present in #93's body. It then introduces Candidate C, which explicitly requires best-practice research ("consult mainstream style guides — Google, Microsoft, Linux kernel, language-community guides — for what they actually prescribe") before any commitment can be made. This expands G8's research and design surface beyond what #93 specifies.

The expansion may be intentional (the goal authors broadened the problem space in-session), but it introduces new research work not tied to any source issue. Per checklist B2, scope that originates in the goal rather than the issue needs to be surfaced for user confirmation.

**Fix options:** (a) Confirm the external-tracker-IDs class is intentionally in scope for this bundle and document it as an in-session addition (analogous to G13, which is explicitly called out as having no source issue). (b) Narrow G8 back to QRSPI-internal IDs only, matching #93's scope, and open a separate issue for the external-tracker question.

---

### R1-F05 — G2 names a specific implementation file, crossing into Structure territory

- **finding_id:** R1-F05
- **severity:** low
- **change_type:** scope
- **referenced_files:** [docs/qrspi/2026-04-29-v0.4-bundle/goals.md]

G2's What we know so far opens: "The recommended fix is to explicitly endorse F-16 fix-path (a) in `per-task-orchestrator.md` and add the directive..." The literal filename `per-task-orchestrator.md` names the specific implementation file to edit. Per Goals DEFERS, "File / component / interface mapping → Structure." Naming the specific file to change is file-level mapping that belongs in Structure, not Goals.

The fix shape (endorse a specific fix-path, add a prohibition directive) is appropriate goal-altitude content. Only the filename crosses the boundary.

**Fix:** Replace `in \`per-task-orchestrator.md\`` with a surface descriptor, e.g.: "in the per-task orchestrator template" or "in the orchestrator dispatch template." Structure will identify the exact file.

---

### R1-F06 — G13↔G7 dependency not surfaced in Cross-Cutting Notes

- **finding_id:** R1-F06
- **severity:** low
- **change_type:** correctness
- **referenced_files:** [docs/qrspi/2026-04-29-v0.4-bundle/goals.md]

G13 Candidate C notes: "how to interact with G7's sandbox-replaces-hooks outcome — if the F-8 binary wall is replaced by per-tool-grant sandboxing, the defensive fallback rationale weakens further and direct-writes become the obvious default everywhere." This identifies a genuine inter-goal dependency: G7's outcome changes the rationale for G13's direct-write default.

The Cross-Cutting Notes section lists G1↔G2, G6↔G7, G7↔#24, and G9↔G12, but does not mention G13↔G7. Per checklist E1, where a dependency genuinely exists it must be called out in Cross-Cutting Notes; a dependency noted only inside a candidate bullet is not surfaced at the level where Plan/parallelize can act on it.

**Fix:** Add a G13↔G7 note to Cross-Cutting Notes, e.g.: "G13 ↔ G7. If G7's hypothesis confirms sandbox covers the Bash execution channel (making the F-8 binary wall audit-only), the defensive text-return fallback in G13's per-researcher dispatch loses its rationale. G13's Candidate A direct-write default becomes unconditional regardless of G7's Edit/Write outcome."

---

## Overall verdict

ship-with-followups
