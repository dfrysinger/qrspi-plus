---
reviewer_tag: quality-claude
artifact: structure
round: 8
status: clean
---

# Structure quality review — round 8 — clean

R7 fix delta validated against R6 baseline (narrow round vs `HEAD~1`, scope_hint: `## File Map`, `## Hook-Point Locations`). All four documented R7 fixes land correctly and the resulting structure is internally consistent with design.md G31's Distribution Table.

## Validated fixes

1. **Slice 1.5 row for `agents/qrspi-plan-test-coverage-reviewer.md` (Consumer #9).** Line 134 adds the row with `Modify` action and a responsibility cell that names Addition C inline placement (TOP of review-procedure section), the standalone disposition (no wrapper preload), and the design rationale (full reviewer block would compromise judgment on `task_type: code` tasks). Matches design.md G31 Addition C placement and the Distribution Table row #9.

2. **G31 Hook-Point subsection rewrite (lines 768–784).** Renamed from "prompt-prose-writer `!cat` include sites" to "prompt-prose `!cat` include sites" (covers writer + reviewer + inline additions). Intro paragraph correctly partitions `!cat` sites from `skills:` frontmatter preload sites (Consumers #4–#8) and explicitly acknowledges Additions A/C/D as inline-permanent (not `!cat`-resolved). All 7 sites enumerated with design-doc cross-references:
   - Consumer #1 — plan classifier (Addition A inline, which itself carries the detection `!cat`)
   - Consumer #2 — plan writer-subagent dispatch payloads (2 sites)
   - Consumer #3 — design authoring step
   - File 4 wrapper SKILL body
   - File 5 wrapper SKILL body
   - Consumer #9 Addition C site
   - Consumer #6 Addition D site

3. **OLD-keyed rename convention.** All four rename rows (line 23 `codex-emission-override.md` → `third-party-emission.md`; line 60 `run-codex-review.sh` → `dispatch-agent.sh`; line 61 `run-third-party-llm.sh` → `dispatch-companion.sh`; line 62 `codex-finding-splitter.sh` → `third-party-finding-splitter.sh`) now use OLD path as the row key with `Rename → NEW` in the Action column. Matches the pre-existing `launch-await-pattern.md` rename row (line 69).

4. **Test file Rename conversion.** Lines 97–98 converted from `Modify` to `Rename → NEW`:
   - `test-run-codex-review.bats` → `test-dispatch-agent.bats`
   - `test-codex-review-codex-availability.bats` → `test-dispatch-companion-availability.bats`
   Responsibility cells updated to reference the new dispatch-agent / dispatch-companion subjects.

## Cross-reference check (full G31 Distribution Table coverage)

All 9 G31 consumers per design.md Distribution Table are accounted for across the structure file map:

| # | Consumer | structure.md location |
|---|---|---|
| 1 | `skills/plan/SKILL.md` § Per-Task Classification | Slice 1.5 row L109 (plan/SKILL.md Modify, lists G31) |
| 2 | `skills/plan/SKILL.md` writer-subagent dispatch (2 sites) | Slice 1.5 row L109 (same) |
| 3 | `skills/design/SKILL.md` authoring step | Slice 1.5 row L106 (design/SKILL.md Modify, lists G31, names the `!cat` pair) |
| 4 | `agents/qrspi-implementer-lightweight.md` | Slice 1.5 row L132 (explicit `prompt-prose-writer` preload) |
| 5 | `agents/qrspi-code-quality-reviewer.md` | Slice 1.4 row L90 (explicit `prompt-prose-reviewer` preload + G22 tier work) |
| 6 | `agents/qrspi-design-reviewer.md` | Slice 1.5 row L110 (G31 listed; Addition D acknowledged in new Hook-Point table row) |
| 7 | `agents/qrspi-plan-reviewer.md` | Slice 1.5 row L112 (G31 listed for shared rules application) |
| 8 | `agents/qrspi-plan-spec-reviewer.md` | Slice 1.5 row L133 (explicit `prompt-prose-reviewer` preload) |
| 9 | `agents/qrspi-plan-test-coverage-reviewer.md` | Slice 1.5 row L134 (new in R7 — Addition C inline, standalone) |

Plus the three shared snippet files + two wrapper SKILLs are created in Slice 1.5 (L120–L124) and `docs/prompt-design-guide.md` rename/handoff at L126.

## No new findings

- Structure matches design: ✓
- Vertical-slice mapping coherent: ✓
- No missing components: ✓
- No unnecessary components: ✓
- Interfaces well-defined: ✓ (Hook-Point table now itemizes every G31 insertion point with design-doc citations)
- No conflicts with existing codebase patterns: ✓ (rename rows now follow established OLD-keyed convention)
