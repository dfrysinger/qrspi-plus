---
status: draft
question_ids: [5]
research_type: codebase
---

# Q5: Marker language in design.md for absorbed/deferred/non-goal goals and plan-author skill interaction

## Summary

**TL;DR:** `design.md` uses four distinct marker conventions to signal goal disposition — a section-heading suffix for absorbed/moot goals, a bold `**Explicit non-goal.**` phrase for in-block exclusions, an HTML comment tag for prose deferred to Implement, and free-prose "deferred to vX.Y+" for next-release deferrals. The plan-author skill (`skills/plan/SKILL.md`) has no explicit procedural rule for skipping absorbed/moot goals; instead, Plan receives `design.md` as a companion input and infers omission from the acceptance-criteria statement "no separate task ships under this goal ID" inside each absorbed/moot block. The `qrspi-plan-goal-traceability-reviewer` agent enforces correctness at review time via a gap-analysis check.

**Key findings:**
- **Absorbed/moot section heading suffix**: Goal blocks for absorbed or moot goals carry a `: moot / absorbed by <CD-ID>` or `: moot / already fixed` suffix in their `## GNN —` section heading (e.g., `## G25 — Per-H4 fail-loud mirror pattern: moot / absorbed by CD-1`; `## G26 — BW02 deprecation warnings: moot / already fixed`; `## G29 — Reviewer dispatch artifact escape hatch: moot / absorbed by CD-1` in `docs/qrspi/2026-05-30-v072-release/design.md`).
- **Explicit non-goal phrase**: Items excluded from a goal's scope appear in a `**What GNN does NOT cover.**` subsection as bulleted items followed by the bold phrase `**Explicit non-goal.**` (e.g., `design.md` lines for G25, G26, G29).
- **Deferred-to-Implement HTML comment marker**: Prose decisions too large to author verbatim in design.md use the HTML comment `<!-- prose-design (deferred to Implement): <target file> § <section> -->` with an intent + skeleton + anchor-phrases block below it (`skills/design/SKILL.md` lines 164–173).
- **Next-release deferral free prose**: Goals or sub-items deferred to a future version use plain prose, e.g., "Codex CLI host support deferred to v0.7.3+" or "deferred to Plan" (`design.md` passim).
- **Goal lifecycle vocabulary** explicitly cited (in G25 Open Questions, design.md line 2117): `known-fix`, `exploratory`, `moot`, `deferred`; "absorbed by a cross-goal decision" is identified as an emergent disposition class in v0.7.2 not yet in the standard vocabulary.
- **Plan skill receives design.md as companion input**: `skills/plan/SKILL.md` line 136 lists `design.md` as a Plan overview subagent input; line 347 passes it as `companion_design` to all seven plan-artifact reviewers (full pipeline only).
- **Plan authoring loop defers to acceptance criteria in design.md**: `skills/plan/SKILL.md` line 142 instructs "Break structure into ordered tasks following vertical slices and phases from `design.md`"; absorbed/moot goal blocks contain an explicit acceptance criterion statement like "G25 is locked at design time as moot / absorbed by CD-1; no separate v0.7.2 task ships under the G25 ID" (`design.md` line 2110) — Plan reads this content and produces no task for that goal.
- **No explicit plan-skill "skip" rule for absorbed goals**: There is no procedural rule in `skills/plan/SKILL.md` that says "if design.md marks a goal as moot, skip it." The signal is communicated entirely through the design.md acceptance-criteria text.
- **Gap-analysis reviewer enforces at review time**: The `qrspi-plan-goal-traceability-reviewer` agent (`agents/qrspi-plan-goal-traceability-reviewer.md` §3 Gap Analysis) checks for design commitments the plan omits and flags mismatches, but would not flag an absent task for a goal whose design block says no task ships.

**Surprises:** The plan-author skill contains no explicit procedural instruction for handling absorbed/moot goals from design.md — the mechanism is entirely inference-from-content (Plan reads the acceptance criteria saying "no task ships") plus downstream reviewer enforcement, rather than a dedicated skip rule.

**Caveats:** The v0.7.3 `design.md` does not yet exist (the directory has `goals.md`, `research/`, etc. but no `design.md`), so all findings are drawn from the v0.7.2 design artifact and current skill/agent files. The goal-lifecycle vocabulary question (whether "absorbed by CD" should become a first-class term alongside `known-fix`, `exploratory`, `moot`, `deferred`) was explicitly left open as a v0.7.3+ question in v0.7.2's design.md.

---

## Full findings

### Marker language in `design.md`

#### 1. Absorbed / moot goal — section-heading suffix

Goals whose original framing is rendered moot by a cross-goal architectural decision, or that are already fixed at design time, carry a disposition suffix appended to the standard `## GNN — <title>` heading. Three examples from `docs/qrspi/2026-05-30-v072-release/design.md`:

| Line | Heading |
|------|---------|
| 2084 | `## G25 — Per-H4 fail-loud mirror pattern: moot / absorbed by CD-1` |
| 2123 | `## G26 — BW02 deprecation warnings: moot / already fixed (regression-prevention rides on G21)` |
| 2308 | `## G29 — Reviewer dispatch artifact escape hatch: moot / absorbed by CD-1` |

The suffix pattern is: `: moot / absorbed by <cross-goal-decision-ID>` or `: moot / already fixed`. Parenthetical notes may be appended after the disposition label (e.g., `(regression-prevention rides on G21)`).

Within each absorbed/moot goal block, the acceptance-criteria subsection makes the no-task implication explicit. Examples:

- `design.md` line 2110: "G25 is locked at design time as moot / absorbed by CD-1; no separate v0.7.2 task ships under the G25 ID."
- `design.md` line 2336: "G29 is locked at design time as moot / absorbed by CD-1; no separate v0.7.2 task ships under the G29 ID."

The `**Type:** known-fix.` field also appears in the goal block header prose for all three (e.g., design.md line 2086: `**Type:** known-fix.`), indicating the goal type in the lifecycle sense.

#### 2. Explicit non-goal — bold phrase in "What GNN does NOT cover" subsection

Within individual goal blocks, items that are explicitly out of scope appear under a `**What GNN does NOT cover.**` bold-prose subheading. Each excluded item is described as a bullet or bold item, followed by the phrase `**Explicit non-goal.**` Examples from `design.md` G25 block (lines 2102–2107):

```
**What G25 does NOT cover.**
- **Authoring a new top-level invariant in the existing pre-CD-1 prose.** Explicit non-goal.
- **A standalone bats pin walking H4s under `### Dispatch routing blocks`.** Explicit non-goal.
- **Hedge implementation in case CD-1 slips.** Explicit non-goal.
```

This pattern appears in G25, G26, and G29. The phrase `Explicit non-goal.` is the canonical marker for in-block scope exclusions.

#### 3. Deferred-to-Implement — HTML comment marker

For design decisions involving large prose artifacts (multi-section skill bodies, lengthy agent instructions), `design.md` uses a two-form HTML comment + fenced block convention, defined in `skills/design/SKILL.md` lines 164–173:

```
<!-- prose-design (deferred to Implement): <target file> § <section> -->
Intent: <one-paragraph behavioral spec>
Skeleton: <ordered list of required subsections>
Anchor phrases (MUST be exact):
  - "<load-bearing sentence 1>"
  - "<load-bearing sentence 2>"
```

The verbatim (paragraph-scale) variant uses `<!-- prose-design: <target file> § <section> -->` without the `(deferred to Implement)` qualifier. The deferred variant signals that Plan must package this spec into a task with test expectations; the verbatim variant is an exact-copy contract for Implement.

#### 4. Next-release deferral — free prose

Goals or sub-decisions deferred to a future release use free prose embedded in the design block text. Examples from `design.md`:

- `design.md` line ~125: "Codex CLI host support deferred to v0.7.3+."
- `design.md` line ~131: "Assertion text, full test procedures, and per-test-file layout are deferred to Plan."

These do not carry a structured marker; they are prose statements within the goal or decision block.

#### 5. Goal lifecycle vocabulary

The established vocabulary is named in `design.md` line 2117 (G25 Open Questions): `known-fix`, `exploratory`, `moot`, `deferred`. The same line identifies "architecturally absorbed by a sibling Cross-Goal Decision" as an emergent v0.7.2 disposition not yet in the standard vocabulary, and poses whether it should become a standard slot.

---

### Plan-author skill interaction with these markers

#### Plan's inputs and authoring loop

`skills/plan/SKILL.md` specifies:

- **Lines 132–136** (Plan Overview Subagent Inputs): `design.md` is a required input alongside `goals.md`, `research/summary.md`, and `structure.md`.
- **Line 142**: The task: "Break structure into ordered tasks following vertical slices and phases from `design.md`."
- **Line 347**: `companion_design — design.md body wrapped between ... markers (full pipeline only — omit on route: quick)` — passed to all seven reviewer dispatches.

The plan overview subagent also receives `design.md` for per-task sub-subagents: "Sub-subagent inputs … `design.md` (for test strategy and vertical slice context)" (`skills/plan/SKILL.md` line 187).

#### No explicit skip rule for absorbed/moot goals

`skills/plan/SKILL.md` does not contain an explicit procedural instruction of the form "if design.md marks a goal as moot / absorbed, do not create a task for it." A keyword search across the plan skill file (`absorbed`, `moot`, `non-goal`, `non_goal`, `Explicit non-goal`) returns no matches in procedural rules. The plan skill defers entirely to the content of design.md itself.

The mechanism is: Plan reads design.md as a companion, encounters the acceptance-criteria text in each absorbed/moot block ("no separate task ships under this goal ID"), and produces no task for that goal. The design.md section-heading suffix (`: moot / absorbed by CD-1`) and the acceptance-criteria statement function together as the signal.

#### Plan DEFERS list re: design.md

`skills/plan/owns-defers.md` line 23 states the explicit boundary: "Architecture decisions, key trade-offs, system diagrams → `design.md` (locked upstream; Plan consumes, does not re-author)." Plan's own `DEFERS` list names "trade-off", "we considered", "alternative approach" in task description as a Design-layer leak triggering a scope finding (`owns-defers.md` line 33). Plan never re-authors absorbed/moot dispositions; it only consumes them.

#### Deferred-to-Implement prose blocks create tasks

When `design.md` contains a `<!-- prose-design (deferred to Implement): ... -->` block, `skills/design/SKILL.md` line 143–145 states: "Plan packages the deferred spec into a task with test expectations that assert intent, skeleton, and anchor-phrase presence." This is the one marker type that directly instructs the plan-author to create a task.

#### Goal traceability reviewer enforces at review time

`agents/qrspi-plan-goal-traceability-reviewer.md` §3 (Gap Analysis, full pipeline only) checks:
- "Does the design address every goal in goals.md?"
- "Are there design commitments the plan doesn't carry as a task or as a test expectation in plan.md?"

This reviewer receives `companion_design` (design.md body) and `companion_goals` (goals.md body). Because absorbed/moot goal blocks contain acceptance criteria stating no task ships, the reviewer would not flag an absent task for those goals as a coverage gap. Conversely, if Plan erroneously created a task for a moot goal, the reviewer's §2 backward-trace check ("Flag any task with no traceable justification") and §4 spec-to-design fidelity check would flag the mismatch.

#### Phase-scoped content rules

`skills/plan/SKILL.md` line 57: "plan.md contains ONLY current-phase tasks. Each task must reference goal IDs that exist in goals.md. Tasks for goals not in the current phase must not appear." For absorbed/moot goals, the design block acceptance criteria establish they produce no implementation task in any phase — the phasing constraint reinforces but does not replace the design-block signal.
