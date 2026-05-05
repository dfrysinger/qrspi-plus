# Sonnet→Haiku Confidence Verifier Design

> **Issue:** #109. **Pattern source:** `/code-review` skill (`~/.claude/plugins/cache/claude-plugins-official/code-review/unknown/commands/code-review.md`). **Sequencing:** Tier 2 of the v0.5 plan; depends on #110 (subagents in agent files), which lands first.

**Goal:** Insert a Haiku-class confidence verifier between QRSPI's artifact-level reviewer subagents and the orchestrator's apply/pause dispatch. Auto-apply findings (`change_type` ∈ `style|clarity|correctness`) that don't survive Haiku scrutiny against a verbatim-copied 0/25/50/75/100 confidence rubric are filtered before they reach the apply path. Pause-class findings (`change_type` ∈ `scope|intent`) are NEVER filtered by score — they always reach the user, regardless of verifier verdict.

**Scope (in/out):** This issue covers ONLY the artifact-level Apply-fix protocol in `skills/using-qrspi/SKILL.md` (the protocol that runs after each artifact review round across Goals/Questions/Research/Design/Phasing/Structure/Plan/Parallelize/Replan). Per-task implementation review (the loop in `skills/implement/SKILL.md`) and the integration review (in `skills/integrate/SKILL.md`) keep their existing apply/pause flows in this issue; their verifier integration is deferred to a follow-up issue (see §8).

**Architecture (one sentence):** Reviewers emit one finding per file; main chat dispatches one Haiku verifier per file in parallel; each Haiku writes its score back into its file; main chat Bash-assembles the per-finding files into a single `round-NN-verified.md` it reads exactly once.

**Tech stack:** Existing QRSPI agent-file infrastructure (per #110), `scripts/codex-companion-bg.sh` async pipeline (extended with a finding-boundary splitter), Bash assembly with no-stdout redirects, `Read`/`Write` tools.

---

## §1 Architecture

A new Haiku-class subagent (`agents/qrspi-finding-verifier.md`, `model: haiku`) scores each finding emitted by upstream artifact-level reviewers (Claude artifact-quality, Claude scope, Codex artifact-quality, Codex scope) using the verbatim 0/25/50/75/100 confidence rubric copied from `/code-review` step 5. Main chat dispatches one verifier per finding in parallel from `using-qrspi/SKILL.md`'s Apply-fix protocol; the verifier writes its score back into the per-finding file; main chat Bash-assembles the round's per-finding files into a single `reviews/{step}/round-NN-verified.md` and reads that file exactly once for apply/pause dispatch. The single read is the audit AND the dispatch surface — there is no second read of per-reviewer files.

**Filter ordering (load-bearing):** The score filter applies BEFORE auto-apply but the verifier never gates pause-class findings. Concretely: at apply-fix dispatch time, the orchestrator partitions findings on `change_type` first; `scope` and `intent` findings flow directly to the existing pause gate regardless of verifier score; `style`, `clarity`, and `correctness` findings are filtered at score ≥80 and the survivors flow to auto-apply. This preserves the reviewer-protocol guarantee that user-decision conflicts (`intent`) and altitude/boundary findings (`scope`) always reach the user. The verifier's job is to reduce auto-apply false-positive pressure, not to gate user surfacing.

The design copies `/code-review`'s pattern faithfully on three load-bearing axes: the verbatim 0/25/50/75/100 rubric with the ≥80 threshold, the per-finding-parallel Haiku dispatch (one Haiku per finding, fault-isolated, attention-isolated), and the input-context discipline (artifact eagerly, upstream/SKILL paths lazily). It diverges from `/code-review` on the dispatch container — `/code-review` is a single-shot PR review, QRSPI is a multi-stage multi-round pipeline — by making the verifier file-format-aware so the audit-trail and main-chat-context-discipline contracts compose with QRSPI's existing disk-write contract.

## §2 Components

### `agents/qrspi-finding-verifier.md` (new)

Frontmatter:
- `name: qrspi-finding-verifier`
- `model: haiku`
- `tools: [Read, Write]`
- `description: "Score a single reviewer finding 0-100 against the /code-review confidence rubric. Read the per-finding file, score against the artifact and lazy-Read upstreams, write the score back to the same file, return a brief ID:score line."`

Body sections:
- **Rubric** — verbatim copy of `/code-review` step 5's 0/25/50/75/100 grade definitions (a/b/c/d/e), including the verbatim "give this rubric to the agent verbatim" prefix language.
- **False-positive examples** — adapted from `/code-review` step 4–5 examples, augmented for QRSPI:
  - Pre-existing issues (already in the artifact before this round's diff)
  - Pedantic nitpicks a senior engineer wouldn't call out
  - Issues that a linter, typechecker, or compiler would catch
  - General code-quality issues not explicitly required in CLAUDE.md or upstream artifacts
  - Issues called out in CLAUDE.md but explicitly silenced
  - Real issues, but on lines that the user did not modify in this artifact's round
  - **(QRSPI-specific)** Altitude mismatches — a Goals reviewer flagging Plan-level detail, a Design reviewer flagging Implementation-level detail. These are out-of-altitude and dropped.
  - **(QRSPI-specific)** "X is missing" findings where X is in the artifact, just not where the reviewer looked. Verifier checks the full artifact body before scoring high.
  - **(QRSPI-specific)** Findings that contradict captured user decisions in `feedback/*.md`. These should be tagged `change_type: intent` by the reviewer (per the secondary-escalation rule in `skills/reviewer-protocol/SKILL.md`); if a finding cites `feedback/*.md` and the citation is consistent with that file, the finding is real and scores high.
- **Input contract** — the agent's prompt parameters:
  - `<finding_file_path>` — absolute path to the per-finding file under `reviews/{step}/round-NN/`
  - `<artifact_path>` — absolute path to the artifact under review
  - `<diff_file_path>` — absolute path to `reviews/{step}/round-NN.diff` (round 2+ only; empty string on round 1)
  - `<upstream_paths>` — newline-separated list of upstream-artifact and SKILL.md paths the verifier may Read on demand
- **Procedure** —
  1. Read `<finding_file_path>` to get the 5-field finding object and prose body.
  2. Read `<artifact_path>` (and `<diff_file_path>` if non-empty) eagerly.
  3. For each `referenced_files` entry in the finding, Read it.
  4. If any `<upstream_paths>` is cited in the finding's `message` or seems load-bearing for the verdict, Read it. Otherwise skip.
  5. Score using EXACTLY one of the discrete rubric values: `0`, `25`, `50`, `75`, or `100`. Continuous scores are not permitted; the rubric is bucketed.
  6. Compose new file content: original content (preserved byte-identically) + appended `## Verifier` block (`score: <S>`, `reason: <≤1-sentence>`).
  7. Write the new content back to `<finding_file_path>`.
  8. Return exactly: `<finding_id>: <score>` (e.g. `R3-F02: 75`). On failure, return `<finding_id>: VERIFY_FAILED:<reason>`.
- **Disk-write contract reference** — points at `skills/reviewer-protocol/SKILL.md` `## Disk-Write Contract` for the brief-return rationale.

### `skills/reviewer-protocol/SKILL.md` (amendments — replaces existing `## Disk-Write Contract`)

The existing `## Disk-Write Contract` section (today: per-reviewer single-file output, `Written to: reviews/{step}/round-NN-{reviewer-tag}.md` brief-return shape, `Findings: 0` clean-summary line) is REPLACED with the new contract below. This is a deliberate amendment, not an additive section. Downstream consumers of the old single-file shape are migrated in the same wave (see §9 — atomic landing).

The new contract defines:

- **Per-finding output directory:** `reviews/{step}/round-NN/` (created by the dispatcher, not the reviewer). Reviewers `Write` only into this directory.

- **Per-finding filename pattern:** `<reviewer-tag>.finding-F<NN>.md` (zero-padded F##; reviewer-tag ∈ `claude` | `scope-claude` | `codex` | `scope-codex`). Findings number from F01 in emission order.

- **Per-finding file format:**
  - YAML frontmatter carries 4 of the 5 schema fields plus 3 audit fields: `finding_id`, `severity`, `change_type`, `referenced_files`, `artifact`, `round`, `reviewer`.
  - The 5th schema field — `message` — lives in the markdown body below the frontmatter (prose, multi-paragraph allowed). The 5-field schema is preserved; the transport changes (header for the structured fields, body for the free-text field) because YAML is a poor transport for multi-paragraph prose.
  - An optional `## Verifier` block is appended by the verifier subagent. The verifier MUST preserve all preceding content byte-identically when writing back; the orchestrator-side preservation guard (§4) enforces this independent of agent-file body grep.

- **Clean-round sentinel:** when a reviewer's analysis surfaces zero findings, it Writes a single file `reviews/{step}/round-NN/<reviewer-tag>.clean.md` with no body content (just the frontmatter `reviewer: <tag>`, `round: <NN>`, `findings: 0`). This sentinel disambiguates "clean round" from "broken reviewer" at the apply-fix step, and replaces the old `Findings: 0` line in the per-reviewer summary.

- **Reviewer brief-return shape (replaces old four-line return):** the reviewer returns exactly:
  ```
  Step: {step}
  Round: {NN}
  Reviewer: {tag}
  Findings: {N}
  Written to: reviews/{step}/round-NN/
  ```
  where `Findings: 0` denotes a clean round (matched by presence of the `<reviewer-tag>.clean.md` sentinel).

- **Partial-write failure:** if the reviewer fails after writing some per-finding files but before completing emission, it returns a single line `WRITE_FAILED: round-NN/<reviewer-tag>.finding-F<NN>.md (or .clean.md): <reason>` and leaves whatever finding files it already wrote on disk for audit. The dispatcher's apply-fix step treats `WRITE_FAILED:` as a hard abort for that reviewer (does NOT proceed to verifier dispatch on the partial output) and surfaces the failure via the existing pause gate. There is no automatic retry of partial-write failures.

- **Subagent guardrail compatibility note:** the per-finding filename pattern (`<reviewer-tag>.finding-F<NN>.md`) and the clean-marker pattern (`<reviewer-tag>.clean.md`) do not match the Claude Code 2.1.x subagent-write blocklist (`^(REPORT|SUMMARY|FINDINGS|ANALYSIS).*\.md$`), so subagents can `Write` these files directly.

### `skills/using-qrspi/SKILL.md` (Apply-fix protocol revisions)

The current Apply-fix protocol (steps 1–6 at line 518+) is replaced with the verifier-aware sequence below. The Apply-fix protocol revision lands in the SAME commit as the reviewer-protocol amendment and the reviewer-agent-file migrations (see §9 — atomic landing) so main does not break between commits.

1. **List per-finding files and clean markers** for the round: `ls reviews/{step}/round-NN/*.finding-*.md reviews/{step}/round-NN/*.clean.md` (silent capture). The combined list partitions cleanly into "to verify" (finding files) and "audit only" (clean markers). If the directory is empty AND no clean markers exist, fail loud per §4 reviewer-side schema-violation guard.
2. **Verifier-enabled gate:** read `verifier_enabled` from `config.md` (lives in `skills/using-qrspi/SKILL.md`'s Config-File schema). If `false`, skip steps 3–4 (no verifier dispatch, no scoring). Otherwise proceed.
3. **Dispatch one `qrspi-finding-verifier` per finding-file path in parallel.** (Clean markers are NOT dispatched against — they have no findings to score.) Each prompt carries the four input-contract parameters. Main chat receives ~10-token returns per Haiku.
4. **Failure handling:** if any verifier returned `VERIFY_FAILED:`, present the failure menu (§5 below) before assembly. User pick is honored before continuing: option 1 sets `verifier_enabled: false` and falls through to step 5; option 2 re-dispatches the failed verifiers (jump back to step 3); option 3 aborts the protocol.
5. **Bash assembly** of the round's per-finding files (and clean markers, included as zero-finding audit rows) into `reviews/{step}/round-NN-verified.md` (silent stdout). Header injected via `awk` over the score lines (totals: scored/kept/dropped/failed/clean). Verifier-disabled rounds assemble the per-finding files exactly as written by the reviewers (no `## Verifier` blocks present); the dispatcher in step 7 detects the missing blocks via explicit branch ("if `verifier_enabled=false` OR no `## Verifier` present: keep all findings, no scoring") rather than synthesizing a score. The orchestrator-side preserve guard (§4) runs DURING this assembly step: each finding file's pre-`## Verifier` content is checksummed against a snapshot taken before verifier dispatch; mismatch aborts assembly and surfaces a hard failure.
6. **Read** `reviews/{step}/round-NN-verified.md`. This is the only main-chat file Read of the apply-fix phase.
7. **Filter and dispatch.** Partition findings by `change_type` first:
   - `scope` and `intent` findings: bypass the score filter entirely; flow directly to the existing Review-Loop Pause Gate. The verifier never gates these.
   - `style`, `clarity`, and `correctness` findings: filter at score ≥80 (verifier-enabled rounds) or keep-all (verifier-disabled rounds); apply survivors via `Edit` on the artifact.

   The `change_type` enum is the canonical 5-value set fixed in `skills/reviewer-protocol/SKILL.md`: `style`, `clarity`, `correctness`, `scope`, `intent`. Any finding whose YAML frontmatter carries a value outside this enum is treated as a contract violation by the reviewer (loud failure, paused for user review — never silently auto-applied).
8. **Write** `reviews/{step}/round-NN-fixes.md` (main-chat-authored, ≤30 lines) listing what was changed and why.
9. **`/compact`** to shed the verified-file Read content from main-chat transcript.
10. **Per-round commit** covers the artifact, `round-NN/` subdir, `round-NN-verified.md`, and `round-NN-fixes.md`. Same diff-file mechanic as today (line 529+) for round NN+1 reviewers.

The diff-handling protocol (line 527+) is unchanged.

### `skills/using-qrspi/SKILL.md` config-md schema additions

The authoritative `config.md` contract lives in `skills/using-qrspi/SKILL.md` under "Config File" (today at lines 339-375). Add a new `verifier_enabled` field there:
- Type: boolean
- Default: `true`
- Set by: the user's `/qrspi` invocation at run start (defaulted to `true` if not specified) or by a mid-run user pick at the verifier failure menu (option 1 sets to `false`).
- Read by: every Apply-fix protocol invocation across every artifact-level step in the route.
- Validation: missing field → treat as `true` (defaults-on for backward compatibility with pre-#109 runs).
- **Persistence semantics (intentional):** `verifier_enabled` is durable run state, written to `config.md` on disk. Once a user picks option 1 ("proceed without verifier for the rest of this run"), the setting persists across `/compact`, pauses, resume, and re-entry within the same QRSPI run directory. A "run" is scoped to the run directory under `docs/qrspi/<date>-<bundle>/` — a fresh run directory starts with `verifier_enabled: true` again. This preserves the user's mental model (one opt-out decision lasts for the rest of the work in front of them) and avoids the alternative ephemeral-state plumbing (which would require threading the choice through every resume path).

This follows the existing precedent for mid-run config mutation (`review_mode` and `review_depth` are written by Implement at phase start).

### `scripts/codex-finding-splitter.sh` (new) and Codex source-of-truth contract

**Codex source-of-truth decision (load-bearing):** post-#109, the Codex stdout stream — captured by `scripts/codex-companion-bg.sh await` — is the canonical artifact for findings. The legacy `output:` path-arg pattern in some Codex prompts (where the reviewer prompt asked Codex to also write to a path) is retired in the same commit wave (§9). Codex prompts in every dispatching skill are amended to instruct Codex to emit findings ONLY to stdout, with a `<<<FINDING-BOUNDARY>>>` delimiter on its own line BEFORE each finding (including the first). Reviewers no longer dual-write.

Today's flow:
- `scripts/codex-companion-bg.sh await --artifact-dir <ABS_DIR> <jobId>` redirects Codex stdout to `reviews/{step}/round-NN-codex.md` (single multi-finding file). Non-zero `await` exit codes (10 = ceiling, 11 = job-not-found, 12 = audit-fail, 13 = hard error, 14 = malformed JSON) cause main chat to write an explicit `round-NN-codex.crash.md` audit note today via the existing crash-note path.

New flow (post-#109):

- After `await` returns 0 (success), main chat invokes `scripts/codex-finding-splitter.sh <codex-stdout-path> <round-subdir> <reviewer-tag>` which:
  - Splits the stdout file on `<<<FINDING-BOUNDARY>>>` lines.
  - Writes each segment to `<round-subdir>/<reviewer-tag>.finding-F<NN>.md` (e.g. `codex.finding-F01.md` for artifact-Codex, `scope-codex.finding-F01.md` for scope-Codex).
  - Each segment must conform to the per-finding file format from `reviewer-protocol/SKILL.md` (Codex prompt enforces YAML frontmatter + body shape).
  - **Zero findings (Codex emits the literal sentinel `NO_FINDINGS` on stdout, no `<<<FINDING-BOUNDARY>>>` markers):** writes a single `<round-subdir>/<reviewer-tag>.clean.md` clean marker and exits 0. This is the codex equivalent of the per-reviewer clean sentinel.
  - **Missing-delimiter fallback (Codex emitted prose without delimiters AND without the `NO_FINDINGS` sentinel):** writes the entire stream to `<reviewer-tag>.finding-F00.md` as a single coarse finding with synthetic frontmatter (`finding_id: R{NN}-F00`, `severity: high`, `change_type: clarity`, `referenced_files: []`) and emits a stderr warning. Verifier still scores it (likely low) and the audit captures the malformed Codex output. Loop continues.
  - **Empty input (Codex stdout was empty):** writes a `<reviewer-tag>.clean.md` with a `## Splitter Note` body indicating empty stdout (treated as clean for apply-fix purposes; flagged in the totals header for human review).
- On non-zero `await` exit code (10/11/12/13/14): main chat does NOT invoke the splitter. It writes a `<round-subdir>/<reviewer-tag>.crash.md` audit file directly (carrying the existing crash-note content) and short-circuits the reviewer's contribution to this round (no findings, no clean marker, no verifier dispatch for this reviewer). The apply-fix step's clean-vs-broken disambiguation rule treats `<reviewer-tag>.crash.md` as a hard reviewer failure and pauses the round via the existing pause gate. (This means crash notes are NEVER fed to the splitter and never become fake findings.)
- **Multi-template Codex sites** (`skills/integrate/SKILL.md`, `skills/test/SKILL.md` — multiple Codex dispatches per round, each with a `<template>` suffix): the splitter is invoked once per template completion, with the per-template reviewer-tag (`codex-<template>`, `scope-codex-<template>`). The per-template tags are recorded in the reviewer-protocol contract.
- Splitter is idempotent (re-running on the same input produces the same output files).

The single-file Codex stdout dump (`round-NN-codex.md`, or per-template equivalents) is retained on disk as raw input for the splitter and as audit-trail compatibility surface for pre-#109 inspectors, but is NOT read by main chat.

### Reviewer agent files (modifications — artifact-level scope only for #109)

Per the §1 scope statement, this issue migrates ONLY the artifact-level reviewer agent files used by the Apply-fix protocol in `using-qrspi/SKILL.md`. The per-task implementation reviewers (used by the Implement loop), the implement-gate reviewer (used by Implement's batch gate), and the integration/security-integration reviewers (used by the Integrate loop) keep their current single-file emission shape under #109; their migration to per-finding emission is deferred to the follow-up issue (§8).

The change is mechanical and per-agent: locate the procedure step that today instructs `Write` to `reviews/{step}/round-NN-{reviewer}.md` and replace it with the per-finding emission contract per `reviewer-protocol/SKILL.md`:

- **Old (today):** "Write findings to `reviews/{step}/round-NN-{reviewer}.md`" (single multi-finding file).
- **New (post-#109):** "For each finding emitted, Write a per-finding file to `reviews/{step}/round-NN/<reviewer-tag>.finding-F<NN>.md` per the Per-Finding File Contract in `reviewer-protocol/SKILL.md`. Findings are zero-padded F01, F02, … in emission order. If zero findings, Write a single `<reviewer-tag>.clean.md` clean marker. The reviewer's brief-return summary follows the new five-line shape (Step / Round / Reviewer / Findings / Written-to-directory)."

**Affected files for #109 (16 total; enumerated by family):**
- 9 artifact-quality reviewers — `qrspi-{goals,questions,research,design,phasing,structure,plan,parallelize,replan}-reviewer.md`
- 7 scope-reviewers — `qrspi-{goals,design,structure,phasing,plan,parallelize,replan}-scope-reviewer.md`

**Files NOT modified by #109 (deferred to follow-up):** plan-artifact reviewers (5: `qrspi-plan-{spec,security,silent-failure-hunter,test-coverage,goal-traceability}-reviewer.md`), per-task implementation reviewers (8: `qrspi-{code-quality,security,silent-failure-hunter,test-coverage,goal-traceability,type-design-analyzer,code-simplifier,spec-reviewer}.md`), implement-gate reviewer (1: `qrspi-implement-gate-reviewer.md`), security-integration reviewer (1: `qrspi-security-integration-reviewer.md`), integration-quality reviewer (1: `qrspi-integration-reviewer.md`). These 16 reviewers continue emitting per-reviewer single files. The reviewer-protocol amendment carves out a "legacy single-file emission (deprecated, in-flight migration)" addendum that documents the dual contract during the migration window.

Worker agent files (implementer, test-writer, research-specialist, research-collator, replan-analyzer) are unaffected in any phase — they don't emit findings.

The Codex reviewer prompt in artifact-level Codex-dispatching skills (`skills/{goals,questions,research,design,phasing,structure,plan,parallelize,replan}/SKILL.md`) is amended to inject the per-finding-file format requirement, the `NO_FINDINGS` clean sentinel, and the `<<<FINDING-BOUNDARY>>>` delimiter instruction. Non-artifact-level Codex-dispatching skills (`skills/{implement,integrate,test}/SKILL.md`) keep their existing Codex prompts under #109.

## §3 Data flow

**Round NN (post-#109, artifact-level review only):**

```
Reviewers (Sonnet/Codex)             Main chat (orchestrator)            Haiku verifiers
─────────────────────────────────    ────────────────────────────────    ─────────────────────
1. Reviewer subagents launched in
   parallel (existing dispatch)
2. Each reviewer writes per-finding
   files into reviews/{step}/round-NN/
   subdir, OR a <reviewer-tag>.clean.md
   sentinel if zero findings, OR a
   crash file if reviewer/await failed.
   Returns the new five-line brief
   (Step/Round/Reviewer/Findings/
   Written-to-directory)             ──> 3. Receives ~30-token returns per
                                       reviewer; never reads finding text
                                    4. Pre-dispatch snapshot: for each
                                       *.finding-*.md, compute checksum
                                       of the pre-`## Verifier` content
                                       (defense for §4 preserve-guard).
                                    5. Reads config.md verifier_enabled.
                                       If false: jump to step 11 with all
                                       findings kept (no scoring, no
                                       synthetic scores).
                                    6. Bash: lists *.finding-*.md +
                                       *.clean.md + *.crash.md silently.
                                       Empty-list-and-no-clean-and-no-
                                       crash → fail loud (§4 schema-
                                       violation guard).
                                    7. Dispatches one Haiku verifier per
                                       finding-file path in parallel
                                       (clean markers and crash files
                                       are NOT scored)              ──> 8. Each Haiku Reads its file +
                                                                              artifact + lazy-Reads upstreams
                                                                              + lazy-Reads referenced_files
                                                                          9. Scores against rubric (discrete
                                                                              0/25/50/75/100), Writes back to
                                                                              same path with ## Verifier block
                                                                              appended (preserves preceding
                                                                              content byte-identically)
                                                                         10. Returns "F##: <score>" or
                                                                              "F##: VERIFY_FAILED:<reason>"
                                   11. Aggregates returns. If any
                                       VERIFY_FAILED, presents §5 menu
                                       BEFORE assembly. User pick:
                                       (1) sets verifier_enabled=false
                                           and falls through to step 12;
                                       (2) re-dispatches failed verifiers
                                           (jump back to step 7);
                                       (3) aborts the protocol.
                                   12. Bash assembly:
                                       cat reviews/{step}/round-NN/
                                       *.finding-*.md *.clean.md
                                       *.crash.md > round-NN-verified.md
                                       (with awk-injected totals header
                                       carrying scored/kept/dropped/
                                       failed/clean/crashed counts).
                                       Preserve-guard: re-checksum each
                                       finding file's pre-`## Verifier`
                                       content vs step-4 snapshot;
                                       mismatch → hard abort.
                                   13. Reads round-NN-verified.md ONCE.
                                   14. Partitions by change_type:
                                       - scope/intent → pause gate
                                         (NEVER score-filtered)
                                       - style/clarity/correctness:
                                         filter at score ≥80 (or all-
                                         kept if verifier_enabled=false
                                         OR `## Verifier` block missing).
                                         Survivors → auto-apply via Edit.
                                       Crash files → pause gate
                                       (reviewer-failure pause path).
                                   15. Writes round-NN-fixes.md.
                                       /compact. Per-round commit covers
                                       round-NN/ subdir, verified.md, fixes.md.
```

**Per-finding file format:**

```markdown
---
finding_id: R3-F02
severity: high
change_type: correctness
referenced_files: [skills/design/SKILL.md]
artifact: design
round: 3
reviewer: claude
---

{message body — reviewer's prose explanation; this IS the 5th schema field (`message`), transported in the body rather than the YAML frontmatter to avoid awkward YAML quoting of multi-paragraph prose; multi-paragraph allowed}

## Verifier
score: 75
reason: confirmed — cited file does not handle the concurrency case under multi-writer pressure
```

The `## Verifier` block is absent before the verifier runs and present after. The dispatcher in step 14 treats absence of the `## Verifier` block as "keep this finding without scoring" via an explicit branch — no synthetic score is materialized. This handles three cases uniformly: `verifier_enabled=false` (all findings kept, no scoring), a verifier that silently failed without returning `VERIFY_FAILED:` (kept under loud-failure-by-default), and pre-#109 audit-trail interop (a future inspector reading these files sees an explicit absent-Verifier signal rather than a synthetic 80).

**Clean-marker file format:**

```markdown
---
reviewer: claude
round: 3
findings: 0
---
```

No body content. The clean marker is the audit signal that a reviewer ran and surfaced zero findings; its absence (combined with absence of any `*.finding-*.md` and `*.crash.md` from a reviewer that the dispatcher expected to run) is the schema-violation signal that a reviewer broke its emission contract.

## §4 Error handling

**Per-finding verifier failure** (Haiku returns `F##: VERIFY_FAILED:{reason}`): collected with all other returns. After full aggregation, present §5 menu before assembly proceeds.

**Wholesale verifier outage** (all N Haikus fail): same menu, same options, no special-casing.

**Reviewer-side schema-violation guard:** if main chat's step 6 `ls` finds zero `*.finding-*.md` files AND zero `<reviewer-tag>.clean.md` markers AND zero `<reviewer-tag>.crash.md` files for a reviewer the dispatcher expected to run, OR finds a legacy per-reviewer single-file (e.g. `round-NN-claude.md` for a reviewer that should be on the post-#109 contract), main chat fails loud with explicit "reviewer X did not emit the post-#109 per-finding shape for round NN — agent file may be out of date" message. No silent fallback. This catches reviewer-agent-file regressions in the per-finding emission contract during the migration window AND after.

**Codex splitter failure modes:**
- `NO_FINDINGS` sentinel emitted: clean marker written, no findings.
- Missing-delimiter input (no boundary markers AND no `NO_FINDINGS` sentinel): writes the entire Codex stream to `<reviewer-tag>.finding-F00.md` as a single coarse high-severity finding with synthetic frontmatter; verifier still scores it; stderr warning surfaced.
- Empty input: writes a clean marker with a `## Splitter Note` body indicating empty stdout (treated as clean for dispatch but flagged in totals header for human review).
- `await` non-zero exit (10/11/12/13/14): splitter NOT invoked; main chat writes `<reviewer-tag>.crash.md` directly; dispatch step routes the round to the pause gate via the reviewer-failure path.

**Verifier preserves preceding content (orchestrator-side enforcement):** the verifier's Write-back step is contractually required to preserve all preceding file content byte-identically and append only the `## Verifier` block. The agent-file body cites this requirement (and the §7 unit test asserts the citation is present), but agent-file grep alone cannot enforce runtime behavior. The orchestrator-side preserve guard (Apply-fix step 4 + step 12) is the authoritative enforcement: main chat checksums each finding file's pre-dispatch content (everything up to the would-be `## Verifier` boundary, which today is end-of-file before verifier runs), then re-checksums after verifier dispatch by truncating each post-verify file at the first `## Verifier` heading and comparing. Mismatch aborts assembly with a hard failure that surfaces the offending file path; the round pauses for user review (no silent corruption of the audit trail). This guard runs unconditionally in verifier-enabled rounds; verifier-disabled rounds skip it (no verifier ran, nothing to checksum against).

## §5 User-facing failure menu

When any per-finding verifier in the round returns `VERIFY_FAILED:`, main chat presents:

```
The finding verifier failed for {N} finding(s). How should we proceed?

1. Proceed without verifier for the rest of this run
   — applies all surviving findings as-is; sets verifier_enabled: false
     in config.md; no further verifier prompts this run.
2. Try again — re-dispatch the failed verifiers.
3. Stop — abort the loop and surface to user.
```

No default. Main chat waits for explicit pick.

A always-on footer reminds: "If Haiku is repeatedly unavailable, option 1 is the recommended escape." (Replaces the prior 3-retry counter, which would have required cross-round state plumbing for marginal value — see §8.)

Option 1 mutates `config.md` to set `verifier_enabled: false` and writes a one-line `reviews/{step}/round-NN-verifier-disabled.md` audit note (timestamp, reason, finding count at disable). Subsequent rounds across the rest of the run skip verifier dispatch.

Option 3 follows the existing autonomous-loop abort path: writes `reviews/{step}/round-NN-aborted.md` with the failure context and surfaces to the user via the standard pause-gate UI.

## §6 Cost discipline

**Main-chat context delta vs status quo (no verifier):**
- Status quo: main chat reads per-reviewer files in apply-fix step 1 (~3–5K tokens). `/compact`-shed after fix-apply.
- Post-#109: main chat reads `round-NN-verified.md` exactly once (~3–5K tokens, includes scores). Per-reviewer files are not read by main chat at all.
- Net delta: ~N × 10 tokens (verifier brief returns at step 9). At typical N=8, ~80 tokens. Functionally a wash.

**Total Haiku token spend per round:** N × (artifact + finding + lazy-Reads). At N=8 with a 5K artifact and ~500-token findings: ~50K Haiku-billed tokens per round. At Haiku 4.5 input rates (~$0.80/MTok), $0.04 per round. Cost is negligible relative to the Sonnet review pass it gates.

**Wallclock:** N parallel Haikus complete in ~Haiku-call latency (~3–5 sec wallclock at Haiku speeds). Sequential per-finding scoring would be N× that. Parallel wins meaningfully on UX.

## §7 Tests

Added to `tests/unit/`:

1. **`test-verifier-agent-file.bats`** — `agents/qrspi-finding-verifier.md` exists; frontmatter has `model: haiku`, `tools: [Read, Write]`, name `qrspi-finding-verifier`; body cites the rubric verbatim (greps for the 0/25/50/75/100 grade definitions and asserts the rubric is described as "discrete" / "exactly one of"); body cites the false-positive examples list; body specifies the input-contract parameter names and the procedure step ordering; body asserts the preserve-preceding-content requirement is documented.

2. **`test-per-finding-file-emission.bats`** — every reviewer agent file under `agents/qrspi-*reviewer*.md` IN THE #109 SCOPE (the 16 artifact-level reviewers enumerated in §2) has body language instructing per-finding emission with the canonical `<reviewer-tag>.finding-F<NN>.md` filename pattern AND the `<reviewer-tag>.clean.md` clean-sentinel pattern; the same files do NOT emit a single multi-finding file (greps for legacy `round-NN-{reviewer}.md` writes and asserts they are absent). The 16 deferred reviewers (per-task implementation, plan-artifact, implement-gate, security-integration, integration-quality) are explicitly skipped by this test with a comment citing the deferred follow-up issue.

3. **`test-codex-splitter.bats`** — `scripts/codex-finding-splitter.sh` exists, is executable, handles boundary-delimited input (multi-finding split with per-template tag flowing through), `NO_FINDINGS`-sentinel input (writes clean marker), missing-delimiter fallback (single F00 file + stderr warning + synthetic frontmatter), empty input (clean marker with `## Splitter Note`), idempotency (re-run produces same output). Also asserts the splitter is NOT invoked when `await` returns non-zero (covered via the dispatch-site test #4).

4. **`test-verifier-dispatch-contract.bats`** — `skills/using-qrspi/SKILL.md` Apply-fix protocol body references the verifier-enabled gate, the pre-dispatch checksum snapshot, the parallel-verifier dispatch step, the Bash assembly step (with preserve-guard re-checksum), the `change_type`-partition rule (scope/intent always pause; style/clarity/correctness score-filtered), and the per-round commit covering `round-NN/` subdir — all in the documented order. Also asserts the protocol does NOT instruct main chat to read per-reviewer single files for #109-scope artifacts. Also asserts that `await` non-zero exit codes route to the crash-file path, not the splitter.

5. **`test-verifier-failure-menu.bats`** — main-chat-authored protocol body (in `using-qrspi/SKILL.md`) describes the §5 menu with the three exact option strings; no default option; option 1 mutates `config.md` `verifier_enabled: false` and writes the audit note path; the always-on footer about repeated unavailability is present.

6. **`test-verified-file-shape.bats`** — `round-NN-verified.md` is the assembly of `*.finding-*.md` + `*.clean.md` + `*.crash.md` with a totals-header injected by `awk` (asserts the header field set: `total_scored`, `kept`, `dropped`, `failed`, `clean`, `crashed`); the file is the sole apply-fix dispatch Read source; the file format is documented in `reviewer-protocol/SKILL.md`.

7. **`test-config-verifier-enabled-field.bats`** — `verifier_enabled` field is documented in `skills/using-qrspi/SKILL.md`'s Config-File schema (NOT a hypothetical `skills/config/` skill); default is `true` on missing field; the field is read by every artifact-level Apply-fix protocol invocation; the run-scope persistence semantics (durable across `/compact` and resume within the same run directory) are documented; mid-run mutation precedent (`review_mode`/`review_depth`) is cited.

8. **`test-disabled-mode-fallthrough.bats`** — when `verifier_enabled: false`, Apply-fix protocol body skips verifier dispatch but STILL assembles `round-NN-verified.md` from the per-finding files (without `## Verifier` blocks); the dispatch step keeps all findings via the explicit "no `## Verifier` block → keep" branch (NOT a synthetic 80 score); the orchestrator-side preserve guard is skipped on disabled rounds (no verifier ran). Asserts via protocol body language plus a fixture round directory.

9. **`test-change-type-partition.bats`** (NEW) — Apply-fix dispatch protocol body asserts that `scope` and `intent` findings flow to the pause gate REGARDLESS of verifier score (no score-based suppression of user-surfacing); `style`/`clarity`/`correctness` findings are score-filtered at ≥80 in verifier-enabled rounds; the canonical 5-value `change_type` enum (`style|clarity|correctness|scope|intent`) is cited from `skills/reviewer-protocol/SKILL.md`; out-of-enum values trigger loud failure. Includes a fixture verified.md with mixed `change_type`s and asserts the routing comment in the protocol body.

10. **`test-clean-sentinel-and-schema-guard.bats`** (NEW) — `reviewer-protocol/SKILL.md` defines the `<reviewer-tag>.clean.md` sentinel format and the dispatcher's "zero-files-and-no-clean-and-no-crash → fail loud" rule; `using-qrspi/SKILL.md` Apply-fix step 1+6 cites the rule; legacy `round-NN-{reviewer}.md` single-file presence in a #109-scope round is also a loud-failure trigger. Includes negative fixtures (legacy file present, all-three-empty) asserting the failure path.

11. **`test-preserve-guard.bats`** (NEW) — `using-qrspi/SKILL.md` Apply-fix protocol body documents the orchestrator-side preserve guard (pre-dispatch checksum snapshot at step 4; re-checksum at step 12 by truncating each post-verify file at the first `## Verifier` heading); the `qrspi-finding-verifier` agent file body documents the byte-identical-preservation requirement; the guard runs only in verifier-enabled rounds. Includes a fixture where a verifier corrupts the preceding content and asserts the dispatcher's hard-abort path is exercised in the protocol language.

## §8 Out of scope

- **Per-task implementation review verifier integration.** The `skills/implement/SKILL.md` per-task review loop (8 reviewer agents per task) keeps its existing single-file emission and its existing apply/pause flow under #109. Verifier integration there requires a parallel migration of those 8 reviewer agents + the per-task aggregation path at `reviews/tasks/task-NN-review.md`; deferred to a follow-up issue.
- **Integration / security-integration review verifier integration.** The `skills/integrate/SKILL.md` review/fix loop and the `qrspi-security-integration-reviewer` keep their existing flow under #109. Same follow-up.
- **Implement-gate review verifier integration.** The `qrspi-implement-gate-reviewer` (Implement batch gate) keeps its existing flow under #109. Same follow-up.
- **Plan-artifact reviewer verifier integration.** The 5 plan-artifact reviewers (`qrspi-plan-{spec,security,silent-failure-hunter,test-coverage,goal-traceability}-reviewer`) keep their existing flow under #109; only the unified `qrspi-plan-reviewer` (artifact-quality) and `qrspi-plan-scope-reviewer` are migrated. Same follow-up.
- **3-retry counter for the failure menu.** Earlier draft proposed a "tried 3 times — Haiku may be down" hint after 3 consecutive option-2 picks. Implementing this requires either persisting a retry counter in `config.md` or threading it through the orchestrator's transcript memory; both add scope and the always-on footer (§5) covers the user-guidance need.
- **Within-round dedup** (same finding flagged by claude AND codex). Convergent flags are signal, not noise — verifier scores both. Future v0.6+ optimization candidate.
- **Across-round dedup** (same finding re-flagged in round N+1 after surviving round N's drop). Memoization adds a cache invalidation surface (artifact edits, backward loops) that complicates the design beyond "copy first." Future v0.6+ candidate.
- **Per-per-reviewer-file dispatch refinement** (one Haiku per per-reviewer-tag instead of one Haiku per finding). Considered for attention-management at very high finding counts (>15/round); not adopted in #109. Future v0.6+ candidate if stress observed.
- **Verifier model upgrades** (Sonnet verifier, custom rubric per artifact type, continuous scoring). The `model: haiku` + discrete-rubric choice is load-bearing for the cost math and the faithful-copy-of-`/code-review` argument. Any upgrade lands in a separate issue.
- **Verifier-disable-by-default mode.** The default is `verifier_enabled: true`. Per-run opt-out exists via the §5 menu (option 1). A pipeline-wide opt-out via CLI flag at run start is out of scope for #109 — add when the use case appears.

## §9 Migration sequence

The implementation plan (forthcoming in `docs/superpowers/plans/`) sequences as follows. The cutover commits (steps 4 + 5) are the load-bearing atomicity boundary: between them, main is GREEN at every commit. The pre-cutover commits (steps 1–3) add new infrastructure that is not yet wired up; the cutover commits flip reviewer emission and apply-fix consumption together; the post-cutover commits (steps 6–7) extend coverage and validate.

1. **Verifier agent file.** Create `agents/qrspi-finding-verifier.md` with the rubric, false-positive examples, and procedure. Land alone with unit test #1. Not yet referenced by any skill — purely additive.

2. **Codex splitter (script only, no prompt changes yet).** Add `scripts/codex-finding-splitter.sh` and `tests/unit/test-codex-splitter.bats`. The Codex prompts in dispatching skills are NOT changed in this commit (so existing Codex flows still work). The splitter is dead code until step 4 wires it up. Land with test #3.

3. **`config.md` schema update.** Add `verifier_enabled` field (default `true`) to `skills/using-qrspi/SKILL.md` Config-File schema. The field is documented but not yet read by any protocol. Land with test #7.

4. **Atomic cutover commit (the load-bearing one).** This single commit lands together:
   - The amended `## Disk-Write Contract` in `skills/reviewer-protocol/SKILL.md` (per-finding files + clean marker + new brief-return shape + partial-write semantics + the deferred-reviewers legacy-emission addendum).
   - All 16 #109-scope reviewer agent file migrations (per-finding emission + clean sentinel) under `agents/qrspi-{goals,questions,research,design,phasing,structure,plan,parallelize,replan}-reviewer.md` and the 7 scope-reviewer files.
   - The Codex prompt amendments in the 9 artifact-level Codex-dispatching skills (`skills/{goals,questions,research,design,phasing,structure,plan,parallelize,replan}/SKILL.md`) to inject the `<<<FINDING-BOUNDARY>>>` delimiter, the `NO_FINDINGS` sentinel instruction, and to retire the `output:` path-arg.
   - The Apply-fix protocol revision in `skills/using-qrspi/SKILL.md` (verifier-aware sequence with all 10 steps, including the orchestrator-side preserve guard, the change_type partition, and the new clean-vs-broken disambiguation).
   - All `using-qrspi`/`reviewer-protocol` test updates that pin the new contracts (tests #2, #4, #5, #6, #8, #9, #10, #11).

   The commit is large by design — main breaks during the migration window otherwise. Pre-merge validation: run the existing reviewer-test bats locally, run the new bats, and run a smoke (step 6) before pushing.

5. **Failure-menu and run-scope persistence (`config.md` mutation path).** The mutation logic for `verifier_enabled: false` (option 1 of the §5 menu) and the always-on-footer message land here. Includes the audit-note write to `reviews/{step}/round-NN-verifier-disabled.md`. Test #5 covers this. (Could be merged into step 4 if scope allows; kept separate for review-readability.)

6. **Smoke test on a real artifact review.** Run Goals or Questions on a fixture spec to validate end-to-end behavior; capture findings, verifier scores, clean markers, and the verified.md totals header; verify the audit shape on disk; verify both the verifier-enabled and verifier-disabled paths.

7. **Document the deferred follow-up.** Open the follow-up issue covering the 16 deferred reviewers (per-task implementation × 8, plan-artifact × 5, implement-gate × 1, security-integration × 1, integration-quality × 1) plus the corresponding apply-fix flows in `skills/{implement,integrate}/SKILL.md`.

Rollback contract: steps 1–3 are individually revertible. Step 4 must be reverted as a whole (it is the cutover). Step 5 can be reverted independently of step 4 (the menu would just present an option that no longer mutates state cleanly — flag in the rollback note). After step 4 lands, the pre-#109 reviewer-output shape is gone for #109-scope reviewers; deferred reviewers retain their existing shape until the follow-up issue.
