---
status: draft
question_ids: [23]
research_type: codebase
---

# Q23: Code-Simplifier Pipeline — Finding Emission, Disk Layout, Severity/Disposition Fields, and Orchestrator Handling

## Summary

**TL;DR:** The code-simplifier (`agents/qrspi-code-simplifier.md`) is a "thoroughness" reviewer that runs only in deep mode, after all correctness reviewers pass. It emits findings under the standard reviewer-protocol per-finding disk-write contract — one `code-simplifier-{tag}.finding-F<NN>.md` file per finding, or a `code-simplifier-{tag}.clean.md` sentinel — to `reviews/tasks/task-NN/round-NN/`. Per its frontmatter description ("simplifications are suggestions, not blocking"), findings carry `change_type: style` and are therefore auto-applied by the review loop rather than pausing for user approval; however, the as-built representative outputs show `severity: suggestion` (non-canonical) and `status: advisory-not-applied` (non-canonical) frontmatter fields, plus an `orchestrator_decision:` annotation that records verbatim why the orchestrator chose not to apply each finding. The clean sentinel from the Claude instance deviates from the standard frontmatter-only format.

**Key findings:**
- The code-simplifier is classified as a **thoroughness** reviewer (`skills/implement/SKILL.md:819`) — it runs only in `review_depth_effective == "deep"` and only on `task_type: code` tasks; lightweight tasks and quick mode never trigger it.
- Output files land at `<ABS_ARTIFACT_DIR>/reviews/tasks/task-NN/round-NN/code-simplifier-{claude|codex}.finding-F<NN>.md` (or `.clean.md` sentinel). For the v0.7.1 hardening run, the only code-simplifier output is at `reviews/tasks/task-02/round-03/`.
- Two emission paths exist: Claude instance uses the Write tool directly; Codex instance emits to stdout and the orchestrator's `scripts/codex-finding-splitter.sh` materializes the files.
- The reviewer-protocol schema specifies `severity` ∈ `{low, medium, high}` and does NOT define a `status:` or `orchestrator_decision:` field. The as-built Codex findings use `severity: suggestion` (deviating from schema) and add `status: advisory-not-applied` plus `orchestrator_decision:` as orchestrator-annotated fields.
- The agent's frontmatter description: "Simplifications are suggestions, not blocking." Formal `change_type: style` means auto-apply per the change-type classifier; but the actual orchestrator handling recorded in the findings was "noted, not applied" with explicit reviewer-disagreement rationale.
- The Claude code-simplifier's clean sentinel (`code-simplifier-claude.clean.md`) uses H1+prose body rather than the canonical `---\nreviewer: …\nround: …\nfindings: 0\n---` frontmatter-only format.
- The orchestrator decided not to apply the Codex findings because the Claude code-simplifier issued a clean review and the two disagreed — the orchestrator defers to the broader-context Claude judgment for suggestion-severity findings.

**Surprises:**
- The as-built Codex finding files carry `severity: suggestion` — a value outside the canonical `{low, medium, high}` closed set defined in `skills/reviewer-protocol/SKILL.md:232`. The schema-guard regex `^R\d+-F\d+$` only applies to `finding_id`; `severity` is not regex-guarded in the schema, so this non-canonical value passes on disk without a guard failure.
- The `orchestrator_decision:` frontmatter field and `status: advisory-not-applied` appear only in the Codex-emitted findings, not in canonical schema. These appear to be orchestrator-annotated post-hoc fields added to the file after the splitter materialized it.
- The Claude clean sentinel deviates structurally from the reviewer-protocol's canonical frontmatter-only format (it uses a full prose body with a markdown table and explanatory notes), yet still functionally communicates "clean."

**Caveats:**
- Only one round of code-simplifier output exists under `docs/qrspi/2026-05-27-v071-hardening/reviews/` (task-02, round-03) — two Codex findings and one Claude clean sentinel. This is a small sample. Other rounds/tasks may show different patterns.
- The `using-qrspi/SKILL.md` was not fully read; references are from `skills/implement/SKILL.md` and `agents/qrspi-code-simplifier.md`.

---

## Full findings

### Agent definition and pipeline position

**File:** `agents/qrspi-code-simplifier.md`

The agent's frontmatter (`agents/qrspi-code-simplifier.md:1–6`):
```yaml
---
name: qrspi-code-simplifier
description: Identifies opportunities to simplify code while preserving all functionality. Deep mode only. Runs after all correctness reviewers pass. Simplifications are suggestions, not blocking.
tools: Read, Write
skills: [reviewer-protocol]
---
```

Key attributes:
- Only has `Read` and `Write` tools (no Bash/Edit).
- Loads `skills/reviewer-protocol` via the `skills:` frontmatter preload — the full reviewer-protocol body arrives in the agent's context automatically.
- Named without the `-reviewer` suffix (historical naming exception, noted at `skills/implement/SKILL.md:488`).

### Pipeline position: thoroughness reviewer

**File:** `skills/implement/SKILL.md:809–819`

The review group table classifies the code-simplifier as:

| Group | Reviewer | Quick | Deep | Execution |
|-------|----------|-------|------|-----------|
| Thoroughness | code-simplifier | No | Yes | Parallel after correctness passes |

The execution order is:
1. `spec-reviewer` (gate)
2. `code-quality-reviewer`, `silent-failure-hunter`, `security-reviewer` in parallel (correctness)
3. `goal-traceability-reviewer`, `test-coverage-reviewer`, `type-design-analyzer`, `code-simplifier` in parallel (thoroughness, deep + code tasks only)

The code-simplifier is **never dispatched** in quick mode or on `task_type: lightweight` tasks, which force `review_depth_effective: quick` regardless of `config.review_depth` (`skills/implement/SKILL.md:507–510`).

### Dispatch mechanism

**File:** `skills/implement/SKILL.md:943`

Claude instance dispatch:
```
Agent({ subagent_type: "qrspi-code-simplifier", model: "sonnet" })
  — output: <ABS_ARTIFACT_DIR>/reviews/tasks/task-NN/round-NN/
  — reviewer_tag: code-simplifier-claude
```

**File:** `skills/implement/SKILL.md:1152–1162`

Codex instance dispatch (via `scripts/run-codex-review.sh`):
```sh
scripts/run-codex-review.sh \
  --agent-file agents/qrspi-code-simplifier.md \
  --reviewer-tag code-simplifier-codex \
  --output-dir "<ABS_ARTIFACT_DIR>/reviews/tasks/task-${NN}/round-${ROUND}/" \
  --round "$ROUND" \
  --subject-code "<repo-relative path 1>" \
  [--subject-code "<repo-relative path 2>" ...] \
  --task-def "tasks/task-${NN}.md" \
  --diff-file "<ABS_ARTIFACT_DIR>/reviews/tasks/task-${NN}/round-${ROUND}.diff" \
  --scope-hint "$SCOPE_HINT"
```

The two dispatches are parallel (both Claude and Codex fire at the same time when `codex_enabled_per_task: true`).

### Disk-write contract and output location

**File:** `skills/reviewer-protocol/SKILL.md:208–260`

Output path pattern:
```
reviews/tasks/task-NN/round-NN/<reviewer_tag>.finding-F<NN>.md    (one per finding)
reviews/tasks/task-NN/round-NN/<reviewer_tag>.clean.md             (sentinel when zero findings)
```

For the code-simplifier specifically, `<reviewer_tag>` is `code-simplifier-claude` (Claude) or `code-simplifier-codex` (Codex).

**Two emission paths:**
1. **Claude:** agent calls the Write tool directly per the per-finding disk-write contract.
2. **Codex:** agent emits to stdout using `<<<FINDING-BOUNDARY>>>` delimiters (or `NO_FINDINGS` sentinel); the orchestrator runs `scripts/codex-finding-splitter.sh` to materialize the same files on disk.

The `Codex Emission Override` document (`skills/reviewer-protocol/codex-emission-override.md`) overrides the "use the Write tool" directive from the agent body for Codex runs only, because Codex operates in a read-only sandbox.

### Finding schema (canonical)

**File:** `skills/reviewer-protocol/SKILL.md:216–236`

Per-finding YAML frontmatter (canonical 5 schema fields + 3 audit fields):
```yaml
---
finding_id: R3-F02        # e.g. R{round}-F{NN}, unique per (round, reviewer_tag)
severity: high            # ∈ {low, medium, high}
change_type: correctness  # ∈ {style, clarity, correctness, scope, intent}
referenced_files: [...]   # file paths, with line-range citations
artifact: design          # the artifact step name
round: 3                  # integer round number
reviewer: quality-claude  # must equal reviewer_tag and filename prefix
---

{message body — prose explanation of the finding}
```

The code-simplifier's findings would be `change_type: style` in normal operation (surface-level presentation changes that are semantics-preserving), which per the **default-action rule** (`skills/reviewer-protocol/SKILL.md:67–70`) means **auto-apply** — no pause gate.

Clean sentinel canonical format:
```markdown
---
reviewer: <reviewer_tag>
round: <round-number>
findings: 0
---
```

### As-built output artifacts in `docs/qrspi/2026-05-27-v071-hardening/reviews/`

**Path:** `docs/qrspi/2026-05-27-v071-hardening/reviews/tasks/task-02/round-03/`

Three code-simplifier files exist for task-02, round-03:

#### `code-simplifier-codex.finding-F01.md`

Frontmatter:
```yaml
---
reviewer: code-simplifier-codex
task: 2
round: 3
finding: F01
severity: suggestion          ← non-canonical (schema expects low|medium|high)
change_type: style
status: advisory-not-applied  ← non-canonical field (not in schema)
model: gpt-5.3-codex
timestamp: 2026-05-28T16:50:00Z
agent_id: t02-r3-code-simplifier-codex
orchestrator_decision: noted, not applied — Claude code-simplifier round-03 review explicitly judged the existing bash patterns intentional...
---
```

Body proposes collapsing a nested `if -f` / `grep -qF` pattern into a single `&&`-chained guard in `tests/unit/test-commit-hygiene-invariants.bats` (approx. lines 246–251).

#### `code-simplifier-codex.finding-F02.md`

Same non-canonical frontmatter structure as F01. Body proposes replacing `grep -E "^\.qrspi-commit-msg\.txt$"` with `grep -qxF` to avoid regex escaping in `tests/unit/test-commit-hygiene-invariants.bats`.

`orchestrator_decision:` for F02: "Not applied. The non-quiet final grep on line 283 is intentional per Claude code-simplifier round-03: aids failure diagnosis when the assertion fires."

#### `code-simplifier-claude.clean.md`

Not in canonical frontmatter-only format. Uses prose body:
```markdown
# Code Simplifier Review — Task 02, Round 03

reviewer: code-simplifier-claude
round: 3
verdict: clean

## Summary

The diff is small (+3 .gitignore, +52 .bats) and well-written. No
simplification opportunities rise to the level of a clear win.

### Category-by-category

| Category | Result |
|---|---|
| Unnecessary Complexity | None |
...
```

The file includes two inline "not filed as a finding" notes discussing specific patterns the Claude instance considered but decided not to file. These rationale notes feed directly into the `orchestrator_decision:` text in the Codex findings.

### Orchestrator decision logic for code-simplifier findings

**No explicit "code-simplifier findings are advisory" rule exists in `skills/implement/SKILL.md`.** The agent's frontmatter description ("Simplifications are suggestions, not blocking") is the authoritative statement of its advisory status, but the mechanism for enforcing "not blocking" is the standard change-type classifier: since simplification findings carry `change_type: style`, they are auto-apply per the reviewer-protocol — not paused for user confirmation.

The actual orchestrator behavior recorded in the v0.7.1 run (`orchestrator_decision:` field) was **not to apply** the Codex findings, with the rationale being **reviewer disagreement**: the Claude instance reviewed the same code and produced a clean sentinel with explicit rationale for why each flagged pattern was intentional. The documented logic:

> "Reviewer-disagreement; orchestrator defers to the broader-context Claude judgment for this suggestion-severity finding." (`code-simplifier-codex.finding-F01.md:12`)

This is not a general orchestrator rule codified in the skills — it is an ad-hoc decision recorded in the finding file post-hoc. The orchestrator annotated the finding files with `status: advisory-not-applied` and `orchestrator_decision:` text after the Codex splitter materialized them.

### Summary of deviations from canonical schema (as-built)

| Field | Canonical value | As-built (Codex findings) |
|---|---|---|
| `severity` | `low\|medium\|high` | `suggestion` |
| `status` | *(not a schema field)* | `advisory-not-applied` |
| `orchestrator_decision` | *(not a schema field)* | prose rationale string |
| `model` | *(not a schema field)* | `gpt-5.3-codex` |
| `timestamp` | *(not a schema field)* | ISO timestamp |
| `agent_id` | *(not a schema field)* | `t02-r3-code-simplifier-codex` |
| `finding` | *(not a schema field — schema uses `finding_id`)* | `F01` |
| `task` | *(not a schema field)* | `2` |

The Claude clean sentinel also deviates from the canonical frontmatter-only format, using a prose body with a category table and inline notes.

### What the apply-fix step-2 schema-violation guard checks

**File:** `skills/reviewer-protocol/SKILL.md:211–212`

The schema-violation guard at apply-fix step 2 asserts that the round directory contains at least one of `<tag>.finding-*.md` or `<tag>.clean.md` for every expected tag. For the `test` step, the expected-reviewer matrix (`skills/reviewer-protocol/SKILL.md:36`) does NOT include `code-simplifier-claude` or `code-simplifier-codex` — code-simplifier is only in the Implement step. A clean sentinel with any content passes the guard as long as the filename is `<tag>.clean.md`.
