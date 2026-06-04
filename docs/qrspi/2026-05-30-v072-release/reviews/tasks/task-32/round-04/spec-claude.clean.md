# Spec Reviewer (claude) — Task 32, Round 4 — CLEAN

Verified against `tasks/task-32.md` requirements:

## Completeness
- **Design incremental persistence** (status: draft, no staging file): `skills/design/SKILL.md` "Incremental Persistence (Direct-to-Artifact Drafting)" section (diff L9–L38). ✓
- **Goals incremental persistence**: `skills/goals/SKILL.md` corresponding section (diff L97–L123). ✓
- **Design Cross-Goal Decisions section** authored as a dedicated `## Cross-Goal Decisions` location (diff L13). ✓
- **Goals dialogue-conduct subset**: Rules 1, 2, 3 (codebase→web only, no research-summary tier), 4, 6, 7, 8 present; Rule 5 (simple-language) intentionally absent — rule numbering jumps 4→6 (diff L67–L96). Wording matches Design verbatim where required. ✓
- **Goals template / question-topic checklist / Pipeline Mode Selection preserved** — unchanged headings, additions inserted alongside (verified at L284, L286 of goals SKILL and pinned by tests at diff L318–L323). ✓
- **Presence ≡ locked semantics** documented in both skills (diff L15, L101). ✓
- **Keyed in-place overwrite on re-lock** documented in both (diff L17, L103). ✓
- **Resume-after-compaction diagnostic** exact string pinned in both: `"Resumed after compaction — last locked decision: GNN (M decisions locked, K remaining). Continuing from G(NN+1)."` (diff L25, L111). ✓
- **Remaining-work split**: Goals asks user (diff L108); Design diffs `goals.md` minus locked blocks (diff L22). ✓
- **Finalize behavior**: Goals validates completeness, optional Purpose append, flips to `approved` (diff L117–L123). Design validates five fields per goal + Cross-Goal Decisions well-formedness, flips to `approved-pending-review` (diff L31–L38). ✓
- **Iron Rule reconciliation (sf-F02)**: placeholder language replaced with "re-enter dialogue to obtain the missing content before persisting the goal block — do NOT write a placeholder, partial, or tentative body (presence ≡ locked …)" (diff L141; verified at goals SKILL L293). ✓
- **Synthesis subagent merge-with-draft (sf-F01)**: both skills' subagent inputs include the existing draft as REQUIRED with explicit "MUST merge … rather than re-synthesizing from conversation alone" (diff L47, L132). ✓
- **Finalize test phrase pin (sf-F04)**: goals finalize test pins finalize-block-unique phrase "Validate that every locked goal" so deletion of finalize block can't be masked by mid-phase prohibition line (diff L277). ✓
- **Simulated-compaction durability contract** pinned in both skills with "identical to a no-compaction run" language (diff L29, L115); tests assert both phrases (diff L291–L299). ✓

## Scope
- All edits limited to the three Target files. No scope creep observed.

## Interpretation
- Rule 3 correctly drops the research-summary tier and uses codebase→web ordering only — matches "Goals-safe grounding order" requirement.
- Rule 5 absence verified by negative grep test (diff L171–L173).
- Goals finalize transitions to `approved` (not `approved-pending-review`); Design transitions to `approved-pending-review`. Both match the spec's skill-specific finalize wording.

## Test Coverage
Every Test expectation in the task spec maps to one or more bats cases (35 new tests at diff L149–L357). No spec expectation uncovered.

## Extras
None.

## Target-files check
PASS — only `skills/goals/SKILL.md`, `skills/design/SKILL.md`, `tests/unit/test-interactive-skill-prompts.bats` modified.

No findings.
