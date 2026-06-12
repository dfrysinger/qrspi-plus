---
status: approved-pending-review
---

# Design: qrspi-plus v0.7.3 — pipeline correctness + prompt-footprint reduction

## Cross-Goal Decisions

### CD-1 — Per-step `upstream_paths` lookup extracted to a script

**Outcome.** The deterministic per-step → upstream-paths mapping that the orchestrator consults when assembling verifier dispatches lives in a script, not in active SKILL.md prose.

**Solution.** A new script `scripts/upstream-paths.sh` accepts `--step <step>` (and `--artifact-dir <path>` for steps whose upstream set is pipeline-mode-aware — currently Plan, per G4) and prints a newline-separated path list to stdout (repo-relative paths for SKILL files and step-relative basenames for artifacts; the orchestrator joins them against the run's `<abs_path>` per the existing dispatch composition pattern in `using-qrspi` step 4 — see Edge cases below) — the per-step pipeline-upstream artifacts, plus the always-appended SKILL paths (`skills/<step>/SKILL.md`, `skills/using-qrspi/SKILL.md`), plus the canonical ID-hygiene authority introduced by G1 (`skills/implementer-protocol/SKILL.md`). The orchestrator reads `upstream_paths` from script stdout when composing each verifier dispatch parameter; `skills/using-qrspi/SKILL.md` § "Per-step upstream-artifact lists" prose block is replaced by a one-line directive pointing at the script. The script is pure stdin/stdout, no manifest, no async — same risk profile as a lookup table, smaller failure surface than the four-stage dispatch chain.

**Why this approach.** The lookup is a deterministic table — no LLM judgment improves it. Carrying ~17 lines of table prose inside `using-qrspi/SKILL.md` (the most-pinned skill, 1262 lines today) is exactly the G9 anti-pattern: "prose that restates what scripts already enforce." Extraction removes the lines from the active prompt window (script files don't enter prompts), and future per-step changes (G1's implementer-protocol path; future Plan/Integrate verifier paths) edit the script instead of expanding the most-pinned skill. The same v0.7.2 universal-dispatcher pattern (`dispatch-agent.sh` etc.) has already proven the shape works; this is a smaller follow-on extraction in the same direction.

**Dependencies + edge cases.**
- Sequenced **before** G1 lands its implementer-protocol-path addition (G1 edits the script's always-appended array; no two-step prose-then-script transition).
- Counts toward G9's footprint reduction (~14 lines deleted from `using-qrspi/SKILL.md`); G9 attributes the deletion to CD-1 in its accounting.
- Edge case: a step name not in the table (e.g. `plan` today) returns the always-appended SKILL paths only. The script must handle unknown step names by printing the always-appended set and exiting 0, not by erroring — orchestrator failure on an absent step would be a regression vs. today's prose behavior.
- The script does NOT resolve absolute paths from `<run_dir>` — it prints repo-relative paths for SKILL files and step-relative artifact basenames (e.g. `goals.md`); the orchestrator joins them against `<abs_path>` per the existing dispatch composition pattern in `using-qrspi` step 4. Keeps the script context-free.

**Acceptance.**
- `scripts/upstream-paths.sh --step <step>` prints the documented set for every supported step (Goals, Questions, Research, Design, Phasing, Structure, Parallelize, Replan); known-good output captured in a bats test.
- Unknown step name returns the always-appended SKILL paths + exit 0 (covered by a bats case).
- `skills/using-qrspi/SKILL.md` § "Per-step upstream-artifact lists" prose block is removed and replaced by a one-line directive citing the script.
- Verifier dispatches in a synthetic round produce the same `upstream_paths` parameter content as the prose-driven path produced (regression-checked against a captured fixture).

### CD-2 — Per-step pre-dispatch input generation owned by `scripts/review-prep.sh`, invoked from `scripts/dispatch-agent.sh`

**Outcome.** Per-step pre-dispatch artifact-derived inputs for a review round (diff with narrowing ref, absorption-map when applicable, scope-set lookup, future inputs) are produced by `scripts/review-prep.sh`, invoked internally by `scripts/dispatch-agent.sh` when called in high-level mode. The orchestrator makes one call per review round; skill-body prose carries one Bash line, not three.

**Solution.** A new script `scripts/review-prep.sh --step <step> --round <N> --artifact-dir <path>` does all per-step pre-dispatch input generation. A step-specific generation table lives internal to the script: Design produces diff + absorption-map (consuming `scripts/design-absorption-markers.sh` per G3.a); Plan produces diff + absorption-map (consuming `scripts/design-absorption-markers.sh` against design.md so the plan-spec reviewer receives `absorption_map_path` per G3 change 3); Goals produces diff only (no upstream artifacts to absorb); Research / Phasing / Structure / Parallelize produce diff with appropriate narrowing; per-task implement review produces a per-task diff. Diff narrowing across all steps follows the existing per-round anchor-file convergence rule documented in `using-qrspi` (G7); `review-prep.sh` does not introduce new narrowing semantics. Outputs are written to known relative paths under `<artifact-dir>/reviews/<step>/round-NN.*` (matching today's path conventions for diff files).

`scripts/dispatch-agent.sh` gains a high-level entry mode: when `--step <step> --round <N> --artifact-dir <path>` are present in addition to today's `--output-dir / --artifact / --agents` batched-mode flags, dispatch-agent invokes review-prep first, then reads the produced paths to thread into reviewer dispatch prompts (`diff_file_path:`, `absorption_map_path:`, etc.). The existing low-level `--diff-file <path>` mode remains for tests and non-standard callers.

review-prep failure → dispatch-agent exits non-zero, propagating review-prep's stderr verbatim. Same single-exit-code shape orchestrator already sees from any internal call dispatch-agent makes (jq, git, etc.).

Skill-body prose for per-step Review Round blocks across all artifact-step skills (`goals`, `questions`, `research`, `design`, `phasing`, `structure`, `parallelize`, `replan`) replaces today's ~6-10 line diff-emission Bash redirect paragraph with a single high-level dispatch-agent invocation referencing `--step --round --artifact-dir`.

**Why this approach.** Today the orchestrator runs N pre-dispatch Bash steps (diff redirect, absorption-map redirect once G3 lands, scope-set lookup) before calling `dispatch-agent.sh`, with the per-step recipe restated as prose in every artifact-step skill body. That shape carries two failure modes: (1) the orchestrator forgets to run a pre-dispatch step (a skip the orchestrator can plausibly rationalize under context pressure — exactly the G5/G9 failure pattern); (2) the per-step recipe drifts across 8 skill bodies as new inputs are added. Collapsing the recipe into `review-prep.sh` and invoking it from inside `dispatch-agent.sh` makes "dispatch a review round" atomic at the orchestrator-visible layer — there is no pre-step the orchestrator can skip because the only orchestrator-visible operation is the dispatch itself. New per-step inputs are added by editing `review-prep.sh`, not by adding skill prose. Same logic and direction as CD-1; CD-2 handles the artifact-derived input generation that CD-1's upstream-paths lookup is adjacent to.

The alternative considered — folding generation into `dispatch-agent.sh` directly — was rejected because per-step generation logic varies (diff narrowing rules differ; absorption-map applies only to Design today, future steps may add other inputs); embedding step-conditional generation in the universal dispatcher bloats the universal layer. The chosen split keeps `dispatch-agent.sh`'s role as "compose prompts and route the call" with `review-prep.sh` as the single owner of "produce per-step inputs." dispatch-agent's high-level mode is a thin call-through, not a logic absorption.

**Dependencies + edge cases.**
- Sequenced with **CD-1** in the script-chain refactor wave that G9's footprint trim depends on; both extractions land before G1 / G3 wire their step-specific behaviors through the new scripts.
- Edge case — per-task implement review uses dispatch-agent today via a different argument shape (`--diff-file <ABS>/reviews/tasks/task-NN/round-N.diff`). The high-level mode does not displace the low-level mode; per-task review either continues low-level OR migrates to high-level by passing `--step task` (review-prep produces a per-task diff for that step). Migration is implementation-time choice, not a CD-2 commitment.
- Edge case — `review-prep.sh` invocation when there is nothing to produce (e.g. an artifact-step that has no diff because the artifact is not in a git repo): the script emits no files for that step and exits 0. dispatch-agent omits the corresponding `*_path:` parameter from the dispatch prompt. Same fail-loud-on-real-error / silent-on-no-input shape as the existing diff-emission contract in `using-qrspi/SKILL.md`.
- Edge case — synthetic dispatches in test fixtures want a controlled diff. Tests use the low-level `--diff-file <path>` mode (preserved). Tests asserting CD-2's high-level behavior pass `--step --round --artifact-dir` against a fixture artifact-dir.

**Acceptance.**
- `scripts/review-prep.sh` produces the documented input set for each supported step (one bats fixture per step under `tests/lint/` or `tests/unit/`, including a fixture for `--step plan` that asserts the absorption-map is written to the expected path for G3 change 3's plan-spec reviewer to consume); fail-loud on a corrupt artifact-dir surfaces a named diagnostic.
- `scripts/dispatch-agent.sh --step <step> --round <N> --artifact-dir <path> ...` (high-level mode) produces a dispatch identical (in prompt content and manifest entries) to the equivalent low-level invocation with pre-computed paths — captured by a side-by-side bats test.
- Skill-body prose audit: zero `git diff > round-NN.diff` Bash redirect blocks remain in `skills/{goals,questions,research,design,phasing,structure,parallelize,replan}/SKILL.md` (grep test).
- Side-by-side comparison: total line count of pre-dispatch Bash redirect prose across the 8 artifact-step skills shrinks by ≥ 80 lines vs. v0.7.2 (G9 footprint contribution attribution).
---

### CD-3 — Prose-density rule (R8) added to `prompt-design-rules.md`

**Outcome.** Authors and reviewers of prompt prose have a named rule (R8) and a reviewer test for prose density. Density tightening becomes a routine reviewer concern, not an ad-hoc judgment call. G9's tightening pass cites R8 as its authority; future reviewer findings citing verbose prose cite R8 by ID and apply the named test. The "minimal does NOT mean short" guardrail from the existing cross-cutting principles bounds the rule so behavioral precision is preserved.

**Solution.** Add a new R8 to `skills/_shared/prompt-design-rules.md` between R7 and the `---` separator that begins the cross-cutting principles section. Update the finding-type gate's `rule-violation` row to include R8 in the rule-ID set reviewers cite.

<!-- prose-design: skills/_shared/prompt-design-rules.md § R8 (new section, inserted between current R7 and the `---` separator at line 99) -->
````
### R8 — Prose density: short declarative sentences, full behavioral precision

Per cross-cutting principle "Aim for the minimal set that fully specifies behavior," "minimal" does NOT mean "short" — fully specifying behavior is the floor. Within that floor, tighter sentences pack more rule-per-token, scan faster, and compound with R3 (load-bearing rules at the end) and R7 (lexical anchoring). Every sentence in a SKILL.md, agent file, or shared prose snippet must earn its weight.

**Tightening patterns to apply:**

| Pattern in current prose | Tightened form | Why it works |
|---|---|---|
| "In order to X, you should Y" | "To X: Y." | Procedural framing dropped; colon does the work. |
| "The following section describes how to X" | (delete — heading does it) | Meta-sentences about the document are dead weight. |
| "You MUST always X" / "It is critical that you X" | "Always X." | Aggressive modal language overtriggers in Claude 4.x (see cross-cutting principle on aggressive MUST/CRITICAL language); imperative is enough. |
| Multi-clause defensive sentence: "When X happens, which can occur if Y is true and Z has not been set, then you should perform A, also taking care to B" | Two short sentences: "When X: do A. Then B." (move conditions to a precondition line if load-bearing) | Each clause becomes a parseable unit. |
| "This means that…" / "As a result…" / "Therefore…" connectives where adjacency makes the logic obvious | (delete) | Connective tissue costs tokens; adjacency carries the inference. |
| "The X is Y because Z" where Z is load-bearing | Split: "Y." + one-line "Why: Z." | R2-compliant rationale, scannable form. |
| Restatement after a rule ("…in other words, this means…") | (delete the restatement) | One statement of a rule is enough at the right altitude. |

**What NOT to tighten** (would violate other rules):

- Negation patterns must keep their positive substitute (per the negation cross-cutting principle: named antagonist + positive substitute + decision rule; stripping the substitute degrades behavior under paraphrase).
- Failure-mode rationale that grounds a rule (R2 — the model generalizes from the rationale; keep where load-bearing).
- Contrastive good/bad examples for observed failure modes (R4 — 1-2 examples for unusual output shape; do not strip below the necessary shape).
- Precondition wrappers that gate behavior ("When X: …" — the condition is load-bearing if it is the gate).
- Exact trigger tokens (R7 — anchor strings must match the source they reference; paraphrasing breaks lexical anchoring).

**Reviewer test (apply to every paragraph):**

> Could this sentence be shorter without losing behavioral precision OR load-bearing rationale?
>
> - If yes: tighten.
> - If no: leave.

A reviewer-emitted R8 finding cites (a) the verbatim original sentence or paragraph, (b) the proposed tightened form, (c) explicit confirmation that the tightening preserves behavioral precision AND any load-bearing rationale (R2). Findings that drop precision or strip a positive substitute under the banner of "tightening" are themselves rule violations and must be declined.

**Density target (rough, not a hard cap):**

Declarative rule sentences average ≤ 20 words. Some rules genuinely need more; the guardrail is "fully specifies behavior" (cross-cutting principle "Aim for the minimal set that fully specifies behavior"), not "fits in 20 words."
````

<!-- prose-design: skills/_shared/prompt-design-rules.md § The finding-type gate > Blocking findings > rule-violation row (in-place edit) -->
```
| **rule-violation** | R1-R8 misapplied OR a pattern the rule explicitly says to cut/keep was missed. Reviewer must cite the rule ID and the line/section. |
```

**Why this approach.**

- **One named rule, broadly applicable.** Existing rules already follow the pattern of one named R-rule per concern. R8 fits the established shape — authors and reviewers cite it by ID, the rules file remains the SSoT for prompt-prose authoring.
- **Reviewer-test format integrates with existing reviewer protocol.** The finding-type gate already classifies `rule-violation` findings as blocking; adding R8 to the cited rule set makes density findings blocking without changing the gate's structure. Reviewers already know how to cite a rule ID and quote the offending text.
- **The guardrails are explicit, not implicit.** "What NOT to tighten" is its own subsection, named, with the rule citations that defend each protection. Reviewers cannot reasonably file an R8 finding that strips a positive substitute and claim ignorance — the rule explicitly forbids it.
- **The density target is "rough, not a hard cap."** Aligns with the existing cross-cutting principle that minimal means "fully specifies behavior," not "fits in N words." A hard cap would invite the opposite anti-pattern (truncating a rule until it loses precision to hit a number).

**Dependencies + edge cases.**

- Depends on `skills/_shared/prompt-design-rules.md` existing and being current. It is the canonical home for prompt-prose authoring rules; no fallback location.
- Edge case — reviewer files an R8 finding that strips load-bearing rationale. The rule explicitly forbids this; the finding is itself a rule violation and must be declined. The finding-type gate's `rule-violation` row covers this directly.
- Edge case — author tightens a sentence in a way that breaks an anchor phrase (R7) or a verbatim Sub-Rule B prose-design block. The tightening anti-pattern list names anchor-phrase preservation; the reviewer rejects the tightening for breaking R7 (or for breaking the verbatim contract on a Sub-Rule B block).
- Edge case — density target read as a hard cap. The rule explicitly disclaims this; the "fully specifies behavior" guardrail is restated inline. Reviewers must not file R8 findings whose only complaint is "exceeds 20 words" without also identifying behavioral-precision-preserving tightening.
- Cross-cutting with G9: G9's tightening pass cites R8 as its authority. The pass is a one-time application of R8 to the trimmed skill bodies; thereafter R8 is enforced ongoing by reviewers.

**Acceptance.**

- `skills/_shared/prompt-design-rules.md` contains the new R8 section verbatim per the prose-design block above. Anchor-phrase grep verifies: the heading `### R8 — Prose density: short declarative sentences, full behavioral precision`, the table header `| Pattern in current prose | Tightened form | Why it works |`, the `What NOT to tighten` subheading, and the `Could this sentence be shorter without losing behavioral precision OR load-bearing rationale?` test sentence are all present and exact.
- The `rule-violation` row of the finding-type gate cites `R1-R8` (anchor-phrase grep: literal substring `R1-R8`).
- G9's tightening pass cites R8 in its task spec (Plan-level test expectation: the G9 task description includes the literal string "R8" as the authority for the pass).
- Bats coverage (lightweight): a grep-based check that no R-rule heading is duplicated and that all referenced R-IDs in the finding-type gate exist as section headings (`R1`–`R8`).

## Goals

### G1 — Verifier rubric grounded in canonical ID-hygiene authority

**Outcome.** The finding-verifier scores ID-hygiene findings against the canonical forbidden-token authority (`skills/implementer-protocol/SKILL.md` § Hygiene contract) instead of improvising grounding from non-authoritative sources, eliminating the false-negative class observed in v0.7.2 T24/T16.

**Solution.** Two coordinated changes:

1. **Rubric clause appended to `agents/qrspi-finding-verifier.md` § Rubric** (verbatim prose-design):

   <!-- prose-design: agents/qrspi-finding-verifier.md § Rubric (new clause appended) -->
   > For findings whose subject is an identifier-hygiene token (forbidden-token-table match, QRSPI-internal IDs such as `[Tnn]` or `R\d+-F\d+` appearing in test names, commit messages, or runtime prose), ground the verdict in `skills/implementer-protocol/SKILL.md` § Hygiene contract — that is the canonical authority for identifier hygiene across implementer and test contexts. Consult it via `<upstream_paths>` Read on the dispatch prompt; if the path is absent from `<upstream_paths>` for the current step, treat that as a dispatch defect (do not improvise an alternative source). The hygiene-contract tables (Internal-ID forbidden tokens, Evergreen-markdown forbidden tokens) are load-bearing — a finding that cites a token covered by either table is a real ID-hygiene rule, not a missing one.

2. **Path added to the always-appended SKILL paths in `scripts/upstream-paths.sh`** (per CD-1): `skills/implementer-protocol/SKILL.md` joins `skills/<step>/SKILL.md` and `skills/using-qrspi/SKILL.md` in the every-step appended set, so every verifier dispatch carries the path in its lazy-Read window regardless of which artifact step is being reviewed.

The canonical home stays at `skills/implementer-protocol/SKILL.md` § Hygiene contract — no migration. The Hygiene contract is already the operational source for the forbidden-token tables consumed by `qrspi-implementer`, `qrspi-implementer-lightweight`, and (parallel inline) `qrspi-code-quality-reviewer`; G1 closes the loop by giving the verifier the same source.

**Why this approach.** The bug isn't where the table lives — implementers and the code-quality reviewer already find it. The bug is that the verifier, when faced with an ID-hygiene finding, had no specified authoritative source in its loaded context, reached for training-data prior, looked at `CONTRIBUTING.md` (which is scoped to branch-naming + commit-message conventions and contains no test-name rules), and declared the rule absent. Fixing the rubric to name the authoritative source and ensuring that source is in the lazy-Read window is the minimum change that closes the false-negative class. Migrating the table to a new home (`_shared/`, a new dedicated authority doc, or `CONTRIBUTING.md`) adds churn for no behavior gain. Skills-injecting the entire `implementer-protocol` body into every verifier dispatch (alternative considered) violates G9's footprint goal — the verifier runs many times per round and the Hygiene contract is large; lazy-Read-on-demand is the lighter shape.

**Dependencies + edge cases.**
- Hard-depends on **CD-1**: the path-addition step requires the script to exist; sequence CD-1 first, G1 second.
- Hard-blocks **G2**: G2's `[Tnn]` sweep cannot be enforced until the verifier stops false-negativing the findings that drive it.
- Edge case — the rubric directive's "treat that as a dispatch defect" line: if a future step is added to the verifier dispatch path without going through `scripts/upstream-paths.sh`, the directive forces a halt rather than silent fallback. This is intentional fail-loud behavior.
- Edge case — a finding cites a token that resembles a QRSPI-internal ID but is not actually in either forbidden-token table (e.g. a fictional `[X99]` form): the rubric clause restricts grounding to "forbidden-token-table match", so a non-matching token is scored on its own merits, not on the hygiene-contract authority.
- Out of scope: rewriting the Hygiene contract tables themselves. The tables are already correct (per Q1 research). G1 is grounding-fix only.

**Acceptance.**
- `agents/qrspi-finding-verifier.md` carries the new rubric clause verbatim (anchor-phrase grep test in bats).
- `scripts/upstream-paths.sh` always-appended array contains `skills/implementer-protocol/SKILL.md` (bats unit test on script output).
- Synthetic verifier dispatch on an ID-hygiene finding (a `[Tnn]` token in a bats test name) reads `skills/implementer-protocol/SKILL.md` from `upstream_paths`, finds the matching forbidden-token row, and scores ≥ 70 (well above the correctness floor) — captured by a bats test that drives the verifier against a fixture finding and inspects the resulting sidecar.
- The same fixture finding scored under the v0.7.2 verifier scores < 70 (regression-direction test), confirming G1 actually moves the score across the threshold.

### G2 — Sweep `[Tnn]` task-ID markers from test names + prevent reintroduction

**Outcome.** Zero `[Tnn]` (and the related `R\d+-F\d+`) task-ID markers remain in `@test "..."` description strings across the release; reintroduction is mechanically blocked by CI before merge.

**Solution.** Three coordinated changes:

1. **One-time mechanical sweep (hybrid).** A single PR runs a regex sweep across `tests/**/*.bats` stripping the leading/trailing `\s*\[T\d+(-[a-z0-9]+)?\]\s*` and `\s*R\d+-F\d+\b\s*` token patterns from inside `@test "..."` description strings (the description string only — body content untouched). The sweep is mechanical: review burden is "is the regex right?" not "is each rename right?" Residue test names that read awkwardly after the strip are accepted as-is; curated rewrites of any genuinely-degraded names are deferred to a backlog item rather than blocking G2's leak-closure.

2. **Promote implementer self-check from advisory to blocking.** `skills/implementer-protocol/SKILL.md` § Pre-DONE self-check (combined hygiene scan) — the existing self-check that scans the implementer's diff for hygiene violations — gains a blocking directive: an ID-hygiene match in any `@test "..."` description string added or modified by this task halts the DONE signal, requiring the implementer to fix the violation before reporting complete. Today the check is advisory (the implementer is told to scan, no enforcement on detection); the change is one anchor sentence promoting detection to halt.

3. **Release-wide structural lint as a permanent CI gate.** A new bats test under `tests/lint/test-bats-test-name-id-hygiene.bats` greps every `@test "..."` line in `tests/**/*.bats` and asserts the description string does NOT match `\[T\d+(-[a-z0-9]+)?\]` or `\bR\d+-F\d+\b`. Failure output lists offending `file:line` locations and the offending strings. This runs in CI on every PR; reintroduction is mechanically impossible to land. The lint is the same shape as bats' built-in `bats:focus` enforcement and matches the Q4 "grep/awk CI script" established practice.

**Why this approach.** The hybrid sweep closes the leak at the lowest review cost — a regex diff is reviewable by inspecting the regex once, not by reading 5514 individual renames. Per-task self-check (change 2) catches at point of authorship but cannot see cross-task systemic patterns (which is how v0.7.2 accumulated 5514 instances despite a per-task hygiene scan being present); the release-wide lint (change 3) is the structural backstop that runs against the full corpus on every PR. Integration-time reviewer fan-out (a fourth candidate from goals.md) becomes redundant once changes 2+3 land — defer to backlog rather than build redundant layers.

**Dependencies + edge cases.**
- Hard-depends on **G1**: the lint will surface findings during pre-merge review; G1's verifier rubric fix is required so the verifier does not false-negative these findings during artifact-review rounds (the failure mode that produced the 5514 backlog in the first place).
- Sequenced **after G1**: G1 must land first so the lint-driven findings survive the verifier when v0.7.3's own review rounds catch any straggler patterns.
- Edge case — pre-existing tokens inside the description string but NOT at the start (e.g., a test description that says "checks the [T18] handler path" as part of natural prose): the lint regex matches anywhere in the string, not just at start/end; the sweep's strip-regex must handle that too (anchor to whitespace, not to start-of-string).
- Edge case — sibling forms beyond `[Tnn]` and `R\d+-F\d+`: per the v0.7.2 self-host, those two patterns cover the observed leak surface. Other QRSPI-internal IDs (e.g. `CD-N`, `G\d+`) are NOT included in the lint — they are legitimate cross-artifact references and have stable meaning. The lint is scoped narrowly on purpose; expansion is a separate decision.
- Edge case — tests intentionally testing the lint itself: `tests/unit/test-hygiene-self-check.bats` and any future test of the new lint MUST contain forbidden tokens as fixture strings. The lint provides a path-shaped carve-out (e.g., skip files matching `*hygiene*` or `*id-hygiene*`) OR an inline carve-out marker (e.g., a `# bats lint:no-id-hygiene` comment above the `@test` line) following the same carve-out pattern `implementer-protocol` uses for the implementer self-check. Carve-out shape is an implementer-level detail; the design decision is that carve-outs exist.

**Acceptance.**
- After the sweep PR, `grep -rE '@test "[^"]*\[T[0-9]+' tests/**/*.bats` returns zero matches.
- `skills/implementer-protocol/SKILL.md` § Pre-DONE self-check carries the new blocking anchor sentence (grep test in a meta-lint bats).
- `tests/lint/test-bats-test-name-id-hygiene.bats` exists, passes on the post-sweep clean tree, and fails (with the documented diagnostic shape) against a fixture file that carries a `[T99]` token — the fail-direction is exercised by a bats test that calls the lint against a fixture.
- A regression PR (synthetic) that adds `[T99]` to a real test name is rejected at CI by the lint.

### G3 — Plan-author respects design-absorption markers (no manufactured-cleanup tasks)

**Outcome.** Plan-author authoring loop honors design.md absorption / non-goal / deferral markers; no plan task gets manufactured under an absorbed/moot/deferred goal ID; residual real work attaches to the absorbing CD's task scope or surfaces a BLOCKED escalation rather than receiving a manufactured wrapper task; the redirect map the plan-author consumes is verified by design review to preserve authorial intent.

**Solution.** Five coordinated changes. The G3.a/G3.b/G3.e/G3.d sub-labels below refer to the original goals.md sub-requirement IDs for this goal — they are intentionally non-sequential and do not represent a missing G3.c; the lettering preserves the goal-ID traceability chain used by the plan-spec and design reviewers, including the `G3.b safety net` paired item.

1. **Authoritative marker pattern set** (G3.a). `scripts/design-absorption-markers.sh <design-path>` greps `design.md` for the canonical 4 marker patterns and prints the absorbed-goal redirect map to stdout (`<absorbed-ID> <TAB> <absorbing-ID|"no-task">` per line). The 4 enumerated patterns:
   - Heading-suffix `^## G\d+ — .+: (moot|absorbed by CD-\d+|already fixed)`
   - Block-internal `\*\*Explicit non-goal\.\*\*`
   - Acceptance-criterion `no separate v\d+\.\d+(\.\d+)? task ships under (the )?G\d+ ID`
   - Free-prose `deferred to v\d+\.\d+`

   Single source of truth = `design.md`. The map is a transient view; no committed map artifact.

2. **Plan-author pre-fanout step** (G3.b). `skills/plan/SKILL.md` § plan-author loop gains a directive: before drafting any per-task spec, run `scripts/design-absorption-markers.sh` and ingest the redirect map. For any goal ID present in the map, do not draft a standalone task. Anchor sentence (verbatim prose-design):

   <!-- prose-design: skills/plan/SKILL.md § plan-author loop (new anchor sentence) -->
   > Before drafting any per-task spec, run `scripts/design-absorption-markers.sh <design-path>` and ingest the absorbed-goal redirect map (`<absorbed-ID> → <absorbing-ID|"no-task">`). For any goal ID present in the map, DO NOT draft a standalone task; if the original intent surfaces residual work that genuinely needs implementation, attach it to the absorbing CD's task scope, NOT to a new "post-<absorbing-ID> cleanup" wrapper task. If residual work genuinely fits nowhere in the surviving goal/CD set, halt with BLOCKED and surface the case to the user instead of manufacturing a task home.

3. **Plan-spec reviewer hardening** (G3.b safety net). `agents/qrspi-plan-spec-reviewer.md` rubric clause: run the same grep against design.md and assert no plan task carries an absorbed/moot goal ID. The reviewer receives the absorption-map via the dispatch parameter `absorption_map_path` (per CD-2's review-prep generation extension at the plan step). Verbatim prose-design clause:

   <!-- prose-design: agents/qrspi-plan-spec-reviewer.md § Rubric (new clause) -->
   > Read the absorption map at `absorption_map_path` (when present in dispatch parameters). For every entry `<absorbed-ID> → <absorbing-ID|"no-task">`, assert `plan.md` contains no task whose goal ID matches `<absorbed-ID>`. A task carrying an absorbed-goal ID — even with framing such as "post-<CD> cleanup" or "<absorbed-ID> regression prevention" — is a finding (`change_type: scope`); the design has already locked that no separate task ships under that ID.

4. **Design-review map-fidelity check** (G3.e). `agents/qrspi-design-reviewer.md` rubric clause: when the dispatch carries `absorption_map_path`, Read both the map and design.md and verify that the map preserves authorial intent across every entry. Verbatim prose-design clause:

   <!-- prose-design: agents/qrspi-design-reviewer.md § Rubric (new clause) -->
   > When the dispatch parameters carry `absorption_map_path: <path>`, Read the map and Read design.md. For every entry in the map (`<absorbed-ID> → <absorbing-ID|"no-task">`), locate the corresponding goal block in design.md and verify that the prose intent matches the extracted redirect: the goal body describes scope that is genuinely absorbed by the named CD, OR genuinely moot/deferred per the marker form. Flag mismatches as findings: (a) a goal block whose prose describes independent scope but whose marker says absorbed (intent/marker contradiction), (b) a goal block whose prose reads as absorbed but which the map does not list (missing or unrecognized marker form — surfaces a marker-set drift not yet caught by the structural lint), (c) two markers in the same goal block producing contradictory map entries. Fidelity is the contract — the script's output is only useful if the map preserves authorial intent.

5. **Marker-set structural lint** (G3.d). A new bats lint test under `tests/lint/` scans every `design.md` under `docs/qrspi/**/` and asserts that any absorption-shaped marker text matches one of the 4 enumerated patterns. New marker forms surface as lint failures on the design.md PR rather than silently bypassing the pre-fanout grep.

**Why this approach.** v0.7.2's plan-author over-scoped 7 tasks under absorbed/moot goal IDs because (a) the design-absorption signal was not load-bearing on the authoring loop (no procedural rule to consult markers), and (b) only the goal-traceability reviewer caught it, with scores barely above the correctness floor. The fix splits enforcement across three layers: prevention (the pre-fanout step prevents bad tasks from being drafted), structural review (the plan-spec reviewer asserts the rule downstream), and fidelity (the design reviewer verifies the map matches authorial intent so plan-author and plan-spec-reviewer aren't both consuming a corrupt input). The marker-set lint (change 5) catches drift in the enumerated pattern set itself. Together, these make absorbed/moot/deferred goals load-bearing at every layer, not just at review.

Goal-traceability-reviewer threshold/escalation (a fourth candidate from goals.md) is deferred to backlog — it becomes redundant once changes 2-4 are in place, and the v0.7.2 finding showed the threshold-floor approach is a weaker safety net than the structural approach.

The map is **derived**, not authored: nobody maintains a redirect-map file. The script computes it from design.md on demand. Single source of truth; no drift between map and prose.

**Dependencies + edge cases.**
- Hard-depends on **CD-2**: the plan-spec reviewer and design reviewer receive `absorption_map_path` via review-prep generation; CD-2 must extend review-prep to handle the design step's absorption-map output AND the plan step's absorption-map input. Sequence CD-2 first, G3 second.
- Edge case — `absorption_map_path` is empty (no markers in design.md, e.g. early in a release before any goals are absorbed): script writes an empty file; dispatch parameter still passed; reviewers' rubric clauses no-op when the map is empty.
- Edge case — a goal's body genuinely changed scope (was independent, became absorbed) but the design author edited the body without adding a marker: the design quality reviewer's existing scope/quality review catches the body/intent contradiction in the normal review pass; the new fidelity check in change 4 backstops the case where the body was edited correctly but the marker placement is ambiguous. The two layers cover both the marker-without-body-update direction and the body-without-marker-update direction.
- Edge case — a residual-work case the plan-author hits BLOCKED on: the user resolves by either (a) revising design.md (if the marker was wrong, lift it; reopens the goal block) or (b) authorizing the work to attach to the absorbing CD's task with explicit user approval. Either path is human-in-the-loop, not orchestrator-side rationalization.
- Out of scope: rewriting v0.7.2's design.md to retroactively conform to the canonical 4-marker set. v0.7.2 is shipped; v0.7.3's design.md is what the lint applies to going forward.

**Acceptance.**
- `scripts/design-absorption-markers.sh` against a fixture design.md with all 4 marker forms returns the expected map; against a marker-free design.md returns empty (bats coverage).
- The G3.d marker-set lint test passes against the v0.7.3 design.md (this very document — meta-acceptance) and fails against a fixture design.md containing a non-enumerated marker form.
- `skills/plan/SKILL.md` carries the new pre-fanout anchor sentence verbatim (anchor-phrase grep test).
- `agents/qrspi-plan-spec-reviewer.md` carries the new rubric clause verbatim; a synthetic plan.md drafted with a task labeled with an absorbed goal ID (per a fixture absorption-map) produces a `change_type: scope` finding from the reviewer when run against the fixture.
- `agents/qrspi-design-reviewer.md` carries the new fidelity-check rubric clause verbatim; a synthetic design.md fixture where a goal block's body describes independent scope but the heading suffix says "absorbed by CD-1" produces a fidelity-mismatch finding.
- v0.7.3 self-host plan-step round-01 produces zero plan-spec-reviewer absorption findings (proof the pre-fanout step works in practice; meta-acceptance via the run that ships these very changes).

### G4 — Apply-fix protocol carries a `plan`-step upstream-artifact entry

**Outcome.** The per-step `upstream_paths` table extracted in CD-1 carries an explicit Plan-step entry, with the correct upstream set for both pipeline modes (full vs. quick). Verifier behavior is reproducible across orchestrator instances on the Plan step instead of relying on improvisation.

**Solution.** `scripts/upstream-paths.sh` (introduced in CD-1) gains a Plan-step branch that reads `pipeline:` from `<artifact-dir>/config.md` and switches the upstream set:
- **Plan (full pipeline):** `goals.md, research/summary.md, design.md, phasing.md, structure.md`
- **Plan (quick fix):** `goals.md, research/summary.md`

The script reads `pipeline:` internally rather than accepting it as a CLI flag — the orchestrator already knows where `config.md` is (via `--artifact-dir`), and the script reading the field once removes one argument the orchestrator has to pass. The same pattern any other config consumer in the chain uses (per the existing config-validation procedure in `using-qrspi`).

**Why this approach.** The upstream-paths-table prose previously had no Plan entry at all, forcing the orchestrator to improvise the list per run — non-reproducibility was the bug. Adding the entry with both pipeline-mode variants is the minimum mechanical fix. The pipeline-mode source choice (read internally from config.md vs. accept as CLI flag) leans toward "internal read" because it matches how `pipeline:` is consumed elsewhere (Research dispatch cap, auto-approve gate) and avoids the orchestrator having to remember an extra flag per call.

The captured-once-at-run-start artifact-dir idea (raised during this design dialog as a sibling concern) is deferred to GitHub issue #315 — mechanism choice (env var vs. runtime state file) deserves its own design dialog with empirical grounding on subagent env propagation across hosts; v0.7.3 surface area is small enough that explicit `--artifact-dir` per call doesn't move the footprint needle vs. CD-1/CD-2 wins.

**Dependencies + edge cases.**
- Hard-depends on **CD-1**: the script must exist before G4 can add a branch to it. Sequence CD-1 first, G4 second.
- Edge case — `config.md` missing or unreadable: per the existing config-validation procedure in `using-qrspi/SKILL.md`, the script halts with a named diagnostic rather than silently defaulting to a pipeline mode. Same fail-loud shape as every other config consumer.
- Edge case — `pipeline:` field absent from a present-but-malformed `config.md`: same fail-loud halt with a named diagnostic. Do not silently default to `full` or `quick`.
- Edge case — Plan step in quick-fix mode where `phasing.md` and `structure.md` don't exist: the upstream set deliberately omits them (matching Plan's quick-fix artifact gating); the Plan-step verifier dispatch correctly excludes those paths from `upstream_paths`. No fallback to "full set when in doubt."

**Acceptance.**
- `scripts/upstream-paths.sh --step plan --artifact-dir <fixture-artifact-dir>` against a fixture with `pipeline: full` config returns `goals.md, research/summary.md, design.md, phasing.md, structure.md` plus the always-appended SKILL paths (bats coverage).
- Same script (`--step plan --artifact-dir <fixture>`) against a fixture with `pipeline: quick` config returns `goals.md, research/summary.md` plus the always-appended SKILL paths (bats coverage).
- Same script (`--step plan --artifact-dir <fixture>`) against a fixture with missing or malformed `config.md` halts with the documented named diagnostic and exits non-zero (bats coverage).
- v0.7.3 self-host Plan step verifier dispatch (when run through the script) carries a deterministic `upstream_paths` parameter — no improvisation. Verifiable by capturing the dispatch parameter from a synthetic Plan-step round and asserting equality with the fixture-expected set.

---

### G5 — Orchestration Boundary observable beyond Implement

**Outcome.** The Orchestration Boundary HARD-RULE — "MAIN CHAT ONLY ORCHESTRATES. ALL CODE EXECUTION, FILE CHANGES, AND GIT OPERATIONS ARE DELEGATED TO SUBAGENTS. MAIN CHAT NEVER RUNS THE WORK." — is in force at every QRSPI phase (not just Implement), and is observable at phase boundaries so violations surface rather than accumulating silently. The v0.7.2 self-host Integrate R1 incident (main chat editing test files and skill prose to fix reviewer findings) cannot recur undetected.

**Solution.**

Three coordinated changes:

**(a) Inline HARD-RULE prose into `integrate/SKILL.md` and `test/SKILL.md`, plus a cross-cutting note in `using-qrspi/SKILL.md`.** Each per-phase block carries the HARD-RULE verbatim, a self-contained "responsibilities" list, a self-contained "does NOT" list, and a self-contained rationale (no cross-skill references — siblings are not loaded by the orchestrator at phase time).

<!-- prose-design: skills/integrate/SKILL.md § Orchestration Boundary (new section after Iron Law) -->
````
### Orchestration Boundary

```
MAIN CHAT ONLY ORCHESTRATES. ALL CODE EXECUTION, FILE CHANGES, AND GIT
OPERATIONS ARE DELEGATED TO SUBAGENTS. MAIN CHAT NEVER RUNS THE WORK.
```

Main chat's responsibilities in Integrate are: dispatch the integration reviewer subagents, fix-task subagents, and CI-fix subagents per the phase's defined dispatch set; aggregate findings; gate transitions; write the small review-bookkeeping files under `reviews/integration/` (per-round commit anchors, scope-set captures, integration review logs).

Main chat does NOT: edit target-project source files (`scripts/`, `tests/`, `skills/`, `agents/`, `docs/`, etc.), run tests / typecheck / lint, run `git add` / `git commit` / `git merge` / `git rebase`, invoke language toolchains, or perform "quick verification" between review rounds. Any of those activities are delegated to a fresh subagent (a fix-task dispatch for fix work; a re-run of the integration reviewer fan-out for re-verification). Integration-branch git operations (the merge itself, the integration commits) are executed by the dispatched subagents, not by main chat.

**Why this rule matters in Integrate.** Integrate works on the merged integration branch without per-task worktree isolation, so there is no structural CWD separation between main chat and dispatched subagents — the discipline is the only thing keeping the boundary intact. Subagents fork into clean per-dispatch contexts and preserve the per-task quality gate (TDD discipline, per-task reviewer fan-out, finding-verifier scoring) that direct main-chat edits skip. Cumulative drift accumulates silently across the phase when the boundary is crossed. The v0.7.2 self-host Integrate R1 incident — main chat editing test files and skill prose directly to fix reviewer findings — is the failure mode this rule exists to prevent.
````

<!-- prose-design: skills/test/SKILL.md § Orchestration Boundary (new section after Iron Law) -->
````
### Orchestration Boundary

```
MAIN CHAT ONLY ORCHESTRATES. ALL CODE EXECUTION, FILE CHANGES, AND GIT
OPERATIONS ARE DELEGATED TO SUBAGENTS. MAIN CHAT NEVER RUNS THE WORK.
```

Main chat's responsibilities in Test are: dispatch the test-writer subagents, test-execution subagents, and fix-task subagents per the phase's defined dispatch set; aggregate findings; gate transitions; write `reviews/test/round-NN-results.md` (the main-chat-authored summary of test execution results and acceptance coverage table — the only file main chat authors directly in this phase).

Main chat does NOT: write or edit test files or target-project source files (`reviews/test/round-NN-results.md` is the sole exception), run the tests themselves, run `git add` / `git commit`, invoke language toolchains, or perform "quick verification" between review rounds. Any of those activities are delegated to a fresh subagent.

**Why this rule matters in Test.** Test works on the merged integration branch without per-task worktree isolation, so there is no structural CWD separation between main chat and dispatched subagents — the discipline is the only thing keeping the boundary intact. Subagents fork into clean per-dispatch contexts and preserve the per-task quality gate (test-writer Iron Law constraint, reviewer fan-out, finding-verifier scoring); direct main-chat edits skip that gate entirely and accumulate drift no review surface catches. Test-writer subagents are particularly load-bearing because their Iron Law constrains them ("writes tests, does NOT fix code or run tests"); main chat editing test files directly bypasses that constraint at the source.
````

<!-- prose-design: skills/using-qrspi/SKILL.md § Orchestration Boundary applies to every phase (new cross-cutting note) -->
```
### Orchestration Boundary applies to every phase

The Orchestration Boundary HARD-RULE — "MAIN CHAT ONLY ORCHESTRATES. ALL CODE EXECUTION, FILE CHANGES, AND GIT OPERATIONS ARE DELEGATED TO SUBAGENTS. MAIN CHAT NEVER RUNS THE WORK." — applies to every QRSPI phase, not just Implement. Per-phase prose (in `skills/implement/SKILL.md`, `skills/integrate/SKILL.md`, `skills/test/SKILL.md`) carries the phase-specific responsibility list, exception set, and rationale. The structural observability hook (`scripts/orchestration-boundary-check.sh`) runs at every phase boundary and surfaces any violation in the batch-gate menu before the next phase advances. Main chat editing target-project files — even one line, even "just to fix a small reviewer finding" — is a discipline violation regardless of phase or edit size.
```

**(b) Structural observability hook at phase boundaries.** New script `scripts/orchestration-boundary-check.sh --phase <phase> --artifact-dir <path>` runs `git status --porcelain` (uncommitted-edit detection) and lists any commits in the phase range whose author name does NOT begin with `qrspi-` (non-subagent-commit detection, implemented via `git log <phase-base>..HEAD --format='%H %an' | awk '$2 !~ /^qrspi-/'`; git's `--author` flag matches authors literally with no negation operator, so the negation must be done by post-filter), against the integration branch, writing results to `<artifact-dir>/reviews/<phase>/orchestration-boundary.md`. The `<phase>` argument is the directory-convention name used under `reviews/` per the existing per-skill conventions — `integration` for the Integrate phase (per `skills/integrate/SKILL.md`), `test` for the Test phase, `implement` for the Implement phase. The script does NOT remap `integrate` → `integration` or perform any other phase-name normalization; callers pass the directory name verbatim. Per-phase examples below use the resolved directory name (e.g., `reviews/integration/orchestration-boundary.md` for the Integrate phase). Empty file ≡ clean; non-empty ≡ violations to surface. Subagent commits carry the `qrspi-<agent-name>` author marker, injected by the dispatch chain (`scripts/dispatch-agent.sh` sets `GIT_AUTHOR_NAME=qrspi-<agent>` / `GIT_AUTHOR_EMAIL=bot@qrspi.local` via env wrapped around subagent git commands; mechanism detail deferred to Plan).

<!-- prose-design: skills/{implement,integrate,test}/SKILL.md § Process Steps (new phase-end step before batch gate) -->
```
### Step N — Orchestration boundary observability check

Before presenting the batch-gate menu for this phase, run `scripts/orchestration-boundary-check.sh --phase <phase> --artifact-dir "<ABS_ARTIFACT_DIR>"`. The script:

1. Runs `git status --porcelain` against the workspace and lists any modified/added/deleted files (catches uncommitted main-chat edits).
2. Runs `git log <phase-base>..HEAD --format='%H %an' | awk '$2 !~ /^qrspi-/ {print $1}'` against the integration branch's phase range and lists any non-subagent-authored commits (catches main-chat-committed edits; subagent commits carry the `qrspi-<agent-name>` author marker injected by the dispatch chain). Note: git's `--author` flag matches a literal regex against the author identity — it has no negation operator (a leading `!` would be treated as a literal character), so the non-subagent filter is implemented as a post-`git log` `awk` step on `%an` rather than as a `--author` argument.

Both findings are written to `<ABS_ARTIFACT_DIR>/reviews/<phase>/orchestration-boundary.md`. An empty file (no uncommitted files AND no non-subagent commits in the phase range) means clean discipline. A populated file means orchestration-boundary violations; surface the count in the batch-gate menu per § Batch Gate.

The check is fail-soft: a populated file does NOT halt phase advancement on its own — it surfaces the violations to the user via the batch-gate menu for the user's decision. Halting unconditionally would prevent the user from advancing a phase whose orchestration drift they have already accepted (which exists for legitimate reasons in some edge cases — e.g., main chat fixing a typo in its own per-phase review log file). Autopilot mode applies a stricter default — see § Batch Gate.
```

**(c) Batch-gate soft-gate surfacing in interactive mode, branched defaults in autopilot.** When `reviews/<phase>/orchestration-boundary.md` is non-empty, the batch-gate menu adds a violation-handling item (interactive); in autopilot, the orchestrator branches on violation type (commit-based → auto-escalate; uncommitted → halt) since no human is present.

<!-- prose-design: skills/{implement,integrate,test}/SKILL.md § Batch Gate menu (new conditional item) -->
```
**Orchestration-boundary violations (when `reviews/<phase>/orchestration-boundary.md` is non-empty).** Prepend the following item to the batch-gate menu, before the standard advance/re-run options:

> Phase <phase> completed with N orchestration-boundary violations recorded in `reviews/<phase>/orchestration-boundary.md`:
> - <K> uncommitted main-chat edits to project files
> - <M> non-subagent commits in the phase range
>
> Choose:
>   (a) Review violations now (open the report and walk through each)
>   (b) Escalate — pause this phase and dispatch a fix-task subagent to remediate (only when the edits should not have happened — e.g., main chat edited project code mid-phase to "quickly fix" a reviewer finding)
>   (c) Acknowledge and continue (advance to next phase with violations noted; appropriate when the edits were legitimate mid-pipeline tooling/hotfix work that happens to fall in the phase range)

If the file is empty, omit this menu item entirely.
```

<!-- prose-design: skills/{implement,integrate,test}/SKILL.md § Batch Gate menu (autopilot default, branched) -->
```
**Autopilot mode.** When `scripts/detect-interaction-mode.sh` reports `autopilot` AND the orchestration-boundary report is non-empty, the orchestrator branches on violation type:

- **Non-subagent commits in the phase range (commit-based violations).** Auto-escalate: dispatch a fix-task subagent with mode `revert-orchestration-drift` that reverts the offending commits and writes the action to `<ABS_ARTIFACT_DIR>/reviews/<phase>/orchestration-boundary-revert.md`. Then re-run the phase-end check; if clean, advance. Cap auto-revert at 1 attempt per phase: if the re-run is still non-empty (something is regenerating the drift), do NOT revert again — fall through to halt-and-surface (write a halt marker at `<ABS_ARTIFACT_DIR>/HALT-orchestration-boundary-recurring.md` listing both the original violations and the post-revert violations, emit "Halted at <phase> batch gate — orchestration-boundary violations recurred after auto-revert," and exit the autopilot loop). Rationale: in autopilot the user is not in the loop, hotfix work cannot be user-approved, ∴ every non-subagent commit in the phase range is discipline drift by construction and safe to auto-revert; but a recurring violation after revert is a different failure shape that requires human triage.

- **Uncommitted workspace changes (`git status --porcelain` non-empty).** Halt: write a halt marker at `<ABS_ARTIFACT_DIR>/HALT-orchestration-boundary.md` listing the dirty paths and the workspace state, emit "Halted at <phase> batch gate — uncommitted main-chat edits require human decision," and exit the autopilot loop. Rationale: auto-reverting uncommitted state (`git checkout -- .` / `git stash`) destroys whatever the agent was mid-doing without anyone able to triage it first.

Interactive mode is unaffected by this branching; the (a)/(b)/(c) menu applies as defined above.
```

**Why this approach.**
- **Inline prose over cross-references** — each per-phase SKILL is consumed standalone by the orchestrator at phase time; sibling SKILLs are not loaded. Cross-references ("see Implement § Orchestration Boundary") would silently drop the rule. Verbatim inline ensures the rule is in context at the moment it applies.
- **Structural observability over self-reporting** — the v0.7.2 incident specifically was main chat believing it was following the rule while editing files anyway. A self-check directive ("did you edit anything directly?") cannot catch the failure mode where the agent doesn't notice. `git status` + `git log ... | awk '$2 !~ /^qrspi-/'` are mechanical and don't depend on the orchestrator's self-awareness.
- **Author marker over tool-call audit log** — tool-call audit log scanning would be host-API-specific (different shape across Claude Code / Copilot CLI / Codex) and would not survive host portability. Git author marker is portable, durable (commits carry it forever), and inspectable post-hoc with one command.
- **Fail-soft in interactive, branched in autopilot** — interactive mode trusts the human to triage. Autopilot has no human, so the design distinguishes the two failure shapes: committed drift (auto-revertable by construction per the user-approval logic for hotfixes) vs. uncommitted dirty workspace (destructive to auto-resolve, halt is safer).

**Dependencies + edge cases.**
- Depends on the dispatch chain setting `GIT_AUTHOR_NAME=qrspi-<agent>` on subagent commits. Without that marker, every commit looks like a violation. G5 owns the marker-injection logic itself — adding the `GIT_AUTHOR_NAME` / `GIT_AUTHOR_EMAIL` env-wrapping around subagent git commands inside `scripts/dispatch-agent.sh`. The dependency on CD-2 is structural, not logical: CD-2 introduces dispatch-agent.sh's high-level (orchestrator-facing) mode that runs subagents end-to-end, so G5 needs CD-2's surface in place before it can attach the marker-injection step to it. Sequence CD-2 before G5.
- Edge case — phase-base SHA selection: the script needs to know where the phase started in the integration branch. Resolved by reading the phase's stage-commit SHA written by the existing stage-commit mechanism (G6's surface). G5 depends on G6 producing a recoverable phase-base anchor. The concrete anchor surface (e.g., a `reviews/<phase>/phase-tip-commit.txt` file, or an equivalent recoverable name on the integration branch's stage-commit chain) is deferred to Plan — G6 already produces stage commits whose SHAs are recoverable from git history; Plan specifies which name and write-site G5's script consumes. Sequence G6 before G5's script lands, or fold both into the same task batch.
- Edge case — legitimate main-chat-authored bookkeeping files under `reviews/<phase>/` show up in `git status` if uncommitted. The check correctly excludes the `reviews/` path tree from the uncommitted-dirt count — those files are explicitly allowed per the per-phase responsibility list.
- Edge case — fix-task `revert-orchestration-drift` mode (new in (c) for autopilot) needs spec. Mode behavior: read the violation report, `git revert --no-edit <SHA>` for each non-subagent commit in reverse chronological order, commit the reverts under the subagent's marker, write `orchestration-boundary-revert.md` summarizing actions. Mode added to the existing fix-task subagent spec (implementer-protocol carries it).
- Edge case — repeated auto-revert loops in autopilot: if the same phase produces violations → auto-revert → re-check → still produces violations, that's a different failure (something is regenerating the drift). Cap auto-revert attempts at 1 per phase; on second violation in the same phase, fall through to halt-and-surface regardless of violation type.

**Acceptance.**
- `skills/integrate/SKILL.md` contains the verbatim Orchestration Boundary section above (anchor-phrase grep: the HARD-RULE block + the "Why this rule matters in Integrate" paragraph).
- `skills/test/SKILL.md` contains the verbatim Orchestration Boundary section above (anchor-phrase grep).
- `skills/using-qrspi/SKILL.md` contains the cross-cutting note (anchor-phrase grep).
- `scripts/orchestration-boundary-check.sh` exists, accepts `--phase` + `--artifact-dir`, writes the report, exits 0 on clean and 0 on dirty (fail-soft; populated report is the signal, not exit code). Bats coverage for: clean integration branch (empty report), one non-subagent commit (one entry in report), uncommitted-edit workspace (entry in report), allowlisted `reviews/` path excluded from uncommitted count.
- `scripts/dispatch-agent.sh` (or its subagent-invocation chain) injects `GIT_AUTHOR_NAME=qrspi-<agent>` such that subagent commits in a synthetic fixture round carry the marker. Bats coverage by inspecting `git log --format='%an'` against a subagent-produced commit.
- `skills/implement/SKILL.md`, `skills/integrate/SKILL.md`, and `skills/test/SKILL.md` all contain a `### Step N — Orchestration boundary observability check` block per the (b) inline above, ordered before the batch-gate step. (Implement runs the check at phase end after all waves complete — the stage-commit chain authored by wave-dispatch is exactly where commit-based orchestration drift is most likely.)
- `skills/{implement,integrate,test}/SKILL.md` Batch Gate sections contain both the interactive menu addition and the autopilot branched-default block per the (c) inlines above.
- v0.7.3 self-host Integrate phase produces an empty `reviews/integration/orchestration-boundary.md` (zero violations); if the phase reproduces the v0.7.2 R1 violation shape (main chat edits to skill prose mid-Integrate), the report is non-empty and the batch-gate menu surfaces it before phase advancement.

---

### G6 — Stage-commit parent SHAs validated against named task tips

**Outcome.** When the Implement-phase wave-dispatch step creates a stage commit labeled `merge(T20, T21, T22)`, the commit's actual git merge parents are validated to equal the named task-tip SHA set at creation time. On mismatch, the wave halts with a named diagnostic and does not advance. The v0.7.2 self-host failure shape (a stage commit labeled `merge(task-21, task-26)` whose actual parents were `stage-after-W4` + `task-26-tip`, silently dropping all of task-21's work, including a security-relevant guard that shipped missing) cannot recur silently.

**Solution.** Add a trust-but-verify fence inside the existing wave-dispatch merge step:

1. After `git merge --no-ff <task-branches>` creates the stage commit, read the actual parent SHAs from `git log --format='%P' -n 1 HEAD`.
2. Compare the actual parent SHA set against the expected parent SHA set captured at wave-dispatch resolution time. **Capture procedure:** immediately before invoking `git merge --no-ff <task-branches>`, the wave-dispatch step captures (a) `git rev-parse HEAD` as the integration-base SHA (will become parent[0] of the `--no-ff` merge), and (b) `git rev-parse refs/heads/<task-NN>` for each task name, writing the full {integration-base, task-tips...} set to a runtime sidecar (path Structure's call — described here as "a runtime sidecar under the artifact-dir's review-state tree"). The sidecar is runtime-only — resolved SHAs are NOT written back to `parallelization.md`, preserving the symbolic-only branch-map invariant established in research Q11/Q12. The validation in step 3 reads from this sidecar and compares the full parent set, with no parent[0]-stripping normalization.
3. On equality, proceed. On mismatch, halt the wave with a named diagnostic: `"stage-commit-parent-mismatch: stage commit <SHA> labeled merge(<task-list>) has actual parents {<actual-set>}, expected {<expected-set>}; task tips missing: <missing>; unexpected parents present: <extra>"`. Do not advance, do not record the wave as complete, do not let the orchestrator continue.

The validation is a wrapper around an existing seam, not new architecture. It runs immediately after the merge so the diagnostic fires at the exact moment the bad commit lands — before any downstream review consumes it.

**Why this approach.** The bug class (named-vs-actual parent drift) bypasses both per-task review and integration review by construction — both review the diff against the **claimed** base, not the actual commit parents. Adding the check at any later stage means downstream reviews continue to spend context against a silently-incorrect base. Validation at merge-time fires before any reviewer is even dispatched. Mechanism is minimal: one `git log --format='%P'` + a set comparison + a halt. No new architecture, no new author markers, no new artifacts — just a fence at the existing merge seam. The only honest alternative considered ("trust the merge command and rely on downstream tests to catch drift") is exactly what v0.7.2 did, and a 3,254-file PR shipped with a missing security guard.

**Dependencies + edge cases.**
- Depends on the wave-dispatch step capturing both the integration-base SHA (`git rev-parse HEAD` before merge) and each task tip SHA to a runtime sidecar under the artifact-dir's review-state tree (exact path Structure's call) immediately before `git merge`. This is new behavior introduced by this goal (not existing — research Q11/Q12 confirms resolved SHAs are never written back to `parallelization.md`, and no prior runtime sidecar exists). The capture step lands in the same dispatch-chain script as the validation; both are part of this goal's surface area.
- Edge case — single-task wave: actual parents = {integration-base, task-tip}; expected = {task-tip}; comparison must include the integration-base parent as expected (it's always parent[0] of `git merge --no-ff`). Either record the expected-set as "everything except parent[0]" or include the integration base in the expected set. Choose the latter for symmetry — the validation always compares full parent set vs. full expected set.
- Edge case — fast-forward avoidance: `--no-ff` is mandatory; without it a single-task "merge" is a fast-forward and has only one parent. The dispatch chain already uses `--no-ff` per implement/SKILL.md; the validation can rely on it.
- Edge case — non-merge commits in the wave step (e.g., a fix-up commit added between merge and the validation call): the check runs against the stage commit's SHA captured immediately after the merge call returns, not against `HEAD` at validation time. Avoids racing against any subsequent commits the orchestrator might layer on.

**Acceptance.**
- `scripts/wave-dispatch.sh` (or its successor in the dispatch chain — name TBD by Plan, not load-bearing for this design) calls a parent-validation helper immediately after the merge. Bats coverage:
  - Fixture stage commit with correct parents → validation passes silently, wave advances.
  - Fixture stage commit with one task tip missing from parent set → validation halts with `stage-commit-parent-mismatch` diagnostic naming the missing tip.
  - Fixture stage commit with an unexpected extra parent → validation halts naming the extra parent.
  - Single-task fixture wave → integration-base parent is correctly counted in expected set; passes when present, halts when absent.
- v0.7.3 self-host Implement waves all produce stage commits whose validation passes silently (zero halts). Verifiable post-hoc by replaying `git log --format='%P'` against each stage commit and comparing to the wave manifest.
- Capture step coverage: a fixture proves the wave-dispatch step writes the integration-base SHA and each task-tip SHA to the runtime sidecar before invoking `git merge`; the validation step in the same script reads from that sidecar; and `parallelization.md` is unchanged after the wave (preserving the symbolic-only branch-map invariant per research Q11/Q12).

---

### G7 — Narrow-round ref selection robust under multi-commit-per-round patterns

**Outcome.** When the Apply-fix protocol step 12 narrows the diff for round N+1 against round N, the ref resolves to round N's per-round commit by name (not by positional `HEAD~1` shorthand). The `HEAD~1` shorthand is brittle in two ways the script-enforced anchor-file lookup eliminates: (1) any unrelated commit landing between rounds (hotfix, bookkeeping, anchor SHA file pickup) shifts `HEAD~1` off the prior round's commit, producing a malformed diff; (2) the current SKILL-prose `HEAD~1` incantation is orchestrator-skippable under context pressure — an orchestrator can rationalize "this round's narrow diff looks fine" without verifying the ref actually points at round N-1. Replacing the implicit positional ref with a script-enforced lookup against the named anchor file (`reviews/<step>/round-<NN-1>-commit.txt`) makes both failure modes structurally impossible. The existing one-commit-per-round shape (per research Q13/Q14) is preserved.

**Solution.** Replace `HEAD~1` with explicit anchor-file lookup in step 12's narrow branch.

Round-N's per-round commit SHA is already written to `reviews/<step>/round-NN-commit.txt` by step 11 (the anchor SHA file-write — not its own commit; per research Q13/Q14 each round produces exactly one commit). Step 12 reads that file directly when computing the narrow ref:

```
git diff "$(cat reviews/<step>/round-<NN-1>-commit.txt)" -- <artifact-path>
```

Keep the existing one-commit-per-round shape (the per-round commit bundles the artifact + the entire `round-NN/` subdir + sibling bookkeeping files; the anchor SHA file `reviews/<step>/round-NN-commit.txt` is written by main chat after the commit and remains uncommitted until the NEXT round's per-round commit picks it up — confirmed in research Q13/Q14). Keep the divergence-sanity-check assertion (if step 12 expects a narrowed diff to be non-empty and gets zero lines, halt with a named diagnostic rather than silently dispatching reviewers against an empty diff).

**Why this approach.** The two candidates from goals.md were "single commit per round (amend-in-place)" vs. "explicit anchor-file lookup." Anchor-file lookup chosen because:
- The bug isn't the commit shape — it's using `HEAD~1` as an implicit positional ref when we already write the SHA by name to a file. Fix the implicit ref; don't restructure the commit pattern.
- The anchor file `round-NN-commit.txt` is preserved as a human-readable audit artifact ("here's exactly what round N reviewed, in a file a human can `cat`"). Losing that artifact loses post-hoc traceability.
- Restructuring would require changing round-prepare mechanics across every skill that uses the pattern (implement + integrate + test + 8 artifact-step skills' review rounds). Wide surface area to solve a problem that one find/replace per skill solves cleanly.
- `git commit --amend` after computing the SHA introduces new bug surface (race against any concurrent commit, gotchas around what `HEAD` resolves to mid-amend, edge cases when the round produced zero changes and there's nothing to commit) that the anchor-file approach simply doesn't touch.

The fix is also tiny — one ref expression per step-12 invocation across the affected skills. Touches `skills/using-qrspi/SKILL.md` § Apply-fix protocol step 12 (the canonical definition) and any skill that inlines the step-12 incantation.

**Dependencies + edge cases.**
- Depends on `reviews/<step>/round-NN-commit.txt` actually existing and containing the correct SHA. Step 11 writes it; this is existing behavior. If the file is missing, the `cat` fails loudly (not silently — `cat` of a missing file exits non-zero, the resulting `git diff "$()"` call fails, the orchestrator sees the error). No silent fallback to `HEAD~1`.
- Edge case — round 1 has no prior round. Step 12's narrow branch only fires from round 2 onward; round 1 reviews the full artifact against the base branch (existing behavior, unchanged).
- Edge case — divergence sanity check: if the narrowed diff is empty when step 12 expects content (the only place this happens legitimately is when the implementer's fix happened to be a no-op, e.g., they reverted a partial change that already matched the baseline), halt with a named diagnostic: `"narrow-round-empty-diff: round NN narrowed diff against round <NN-1> SHA <SHA> is empty; either implementer fix was a no-op or anchor SHA points wrong commit"`. Forces human triage rather than silently dispatching an empty review.
- Cross-cutting with G5 author marker: the anchor SHA file (`round-NN-commit.txt`) is a file-write performed by main chat (research Q13/Q14 confirms one commit per round; the file write is not its own commit and remains uncommitted until the next round's per-round commit picks it up). Under G5, that file write is bookkeeping main-chat operation, allowlisted because it only writes to `reviews/<step>/` (the per-phase review log path tree, explicitly allowed). No subagent authors the anchor file; the orchestration-boundary rules apply only to git commits.

**Acceptance.**
- `skills/using-qrspi/SKILL.md` § Apply-fix protocol step 12 prose replaces `HEAD~1` with the anchor-file-lookup incantation above. Anchor-phrase grep verifies the literal `git diff "$(cat reviews/` substring is present and that no occurrence of `git diff HEAD~1 --` remains in step 12's prose.
- Any other skill that inlines step-12's incantation (sweep: `grep -rn 'HEAD~1' skills/` under the v0.7.2 baseline) is updated to match.
- Bats coverage:
  - Fixture with an unrelated commit between rounds (regression-guard against the v0.7.2 `HEAD~1`-shifted shape): anchor-file-based diff returns the correct content (round N's per-round commit diff), `HEAD~1`-based diff returns wrong content.
  - Missing anchor file: the orchestrator's call exits non-zero with a clear error (no silent fallback).
  - Empty-narrowed-diff: the divergence sanity check fires with the `narrow-round-empty-diff` diagnostic.
- v0.7.3 self-host: every step-12 dispatch resolves its narrow ref by reading `reviews/<step>/round-<NN-1>-commit.txt`. Verifiable by inspecting any phase's review-round dispatch logs for the literal `cat reviews/` pattern in the diff command.

---

### G8 — Centralized version source for the plugin manifest set

**Outcome.** The plugin version string has a single canonical source at `VERSION` (repo root, bare one-line file). All five consumer files (`.claude-plugin/marketplace.json`, `.claude-plugin/plugin.json`, `.github/plugin/marketplace.json`, `.github/plugin/plugin.json`, `build/.claude-plugin/plugin.json`) are stamped from that source by `tools/build-plugin.mjs` on every build. CI fails on any divergence between committed tree and freshly-built output. The five-site hand-bump pattern that produced ongoing release-time footguns and adjacent regressions like v0.7.2.3's `source` mismatch cannot recur silently.

**Solution.**

1. **Canonical source: repo-root `VERSION` file.** Bare one-line file containing the version string (e.g., `0.7.3\n`). No JSON, no metadata, no surrounding tooling — just the version. No `package.json` introduction (avoids implying npm conventions the project doesn't use).

2. **Stamper: `tools/build-plugin.mjs` reads `VERSION` and writes it into all five consumer files on every build.** Build script is the sole writer of version fields in those files. Manual edits to `"version"` in any of the five consumer files are no longer the authoring path — `VERSION` is the only file an author edits.

3. **CI gate: build-then-diff.** A CI step runs `node tools/build-plugin.mjs` and then `git diff --exit-code` against the committed tree. Any divergence — version mismatch, build-output drift in `build/`, marketplace `source` field shifted, anything the build writes that doesn't match what's committed — fails the build. This generalizes beyond version-stamping to catch the entire class of "did the committed build/ artifact match the source?" regressions (the v0.7.2.3 `source: "./"` vs `"./build"` shape).

4. **Authoring discipline.** `build/` stays committed (for `git clone` install path). The build script is the sole writer under `build/`. No manual edits to `build/.claude-plugin/plugin.json` permitted; CI gate enforces.

**Why this approach.**

- **`VERSION` over `package.json`.** No `package.json` exists today. Adding one to be the version source implies npm conventions (install steps, scripts, `npm publish` flows) the project explicitly does not use. `VERSION` introduces zero tooling-convention baggage — it is the version string and nothing else.
- **`VERSION` over "designate an existing manifest as canonical."** Picking one of the five existing manifests as authoritative still requires every contributor to know WHICH one is canonical. Same footgun shape, just renamed. `VERSION` at repo root is unambiguously canonical because it has no other purpose; nobody mistakes it for one of the consumer manifests.
- **Build-then-diff CI gate over pre-commit hook.** Pre-commit hook requires every contributor to install the hook locally (install burden, drift across machines, can be bypassed). CI runs unconditionally. Build-then-diff also catches a strictly broader class of drift than version-only checks — it asserts the entire committed `build/` matches a fresh build output, which is the actual property we want (and would have caught v0.7.2.3 directly).
- **Stamper in the existing build script over a new dedicated tool.** `tools/build-plugin.mjs` already runs on every release; adding version-stamping there keeps the surface area minimal. No new build infrastructure to learn or maintain.

**Dependencies + edge cases.**

- Edge case — `VERSION` file missing or malformed (empty, non-version content, multi-line). Build script halts with a named diagnostic (`"version-source-missing-or-malformed: VERSION at repo root must contain a single non-empty version string"`). No silent fallback to a default version.
- Edge case — version string format. Honor whatever the existing manifests use (e.g., `0.7.3` semver-ish). Build script does not parse or validate semver — just reads the line and writes it through. Stricter validation can land later if it matters.
- Edge case — a contributor edits `"version"` in one of the consumer files directly (forgetting that `VERSION` is canonical). CI's build-then-diff gate catches this: a fresh build overwrites the manual edit, `git diff --exit-code` fails, the contributor is told to edit `VERSION` instead.
- Edge case — release commit ordering. The release flow becomes: edit `VERSION`, run `node tools/build-plugin.mjs`, commit the entire diff (VERSION + propagated stamps + any other build-regenerated content) in one commit. CI gate then passes on that commit. Document this in the release runbook.
- Cross-cutting with G9 footprint: G8 touches `tools/build-plugin.mjs` and the five consumer files only — no SKILL.md surface. Independent of G9's trimming, lands in any phase.

**Acceptance.**

- `VERSION` exists at repo root, contains exactly one version string.
- `tools/build-plugin.mjs` reads `VERSION` and writes the version into all five consumer files on every build. Bats coverage (or node-test): `echo "9.9.9" > VERSION && node tools/build-plugin.mjs && grep '"version": "9.9.9"'` matches in all five consumer files.
- CI step runs `node tools/build-plugin.mjs && git diff --exit-code` and fails on any divergence. Test: a fixture commit that hand-edits `"version"` in one consumer file (without bumping `VERSION`) causes the CI step to fail.
- Build script halts with the named diagnostic on missing or malformed `VERSION`. Bats coverage for the empty-file and missing-file cases.
- Release runbook (or contributing prose under `docs/`) updated to instruct contributors to edit `VERSION` and let the build script propagate.
- v0.7.3 release itself is shipped via the new flow — `VERSION` bumped to `0.7.3`, single build run, single commit. Verifiable by inspecting the v0.7.3 release commit.


---

### G9 — Active-skill-prompt footprint reduction across all 14 skills

**Outcome.** Total active-context skill footprint per typical session drops from ~80-95K tokens (current: using-qrspi + heaviest active skill) to ~15-30K tokens (post-trim using-qrspi + post-trim active skill + `!cat`'d shared snippets). Per-skill SKILL.md bodies carry only decision contracts and load-bearing process steps. Cross-cutting orchestrator behaviors live in a thin `using-qrspi/SKILL.md` bootstrapper. Multi-skill process boilerplate lives in `skills/_shared/<topic>.md` snippets, `!cat`-inlined at skill-load time for max salience. Script-mechanic restatements are deleted outright (scripts are SSoT). Optional examples and rare-path procedures move to per-skill `references/<topic>.md` Read on-demand. A prose-density tightening pass (per CD-3 / R8) is applied to every kept paragraph. The v0.7.2 phase-1 acceptance suite passes against the trimmed skills as the regression backstop.

**Solution.** Four coordinated passes, applied in order across all 14 active skills:

**Pass 1 — Three-tier content placement.** Apply the placement rule uniformly. The architectural decision is the four reuse tiers below (universal / multi-skill-shared / skill-specific / on-demand-optional) and which kind of content belongs to each tier; the specific file paths in the "Lives where" column are the established conventional locations and may be refined by Structure if needed (the tier identity is what Design fixes, not the literal path string).

| Content type | Lives where | Why |
|---|---|---|
| Universal orchestrator behaviors (Iron Laws, Approval Markers, status flow, mid-pipeline entry, backward loops, common-rationalizations STOP, behavioral directives D1-D4, route table, when-to-trigger, the G5 cross-cutting orchestration-boundary note) | `using-qrspi/SKILL.md` | Truly universal; every session needs them; 1× load per session beats N× inlining. Salience less critical because these are context-of-being rules, not per-skill decision rules. |
| Multi-skill load-bearing process boilerplate (reviewer-dispatch incantation, Standard Review Loop body, Config Validation procedure body, Compaction Checkpoint template, Pause Gate UI, Feedback File Format) | `skills/_shared/<topic>.md`, `!cat`-ed into each skill that uses it | Max salience for the current skill (R3). Maintainability via single source file. Token cost paid only when consuming skills load. |
| Skill-specific process + decision logic | The skill's own SKILL.md body | Maximally salient; no reason to move out. |
| Optional examples, worked examples, pedagogical content, rare-error-path recovery procedures | `skills/<name>/references/<topic>.md`, Read on-demand | R5(a)/(b)/(c) conditions hold here; zero active cost when not needed. |
| All script-mechanic restatements | DELETED | Scripts are SSoT (see Pass 2). |

**Pass 2 — Delete script-mechanic restatements outright** (scripts are SSoT, the prose adds nothing the orchestrator does not already learn from script exit codes or behavior):

- Codex/third-party dispatch pipeline prose — owned by `scripts/dispatch-companion.sh` (config-driven transport selection) and `scripts/codex-companion-bg.sh` (jobId lifecycle).
- jobId await / tmpfile / raw-capture mechanics — owned by `scripts/await-round.sh` and the output-bound contract built into every async script.
- HEAD~1 SHA safety-check prose — owned by `scripts/round-prepare.sh` (exit codes 10/11/12).
- Convergence narrow/broaden rule tables — owned by `scripts/round-prepare.sh` ("deterministic set comparison").
- Verifier sidecar schema, `change_type` enum, threshold rules — owned by `scripts/verifier-fan-in.sh` (literally labeled "SINGLE SOURCE OF TRUTH").
- Per-finding split mechanics from raw third-party output — owned by `scripts/third-party-finding-splitter.sh`.
- "Halt with named diagnostic" prose where the script returns the diagnostic.
- HARD-GATE prose restating script-enforced gates.
- The 4× verifier wiring duplication in implement/SKILL.md.
- The 2× visual-fidelity dispatch duplication in implement/SKILL.md.
- Per-skill restatements of using-qrspi's Standard Review Loop step 1 diff-emission contract (CD-2 already moves the diff emission into `scripts/review-prep.sh`; the prose restatements in the artifact-step skills go to zero).

**Pass 3 — Prose-density tightening per R8 (from CD-3).** Apply R8's tightening patterns + the "what NOT to tighten" guardrails to every kept paragraph in every skill body. Reviewer test from R8 applies: "Could this sentence be shorter without losing behavioral precision OR load-bearing rationale?" — if yes, tighten; if no, leave. The pass cites R8 as its authority in the task spec.

**Pass 4 — Regression guard execution.** Run the v0.7.2 phase-1 acceptance suite (already captured under `goals.md` § Constraints as the regression backstop) against the trimmed skill set. Every test passes against the trimmed skills, OR a failing test diagnoses a load-bearing rule that was over-trimmed (escalate the offending content from `references/` back into the active skill body, or restore the deleted boilerplate to `_shared/`). Zero regressions on the suite is the gate.

**Sequencing within v0.7.3 phasing.** G9 lands last (per goals.md cross-cutting note). G1-G7 + G8 + CD-1 + CD-2 + CD-3 land first — they add prose (orchestration-boundary inlines, anchor-file lookup, parent validation, etc.) and extract shared snippets. G9 then trims the resulting state. Doing G9 first would create merge churn against every other goal's edits.

**Why this approach.**

- **Three-tier placement is the only architecture that respects both don't-unload and salience.** Don't-unload (skills load sequentially and stay): cross-cutting boilerplate in using-qrspi costs 1× per session vs. N× inlining. Salience (R3): per-skill body is more salient than session-bootstrap context. Resolving both: universal context-rules in using-qrspi (low salience cost is acceptable for universal rules); multi-skill load-bearing process content in `_shared/` `!cat`-ed into each skill (max salience for the consuming skill, maintained in one file).
- **R5 explicitly rules out Read-on-demand for content every invocation needs.** "Spine + references saves zero tokens if the spine always instructs the read." The reviewer-dispatch incantation is needed every Review Round; Read-on-demand would save nothing while losing salience. `_shared/` + `!cat` is the right shape; per-skill `references/` is only correct for genuinely optional content (R5 conditions).
- **Deleting script-mechanic restatements has no behavioral cost.** The orchestrator does not need to understand the dispatch pipeline to invoke it correctly — it invokes the script, the script either returns an exit code (halt) or completes (proceed). Prose narrating the pipeline mechanics is pure verbosity-bias cost.
- **R8 tightening compounds with structural trim.** The architecture moves the right content to the right tier; R8 tightens what remains. Stacked, the savings are multiplicative, not additive.
- **Experimental posture for the optional/references split.** Per the user-directed compromise: start tight, watch for gaps in real use, escalate from `references/` back into the active skill body via `!cat` from the same `references/` file if gaps emerge. Zero rework cost. The default lean is "more in `references/`, less in the active body" because un-trimming is cheap (re-`!cat`) and over-bloating is expensive (every-turn cost).

**Dependencies + edge cases.**

- Depends on CD-1 (upstream-paths.sh extraction) and CD-2 (review-prep.sh + dispatch-agent high-level mode) having landed first. Both extract significant prose from skill bodies; G9 trims what remains.
- Depends on G5's orchestration-boundary HARD-RULE prose being authored into integrate/test/using-qrspi BEFORE the trim pass. G9 must not delete content G5 just authored; sequence within the same phase but order the additions before the tightening pass.
- Edge case — `!cat` snippet ordering. When a skill `!cat`s multiple shared snippets, ordering matters for R3 (load-bearing rules at end). Snippets that are NOT load-bearing (informational templates) `!cat` earlier; snippets carrying load-bearing rules (reviewer-dispatch, review-loop semantics) `!cat` later in the skill body to preserve the end-of-context advantage.
- Edge case — a skill that uses a `_shared/` snippet only conditionally (e.g., only in full pipeline mode, not quick-fix mode). Snippet still `!cat`s unconditionally at skill-load time (no conditional `!cat` mechanism). Acceptable — the snippet is small, and conditional behavior is gated by the orchestrator's process-step logic, not by snippet presence.
- Edge case — a `references/` file that turns out to be needed every invocation. Detected by the regression guard (Pass 4) — if the v0.7.2 acceptance suite catches a load-bearing rule lost to over-trimming, escalate the content back into the active skill body. Re-`!cat` from the same `references/` file path; no content rewrite needed.
- Edge case — using-qrspi shrinks below the bootstrapper threshold (say, < 150 lines), suggesting the universal-orchestrator-behaviors list was over-trimmed. Same regression-guard mechanism catches this; restore the missing rule.
- Cross-cutting with CD-3: G9's tightening pass cites R8 verbatim. CD-3 must land before G9 (or in the same task batch, with CD-3 applied first within the batch).
- Cross-cutting with G8: G8 is independent of the SKILL.md surface; no sequencing constraint.

**Acceptance.**

- **Structural trim.** `using-qrspi/SKILL.md` < 350 lines (currently 1,262); `implement/SKILL.md` < 500 lines (currently 1,451); `plan/SKILL.md` < 400 lines (currently 726); each artifact-step skill < 300 lines (currently 270-499). Line-count targets are guideposts, not hard caps — passing the regression guard (below) is the real gate.
- **Three-tier placement enforced.** Every kept paragraph in every SKILL.md is one of: a decision contract, a skill-specific process step, an Iron Law / OWNS / Red Flag / handoff, or a `!cat` reference to a `_shared/` snippet. No script-mechanic restatements remain (grep audit: zero matches for jobId / tmpfile / HEAD~1 narrative / sidecar schema / change_type enum across all active SKILL.md files).
- **`skills/_shared/` populated.** New snippets exist: `reviewer-dispatch.md`, `review-loop.md`, `config-validation.md`, `compaction-checkpoint.md`, `pause-gate.md`, `feedback-format.md`. Each is `!cat`-referenced from the skills that need it; each is the SSoT for its content (no duplication in any active SKILL.md).
- **`references/` populated per-skill.** Skills with worked examples or rare-path procedures (e.g., design's Sub-Rule worked examples, implement's wave-dispatch deep dive, replan's backward-loop examples) have their pedagogical content moved to `skills/<name>/references/<topic>.md`. The active SKILL.md retains a one-line pointer where context-relevant ("Worked examples for Sub-Rule A live in `references/sub-rule-a-examples.md`; Read on-demand when authoring an A-altitude block").
- **R8 tightening applied.** The G9 task spec cites R8 as authority. Reviewer test from R8 has been applied to every kept paragraph in every skill body (auditable post-hoc via reviewer findings: zero open R8 findings against the trimmed skill bodies at G9 task completion).
- **Regression guard.** The v0.7.2 phase-1 acceptance suite (already in `tests/acceptance/v07-phase1/`) passes against the trimmed skill set. Zero regressions.
- **Footprint measurement.** Active-context token measurement (using a deterministic tokenizer — tiktoken or the host's tokenizer) shows total per-turn footprint (using-qrspi + heaviest active skill + `!cat`'d shared snippets) below 30K tokens for a typical session. The measurement script lives at `scripts/measure-active-footprint.sh` and is run as the final acceptance gate; output recorded at `docs/qrspi/2026-06-04-v073-release/g9-footprint-report.md`.
- **Trim audit grep set.** A grep-based audit confirms zero matches across all active SKILL.md files for the following patterns (each match would indicate Pass 2 was incomplete): `jobId`, `tmpfile`, `HEAD~1`, `narrow.broaden`, `sidecar.*schema`, `change_type:.*enum`, `verifier.*threshold`, `third-party.*splitter` (narrative restatements; concrete script names in process-step calls are fine).
