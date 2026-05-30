# Research Round 01 Dispositions

Reviewers: quality-claude (sonnet-4.6), quality-codex (gpt-5.3-codex). No scope-reviewer for Research per canonical topology.

## Findings summary

| ID | Reviewer | Subject | Verifier score | Disposition |
|----|----------|---------|----------------|-------------|
| F01 | quality-claude | Cross-References section is "synthesis violation" of verbatim-extraction rule | 0 | **DROP** — false positive |
| F01 | quality-codex | Same: Cross-References section "violates verbatim collation" | 0 | **DROP** — false positive |
| F02 | quality-codex | Per-question summary blocks lack file:line citations for code claims | 5 | **DROP** — premise wrong |
| F03 | quality-codex | Q17 and Q18 (web research) summary blocks lack inline URL citations for factual claims | 75 | **KEEP** — applied via Rejection Path 2 |

## qc-F01 / qx-F01: Cross-References DROP (convergent false positive)

Both reviewers (Claude and Codex) flagged the `## Cross-References` section at the end of `summary.md` as a verbatim-collation violation. The reviewer-agent body's Step 2 verbatim-collation check (`agents/qrspi-research-reviewer.md`) reads strictly: "the collator must not synthesize or paraphrase."

However, `skills/research/SKILL.md` L87 explicitly permits a Cross-References section: **"the assembled output is just those blocks stitched together in question order, plus a short Cross-References section."** This is a documented authoring carve-out the reviewer agent body fails to honor.

This is a real plugin defect — the reviewer agent body and the skill contradict each other on what the collator is permitted to produce. Filed as **PI-007** (status: observed) — will be reported to the GitHub repo in the issues batch at design human-gate.

Verifier-confirmed (both at score 0, premise wrong): DROP. The Cross-References section in `summary.md` is correct per the skill.

## qx-F02: file:line citations DROP

Codex F02 claimed that per-question summary blocks (## Summary headers at the head of each `q*.md` file, extracted by the collator) lack file:line citations.

Verifier inspection of the underlying q-files showed that file:line citations DO appear consistently in the **Full findings** body of each q*.md report. The "summary block" (TL;DR / Key findings / Surprises / Caveats) is a deliberate at-a-glance précis per the Per-Researcher Subagent template, and the canonical evidence lives in `## Full findings` below. The finding conflates the summary-block-level précis with the canonical evidence.

Verifier score: 5 (premise wrong). DROP.

## qx-F03: web URL citations APPLIED (Rejection Path 2 — specialist re-dispatch)

Codex F03 correctly identified that Q17 (bats-core BW02 / shellcheck rules — web research) and Q18 (Anthropic / OpenAI subagent tool-grant documentation — web research) had summary blocks listing factual claims without inline URL citations next to each claim. URLs existed in the `## Full findings` sections below but not in the summary block.

This is a real defect — a reader skimming only the collated `research/summary.md` cannot verify each web-research claim against a source.

Verifier score: 75 (correctness ≥70 threshold met). **KEEP**.

**Fix path:** Rejection Path 2 — re-dispatched Q17 and Q18 specialists (`qrspi:qrspi-research-specialist`, claude-sonnet-4.6, mode: background) with a sanitized defect summary scoped to citation density in the summary block. Both completed; rewrites preserved all prior facts and added inline URLs to every factual claim in TL;DR / Key findings / Surprises bullets. Re-dispatched collator (`qrspi:qrspi-research-collator`) to re-extract; renamed `_collated.md` → `summary.md`.

Verification: `grep "http" Q17-summary-block` = 8 inline URL refs; Q18 = 12 inline URL refs. Both ≥1 URL per factual bullet — citation density restored.

## Plugin issues observed this round

- **PI-007** (status: observed, severity: p2) — Research reviewer agent body Step 2 verbatim-collation check fails to honor the Cross-References carve-out at `skills/research/SKILL.md` L87. Both Claude and Codex reviewers convergently flagged the section as a violation. Filed at design human-gate.
- **PI-006 recurrence** — 1 of 4 R1 verifiers (verify-research-r1-qx-f01, claude-haiku-4.5) returned chat-only without writing the sidecar. Orchestrator wrote the sidecar manually. Verifier non-determinism continues to manifest.
- **Sidecar filename drift** — one verifier sidecar wrote to `verify-quality-codex.finding-F02.md.score.yml` (duplicate extension stem instead of `.md → .score.yml`). PI-008 family pattern; tracking for batch report at design gate.
