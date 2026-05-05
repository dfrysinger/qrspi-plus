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
  6. Compose new file content: original content (preserved byte-identically) + a single newline + the boundary sentinel `<!-- @@QRSPI-VERIFIER-BOUNDARY@@ -->` on its own line + the `## Verifier` block (`score: <S>`, `reason: <≤1-sentence>`).
  7. Write the new content back to `<finding_file_path>`.
  8. Return exactly: `<finding_id>: <score>` (e.g. `R3-F02: 75`) where `<score>` is one of the discrete bucket values 0/25/50/75/100. If the agent's reasoning would land off-bucket, snap to the NEAREST bucket (e.g. 80 → 75; 60 → 50; 90 → 100). The snap rule is documented in the agent file body so the orchestrator's brief-return parser can rely on always-discrete values. On failure, return `<finding_id>: VERIFY_FAILED:<reason>`.
- **Disk-write contract reference** — points at `skills/reviewer-protocol/SKILL.md` `## Disk-Write Contract` for the brief-return rationale.

### `skills/reviewer-protocol/SKILL.md` (amendments — bifurcated contract during the migration window)

Because `skills/reviewer-protocol/SKILL.md` is preloaded by EVERY reviewer agent (artifact-level + per-task implementation + plan-artifact + integration + implement-gate + security-integration), and #109 migrates only the 16 artifact-level reviewers (§2 "Reviewer agent files"), a wholesale replacement of the existing `## Disk-Write Contract` would give the 16 deferred reviewers contradictory instructions. The amendment below is therefore **bifurcated**: it keeps the current single-file contract intact (renamed `## Legacy Disk-Write Contract (deferred reviewers)`), and adds a new `## Per-Finding Disk-Write Contract (#109 reviewers)` alongside it. The skill body adds an explicit **Reviewer-Tag Routing Table** at the top that lists which reviewer-tag uses which contract; reviewer agent files preload the skill and follow the contract their tag is routed to.

The bifurcation is removed in the follow-up issue (§8) when the remaining 16 reviewers migrate. At that point the legacy section is deleted and the routing table collapses.

The new `## Per-Finding Disk-Write Contract (#109 reviewers)` section defines:

- **Per-finding output directory:** `reviews/{step}/round-NN/` (created by the dispatcher, not the reviewer). Reviewers `Write` only into this directory.

- **Per-finding filename pattern:** `<reviewer-tag>.finding-F<NN>.md` (zero-padded F##; reviewer-tag ∈ `claude` | `scope-claude` | `codex` | `scope-codex`). Findings number from F01 in emission order.

- **Per-finding file format:**
  - YAML frontmatter carries 4 of the 5 schema fields plus 3 audit fields: `finding_id`, `severity`, `change_type`, `referenced_files`, `artifact`, `round`, `reviewer`.
  - The 5th schema field — `message` — lives in the markdown body below the frontmatter (prose, multi-paragraph allowed). The 5-field schema is preserved; the transport changes (header for the structured fields, body for the free-text field) because YAML is a poor transport for multi-paragraph prose.
  - An optional `## Verifier` block is appended by the verifier subagent, prefixed by a unique HTML-comment sentinel `<!-- @@QRSPI-VERIFIER-BOUNDARY@@ -->` on its own line immediately before the `## Verifier` heading. The sentinel is the unambiguous marker for the orchestrator-side preserve guard (§4) — splitting/truncating on the sentinel rather than the heading avoids false matches if a reviewer's `message` body legitimately quotes the literal string `## Verifier`. The verifier MUST preserve all preceding content (everything before the sentinel) byte-identically when writing back; the preserve guard enforces this independent of agent-file body grep.

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

- **Partial-write failure:** if the reviewer fails after writing some per-finding files but before completing emission, it returns a single line `WRITE_FAILED: round-NN/<reviewer-tag>.finding-F<NN>.md (or .clean.md): <reason>`. The dispatcher writes a `<reviewer-tag>.crash.md` file capturing the WRITE_FAILED return text alongside whatever partial finding files were emitted. Round-NN/ subdirs are scoped strictly to round NN — round NN+1 reviewers write into `round-(NN+1)/` so partial files from round NN are audit-only and cannot mislead subsequent rounds' apply-fix steps. The dispatcher's apply-fix step treats the `<reviewer-tag>.crash.md` presence as a reviewer-failure pause path (no verifier dispatch on the partial finding files; round routes to the pause gate). There is no automatic retry of partial-write failures.

- **Subagent guardrail compatibility note:** the per-finding filename pattern (`<reviewer-tag>.finding-F<NN>.md`) and the clean-marker pattern (`<reviewer-tag>.clean.md`) do not match the Claude Code 2.1.x subagent-write blocklist (`^(REPORT|SUMMARY|FINDINGS|ANALYSIS).*\.md$`), so subagents can `Write` these files directly.

The skill body also adds a **Reviewer-Tag Routing Table** at its top with the canonical routing for each reviewer-tag. For #109, the routing is:

```
Per-Finding Disk-Write Contract (#109):
  claude, scope-claude, codex, scope-codex
  (one tag per artifact step; nine artifact steps × four tags = 36 dispatch slots,
  but each round invokes only the four tags for the current step)

Legacy Disk-Write Contract (deferred):
  plan-spec, plan-security, plan-silent-failure-hunter, plan-test-coverage,
  plan-goal-traceability, code-quality, security, silent-failure-hunter,
  test-coverage, goal-traceability, type-design-analyzer, code-simplifier,
  spec-reviewer, implement-gate, security-integration, integration
```

The legacy section content is preserved verbatim from today's reviewer-protocol skill body (single-file `Write` to `reviews/{step}/round-NN-{reviewer-tag}.md`, four-line return, `Findings: 0` clean line, `WRITE_FAILED:` failure return). The follow-up issue migrates the deferred reviewers and removes the legacy section + the routing table.

### `skills/using-qrspi/SKILL.md` (Apply-fix protocol revisions)

The current Apply-fix protocol (steps 1–6 at line 518+) is replaced with the verifier-aware sequence below. The Apply-fix protocol revision lands in the SAME commit as the reviewer-protocol amendment and the reviewer-agent-file migrations (see §9 — atomic landing) so main does not break between commits.

1. **List all per-reviewer outputs** for the round: `ls reviews/{step}/round-NN/*.finding-*.md reviews/{step}/round-NN/*.clean.md reviews/{step}/round-NN/*.crash.md` (silent capture). All three file kinds — finding files, clean markers, crash files — are part of the primary enumeration so a crashed reviewer never trips the schema-violation guard. The combined list partitions into "to verify" (finding files), "audit-only clean" (clean markers), and "audit-only crash" (crash files).
2. **Per-expected-reviewer schema-violation guard:** the dispatching skill (e.g. `skills/goals/SKILL.md`) declares the **expected reviewer-tag set** for the step (today: `claude`, `scope-claude`, `codex`, `scope-codex` for every #109-scope artifact step). For each expected tag, assert that step-1's `ls` produced AT LEAST ONE of (`<tag>.finding-*.md`, `<tag>.clean.md`, `<tag>.crash.md`). Any expected tag with zero matches fails loud with "reviewer X did not emit any output for round NN — agent file may be out of date or dispatch failed silently." Crash precedence is explicit: if a tag has both a crash file and finding files, treat as reviewer failure (route to pause via the crash path; do NOT verifier-dispatch the finding files for that tag).
3. **Verifier-enabled gate:** read `verifier_enabled` from `config.md` (lives in `skills/using-qrspi/SKILL.md`'s Config-File schema). If `false`, skip steps 4–6 (no checksum snapshot, no verifier dispatch, no preserve guard). Jump to step 7 with all findings kept (no scoring).
4. **Pre-dispatch checksum snapshot.** For each `*.finding-*.md` produced by a non-crashed reviewer-tag, compute `sha256sum` of the entire file content (which today, pre-verifier-dispatch, contains no boundary sentinel). Store the snapshot in memory (or a temp file) keyed by file path. The snapshot is the input to the preserve guard at step 6.
5. **Dispatch one `qrspi-finding-verifier` per non-crashed-tag finding-file path in parallel.** (Clean markers and crash files are NOT dispatched against; finding files from a crashed reviewer-tag are NOT dispatched against.) Each prompt carries the four input-contract parameters. Main chat receives ~10-token returns per Haiku.
6. **Failure handling + preserve guard:**
   - **Verifier-failure:** if any verifier returned `VERIFY_FAILED:`, present the failure menu (§5 below) before assembly. User pick is honored before continuing: option 1 sets `verifier_enabled: false` and falls through to step 7; option 2 re-dispatches ONLY the failed verifiers (NOT all verifiers — the un-failed ones already wrote their `## Verifier` blocks; re-dispatching them would invalidate the step-4 snapshot for files already verified); option 3 aborts the protocol.
   - **Preserve guard:** for each finding file from step 4's snapshot, read the post-verify file content, locate the `<!-- @@QRSPI-VERIFIER-BOUNDARY@@ -->` sentinel, take everything before the sentinel (excluding the trailing newline), and `sha256sum` it. Compare to the step-4 snapshot. Mismatch (or missing sentinel on a file the verifier was supposed to score) aborts the protocol with a hard failure surfacing the offending file path. Verifier-disabled rounds skip this guard entirely (verifier didn't run, nothing to compare against).
7. **Bash assembly** of the round's finding files (post-verify) + clean markers + crash files into `reviews/{step}/round-NN-verified.md` (silent stdout). Header injected via `awk` over the score lines (totals: scored/kept/dropped/failed/clean/crashed/empty-codex; the empty-codex row is the surfaced signal for the empty-stdout case from the splitter — non-zero rows here flag for human review). Verifier-disabled rounds assemble the per-finding files exactly as written by the reviewers (no `## Verifier` blocks present); the dispatcher in step 9 detects missing blocks via explicit branch ("if `verifier_enabled=false` OR no `## Verifier` present: keep all findings, no scoring") rather than synthesizing a score.
8. **Read** `reviews/{step}/round-NN-verified.md`. This is the only main-chat file Read of the apply-fix phase.
9. **Filter and dispatch.** Partition findings by `change_type` first:
   - `scope` and `intent` findings: bypass the score filter entirely; flow directly to the existing Review-Loop Pause Gate. The verifier never gates these.
   - `style`, `clarity`, and `correctness` findings: filter at score ≥80 (verifier-enabled rounds) or keep-all (verifier-disabled rounds); apply survivors via `Edit` on the artifact.

   Crash files (`<reviewer-tag>.crash.md`) flow to the pause gate via the reviewer-failure path, regardless of verifier state.

   The `change_type` enum is the canonical 5-value set fixed in `skills/reviewer-protocol/SKILL.md`: `style`, `clarity`, `correctness`, `scope`, `intent`. Any finding whose YAML frontmatter carries a value outside this enum is treated as a contract violation by the reviewer (loud failure, paused for user review — never silently auto-applied).
10. **Write** `reviews/{step}/round-NN-fixes.md` (main-chat-authored, ≤30 lines) listing what was changed and why.
11. **`/compact`** to shed the verified-file Read content from main-chat transcript.
12. **Per-round commit** covers the artifact, `round-NN/` subdir, `round-NN-verified.md`, and `round-NN-fixes.md`. Same diff-file mechanic as today (line 529+) for round NN+1 reviewers.

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
  - **Missing-delimiter fallback (Codex emitted prose without delimiters AND without the `NO_FINDINGS` sentinel):** writes the entire stream to `<round-subdir>/<reviewer-tag>.finding-F00.md` as a single coarse finding with synthetic frontmatter:
    ```
    finding_id: R{NN}-{reviewer-tag}-F00   # tag-prefixed for round-wide uniqueness
    severity: high
    change_type: intent                     # routes to pause gate (NEVER auto-applied)
    referenced_files: []
    ```
    The `change_type: intent` choice is load-bearing: it routes the malformed-Codex finding to the pause gate (so a human triages it) rather than the auto-apply path where the verifier could silently drop it. The tag-prefixed `finding_id` form (e.g. `R3-codex-F00`, `R3-scope-codex-F00`) ensures uniqueness even if multiple Codex reviewers in the same round all hit the fallback. Splitter emits a stderr warning. Verifier still scores it (likely low) and the score is purely advisory — the change_type partition routes it to pause regardless of score.
  - **Empty input (Codex stdout was empty when the reviewer was expected to emit):** writes a `<round-subdir>/<reviewer-tag>.crash.md` (NOT a clean marker — empty stdout is failure, not success) with a `## Splitter Note` body indicating "Codex stdout was empty; reviewer produced no output." Routes to the pause gate via the reviewer-failure path. (A reviewer that genuinely surfaces no findings is contractually required to emit `NO_FINDINGS` — empty stdout is unambiguous failure.)
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

**Round NN (post-#109, artifact-level review only) — step numbers match Apply-fix protocol §2:**

```
Reviewers (Sonnet/Codex)             Main chat (orchestrator)            Haiku verifiers
─────────────────────────────────    ────────────────────────────────    ─────────────────────
0. Reviewer subagents launched in
   parallel (existing dispatch).
   Each writes per-finding files
   to reviews/{step}/round-NN/, OR
   a <reviewer-tag>.clean.md
   sentinel if zero findings, OR a
   <reviewer-tag>.crash.md if the
   reviewer/await failed. Returns
   the new five-line brief
   (Step/Round/Reviewer/Findings/
   Written-to-directory).            ──> 1. Bash: lists *.finding-*.md +
                                          *.clean.md + *.crash.md silently.
                                       2. Per-expected-tag schema-violation
                                          guard: any expected tag with zero
                                          matches → fail loud. Crash
                                          precedence: tags with crash
                                          files route to pause via the
                                          reviewer-failure path.
                                       3. Reads config.md verifier_enabled.
                                          If false: jump to step 7 with all
                                          findings kept (no scoring; skip
                                          steps 4-6 entirely).
                                       4. Pre-dispatch checksum snapshot:
                                          for each non-crashed-tag
                                          *.finding-*.md, sha256sum the
                                          full file content. Stored in
                                          memory keyed by path.
                                       5. Dispatches one Haiku verifier per
                                          non-crashed-tag finding-file path
                                          in parallel              ──> Each Haiku Reads its file +
                                                                          artifact + lazy-Reads upstreams
                                                                          + lazy-Reads referenced_files.
                                                                          Scores against discrete rubric
                                                                          (0/25/50/75/100; off-bucket
                                                                          snaps to nearest). Writes back
                                                                          to same path with the
                                                                          @@QRSPI-VERIFIER-BOUNDARY@@
                                                                          sentinel + ## Verifier block
                                                                          appended (preceding content
                                                                          byte-identical). Returns
                                                                          "F##: <bucket>" or
                                                                          "F##: VERIFY_FAILED:<reason>".
                                       6. Aggregates returns + preserve
                                          guard.
                                          - VERIFY_FAILED handling: present
                                            §5 menu. Option 1 → set
                                            verifier_enabled=false and
                                            fall through to step 7. Option
                                            2 → re-dispatch ONLY the
                                            failed verifiers (the
                                            un-failed verifier files are
                                            already in their post-verify
                                            shape; re-dispatching them
                                            would invalidate the step-4
                                            snapshot). Option 3 → abort.
                                          - Preserve guard: for each
                                            finding-file with a step-4
                                            snapshot, locate the
                                            @@QRSPI-VERIFIER-BOUNDARY@@
                                            sentinel; take everything
                                            before it; sha256sum and
                                            compare. Mismatch (or missing
                                            sentinel where one was
                                            expected) → hard abort.
                                       7. Bash assembly:
                                          cat reviews/{step}/round-NN/
                                          *.finding-*.md *.clean.md
                                          *.crash.md > round-NN-verified.md
                                          (with awk-injected totals header
                                          carrying scored/kept/dropped/
                                          failed/clean/crashed/empty-codex
                                          counts).
                                       8. Reads round-NN-verified.md ONCE.
                                       9. Partitions by change_type:
                                          - scope/intent → pause gate
                                            (NEVER score-filtered)
                                          - style/clarity/correctness:
                                            filter at score ≥80 (or
                                            all-kept if verifier_enabled
                                            =false OR ## Verifier block
                                            missing). Survivors →
                                            auto-apply via Edit.
                                          Crash files → pause gate
                                          (reviewer-failure path).
                                      10. Writes round-NN-fixes.md.
                                      11. /compact. 12. Per-round commit.
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

**Reviewer-side schema-violation guard (per-expected-tag):** the dispatching skill declares the **expected reviewer-tag set** for the step. Apply-fix step 2 enforces that EACH expected tag produced AT LEAST ONE of `<tag>.finding-*.md`, `<tag>.clean.md`, or `<tag>.crash.md`. Any expected tag with zero matches fails loud with explicit "reviewer <tag> did not emit any output for round NN — agent file may be out of date or dispatch failed silently". Legacy single-file presence (e.g. `round-NN-claude.md` for a reviewer that should be on the post-#109 contract) is also a fail-loud trigger. No silent fallback. This catches reviewer-agent-file regressions in the per-finding emission contract during the migration window AND after.

**Codex splitter failure modes:**
- `NO_FINDINGS` sentinel emitted: clean marker written, no findings.
- Missing-delimiter input (no boundary markers AND no `NO_FINDINGS` sentinel): writes the entire Codex stream to `<reviewer-tag>.finding-F00.md` as a single coarse high-severity finding with tag-prefixed unique `finding_id: R{NN}-<reviewer-tag>-F00` and `change_type: intent` (route-to-pause). Stderr warning surfaced. Verifier scores it but the score is advisory — change_type partitioning routes it to the pause gate regardless.
- Empty input: writes a `<reviewer-tag>.crash.md` (NOT a clean marker — empty Codex stdout is failure, not success) with a `## Splitter Note` body. Routes to the pause gate via the reviewer-failure path.
- `await` non-zero exit (10/11/12/13/14): splitter NOT invoked; main chat writes `<reviewer-tag>.crash.md` directly; dispatch step routes the round to the pause gate via the reviewer-failure path.

**Verifier preserves preceding content (orchestrator-side enforcement):** the verifier's Write-back step is contractually required to preserve all preceding file content byte-identically and append only the boundary sentinel + `## Verifier` block. The agent-file body cites this requirement (and the §7 unit test asserts the citation is present), but agent-file grep alone cannot enforce runtime behavior. The orchestrator-side preserve guard (Apply-fix steps 4 + 6) is the authoritative enforcement, implemented in a new helper script `scripts/verifier-preserve-guard.sh` (so the logic is unit-testable in bats rather than only documented in protocol prose):

- `scripts/verifier-preserve-guard.sh snapshot <finding-file-path>` prints the sha256 of the file content at snapshot time (pre-verifier-dispatch).
- `scripts/verifier-preserve-guard.sh check <finding-file-path> <expected-sha256>` reads the post-verify file, splits at the first occurrence of the unique sentinel `<!-- @@QRSPI-VERIFIER-BOUNDARY@@ -->`, takes everything before the sentinel (excluding the trailing newline), sha256s it, and compares to the expected hash. Exit 0 on match; exit 1 with the offending path on stderr on mismatch; exit 2 if the sentinel is missing on a file that was supposed to be verified.

Apply-fix step 4 invokes `snapshot`; step 6 invokes `check`. Mismatch (or missing sentinel where one was expected) aborts the protocol with a hard failure that surfaces the offending file path. The round pauses for user review (no silent corruption of the audit trail). The guard runs unconditionally in verifier-enabled rounds; verifier-disabled rounds skip it (no verifier ran, nothing to compare against). The unique sentinel form (`@@QRSPI-VERIFIER-BOUNDARY@@` inside an HTML comment) is chosen to be unambiguously distinct from any plausible reviewer-authored `message` body — including a finding that quotes the literal `## Verifier` heading, since the truncation key is the sentinel, not the heading.

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

11. **`test-preserve-guard.bats`** (NEW) — exercises `scripts/verifier-preserve-guard.sh` directly with bats fixtures:
    - `snapshot`/`check` happy path on a file the verifier wrote correctly (sentinel present, prefix unchanged) → exit 0.
    - Corrupted prefix: a fixture where the post-verify file's pre-sentinel content differs from snapshot → exit 1, offending path on stderr.
    - Missing sentinel: a fixture where the verifier wrote `## Verifier` without the boundary sentinel → exit 2.
    - Sentinel-collision robustness: a fixture where the finding's `message` body legitimately contains the literal string `## Verifier` (e.g., a reviewer quoting another verifier output) AND the finding has been correctly verified → exit 0 (sentinel-based truncation must succeed; heading-based truncation would have failed). Asserts the chosen sentinel is unique enough to survive realistic reviewer prose.
    Additionally asserts: `using-qrspi/SKILL.md` Apply-fix protocol body invokes the helper script at the documented steps; the `qrspi-finding-verifier` agent file body documents the byte-identical-preservation requirement and the sentinel form; the guard is documented as skipped on verifier-disabled rounds.

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

4. **Atomic cutover commit (the load-bearing one).** This single commit lands EVERY runtime-behavior change together — including the failure-menu mutation logic. Splitting any of these out would leave main in a contradictory runtime state:
   - The bifurcated reviewer-protocol amendment in `skills/reviewer-protocol/SKILL.md` (Reviewer-Tag Routing Table + new `## Per-Finding Disk-Write Contract` for the 4 #109 tags + renamed `## Legacy Disk-Write Contract` preserved verbatim for the deferred tags).
   - All 16 #109-scope reviewer agent file migrations (per-finding emission + clean sentinel + new brief-return shape) under `agents/qrspi-{goals,questions,research,design,phasing,structure,plan,parallelize,replan}-reviewer.md` and the 7 scope-reviewer files.
   - The Codex prompt amendments in the 9 artifact-level Codex-dispatching skills (`skills/{goals,questions,research,design,phasing,structure,plan,parallelize,replan}/SKILL.md`) to inject the `<<<FINDING-BOUNDARY>>>` delimiter, the `NO_FINDINGS` sentinel instruction, and to retire the `output:` path-arg.
   - `scripts/verifier-preserve-guard.sh` (new helper, with `snapshot` and `check` subcommands per §4).
   - The Apply-fix protocol revision in `skills/using-qrspi/SKILL.md` (verifier-aware sequence with all 12 steps, including the per-expected-tag schema-violation guard, the orchestrator-side preserve guard via the helper script, the change_type partition, and the new clean-vs-broken disambiguation).
   - The §5 failure-menu mutation logic in `skills/using-qrspi/SKILL.md` (option 1 → write `verifier_enabled: false` to `config.md` + write the `reviews/{step}/round-NN-verifier-disabled.md` audit note + the always-on footer text).
   - All `using-qrspi`/`reviewer-protocol`/script test updates that pin the new contracts (tests #2, #4, #5, #6, #8, #9, #10, #11).

   The commit is large by design — every smaller cut would leave main with contradictory runtime behavior between commits (e.g., a step-4-without-step-5 commit would document option 1 in the protocol but the menu-handling logic wouldn't mutate config.md, so the user's pick would silently no-op for the rest of the run). Pre-merge validation: run the existing reviewer-test bats locally, run the new bats, and run a smoke (step 5) before pushing.

5. **Smoke test on a real artifact review.** Run Goals or Questions on a fixture spec to validate end-to-end behavior; capture findings, verifier scores, clean markers, crash files (synthesize one), and the verified.md totals header; verify the audit shape on disk; verify both the verifier-enabled and verifier-disabled paths and an option-1 mid-run mutation.

6. **Document the deferred follow-up.** Open the follow-up issue covering the 16 deferred reviewers (per-task implementation × 8, plan-artifact × 5, implement-gate × 1, security-integration × 1, integration-quality × 1) plus the corresponding apply-fix flows in `skills/{implement,integrate}/SKILL.md`. The follow-up will collapse the bifurcated reviewer-protocol skill back to a single contract.

Rollback contract: steps 1–3 are individually revertible (purely additive). Step 4 must be reverted as a whole (it is the cutover; every behavior change ships together). Steps 5–6 are not code changes (smoke + issue filing). After step 4 lands, the pre-#109 reviewer-output shape is gone for #109-scope reviewers; deferred reviewers retain their existing shape (via the legacy section in reviewer-protocol) until the follow-up issue.
