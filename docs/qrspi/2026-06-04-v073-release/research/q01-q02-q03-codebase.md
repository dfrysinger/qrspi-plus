---
status: draft
question_ids: [1,2,3]
research_type: codebase
---

# Q1, Q2, Q3: Finding-verifier document consultation, identifier-naming rule tables, and bats test identifier conventions

## Summary

**TL;DR:** The finding-verifier reads `change_type` from the finding's YAML frontmatter only; it has no dedicated step for consulting upstream documents specifically for `change_type` evaluation — upstream documents are available lazily via `<upstream_paths>` but those paths are assembled by the orchestrator in the dispatch prompt, not in the agent body. Identifier-naming rule tables and constraint sets for non-test contexts live primarily in `skills/implementer-protocol/SKILL.md` (§ Hygiene contract) and `skills/reviewer-protocol/SKILL.md` (§ Finding Schema), loaded by agents via `skills:` frontmatter or inline enforcement sections. No canonical document defines bats `@test` identifier naming conventions — the one formal constraint is a negative rule (QRSPI-internal IDs forbidden in test names), stated in `skills/implementer-protocol/SKILL.md` and enforced by `agents/qrspi-code-quality-reviewer.md`.

**Key findings:**
- The finding-verifier (Step 1 of its procedure) reads `change_type` from the finding's YAML frontmatter; no subsequent step validates `change_type` against the enum. Validation of the field against the enum is handled by `scripts/verifier-fan-in.sh`, not the verifier agent.
- `<upstream_paths>` passed to the verifier (per `skills/using-qrspi/SKILL.md` step 4 dispatch block) include per-step pipeline upstream artifacts plus `skills/<step>/SKILL.md` and `skills/using-qrspi/SKILL.md`. These paths are specified as dispatch PROMPT parameters assembled by the orchestrator, not in the verifier agent body itself.
- The primary canonical table of forbidden identifier tokens is in `skills/implementer-protocol/SKILL.md` § Hygiene contract (Internal-ID forbidden tokens, Evergreen-markdown forbidden tokens tables). Implementer agents load it via `skills: [implementer-protocol]` frontmatter. The code-quality reviewer carries a parallel enforcement section inline (§ 11 ID Hygiene), rather than loading it by reference.
- `CONTRIBUTING.md` carries branch-naming and commit-message conventions. `skills/reviewer-protocol/SKILL.md` carries the `finding_id` regex and `change_type` enum. `agents/qrspi-finding-verifier.md` carries the `defect_class` shape regex.
- For bats test identifiers, no formal positive naming convention document exists. The test-writer agent defers naming to convention-detection from existing tests. The only formal rule is negative: QRSPI-internal IDs are forbidden in test names (from `implementer-protocol/SKILL.md` § Hygiene contract and enforced by `agents/qrspi-code-quality-reviewer.md` § ID Hygiene).
- The `agents/qrspi-test-writer.md` § TEST TYPE TEMPLATES section defines naming conventions for JS-style `test('...')` calls (acceptance/boundary/E2E/integration prefixes), but these do not apply to bats `@test` identifiers.

**Surprises:** Some existing bats test files (e.g., `tests/unit/test-detect-interaction-mode.bats`, `tests/unit/test-plan-post-approval-split.bats`, `tests/unit/test-hygiene-self-check.bats`) carry `[T24]`, `[T32-split]`, and `[T18]` prefixes in `@test` strings — T-prefixed token forms that match the Task ID pattern `\bT\d{2}\b` in the implementer-protocol's forbidden-token table, which explicitly forbids these in test names. These appear to be pre-existing tests that predate the hygiene rule; the code-quality reviewer's grep procedure treats pre-existing tokens as out-of-scope for new diffs.

**Caveats:** The `upstream_paths` parameter list was read from `skills/using-qrspi/SKILL.md`; the built `build/skills/using-qrspi/SKILL.md` may differ. The `agents/qrspi-implementer-lightweight.md` agent was not read, but the implementer-protocol SKILL.md states "both implementer agent variants load this section via the `implementer-protocol` preload." Only the `tests/unit/` directory was surveyed for bats naming patterns; `tests/acceptance/`, `tests/integration/`, and `tests/lint/` subdirectories were not fully enumerated.

---

## Full findings

### Q1: What documents does the finding-verifier consult when evaluating a finding's `change_type`?

#### Source of truth: `agents/qrspi-finding-verifier.md`

The finding-verifier procedure (Step 1) reads `change_type` from the finding's YAML frontmatter:

> **agents/qrspi-finding-verifier.md:70**: "**Read `<finding_file_path>`** — parse the 5-field finding object (YAML frontmatter: `finding_id`, `severity`, `change_type`, `referenced_files`, plus the prose `message` body)..."

No subsequent procedural step consults an external document specifically to evaluate or validate `change_type`. The scoring rubric (Step 5) is embedded entirely in the agent body. The rubric's 0/25/50/75/100 anchors make no reference to any upstream document for `change_type` interpretation.

#### How `change_type` affects scoring (in-body logic)

`change_type` has one indirect effect on scoring within the agent body: the `Informational:` scoring carve-out (agents/qrspi-finding-verifier.md:21–44) uses a 75/50/25 structural-confidence scale instead of the false-positive rubric. However, this carve-out is triggered by the `message` body prefix (`Informational:`), not by the `change_type` value itself.

#### `change_type` enum validation: NOT in the verifier

Validation of `change_type` against the canonical five-value enum (`style`, `clarity`, `correctness`, `scope`, `intent`) is explicitly NOT the verifier's job. Per `skills/reviewer-protocol/SKILL.md:61`:

> "Out-of-enum `change_type:` is a contract violation... the fan-in script validates each finding's `change_type` against this same enum and halts loudly with a `change_type_out_of_enum` cause when a finding carries a value outside the enum."

The validation belongs to `scripts/verifier-fan-in.sh`, not to the verifier agent.

#### `<upstream_paths>` — available but lazily read

Step 4 of the verifier procedure (agents/qrspi-finding-verifier.md:88):

> "**If any `<upstream_paths>` entry is cited in the finding or seems load-bearing**, Read it (lazy — only as needed)."

The verifier MAY read upstream documents, but only on demand. These are NOT consulted specifically for `change_type` evaluation.

#### How `<upstream_paths>` are specified — in the dispatch call, not the agent body

The agent body defines `<upstream_paths>` as a dispatch parameter (agents/qrspi-finding-verifier.md:66):

> "`<upstream_paths>` — newline-separated upstream-artifact and SKILL paths the verifier may Read on demand."

The actual document paths are assembled by the orchestrator. Per `skills/using-qrspi/SKILL.md:805–838`, the parallel verifier dispatch block specifies the path construction:

```
upstream_paths: |
  <abs_path>/<upstream-artifact-1>.md
  <abs_path>/<upstream-artifact-2>.md
  ...
  skills/<step>/SKILL.md
  skills/using-qrspi/SKILL.md
```

**Per-step upstream-artifact lists** (from `skills/using-qrspi/SKILL.md:827–835`):

| Step | Upstream artifacts |
|---|---|
| Goals | *(none — SKILL paths only)* |
| Questions | `goals.md` |
| Research | `goals.md`, `questions.md` |
| Design | `goals.md`, `questions.md`, `research/summary.md` |
| Phasing | `goals.md`, `design.md` |
| Structure | `goals.md`, `design.md`, `phasing.md` |
| Parallelize | `goals.md`, `design.md`, `structure.md` |
| Replan | `plan.md`, `replan-trigger-source` |

**SKILL paths appended on every step** (from `skills/using-qrspi/SKILL.md:836–838`):
- `skills/<step>/SKILL.md`
- `skills/using-qrspi/SKILL.md`

These paths are present in the dispatch prompt (the `prompt:` block in the `Task` call constructed by the orchestrator), not in the verifier agent body itself.

#### Summary for Q1

The finding-verifier consults no specific external document to evaluate `change_type`. It reads the value from the finding's YAML frontmatter (Step 1). The rubric used for scoring is embedded in the agent body. Upstream document paths are specified as dispatch parameters constructed by the orchestrator per `skills/using-qrspi/SKILL.md`, not within the verifier agent body.

---

### Q2: What documents carry identifier-naming rule tables or constraint sets for non-test contexts?

#### 1. `skills/implementer-protocol/SKILL.md` — primary canonical table

This is the "single source of truth for the combined ID-hygiene and evergreen-markdown hygiene rules" (skills/implementer-protocol/SKILL.md:92). Contains two formal tables:

**Internal-ID forbidden tokens table** (skills/implementer-protocol/SKILL.md:96–107):

| Family | Regex shape | Examples |
|---|---|---|
| Reviewer finding ID | `round-\d+\s+finding-\d+` or `R\d+-F\d+` | `R3-F01`, `round-2 finding-05` |
| Task ID | `\bT\d{2}\b` | `T01`, `T14` |
| Goal ID | `\bG\d+\b` (not in file path context) | `G1`, `G18` |
| Question ID | `\bQ\d+\b` | `Q3`, `Q12` |
| Future-goal ID | `\bF-\d+\b` | `F-1`, `F-23` |
| Design decision ID | `\bD\d+\b` (not in file path context) | `D2`, `D15` |

**Evergreen-markdown forbidden tokens table** (skills/implementer-protocol/SKILL.md:112–118, `.md` files only):

| Family | Regex shape | Examples |
|---|---|---|
| Release-version token | `v\d+\.\d+` | `v0.7`, `v1.2` |
| Milestone wording | `in v\d+\.\d+`, `after this release`, `after the \w+ release` | `in v0.7` |
| PR/issue reference as behavior justification | `(see\|per\|fixes\|closes)\s+#\d+` used to justify current behavior | `per #42`, `see #172` |

**Path-shaped carve-outs** (skills/implementer-protocol/SKILL.md:121–135): Exempt surfaces include `docs/qrspi/**`, `agents/qrspi-*-reviewer.md`, `reviews/**`, `CHANGELOG.md`, `tests/fixtures/**`, and dated `docs/superpowers/` artifacts.

**Inline carve-outs** (skills/implementer-protocol/SKILL.md:137–146): `<!-- id-hygiene-exempt -->` and `<!-- evergreen-exempt -->` suppress findings on a per-line basis.

**Constraint surface listing** for non-test contexts (skills/implementer-protocol/SKILL.md:77–84):

- **Strict surfaces** — both QRSPI-internal AND external tracker IDs forbidden: code identifiers (variable, function, type, file names), runtime string literals (error messages, log lines, UI strings, telemetry tags), prompt templates and prompt strings.
- **Comments** — QRSPI-internal IDs forbidden. External tracker IDs allowed only as scoped "see #N for context" references with a stated reason.
- **Commit messages / PR bodies** — `Closes #N` is explicitly allowed (skills/implementer-protocol/SKILL.md:86).

#### 2. `skills/reviewer-protocol/SKILL.md` — Finding Schema naming rules

The reviewer-protocol SKILL.md (loaded by all reviewer agents via `skills: [reviewer-protocol]`) defines three naming constraints:

**`finding_id` format** (skills/reviewer-protocol/SKILL.md:71): Canonical form `R{NN}-F{NN}`; guard regex `^R\d+-F\d+$`. Identifiers failing the regex are rejected.

**`change_type` enum** (skills/reviewer-protocol/SKILL.md:65): One of `style`, `clarity`, `correctness`, `scope`, `intent`. The field MUST be emitted as `change_type:` (not `category:` or any synonym).

**`reviewer` audit field** (skills/reviewer-protocol/SKILL.md:81): MUST equal the dispatcher-supplied `<reviewer_tag>` for the current dispatch.

#### 3. `agents/qrspi-finding-verifier.md` — `defect_class` shape rule

The verifier body (agents/qrspi-finding-verifier.md:93–97) defines the `defect_class` identifier shape:

- Lowercase kebab-case: letters, digits, and hyphens only
- Shape regex: `^[a-z0-9][a-z0-9-]*$`
- Maximum 30 characters total
- First character MUST be a letter or digit (no leading hyphen)
- On rule violation (uppercase, underscore, space, dot, slash, other punctuation, length > 30): emit `defect_class: unspecified`

#### 4. `CONTRIBUTING.md` — Branch naming and commit conventions

**Branch naming conventions** (CONTRIBUTING.md:36–44): `feat/<slug>`, `fix/<slug>`, `docs/<slug>`, `refactor/<slug>`, `test/<slug>`, `chore/<slug>`.

**Commit messages** (CONTRIBUTING.md:54): Conventional-Commits style (`type(scope): subject`). Same prefix set as branches.

**Skill prose authoring** (CONTRIBUTING.md:165–225): Table of anti-patterns for SKILL.md prose:

| Pattern | Recognize by | Rewrite as |
|---|---|---|
| `_shared/*.md` file-path inside SKILL.md prose | tokens like `per _shared/foo.md contract` | self-relative phrasing or full restate |
| G-label / CD-label with design-doc qualifier | tokens like `per G4 solution step 1` | self-relative phrasing |
| "Cross-Goal Decision X" phrasing | literal string in skill prose | restate the contract inline |
| Forward-reference summary paragraph | sentences like "The forward-reference to X covers Y" | drop if Y is inline above |

#### 5. `agents/qrspi-code-quality-reviewer.md` — § 11 ID Hygiene (enforcement section)

The code-quality reviewer carries an inline enforcement section (agents/qrspi-code-quality-reviewer.md:99–118) that mirrors the implementer-protocol rules, including grep-lint patterns for detecting violations:

- QRSPI-internal pattern: `\b[GRDFTQ]-?[0-9]+[A-Za-z]?\b` — applied to all changed files except `docs/qrspi/`
- External tracker pattern: `(#[0-9]+|[A-Z]{2,}-[0-9]+)` — applied to comments and test-name strings

#### How implementer agents reference these documents

Implementer agents (`qrspi-implementer.md:6`, `qrspi-implementer-lightweight.md`) declare `skills: [implementer-protocol]` in their frontmatter. The skill is auto-loaded at agent activation; the implementer-protocol SKILL.md's Hygiene contract section becomes part of the agent's context. The agent body references it explicitly: "Both implementer agent variants load this section via the `implementer-protocol` preload" (skills/implementer-protocol/SKILL.md:92).

#### How reviewer agents reference these documents

Reviewer agents declare `skills: [reviewer-protocol]` in their frontmatter to load the reviewer-protocol SKILL.md (which defines `finding_id` format, `change_type` enum, etc.). The code-quality reviewer does NOT cite implementer-protocol by reference — it carries a parallel inline § 11 ID Hygiene section with its own grep-lint procedure. The finding-verifier agent does not load either skill; its `defect_class` naming rule is self-contained in the agent body.

---

### Q3: What naming conventions govern bats test identifiers, and where are the formal rules defined?

#### No canonical positive naming convention document exists

There is no single document in the codebase that defines formal positive naming conventions for bats `@test` identifiers. The `skills/test/SKILL.md:82` explicitly delegates test naming to the test-writer agent:

> "Per-type rule sets (test structure, naming convention, anti-patterns) live in the `qrspi-test-writer` agent body — see `agents/qrspi-test-writer.md` § TEST TYPE TEMPLATES."

#### The test-writer defers to convention inference from existing tests

`agents/qrspi-test-writer.md:67`:

> "Survey `companion_codebase_context` to detect the project's test framework, file naming conventions, and any relevant fixtures or helpers."

`agents/qrspi-test-writer.md:101` (test-phase mode):

> "Survey existing tests before writing — use Read, Grep, and Glob to enumerate the project's current test suite so new tests follow established naming conventions..."

Both implement-phase and test-phase modes instruct the test-writer to infer naming conventions from existing tests, not from a rule document.

#### The only formal constraints are negative (forbidding QRSPI-internal IDs)

**`skills/implementer-protocol/SKILL.md:83`** (applied to all `@test` name strings):

> "**QRSPI-internal IDs:** forbidden in code comments, test names, `describe` / `it` blocks, and fixture names — everywhere outside `docs/qrspi/`."

The six ID families in the Internal-ID forbidden tokens table all apply to `@test` identifier strings.

**`agents/qrspi-code-quality-reviewer.md:107`** (reviewer-side enforcement):

> "**QRSPI-internal IDs** — G/R/D/T/Q-prefixed numeric tokens: forbidden in code comments, test names, `describe` / `it` blocks, and fixture names — flag every occurrence outside `docs/qrspi/`, regardless of how scoped the comment is."

#### The § TEST TYPE TEMPLATES naming conventions do not apply to bats

`agents/qrspi-test-writer.md:129–200` defines naming conventions using JS-style `test('...', ...)` function signatures:

- Acceptance: `test('[criterion] - [specific behavior]', ...)`  
- Boundary: `test('boundary: [boundary description]', ...)`  
- E2E: `test('E2E: [user journey description]', ...)`  
- Integration: `test('[component A] → [component B] - [data flow description]', ...)`

These conventions target the JavaScript `test()` function and do not specify a bats `@test` string format.

#### Observed conventions in existing bats files (inferred, not formally specified)

From inspection of `tests/unit/`:

- **File naming**: `test-{kebab-case-subject}.bats` under `tests/unit/`, `tests/integration/`, `tests/acceptance/`
- **`@test` strings**: Natural-language behavioral descriptions, e.g.:
  - `@test "verifier agent file exists"` (`test-verifier-agent-file.bats:3`)
  - `@test "frontmatter does NOT declare a top-level model: key"` (`test-verifier-agent-file.bats:7`)
  - `@test "style finding has change_type=style and routes to auto-apply"` (`test-change-type-classification.bats:168`)
  - `@test "secondary-escalation: clarity-tagged finding citing feedback/*.md escalates to intent"` (`test-change-type-classification.bats:215`)
- **Bracketed task-prefix pattern (some tests only)**: A subset of tests use `[T24]`, `[T32-split]`, `[T18]`, `[T10/TE6]` prefixes in `@test` strings. For example:
  - `@test "[T24] Unknown host emits EVIDENCE naming the safe default"` (`test-detect-interaction-mode.bats:159`)
  - `@test "[T18] fixture-1: internal-ID on skills/foo/SKILL.md triggers hit naming file and family"` (`test-hygiene-self-check.bats:137`)
  - These T-prefixed tokens technically match the `\bT\d{2}\b` pattern in the implementer-protocol forbidden-token table. These appear to be pre-existing tests that predate or are grandfathered under the hygiene rule. The code-quality reviewer's grep procedure treats pre-existing tokens as "customer's own naming and ... not in scope" (skills/implementer-protocol/SKILL.md:75).

#### No lint or CI gate specifically validates `@test` string format

The CI workflow validates shellcheck, bash32 compatibility, and the build-sync gate (`CONTRIBUTING.md:70–97`). No CI check specifically validates `@test` string content or format beyond the bats syntax check implicit in `bats -r tests`.
