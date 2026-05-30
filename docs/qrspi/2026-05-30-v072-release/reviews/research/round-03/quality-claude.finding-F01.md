---
finding_id: quality-claude.R3-F01
severity: low
change_type: correctness
artifact: research
round: 3
reviewer: quality-claude
referenced_files:
  - docs/qrspi/2026-05-30-v072-release/research/summary.md
---

# Cross-References section omits all Q24–Q27 inter-question relationships

## Location

`research/summary.md` — `## Cross-References` section (the final section of the file, after the Q27 block).

## Observation

The `## Cross-References` section documents inter-question relationships for Q1–Q23 (nine entries, each covering a multi-question relationship cluster). No entries were added for Q24–Q27 in this mini-round delta. At least four documentable relationships exist between the new questions and the existing corpus:

1. **Q24 × Q26** — Q24 catalogs `artifact_body` usage across all 11 per-skill SKILL.md dispatch shapes; Q26 independently confirms `artifact_body` is the sole in-contract delivery form with no competing `artifact_path` parameter in any reviewer dispatch. They are complementary halves of the same inventory.

2. **Q26 × Q27** — Q26 establishes that `artifact_path` is outside the reviewer dispatch contract (appears only in scope-tagger and git-diff shell contexts); Q27 documents the only observed real-world instance of out-of-contract `artifact_path` use (87 KB v072 `summary.md`, commit `45625ed`, goals.md G29 / issue #262). Together they form the "contract gap + its sole empirical instance" pair.

3. **Q25 × Q3** — Q3 covers the apply-fix protocol filter thresholds (≥80 style/clarity, ≥70 correctness); Q25 confirms those threshold rules have no cluster-exception carve-out anywhere in `skills/`, `agents/`, or `scripts/`, and that all observed cluster-application precedent is confined to v072 orchestrator-authored dispositions files.

4. **Q24 × Q4 × Q5** — Q4 and Q5 form the existing "Codex dispatch path trinity" Cross-Reference entry (Q4: task-tool vs. shell-pipeline decision; Q5: internal wiring through `run-codex-review.sh` → `run-third-party-llm.sh` → `codex-finding-splitter.sh`). Q24 extends that documentation to cover all 11 per-skill SKILL.md files, including the boilerplate-present vs. boilerplate-absent split across the skills.

## Why this is a correctness gap

The Cross-References section is part of the collated summary artifact; its purpose is to document known inter-question relationships for readers navigating the research. The relationships above are factually established by the Q24–Q27 findings themselves. Leaving them out means the section provides an incomplete picture of how the new questions relate to the existing Q1–Q23 findings. This is a factual omission in the summary artifact, not merely a presentation preference.

## Suggested addition (illustrative — do not editorialize)

The following entries represent what a complete Cross-References section would contain for Q24–Q27. Exact wording should be drawn verbatim from the relevant Q sections per the collation-fidelity rule:

- **Q24 × Q26 — Reviewer dispatch mechanics / artifact delivery form**: Q24 documents the `artifact_body` parameter used in every per-skill Claude and Codex dispatch shape; Q26 confirms `artifact_body` (inline-wrapped form) is the sole mechanism prescribed by `reviewer-protocol/SKILL.md § Reviewer Dispatch Contract`, with `artifact_path` absent from all reviewer dispatch shapes.
- **Q26 × Q27 — Out-of-contract `artifact_path` use**: Q26 establishes that `artifact_path` is not a reviewer dispatch parameter in any current contract; Q27 documents the only observed ad-hoc use — the v072 87 KB `research/summary.md` dispatched via `artifact_path` (commit `45625ed`, goals.md G29 / PI-012) — which seeded the G29 goal to canonize path-based dispatch for large artifacts.
- **Q25 × Q3 — Threshold rules / no cluster exception**: Q3 covers the ≥80/≥70 filter thresholds applied in the apply-fix protocol; Q25 confirms those rules contain no cluster-exception text anywhere in `skills/`, `agents/`, or `scripts/`, with all observed cluster-application rationale confined to v072 orchestrator dispositions files.
- **Q24 × Q4 × Q5 — Codex dispatch path (extended)**: Q4 and Q5 cover the Codex dispatch path trinity (task-tool decision, `run-codex-review.sh` internal wiring); Q24 extends that coverage to all 11 per-skill SKILL.md files and documents the boilerplate-present (goals–parallelize, 7 skills) vs. boilerplate-absent (plan–test, 4 skills) split, with the wrapper supplying the emission format for the latter group.
