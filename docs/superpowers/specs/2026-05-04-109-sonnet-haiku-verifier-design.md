# Sonnet→Haiku Confidence Verifier Design

> **Issue:** #109. **Pattern source:** `/code-review` skill (`~/.claude/plugins/cache/claude-plugins-official/code-review/unknown/commands/code-review.md`). **Sequencing:** Tier 2 of the v0.5 plan; depends on #110 (subagents in agent files), which lands first.

**Goal:** Insert a Haiku-class confidence verifier between QRSPI's artifact-level reviewer subagents and the orchestrator's apply/pause dispatch. Auto-apply findings (`change_type` ∈ `style|clarity|correctness`) that don't survive Haiku scrutiny against the verbatim 0–100 rubric from `/code-review` are filtered before they reach the apply path. Pause-class findings (`change_type` ∈ `scope|intent`) are NEVER filtered by score — they always reach the user.

**Scope:** ONLY the artifact-level Apply-fix protocol in `skills/using-qrspi/SKILL.md` for the 8 artifact steps `Goals / Questions / Research / Design / Phasing / Structure / Parallelize / Replan`. Plan, per-task implementation, integration, and test reviewers retain their existing flows; their verifier integration is deferred (§7).

**Architecture (one sentence):** Reviewers emit one finding per file; main chat dispatches one Haiku verifier per file in parallel; each Haiku writes a **sidecar score file** next to the finding (it never mutates the original); main chat Bash-assembles the per-finding files + sidecars + clean/crash markers into `round-NN-verified.md` it reads exactly once.

**Tech stack:** Existing QRSPI agent-file infrastructure (per #110), `scripts/codex-companion-bg.sh` async pipeline (extended with a finding-boundary splitter), Bash assembly with no-stdout redirects, `Read`/`Write` tools.

**Error-handling philosophy:** any abnormality (verifier failure, malformed reviewer output, unexpected exit code) routes through a single generic 3-option menu (`skip`, `retry`, `stop`). The spec does NOT enumerate per-failure-mode preserve guards, snapshots, or sentinels — the sidecar design eliminates the file-corruption surface the heavy machinery was defending against, and any other anomaly is handed to the user.

---

## §1 Components

### `agents/qrspi-finding-verifier.md` (new)

Frontmatter:
- `name: qrspi-finding-verifier`
- `model: haiku`
- `tools: [Read, Write]`
- `description: "Score a single reviewer finding 0–100 against the /code-review confidence rubric. Read the per-finding file + artifact + lazy-Read upstreams; Write a sidecar score file; return a brief <reviewer_tag>.<finding_id>: <score> line."`

Body sections:
- **Rubric** — verbatim copy of `/code-review` step 5's 0/25/50/75/100 anchor definitions (a/b/c/d/e), including the verbatim "give this rubric to the agent verbatim" prefix language. Anchors are reference points on the continuous 0–100 scale; the verifier emits any integer in `0..100`.
- **False-positive examples** — adapted from `/code-review` step 4–5, augmented for QRSPI:
  - Pre-existing issues
  - Pedantic nitpicks
  - Issues a linter/typechecker/compiler would catch
  - General code-quality issues not in CLAUDE.md or upstream artifacts
  - Issues called out in CLAUDE.md but explicitly silenced
  - Real issues on lines the user did not modify in this round
  - **(QRSPI)** Altitude mismatches (e.g. Goals reviewer flagging Plan-level detail) — drop
  - **(QRSPI)** "X is missing" findings where X is in the artifact, just not where the reviewer looked
  - **(QRSPI)** Findings that contradict captured user decisions in `feedback/*.md` (verifier checks the citation against the file)
- **Input contract** — prompt parameters:
  - `<finding_file_path>` — absolute path under `reviews/{step}/round-NN/`
  - `<sidecar_path>` — absolute path the verifier writes to (always `<finding_file_path>` with `.md` → `.score.md`)
  - `<artifact_path>` — absolute path to the artifact under review
  - `<diff_file_path>` — absolute path to `reviews/{step}/round-NN.diff` (round 2+; empty string on round 1)
  - `<upstream_paths>` — newline-separated upstream-artifact + SKILL paths the verifier may Read on demand
- **Procedure**:
  1. Read `<finding_file_path>` (5-field finding object + prose body).
  2. Read `<artifact_path>` + `<diff_file_path>` (if non-empty) eagerly.
  3. For each `referenced_files` entry, Read it.
  4. If any `<upstream_paths>` is cited or seems load-bearing, Read it.
  5. Score on the continuous 0–100 integer scale using the rubric anchors.
  6. Write `<sidecar_path>` with the YAML body:
     ```yaml
     score: <int 0..100>
     reason: <≤1-sentence>
     ```
     On failure, instead Write:
     ```yaml
     score: VERIFY_FAILED
     reason: <one-sentence diagnosis>
     ```
  7. Return exactly: `<reviewer_tag>.<finding_id>: <score>` (e.g. `quality-claude.R3-F02: 87`) or `<reviewer_tag>.<finding_id>: VERIFY_FAILED:<reason>`. The reviewer-tag prefix disambiguates findings that share a `finding_id` across reviewer_tag values (per §2 finding-id uniqueness rules).

The verifier never edits the finding file — only ever writes a sibling sidecar. This eliminates the entire "verifier mutates source-of-truth" hazard surface (no preserve guard, no checksum snapshot, no boundary sentinel needed).

### `skills/reviewer-protocol/SKILL.md` (amendments — bifurcated contract during the migration window)

`reviewer-protocol/SKILL.md` is preloaded by every reviewer agent (artifact-level + per-task + plan-step + integration + test). #109 migrates only the 14 artifact-level reviewers; the rest are deferred. The amendment is **bifurcated**:
- The current single-file contract is renamed `## Legacy Disk-Write Contract (deferred reviewers)`.
- A new `## Per-Finding Disk-Write Contract (#109 reviewers)` is added alongside.
- A **Reviewer-Tag Routing Table** at the top of the skill enumerates which tag uses which contract.

The bifurcation is removed in the follow-up issue (§7) when the deferred reviewers migrate. The new section defines:
- **Per-finding emission contract** — file path = `reviews/{step}/round-NN/<reviewer_tag>.finding-F<NN>.md`, F-numbered zero-padded in emission order, where `<reviewer_tag>` is the dispatcher-supplied value (one of `quality-claude` / `scope-claude` / `quality-codex` / `scope-codex` for #109).
- **Per-finding file format** — YAML frontmatter (4 schema fields + 3 audit fields) + body (prose `message`):
  ```yaml
  ---
  finding_id: R3-F02
  severity: high
  change_type: correctness
  referenced_files: [skills/design/SKILL.md]
  artifact: design
  round: 3
  reviewer: quality-claude
  ---

  {message body — multi-paragraph prose, the 5th schema field, transported in the body to avoid YAML quoting}
  ```
- **Schema fields** (the canonical 5-field finding schema): `finding_id`, `severity` ∈ `low|medium|high`, `change_type` ∈ `style|clarity|correctness|scope|intent`, `referenced_files` (list), `message` (body).
- **Audit fields** (frontmatter only): `artifact`, `round`, `reviewer` (must equal `<reviewer_tag>` and the filename prefix).
- **`finding_id` uniqueness** — unique per `(round, reviewer_tag)`. Canonical form `R{NN}-F{NN}`. Splitter-fallback form (Codex emitted malformed output) `R{NN}-F00-<reviewer_tag>` — the schema-guard regex `^R\d+-F\d+(-[a-z-]+)?$` accepts both.
- **Clean-round sentinel** — when a reviewer's analysis surfaces zero findings, it Writes a single `reviews/{step}/round-NN/<reviewer_tag>.clean.md` with a frontmatter-only body (`reviewer: <tag>`, `round: <NN>`, `findings: 0`).
- **Reviewer brief-return shape** — five lines: `Step / Round / Reviewer / Findings / Written to`.
- **Trailing newline** — every per-finding file ends with exactly one `\n` (deterministic byte-level normalize-then-warn at apply-fix step 2 if malformed).

The Expected-Reviewer Matrix lives adjacent to the Routing Table, listing the expected reviewer-tag set per artifact step (config-aware: respects `codex_reviews: false`, no scope reviewer for Questions/Research).

### Reviewer agent files (modifications)

Per the scope statement, this issue migrates ONLY the artifact-level reviewers for the 8 artifact steps. The change is mechanical and per-agent: locate the procedure step that today writes `reviews/{step}/round-NN-{reviewer}.md` and replace it with the per-finding emission contract.

**Affected files for #109 (14 reviewer agent files):**
- 8 artifact-quality reviewers — `qrspi-{goals,questions,research,design,phasing,structure,parallelize,replan}-reviewer.md`
- 6 scope reviewers — `qrspi-{goals,design,phasing,structure,parallelize,replan}-scope-reviewer.md`

(Plan excluded; Questions and Research have no scope reviewers, hence 6 scope reviewers not 8.)

**Dispatch-site amendments (8 dispatching skills):** `skills/{goals,questions,research,design,phasing,structure,parallelize,replan}/SKILL.md` pass the role-distinct `reviewer_tag` value (replacing today's collapsed `claude`/`codex`); inject the per-finding-file format + `NO_FINDINGS` sentinel + `<<<FINDING-BOUNDARY>>>` delimiter into the Codex reviewer prompt, with worked one-finding and zero-findings examples and an explicit constraint "emit only finding blocks (each preceded by `<<<FINDING-BOUNDARY>>>`) or the literal `NO_FINDINGS` sentinel; no prose outside finding bodies."

**The role-distinct rename is load-bearing:** today the unique disambiguator between artifact-quality and scope is the output FILE PATH (`round-NN-claude.md` vs `round-NN-scope-claude.md`); post-#109 both write into the same `round-NN/` directory, so path-based disambiguation collapses. Routing keys on the role-distinct tag values; per-finding filenames carry the role-distinct prefix.

**Files NOT modified by #109 (deferred to follow-up):** the 5 plan-artifact reviewers, the unified plan-quality + plan-scope reviewers, the 8 per-task implementation reviewers, the implement-gate reviewer, the security-integration reviewer, the integration-quality reviewer (18 reviewers total). Migration is atomic in the follow-up issue so Plan never has mixed-contract rounds.

### `scripts/codex-finding-splitter.sh` (new)

`scripts/codex-companion-bg.sh await --artifact-dir <ABS_DIR> <jobId>` is unchanged. After `await` returns:

- **Exit 0, well-formed stdout** — main chat invokes `scripts/codex-finding-splitter.sh <stdout-path> <round-subdir> <reviewer_tag>`:
  - Splits on `<<<FINDING-BOUNDARY>>>` lines; writes each segment to `<round-subdir>/<reviewer_tag>.finding-F<NN>.md`.
  - On the literal `NO_FINDINGS` sentinel: writes a single `<reviewer_tag>.clean.md`.
  - On malformed input (no boundaries AND no `NO_FINDINGS` sentinel, OR empty stdout): writes a single `<reviewer_tag>.crash.md` whose body contains a one-line `## Splitter Note` with the failure reason and the raw Codex stdout verbatim. NO synthetic frontmatter, NO F00 fake-finding — the crash file is the user-triage surface and the failure menu (§3) handles it.
- **Exit non-zero (10/11/12/13/14)** — main chat does NOT invoke the splitter. It writes a `<reviewer_tag>.crash.md` audit file directly with the existing crash-note content.

Splitter is idempotent.

### `skills/using-qrspi/SKILL.md` (Apply-fix protocol — verifier-aware revision)

The current Apply-fix protocol is replaced with this 12-step sequence. Lands atomically in the cutover commit (§8) with the reviewer-protocol amendment + reviewer-agent migrations.

1. **List per-reviewer outputs** for the round (nullglob-safe, fully path-qualified):
   ```bash
   shopt -s nullglob
   D="reviews/{step}/round-NN"
   findings=( "$D"/*.finding-*.md )
   cleans=( "$D"/*.clean.md )
   crashes=( "$D"/*.crash.md )
   ```
2. **Per-expected-tag schema-violation guard.** Evaluate the Expected-Reviewer Matrix for the current step against `config.md.codex_reviews`. For each expected tag, assert step 1 produced at least one of (`<tag>.finding-*.md`, `<tag>.clean.md`, `<tag>.crash.md`). Any expected tag with zero matches → present the §3 failure menu. Step 2 also fails loud on: malformed YAML, missing required fields, malformed `change_type` enum, unrouted `(step, tag)` route. Trailing-newline malformations are normalized (deterministic strip+append-`\n`) with a one-line audit warning, NOT a hard fail.
3. **Crash-staging + verifier-enabled gate (unconditional, then conditional).** First (always): for each tag with both a crash file and finding files, move the tag's finding files to `reviews/{step}/round-NN/.crash-skipped/`. Re-glob to refresh the post-staging arrays. Then read `verifier_enabled` from `config.md`; if `false`, jump to step 6 (skip dispatch, all findings kept, no scoring).
4. **Dispatch one `qrspi-finding-verifier` per non-crashed finding-file path in parallel.** Each verifier reads its file + artifact + lazy-Reads upstreams + writes its sidecar `.score.md`. Main chat receives ~10-token returns per Haiku.
5. **Aggregate returns.** If any return is `VERIFY_FAILED:` OR any sidecar is missing on disk after dispatch, route to the §3 failure menu BEFORE assembly. Otherwise continue.
6. **Bash assembly** of the round into `reviews/{step}/round-NN-verified.md`:
   ```bash
   cat "${findings[@]}" \
       "${findings[@]/%.md/.score.md}" \
       "${cleans[@]}" \
       "${crashes[@]}" \
     > "$D/../round-NN-verified.md"
   ```
   (Schematic — the implementation pairs each finding with its sidecar in interleaved order so the assembled file groups them. The `awk` totals header is then injected on top.) Header fields: `verifier_enabled: <true|false>`, `scored`, `kept`, `dropped`, `failed`, `clean`, `crashed`, `crash-skipped`. Counts derive from sidecar contents and file presence — there is no disambiguator between empty-stdout and other crashes; both count as `crashed`.
7. **Read** `reviews/{step}/round-NN-verified.md` exactly once.
8. **Filter and dispatch.** Partition findings by `change_type`:
   - `scope` and `intent`: bypass score filter; flow directly to the existing pause gate.
   - `style`, `clarity`, `correctness`: filter at score ≥80 (verifier-enabled rounds with a sidecar score) or keep-all (verifier-disabled rounds OR sidecar absent OR sidecar has VERIFY_FAILED). Survivors → `Edit` on the artifact.
   - Crash files → pause gate (reviewer-failure path).

   Out-of-enum `change_type` values are loud failures from step 2's schema guard.
9. **Write** `reviews/{step}/round-NN-fixes.md` (≤30 lines).
10. **`/compact`** to shed the verified-file Read.
11. **Per-round commit** covers the artifact, `round-NN/` subdir (including sidecars + `.crash-skipped/`), `round-NN-verified.md`, `round-NN-fixes.md`.

The diff-handling protocol (today's line 527+) is unchanged.

### `skills/using-qrspi/SKILL.md` config schema additions

Add `verifier_enabled` (boolean, default `true`) to the Config-File schema:
- **Default:** `true`. Set by the using-qrspi run-init code at run creation. CLI-flag opt-out is out of scope (§7); to start a run with the verifier disabled, the user runs once, hits the §3 menu, picks `skip` (which writes `verifier_enabled: false` to config for the rest of the run).
- **Persistence:** durable across `/compact`, pause, resume, and re-entry within the run directory under `docs/qrspi/<date>-<bundle>/`. Fresh run directory starts with `verifier_enabled: true`.
- **Carve-out from the no-silent-defaults rule:** runtime-backfill — if the field is missing from `config.md` on first verifier-aware Apply-fix invocation, treat as `true`, surface a one-line stderr warning once per resume, and backfill the field. Documented in the Config-File schema's "Exceptions" section.

## §2 Data flow (compressed)

```
Reviewers (Sonnet/Codex)             Main chat (orchestrator)              Haiku verifiers
─────────────────────────────────    ────────────────────────────────      ─────────────────────
Per-finding files emitted to         1. List finding/clean/crash files
reviews/{step}/round-NN/.            2. Schema-violation guard.
Codex stdout → splitter →            3. Stage crashed-tag findings into
  per-finding files OR clean            .crash-skipped/. Read verifier_
  marker OR crash file.                 enabled. If false → step 6.
                                     4. Dispatch one Haiku per finding ──> Read finding + artifact +
                                        in parallel.                        upstreams. Score 0–100
                                                                            against rubric. Write
                                                                            <finding>.score.md
                                                                            sidecar. Return
                                                                            "<tag>.<id>: <int>" or
                                                                            "<tag>.<id>: VERIFY_FAILED:
                                                                            <reason>".
                                     5. If any VERIFY_FAILED or any
                                        missing sidecar → §3 menu.
                                     6. Bash assembly of finding files +
                                        sidecars + clean + crash files →
                                        round-NN-verified.md (awk header
                                        with totals).
                                     7. Read round-NN-verified.md once.
                                     8. Partition by change_type:
                                          scope/intent → pause gate
                                          style/clarity/correctness →
                                            score ≥80 (or keep-all if
                                            sidecar missing or
                                            verifier_enabled=false)
                                          → Edit on artifact
                                        crashes → pause gate.
                                     9. Write round-NN-fixes.md.
                                    10. /compact. 11. Per-round commit.
```

## §3 Failure handling (single generic menu)

Any abnormality during Apply-fix dispatches the same 3-option menu:

```
QRSPI verifier round failure
─────────────────────────────
{one-line summary of the abnormality, e.g.:
  - "Verifier returned VERIFY_FAILED for 2 findings"
  - "Reviewer quality-claude produced no output"
  - "Codex stdout malformed (no FINDING-BOUNDARY delimiters)"
  - "Sidecar missing for finding quality-claude.R3-F02"}

What would you like to do?
  1. skip   — proceed without scoring this round (kept-all assembly).
              Sets verifier_enabled: false for the rest of this run
              and writes reviews/{step}/round-NN-verifier-disabled.md
              (timestamp + reason + finding count).
  2. retry  — re-dispatch the failed verifiers / re-run the splitter
              against the same Codex stdout / re-prompt the reviewer.
              Specific to the failure type; each retry path is bounded
              and surfaces the same menu again on a second failure.
  3. stop   — abort the protocol with no commit. The round directory
              remains on disk for inspection.

(no default; user must pick)
```

Always-on footer: "If the same path keeps failing, picking `skip` is the safe escape."

`skip` is the only option that mutates state (config.md). `retry` is bounded by the underlying operation (verifier dispatch → re-dispatch failed verifiers only; splitter → re-run on same input; reviewer no-output → re-dispatch the reviewer). `stop` is non-destructive. There is no retry counter — repeated retries surface the menu repeatedly so the user can switch to `skip` whenever.

## §4 Cost discipline

Per-round Haiku cost (typical `N=8` finding-file count, `~5K` artifact, `~500-token` finding):
- Per-finding tokens: `~500 (finding) + 5000 (artifact) + ~200 (rubric) + ~1500 (lazy upstreams when read) ≈ ~7K input + ~50 output`.
- Round total: `8 × 7K ≈ 56K input + 400 output`.
- Haiku 4.5 input rate ≈ `$0.80/MTok` → **`~$0.045 per round`**. Negligible.

Wallclock: parallel dispatch → ~3–5 sec total (Haiku call latency).

## §5 Tests

Added to `tests/unit/`:

1. **`test-verifier-agent-file.bats`** — `agents/qrspi-finding-verifier.md` exists; frontmatter has `model: haiku`, `tools: [Read, Write]`; body cites the 0/25/50/75/100 anchors verbatim from /code-review step 5; rubric described as continuous 0–100; sidecar path is constructed by replacing `.md` → `.score.md`; brief-return shape is `<reviewer_tag>.<finding_id>: <int 0..100>` (or VERIFY_FAILED).
2. **`test-per-finding-file-emission.bats`** — every #109-scope reviewer agent file (14 files) instructs per-finding emission with the canonical filename pattern using role-distinct `reviewer_tag` values; `<reviewer_tag>.clean.md` clean-sentinel pattern documented; legacy single-file writes are absent. Deferred reviewers (18) are explicitly skipped with a comment citing the follow-up issue number.
3. **`test-codex-splitter.bats`** — `scripts/codex-finding-splitter.sh` exists, executable; handles boundary-delimited input (multi-finding split with role-distinct tag in filenames), `NO_FINDINGS` sentinel (writes clean marker), malformed input (writes crash file with raw stdout in body, NO synthetic finding), empty input (writes crash file), idempotency. Asserts splitter is NOT invoked on `await` non-zero exit. Asserts the Codex prompt template in each #109 dispatching skill includes worked one-finding + zero-findings examples + the no-prose-outside-finding-blocks constraint.
4. **`test-verifier-dispatch-contract.bats`** — `using-qrspi/SKILL.md` Apply-fix protocol body references the 11 documented steps in order: enumerate, schema guard, stage+gate, parallel verifier dispatch, aggregate, assembly, read-once, filter/partition by change_type, write fixes, /compact, per-round commit. Asserts the protocol does NOT instruct main chat to read per-reviewer single files for #109-scope artifacts. Asserts `await` non-zero routes to crash-file path, not splitter.
5. **`test-failure-menu.bats`** — main-chat-authored protocol body describes the §3 menu with three exact option strings (`skip`, `retry`, `stop`); no default option; `skip` mutates `config.md` `verifier_enabled: false` and writes `round-NN-verifier-disabled.md`; the always-on footer is present. Fixture covers each abnormality the menu handles (VERIFY_FAILED, missing reviewer output, malformed Codex stdout, missing sidecar).
6. **`test-verified-file-shape.bats`** — `round-NN-verified.md` is the assembly of `*.finding-*.md` + `*.score.md` + `*.clean.md` + `*.crash.md` with totals header (`verifier_enabled`, `scored`, `kept`, `dropped`, `failed`, `clean`, `crashed`, `crash-skipped`). The file is the sole apply-fix dispatch Read source. Three fixtures: enabled+clean (scored>0, some kept, some dropped); disabled-from-start (scored=0, all kept); skip-after-failure (scored = pre-failure successful subset, kept = scored + VERIFY_FAILED + un-dispatched, failed = VERIFY_FAILED count).
7. **`test-config-verifier-enabled-field.bats`** — `verifier_enabled` documented in the Config-File schema; default `true`; runtime-backfill carve-out documented; field is read by every artifact-level Apply-fix invocation; persistence semantics (durable across /compact + resume) documented; mid-run mutation precedent (`review_mode`/`review_depth`) cited.
8. **`test-disabled-mode-fallthrough.bats`** — when `verifier_enabled: false`, Apply-fix protocol skips verifier dispatch (no sidecars created) but STILL assembles `round-NN-verified.md`; dispatch keeps all findings via "no sidecar → keep" branch (NOT a synthetic 80 score); no preserve-guard semantics referenced. Fixture round directory verifies behavior.
9. **`test-change-type-partition.bats`** — Apply-fix dispatch protocol asserts scope/intent flow to pause gate REGARDLESS of score; style/clarity/correctness are score-filtered at ≥80 in verifier-enabled rounds; the canonical 5-value `change_type` enum is cited from `reviewer-protocol/SKILL.md`; out-of-enum values trigger loud failure. Fixture verified.md with mixed `change_type`s + assertion of routing.
10. **`test-clean-sentinel-and-schema-guard.bats`** — `reviewer-protocol/SKILL.md` defines `<reviewer_tag>.clean.md` sentinel format and the dispatcher's "zero-files-and-no-clean-and-no-crash → fail loud" rule. Negative fixtures assert the failure path.

## §6 Out of scope

- **Plan-step verifier integration** (entire Plan dispatching skill including 7 reviewers).
- **Per-task implementation review verifier integration** (8 reviewers + per-task aggregation).
- **Integration / security-integration / integration-quality verifier integration**.
- **Implement-gate verifier integration**.
- **Within-round dedup** (same finding flagged by Claude AND Codex).
- **Across-round dedup** (same finding re-flagged in round N+1 after surviving round N's drop).
- **Per-per-reviewer-tag dispatch** (one Haiku per tag instead of per finding).
- **Verifier model upgrades** (Sonnet verifier, custom rubric per artifact type).
- **CLI-flag opt-out at `/qrspi` invocation** for verifier-disabled-from-start mode.
- **Preserve guard / checksum snapshot / boundary sentinel infrastructure.** The sidecar-write design eliminates the file-mutation surface this would defend; if practice surfaces verifier-side corruption, add then.

The follow-up issue migrates Plan-step reviewers atomically and collapses the bifurcated reviewer-protocol skill back to a single contract.

## §7 Migration sequence

The cutover commit (step 4) is the load-bearing atomicity boundary. Pre-cutover commits are purely additive.

**Step 0:** File the follow-up issue BEFORE any code commits. Body cites the spec by stable path (`docs/superpowers/specs/2026-05-04-109-sonnet-haiku-verifier-design.md §6`), not by merged-commit file paths. Test #2's deferred-reviewer comments cite the follow-up issue number.

1. **Verifier agent file.** Create `agents/qrspi-finding-verifier.md` with rubric + false-positive examples + sidecar-write procedure. Land alone with test #1. Not yet referenced — purely additive.

2. **Codex splitter (script only, no prompt or wrapper changes).** Add `scripts/codex-finding-splitter.sh` and a NARROWED `tests/unit/test-codex-splitter.bats` that exercises the splitter directly with synthetic inputs (boundary-delimited, NO_FINDINGS, malformed, empty). Codex prompts in dispatching skills are NOT changed in this commit; the test does NOT grep dispatching skill prompts. Splitter is dead code until step 4 wires it up.

3. **`config.md` schema update (documentation only).** Add `verifier_enabled` field (default `true`) to `using-qrspi/SKILL.md` Config-File schema. Land with a NARROWED `test-config-verifier-enabled-field.bats` that asserts schema-doc presence (default-on, persistence, runtime-backfill carve-out) — does NOT yet assert the field is read by any protocol.

4. **Atomic cutover commit (the load-bearing one).** Single commit lands every runtime-behavior change:
   - The bifurcated reviewer-protocol amendment (Routing Table + Expected-Reviewer Matrix + new Per-Finding Disk-Write Contract keyed on the 4 role-distinct tags + renamed Legacy section).
   - All 14 #109-scope reviewer agent file migrations (per-finding emission + clean sentinel + new brief-return shape, using the role-distinct `reviewer_tag` value).
   - Codex prompt + dispatch-parameter amendments in 8 dispatching skills (role-distinct tag, `<<<FINDING-BOUNDARY>>>` + `NO_FINDINGS` + worked examples, retire `output:` path-arg).
   - The Apply-fix protocol revision in `using-qrspi/SKILL.md` (11-step verifier-aware sequence including the runtime-backfill code).
   - The §3 failure-menu logic in `using-qrspi/SKILL.md` (`skip`/`retry`/`stop` + `skip` mutation + always-on footer).
   - Test updates pinning the new contracts (tests #2, #3, #4, #5, #6, #7, #8, #9, #10).

   The commit is large by design (~50 files: 14 agent files + 8 dispatching skills + 1 reviewer-protocol skill + 1 using-qrspi skill + the splitter + ~10 test files + a few READMEs/docs). Pre-merge gates: (i) every existing bats passes; (ii) every new bats passes; (iii) the §7 step-5 smoke matrix passes for ALL 8 #109 steps.

5. **Smoke matrix.** Run a real review round per behavior class:
   - Questions or Research (no scope reviewer) — verifies the config-aware matrix doesn't false-fail.
   - Goals or Design (full 4-reviewer set) — verifies routing-table disambiguation.
   - One run with `verifier_enabled: false` from start (smoke fixture manually edits `config.md` before the run).
   - One run with `codex_reviews: false`.
   - One run with synthesized crash + finding files for one tag (verifies step-3 staging in both modes).
   - One run that triggers splitter malformed-input → crash file (no synthetic finding).
   - One run with a verifier hitting VERIFY_FAILED → §3 menu → `skip` chosen (verifies kept-all fall-through).
   - One run with a verifier hitting VERIFY_FAILED → §3 menu → `retry` chosen (verifies re-dispatch).

6. **Documentation update** in `docs/qrspi/CHANGELOG.md` describing the verifier addition and listing the follow-up issue.

Rollback contract: steps 1–3 are individually revertible (purely additive). Step 4 must be reverted as a whole. Step 5 is not a code change. After step 4 lands, the pre-#109 reviewer-output shape is gone for #109-scope reviewers; deferred reviewers retain their existing shape via the legacy section.
