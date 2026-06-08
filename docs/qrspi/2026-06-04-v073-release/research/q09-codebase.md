---
status: draft
question_ids: [9]
research_type: codebase
---

# Q9: How is the Orchestration Boundary HARD-RULE referenced across skill files in the codebase, and what does each reference consist of?

## Summary

**TL;DR:** The Orchestration Boundary rule is defined once — as a `### Orchestration Boundary` section in `skills/implement/SKILL.md` — and appears in two additional places in that same file as inline back-references. One other skill file, `skills/implementer-protocol/notifications.md`, cites it by path pointer. No other skill files reference it directly. The label "HARD-RULE" does not appear verbatim in any skill file; it is used only in non-skill documentation.

**Key findings:**
- The canonical definition site is `skills/implement/SKILL.md:454`, under `## Per-Task Execution → ### Orchestration Boundary`, which contains the all-caps rule block, detailed prose on main chat's responsibilities and prohibitions, a rationale paragraph ("Why this rule matters"), and a "Red flag — STOP" callout.
- `skills/implement/SKILL.md:1103` contains an inline cross-reference: "Do NOT have main chat run `git commit` itself — that violates the orchestration boundary at § Per-Task Execution → Orchestration Boundary."
- `skills/implement/SKILL.md:1281` contains a red-flag bullet: "Main chat running tests, typecheck, lint, git commit, or file writes directly — these must be subagent work (see Orchestration Boundary)."
- `skills/implementer-protocol/notifications.md:123` cites the section by path pointer to carve out an exception: writing `resolution: n/a` to notification frontmatter is NOT a violation because notification files are artifact metadata, not target-project source files.
- `skills/integrate/SKILL.md` and `skills/test/SKILL.md` contain no reference to the Orchestration Boundary by name, despite both involving fix loops where the rule applies.
- The string "HARD-RULE" does not appear anywhere in any skill file; it appears only in `docs/qrspi/2026-06-04-v073-release/goals.md`.

**Surprises:** The term "HARD-RULE" is used colloquially in the goals.md problem statement to refer to this rule, but the skill files themselves never use that label. The rule is presented as a section heading with an all-caps code block and explanatory prose.

**Caveats:** The `build/skills/` directory is a build-output copy of `skills/`; it was confirmed to contain identical references and is not treated as a separate source tree. Worktree copies (`.worktrees/v0.7.2-release/task-*/skills/`) were not individually enumerated, as they are per-task working copies rather than canonical sources. The investigation covered all files under `skills/` exhaustively.

## Full findings

### Location 1 — Definition site: `skills/implement/SKILL.md:454`

**Section:** `## Per-Task Execution → ### Orchestration Boundary`

**What it consists of:**

The heading introduces the rule with an all-caps code block:

```
MAIN CHAT ONLY ORCHESTRATES. ALL CODE EXECUTION, FILE CHANGES, AND GIT
OPERATIONS ARE DELEGATED TO SUBAGENTS. MAIN CHAT NEVER RUNS THE WORK.
```

Immediately following the block, prose enumerates:

- **Main chat's responsibilities:** dispatch implementer + reviewer + fix-round subagents, aggregate their findings, gate transitions, and write review logs (`reviews/tasks/task-NN-review.md` — the only file main chat authors directly).
- **Main chat's explicit prohibitions:** run tests / typecheck / lint, write or edit target-project source files (except the review log), run `git add` / `git commit`, invoke language toolchains, or perform "quick verification" between review rounds.
- **"Why this rule matters" rationale:** Subagents inherit main chat's CWD, so keeping main chat at project root preserves clean recovery semantics — main chat can re-dispatch subagents into any worktree and write review logs at the artifact dir without first cd-ing back out of a task tree.
- **"Red flag — STOP" callout:** "If you find yourself about to run `pnpm` / `npm` / `cargo` / `git commit` / `Write` / `Edit` from main chat as part of task execution, stop. Dispatch a subagent instead. The only code main chat writes directly is review-log markdown under `reviews/tasks/`."

(File: `skills/implement/SKILL.md`, lines 454–467)

---

### Location 2 — Inline back-reference: `skills/implement/SKILL.md:1103`

**Section:** `## Per-Task Execution → ### Between Rounds` (HEAD-advanced verification paragraph)

**What it consists of:**

A prohibition at the end of the SHA-verification description:

> "Do NOT have main chat run `git commit` itself — that violates the orchestration boundary at § Per-Task Execution → Orchestration Boundary."

This appears in the context of explaining that `round-prepare.sh` owns anchor writes and that a failed verification leaves no `round-NN-commit.txt` on disk. The sentence applies the Orchestration Boundary rule as a concrete prohibition against main chat running `git commit` in response to exit-code failures.

(File: `skills/implement/SKILL.md`, line 1103)

---

### Location 3 — Red-flag bullet: `skills/implement/SKILL.md:1281`

**Section:** `## Per-Task Execution → ### Per-Task Red Flags — STOP`

**What it consists of:**

A bold bullet in the Per-Task Red Flags list:

> "**Main chat running tests, typecheck, lint, git commit, or file writes directly — these must be subagent work (see Orchestration Boundary).**"

This reference enumerates the specific operations prohibited and points the reader back to the Orchestration Boundary section by name, without quoting the rule text inline.

(File: `skills/implement/SKILL.md`, line 1281)

---

### Location 4 — Path-pointer cross-reference: `skills/implementer-protocol/notifications.md:123`

**Section:** Inline exception carve-out for main-chat `resolution: n/a` writes

**What it consists of:**

A sentence clarifying that writing `resolution: n/a` directly into a notification file's frontmatter does NOT violate the Orchestration Boundary:

> "This is treated as artifact metadata authoring (notifications live under `tasks/task-NN/notifications/`, inside the artifact directory) and does NOT violate the 'main chat does not edit target-project source files' rule in `implement/SKILL.md` § Per-Task Execution → Orchestration Boundary."

The reference is a path pointer (not inline prose restatement) used to assert an exception. Three criteria must hold for the exception to apply: the notification's `target_file` is not modified by any in-batch task; the `change_shape` requires no in-batch code change; and the user has assented.

(File: `skills/implementer-protocol/notifications.md`, lines 121–123)

---

### Skill files with NO reference to Orchestration Boundary

The following skill files in `skills/` contain no reference to the Orchestration Boundary by name, despite involving orchestration loops where the rule applies:

| File | Notes |
|------|-------|
| `skills/integrate/SKILL.md` | Defines a fix loop (dispatches implementer subagents for findings) but does not restate or cross-reference the Orchestration Boundary |
| `skills/test/SKILL.md` | Runs acceptance testing and dispatches Implement as a subagent for fix routing, but does not reference the Orchestration Boundary |
| `skills/plan/SKILL.md` | No reference |
| `skills/design/SKILL.md` | Uses "orchestrator/subagent boundary" in a different, generic context (line 208, 219); not a reference to the Orchestration Boundary rule |
| `skills/goals/SKILL.md` | No reference |
| `skills/parallelize/SKILL.md` | No reference |
| `skills/replan/SKILL.md` | No reference |
| `skills/phasing/SKILL.md` | Uses "boundary" in unrelated contexts |
| `skills/research/SKILL.md` | No reference |
| `skills/research-isolation/SKILL.md` | Uses "boundary" only in the context of the FINDING-BOUNDARY marker, unrelated |
| `skills/reviewer-protocol/SKILL.md` | No reference |
| `skills/questions/SKILL.md` | No reference |
| `skills/structure/SKILL.md` | No reference |
| `skills/using-qrspi/SKILL.md` | No reference |
| `skills/implementer-protocol/SKILL.md` | No reference (the implementer protocol describes what the implementer subagent does, not what main chat does) |

---

### The "HARD-RULE" label

The phrase "HARD-RULE" does not appear anywhere in any skill file. It appears in `docs/qrspi/2026-06-04-v073-release/goals.md` in the problem statement for G5, where it is used colloquially to describe the all-caps rule block in `implement/SKILL.md`. Within the skill files, the rule is presented as a section heading (`### Orchestration Boundary`) with an all-caps code block — not as a labeled "HARD-RULE" token.
