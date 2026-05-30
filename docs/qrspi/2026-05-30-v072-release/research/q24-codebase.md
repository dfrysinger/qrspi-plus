---
status: draft
question_ids: [24]
research_type: codebase
---

# Q24: Reviewer dispatch contracts across all per-skill SKILL.md files

## Summary

**TL;DR:** All eleven in-scope `skills/*/SKILL.md` files use the same two-transport model for reviewer dispatch: the **Claude task tool** (`Agent({ subagent_type: "…" })`) for Claude reviewers and a **shell pipeline** via `scripts/run-codex-review.sh` + `scripts/codex-companion-bg.sh await` + `scripts/codex-finding-splitter.sh` for Codex reviewers. The per-finding-emission boilerplate (the "Output format (per-finding emission, #109)" paragraph + worked one-finding example + `NO_FINDINGS` sentinel + constraint reminder) appears **verbatim and identically** in the first seven skills (goals, questions, research, design, phasing, structure, parallelize) but is **entirely absent** from the last four (plan, implement, integrate, test), which instead rely on the `run-codex-review.sh` wrapper to inject the format. Two additional, smaller divergences exist: Goals alone appends "Protocol and agent body flow via stdin" to its Codex dispatch header, and Integrate/Test describe their transport as "via the wrapper" rather than "via shell pipelines."

**Key findings:**
- **Claude dispatch** — identical mechanism across all 11 skills: `Agent({ subagent_type: "qrspi-{skill}-reviewer", model: "sonnet" })` task tool call with a structured prompt body; reviewer-protocol rules arrive via the agent's `skills: [reviewer-protocol]` preload, not inline in the dispatch prompt.
- **Codex dispatch** — all 11 skills use the same `scripts/run-codex-review.sh` wrapper (prints a jobId), then `scripts/codex-companion-bg.sh await <jobId> > /tmp/codex-stdout-<jobId>.txt`, then `scripts/codex-finding-splitter.sh <stdout-file> <review-dir> <reviewer-tag>` to materialize per-finding files.
- **Per-finding boilerplate present** in goals, questions, research, design, phasing, structure, parallelize (7 of 11): word-for-word identical text covering `<<<FINDING-BOUNDARY>>>` literal, `NO_FINDINGS` sentinel, splitter behavior on malformed output, worked one-finding YAML example, worked zero-findings example, and constraint reminder.
- **Per-finding boilerplate absent** in plan, implement, integrate, test (4 of 11): implement's SKILL.md (line 1060) explicitly states the wrapper "assembles the reviewer-protocol body, the named agent body (frontmatter stripped), the emission-override, and the Dispatch parameters block" — the format lives in the wrapper, not the SKILL.md prose.
- **Scope-reviewer topology**: goals/design/phasing/structure/parallelize/plan dispatch a scope-reviewer; questions/research/integrate/test/implement do NOT.
- **Minor transport-description divergences**: Goals line 260 uniquely adds "Protocol and agent body flow via stdin"; integrate line 122 and test line 152 say "via the wrapper" rather than "via shell pipelines."

**Surprises:** Plan (line 316) says "via shell pipelines" — consistent with goals–parallelize — yet omits the inline per-finding boilerplate entirely, making it the transitional skill between the two groups. Implement explicitly delegates format injection to the wrapper and documents that delegation at line 1060, making the omission intentional and self-documenting.

**Caveats:** The `skills/replan/SKILL.md` file was discovered to also contain a Codex dispatch block (line 142: "Protocol and agent body flow via stdin") but is **not** in the enumerated scope of Q24. The `scripts/run-codex-review.sh` wrapper source was not read — its exact emission-override content is not verified here. Findings are based on the SKILL.md prose and shell-pipeline code blocks; no runtime execution was performed.

---

## Full findings

### Overview: transport mechanisms

Every in-scope SKILL.md uses both transports in every review round:

| Transport | Claude | Codex |
|---|---|---|
| Mechanism | `Agent({ subagent_type: "qrspi-{skill}-reviewer", model: "sonnet" })` task tool | `scripts/run-codex-review.sh` shell pipeline launcher + `scripts/codex-companion-bg.sh await` + `scripts/codex-finding-splitter.sh` |
| Output | Reviewer writes finding files directly to `output` / `round_subdir` per reviewer-protocol disk-write contract | Splitter materializes per-finding files from Codex stdout into the same round directory |
| Rules delivery | Via agent's `skills: [reviewer-protocol]` preload; zero rules in dispatch prompt | Via wrapper (injects reviewer-protocol body + agent body per implement:1060) |

---

### `skills/goals/SKILL.md`

**Lines: 240–329**

- **Claude dispatch (quality + scope, in parallel):**
  - `Agent({ subagent_type: "qrspi-goals-reviewer", model: "sonnet" })` — reviewer_tag: `quality-claude` (line 240)
  - `Agent({ subagent_type: "qrspi-goals-scope-reviewer", model: "sonnet" })` — reviewer_tag: `scope-claude` (line 250)
  - Prompt fields: `artifact_body` (wrapped `goals.md`), `diff_file_path`, `reviewer_tag`, `scope_hint` (wrapped in `<<<UNTRUSTED-SCOPE-HINT-START/END>>>`), `round_subdir`
  - Reviewer-protocol and goals-specific checks arrive via agent's `skills:` preload. Scope-reviewer loads `skills/goals/owns-defers.md` at runtime.
  - **Transport description (line 260):** "via shell pipelines. Protocol and agent body flow via stdin:" — unique phrase across all 11 skills.

- **Codex dispatch (quality + scope, in parallel):**
  - Line 260: `scripts/run-codex-review.sh --agent-file agents/qrspi-goals-reviewer.md --reviewer-tag quality-codex …`
  - Line 303: `scripts/run-codex-review.sh --agent-file agents/qrspi-goals-scope-reviewer.md --reviewer-tag scope-codex …`
  - Await + splitter (lines 317–328): `codex-companion-bg.sh await <jobId> > /tmp/codex-stdout-<jobId>.txt` → `codex-finding-splitter.sh /tmp/codex-stdout-<jobId>.txt reviews/goals/round-NN/ quality-codex`; same for scope-codex.

- **Per-finding boilerplate (lines 262–289): PRESENT.**
  - `<<<FINDING-BOUNDARY>>>` literal — each finding block preceded by exactly this line.
  - `NO_FINDINGS` sentinel — entire output is one line when no findings.
  - Worked one-finding YAML example (lines 267–279): frontmatter with `finding_id`, `severity`, `change_type`, `referenced_files`, `artifact`, `round`, `reviewer`.
  - Worked zero-findings example (lines 283–285).
  - Constraint reminder (line 289).
  - Splitter behavior on malformed output described: "anything that is neither boundary-prefixed nor the `NO_FINDINGS` sentinel is malformed and produces zero finding files for this tag."

---

### `skills/questions/SKILL.md`

**Lines: 79–149**

- **Claude dispatch (quality only — no scope-reviewer per canonical topology):**
  - `Agent({ subagent_type: "qrspi-questions-reviewer", model: "sonnet" })` — reviewer_tag: `quality-claude` (line 83)
  - Prompt fields: `artifact_body` (wrapped `questions.md`), `companion_goals` (wrapped `goals.md`), `diff_file_path`, `reviewer_tag`, `scope_hint` (wrapped), `round_subdir`.
  - **Transport description (line 94):** "via a shell pipeline" (singular; no "Protocol and agent body" phrase).

- **Codex dispatch (quality only):**
  - Line 126: `scripts/run-codex-review.sh --agent-file agents/qrspi-questions-reviewer.md --reviewer-tag quality-codex …`
  - Await + splitter (lines 143–148): `codex-companion-bg.sh await <jobId> > /tmp/codex-stdout-<jobId>.txt` → `codex-finding-splitter.sh /tmp/codex-stdout-<jobId>.txt reviews/questions/round-NN/ quality-codex`.

- **Per-finding boilerplate (lines 96–123): PRESENT.** Identical text to goals.

---

### `skills/research/SKILL.md`

**Lines: 133–224**

- **Claude dispatch (quality only — no scope-reviewer):**
  - `Agent({ subagent_type: "qrspi-research-reviewer", model: "sonnet" })` — reviewer_tag: `quality-claude` (line 137)
  - Prompt fields: `artifact_body` (wrapped `research/summary.md`), `companion_qfile_paths` (list of absolute paths; reviewer Reads each file directly — NOT inline-embedded), `diff_file_path`, `reviewer_tag`, `scope_hint` (wrapped), `round_subdir`.
  - Pre-dispatch precondition: runs `check-qfile-paths.sh` to enumerate `research/q*.md` files; refuses dispatch on empty list or unreadable paths (lines 139–149).
  - Research-isolation invariant: NO `companion_goals`, NO `companion_questions` in dispatch.
  - **Transport description (line 168):** "via a shell pipeline" (singular).

- **Codex dispatch (quality only):**
  - Line 200: `scripts/run-codex-review.sh --agent-file agents/qrspi-research-reviewer.md --reviewer-tag quality-codex … --artifact-body research/summary.md --companion companion_qfiles=research/q01-{tag}.md …`
  - Await + splitter (lines 218–223): `codex-companion-bg.sh await <jobId> > /tmp/codex-stdout-<jobId>.txt` → `codex-finding-splitter.sh /tmp/codex-stdout-<jobId>.txt reviews/research/round-NN/ quality-codex`.

- **Per-finding boilerplate (lines 170–197): PRESENT.** Identical text to goals.

---

### `skills/design/SKILL.md`

**Lines: 151–248**

- **Claude dispatch (quality + scope, in parallel):**
  - `Agent({ subagent_type: "qrspi-design-reviewer", model: "sonnet" })` — reviewer_tag: `quality-claude` (line 157)
  - `Agent({ subagent_type: "qrspi-design-scope-reviewer", model: "sonnet" })` — reviewer_tag: `scope-claude` (line 169)
  - Quality reviewer prompt fields: `artifact_body` (wrapped `design.md`), `companion_goals`, `companion_research` (wrapped `research/summary.md`), `diff_file_path`, `reviewer_tag`, `scope_hint` (wrapped), `round_subdir`. On-demand: may also Read `research/q*.md` to verify citations (quality reviewer only).
  - Scope reviewer takes no companions; loads `skills/design/owns-defers.md` at runtime.
  - **Transport description (line 179):** "via shell pipelines:" (plural).

- **Codex dispatch (quality + scope, in parallel):**
  - Lines 211–228: `scripts/run-codex-review.sh --agent-file agents/qrspi-design-reviewer.md --reviewer-tag quality-codex …` and `--agent-file agents/qrspi-design-scope-reviewer.md --reviewer-tag scope-codex …`
  - Await + splitter: same pattern as goals for both quality-codex and scope-codex.

- **Per-finding boilerplate (lines 181–208): PRESENT.** Identical text to goals.

---

### `skills/phasing/SKILL.md`

**Lines: 104–207**

- **Claude dispatch (quality + scope, in parallel):**
  - `Agent({ subagent_type: "qrspi-phasing-reviewer", model: "sonnet" })` — reviewer_tag: `quality-claude` (line 112)
  - `Agent({ subagent_type: "qrspi-phasing-scope-reviewer", model: "sonnet" })` — reviewer_tag: `scope-claude` (line 126)
  - Quality reviewer prompt fields: `artifact_body` (wrapped `phasing.md`), `companion_roadmap`, `companion_pruned_pairs` (4 pruned + 4 future-* artifacts), `companion_goals_snapshot`, `companion_design_snapshot`, `diff_file_path`, `reviewer_tag`, `scope_hint` (wrapped), `round_subdir`.
  - Scope reviewer loads `skills/phasing/owns-defers.md`; fail-closed on missing/malformed OWNS/DEFERS section (line 134).
  - **Transport description (line 136):** "via shell pipelines:" (plural).

- **Codex dispatch (quality + scope, in parallel):**
  - Lines 168–185: `scripts/run-codex-review.sh` for quality-codex and scope-codex.
  - Await + splitter: same pattern, output dirs `reviews/phasing/round-NN/` (lines 195–207).

- **Per-finding boilerplate (lines 138–165): PRESENT.** Identical text to goals.

---

### `skills/structure/SKILL.md`

**Lines: 145–248**

- **Claude dispatch (quality + scope, in parallel):**
  - `Agent({ subagent_type: "qrspi-structure-reviewer", model: "sonnet" })` — reviewer_tag: `quality-claude` (line 153)
  - `Agent({ subagent_type: "qrspi-structure-scope-reviewer", model: "sonnet" })` — reviewer_tag: `scope-claude` (line 167)
  - Quality reviewer prompt fields: `artifact_body` (wrapped `structure.md`), `companion_goals`, `companion_research` (wrapped `research/summary.md`), `companion_design`, `companion_phasing`, `diff_file_path`, `reviewer_tag`, `scope_hint` (wrapped), `round_subdir`.
  - Scope reviewer loads `skills/structure/owns-defers.md`.
  - **Transport description (line 177):** "via shell pipelines:" (plural).

- **Codex dispatch (quality + scope, in parallel):**
  - Lines 209–226: `scripts/run-codex-review.sh` for quality-codex and scope-codex.
  - Await + splitter: same pattern, output dirs `reviews/structure/round-NN/` (lines 236–248).

- **Per-finding boilerplate (lines 179–206): PRESENT.** Identical text to goals.

---

### `skills/plan/SKILL.md`

**Lines: 263–421**

- **Claude dispatch (7 reviewers in parallel: 1 quality + 5 plan-artifact + 1 scope):**
  - `Agent({ subagent_type: "qrspi-plan-reviewer", model: "sonnet" })` — reviewer_tag: `quality-claude` (line 283)
  - Five plan-artifact reviewers: `qrspi-plan-spec-reviewer` (spec-claude), `qrspi-plan-security-reviewer` (security-claude), `qrspi-plan-silent-failure-hunter` (silent-failure-claude), `qrspi-plan-goal-traceability-reviewer` (goal-traceability-claude), `qrspi-plan-test-coverage-reviewer` (test-coverage-claude) (lines 298–302)
  - `Agent({ subagent_type: "qrspi-plan-scope-reviewer", model: "sonnet" })` — reviewer_tag: `scope-claude` (line 306)
  - All 6 quality+artifact dispatches share companions (`companion_goals`, `companion_research`, `companion_phasing`; + `companion_design`, `companion_structure` on full pipeline only) and a `route` field. Scope reviewer takes NO companions and NO `route`.
  - **Transport description (line 316):** "via shell pipelines:" (plural) — consistent with design/phasing/structure/parallelize.

- **Codex dispatch (7 in parallel — one per Claude reviewer):**
  - Lines 321–375: `scripts/run-codex-review.sh` for all 7 reviewers; scope reviewer omits companion flags.
  - Await + splitter (lines 383–418): `codex-companion-bg.sh await <jobId> > /tmp/codex-stdout-<jobId>.txt` → `codex-finding-splitter.sh /tmp/…txt reviews/plan/round-NN/ <tag>`, one block per reviewer.

- **Per-finding boilerplate: ABSENT.** Plan is the first skill in pipeline order to omit the "Output format (per-finding emission, #109)" paragraph, the worked examples, and the constraint reminder. The Codex dispatch block (line 316) goes directly to the shell code. No inline explanation of `<<<FINDING-BOUNDARY>>>` or `NO_FINDINGS`.

---

### `skills/parallelize/SKILL.md`

**Lines: 170–270**

- **Claude dispatch (quality + scope, in parallel):**
  - `Agent({ subagent_type: "qrspi-parallelize-reviewer", model: "sonnet" })` — reviewer_tag: `quality-claude` (line 178)
  - `Agent({ subagent_type: "qrspi-parallelize-scope-reviewer", model: "sonnet" })` — reviewer_tag: `scope-claude` (line 190)
  - Quality reviewer prompt fields: `artifact_body` (wrapped `parallelization.md`), `companion_plan`, `companion_tasks` (current-phase `tasks/*.md`), `diff_file_path`, `reviewer_tag`, `scope_hint` (wrapped), `round_subdir`.
  - Scope reviewer loads `skills/parallelize/owns-defers.md`.
  - **Transport description (line 200):** "via shell pipelines:" (plural).

- **Codex dispatch (quality + scope, in parallel):**
  - Lines 232–248: `scripts/run-codex-review.sh` for quality-codex and scope-codex.
  - Await + splitter (lines 258–269): same pattern, output dirs `reviews/parallelize/round-NN/`.

- **Per-finding boilerplate (lines 202–229): PRESENT.** Identical text to goals.

---

### `skills/implement/SKILL.md`

**Lines (per-task): 868–1182; gate reviewer: 1427–1454**

- **Claude dispatch (per-task correctness: 4 reviewers always; thoroughness: 4 more in deep mode for `task_type: code`):**
  - Correctness: `Agent({ subagent_type: "qrspi-spec-reviewer" })` (spec-claude), `qrspi-code-quality-reviewer` (code-quality-claude), `qrspi-silent-failure-hunter` (silent-failure-claude), `qrspi-security-reviewer` (security-claude) — lines 933–936.
  - Thoroughness (deep + code only): `qrspi-goal-traceability-reviewer`, `qrspi-test-coverage-reviewer`, `qrspi-type-design-analyzer`, `qrspi-code-simplifier` — lines 940–943.
  - Implement-gate reviewer (batch-level): `Agent({ subagent_type: "qrspi-implement-gate-reviewer", model: "sonnet" })`.
  - No scope-reviewer in implement.
  - Each dispatch prompt carries: `subject_code`, `task_definition`, `output`, `reviewer_tag`, `round`, `diff_file_path`, `scope_hint` (when narrowed). Additional `companion_plan` / `companion_goals` / `companion_test_expectations` for thoroughness reviewers.
  - **Transport description (line 1058):** "Dispatch a non-blocking Codex parallel. … Use `scripts/run-codex-review.sh` — the canonical reviewer dispatch wrapper. It assembles the reviewer-protocol body, the named agent body (frontmatter stripped), the emission-override, and the Dispatch parameters block, then pipes to the Codex companion launcher." — most explicit description of why no inline boilerplate is needed.

- **Codex dispatch (per-task):**
  - Lines 1062–1163: `scripts/run-codex-review.sh` invocations for each reviewer (spec, code-quality, silent-failure, security; + goal-traceability, test-coverage, type-design, code-simplifier in deep mode).
  - Await + splitter (lines 1168–1179): uses mktemp-based temp file, not `/tmp/codex-stdout-<jobId>.txt` naming convention (minor variation: `codex_stdout="$(mktemp)"`).

- **Per-finding boilerplate: ABSENT.** No `<<<FINDING-BOUNDARY>>>` documentation, no `NO_FINDINGS` worked example, no constraint reminder in the Codex dispatch block. The wrapper handles format injection.

---

### `skills/integrate/SKILL.md`

**Lines: 87–172**

- **Claude dispatch (integration + security, in parallel — no scope-reviewer):**
  - `Agent({ subagent_type: "qrspi-integration-reviewer", model: "sonnet" })` — reviewer_tag: `integration-claude` (line 102)
  - `Agent({ subagent_type: "qrspi-security-integration-reviewer", model: "sonnet" })` — reviewer_tag: `security-claude` (line 112)
  - Prompt fields (shared): `subject_code` (wrapped changed files), `companion_design`, `companion_structure`, `companion_task_review_findings`, `diff_file_path`, `reviewer_tag`, `scope_hint` (wrapped), `round_subdir`.
  - Integrate's diff covers entire merged feature branch (not a single artifact file); diff command omits `--` artifact-path argument.
  - **Transport description (line 122):** "via the wrapper:" — diverges from goals–plan which say "via shell pipelines."

- **Codex dispatch (integration + security, in parallel):**
  - Lines 125–154: `scripts/run-codex-review.sh --agent-file agents/qrspi-integration-reviewer.md --reviewer-tag integration-codex …` and `--agent-file agents/qrspi-security-integration-reviewer.md --reviewer-tag security-codex …`
  - Await + splitter (lines 161–171): `codex-companion-bg.sh await <integrationJobId> > /tmp/codex-stdout-<integrationJobId>.txt` → `codex-finding-splitter.sh /tmp/codex-stdout-<integrationJobId>.txt reviews/integration/round-NN/ integration-codex`; same for security-codex.

- **Per-finding boilerplate: ABSENT.** No inline format documentation.

---

### `skills/test/SKILL.md`

**Lines: 103–210**

- **Claude dispatch (3 reviewers: spec + code-quality + goal-traceability — same agents as Implement but in Test-phase reuse mode):**
  - `Agent({ subagent_type: "qrspi-spec-reviewer", model: "sonnet" })` — reviewer_tag: `spec-claude` (line 126)
  - `Agent({ subagent_type: "qrspi-code-quality-reviewer", model: "sonnet" })` — reviewer_tag: `code-quality-claude` (line 134)
  - `Agent({ subagent_type: "qrspi-goal-traceability-reviewer", model: "sonnet" })` — reviewer_tag: `goal-traceability-claude` (line 142)
  - **Test-phase reuse signal**: `task_definition` is OMITTED from prompt — its absence selects Test-phase branch on agent body. Correspondingly, `diff_file_path` and `scope_hint` are also omitted (test step opts out of diff-file wiring and scope-tagger narrowing per lines 104–106).
  - No scope-reviewer in test.
  - **Transport description (line 152):** "via the wrapper" (same wording as integrate).

- **Codex dispatch (3 reviewers: spec + code-quality + goal-traceability):**
  - Lines 156–186: `scripts/run-codex-review.sh` for spec-codex, code-quality-codex, goal-traceability-codex; none passes `--task-def`.
  - Await + splitter (lines 194–209): `codex-companion-bg.sh await <specJobId> > /tmp/codex-stdout-<specJobId>.txt` → `codex-finding-splitter.sh … spec-codex`; same for code-quality-codex and goal-traceability-codex.

- **Per-finding boilerplate: ABSENT.** No inline format documentation.

---

### Boilerplate divergence summary table

| Skill | Claude transport | Codex transport intro | Per-finding boilerplate (Output format + worked examples + constraint reminder) | Scope reviewer |
|---|---|---|---|---|
| goals | Task tool (Agent) | "via shell pipelines. Protocol and agent body flow via stdin" (line 260) | **PRESENT** (lines 262–289) | YES (quality + scope) |
| questions | Task tool (Agent) | "via a shell pipeline" (line 94) | **PRESENT** (lines 96–123) | NO |
| research | Task tool (Agent) | "via a shell pipeline" (line 168) | **PRESENT** (lines 170–197) | NO |
| design | Task tool (Agent) | "via shell pipelines" (line 179) | **PRESENT** (lines 181–208) | YES (quality + scope) |
| phasing | Task tool (Agent) | "via shell pipelines" (line 136) | **PRESENT** (lines 138–165) | YES (quality + scope) |
| structure | Task tool (Agent) | "via shell pipelines" (line 177) | **PRESENT** (lines 179–206) | YES (quality + scope) |
| parallelize | Task tool (Agent) | "via shell pipelines" (line 200) | **PRESENT** (lines 202–229) | YES (quality + scope) |
| plan | Task tool (Agent) | "via shell pipelines" (line 316) | **ABSENT** | YES (quality + 5 plan-artifact + scope = 7 total) |
| implement | Task tool (Agent) | "via the wrapper" / wrapper described at line 1060 | **ABSENT** | NO |
| integrate | Task tool (Agent) | "via the wrapper" (line 122) | **ABSENT** | NO |
| test | Task tool (Agent) | "via the wrapper" (line 152) | **ABSENT** | NO |

---

### Enumeration of divergence locations

1. **Per-finding boilerplate absent from plan onward**
   - First absence: `skills/plan/SKILL.md` line 316 (Codex dispatch block starts immediately after "via shell pipelines:" with no "Output format" paragraph).
   - Also absent: `skills/implement/SKILL.md` (Codex block at lines 1062–1163), `skills/integrate/SKILL.md` (Codex block at lines 125–154), `skills/test/SKILL.md` (Codex block at lines 156–186).
   - Implement SKILL.md (line 1060) explains the design intent: the `scripts/run-codex-review.sh` wrapper "assembles the reviewer-protocol body, the named agent body (frontmatter stripped), the emission-override, and the Dispatch parameters block."

2. **Goals-only "Protocol and agent body flow via stdin" phrase**
   - `skills/goals/SKILL.md` line 260 — unique addition not present in any of the other 10 in-scope skills.

3. **"via the wrapper" vs "via shell pipelines" wording**
   - `skills/integrate/SKILL.md` line 122 and `skills/test/SKILL.md` line 152 say "via the wrapper."
   - All other skills (goals through plan) say "via shell pipelines" (or "shell pipeline" singular for questions/research).

4. **Codex temp-file naming convention in implement**
   - `skills/implement/SKILL.md` lines 1168–1169: uses `codex_stdout="$(mktemp)"` (no explicit `/tmp/codex-stdout-<jobId>.txt` path).
   - All other skills use the literal `/tmp/codex-stdout-<jobId>.txt` naming in their await blocks.

5. **Test step omits `diff_file_path` and `scope_hint`**
   - `skills/test/SKILL.md` lines 104–106: explicitly opts out of diff-file emission and scope-tagger wiring (test reviewers receive neither `diff_file_path` nor `scope_hint`).
   - All other skills pass `diff_file_path` and conditionally pass `scope_hint` to both Claude and Codex dispatches.

6. **Research Claude reviewer uses path-list parameter, not inline artifact body**
   - `skills/research/SKILL.md` line 151: `companion_qfile_paths` is a list of absolute paths; reviewer Reads each file directly. All other skills embed artifact bodies inline as wrapped text blocks.
