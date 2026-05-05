# Sonnet→Haiku Confidence Verifier Design

> **Issue:** #109. **Pattern source:** `/code-review` skill (`~/.claude/plugins/cache/claude-plugins-official/code-review/unknown/commands/code-review.md`). **Sequencing:** Tier 2 of the v0.5 plan; depends on #110 (subagents in agent files), which lands first.

**Goal:** Insert a Haiku-class confidence verifier between QRSPI's reviewer subagents and the orchestrator's apply/pause dispatch. Findings that don't survive Haiku scrutiny against a verbatim-copied 0/25/50/75/100 confidence rubric are filtered before they reach the apply or pause path.

**Architecture (one sentence):** Reviewers emit one finding per file; main chat dispatches one Haiku verifier per file in parallel; each Haiku writes its score back into its file; main chat Bash-assembles the per-finding files into a single `round-NN-verified.md` it reads exactly once.

**Tech stack:** Existing QRSPI agent-file infrastructure (per #110), `scripts/codex-companion-bg.sh` async pipeline (extended with a finding-boundary splitter), Bash assembly with no-stdout redirects, `Read`/`Write` tools.

---

## §1 Architecture

A new Haiku-class subagent (`agents/qrspi-finding-verifier.md`, `model: haiku`) scores each finding emitted by upstream reviewers (Claude artifact-quality, Claude scope, Codex artifact-quality, Codex scope, plus the per-task implementation reviewers and the implement-gate reviewer) using the verbatim 0/25/50/75/100 confidence rubric copied from `/code-review` step 5. Main chat dispatches one verifier per finding in parallel from `using-qrspi/SKILL.md`'s Apply-fix protocol; the verifier writes its score back into the per-finding file; main chat Bash-assembles the round's per-finding files into a single `reviews/{step}/round-NN-verified.md` and reads that file exactly once for apply/pause dispatch. The single read is the audit AND the dispatch surface — there is no second read of per-reviewer files.

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
  5. Score 0/25/50/75/100 per the rubric.
  6. Compose new file content: original content + appended `## Verifier` block (`score: <S>`, `reason: <≤1-sentence>`).
  7. Write the new content back to `<finding_file_path>`.
  8. Return exactly: `<finding_id>: <score>` (e.g. `R3-F02: 87`). On failure, return `<finding_id>: VERIFY_FAILED:<reason>`.
- **Disk-write contract reference** — points at `skills/reviewer-protocol/SKILL.md` `## Disk-Write Contract` for the brief-return rationale.

### `skills/reviewer-protocol/SKILL.md` (additions)

A new `## Per-Finding File Contract` section is added, defining:
- The per-finding filename pattern: `reviews/{step}/round-NN/<reviewer-tag>.finding-F<NN>.md` (zero-padded F##; reviewer-tag ∈ `claude` | `scope-claude` | `codex` | `scope-codex` | `task-NN-<reviewer>` | `implement-gate`).
- The per-finding file format: 5-field finding object in YAML frontmatter, `message` body in prose, optional `## Verifier` block appended by the verifier subagent (verifier MUST preserve all preceding content verbatim when writing back).
- The reviewer's emission contract: a reviewer subagent for a round writes N per-finding files (one per finding emitted) plus its existing brief return summary. It does NOT write a per-reviewer multi-finding file. (Legacy single-file emission is replaced.)
- The subagent guardrail compatibility note: the per-finding filename pattern does not match the Claude Code 2.1.x subagent-write blocklist (`^(REPORT|SUMMARY|FINDINGS|ANALYSIS).*\.md$`), so subagents can `Write` these files directly.

### `skills/using-qrspi/SKILL.md` (Apply-fix protocol revisions)

The current Apply-fix protocol (steps 1–6 at line 518+) is replaced with the verifier-aware sequence:

1. **List per-finding files** for the round: `ls reviews/{step}/round-NN/*.finding-*.md` redirected to a path-list capture (no main-chat content).
2. **Verifier-enabled gate:** if `config.md`'s `verifier_enabled` is `false` (set by a prior round's user pick), skip steps 3–4. Otherwise proceed.
3. **Dispatch one `qrspi-finding-verifier` per per-finding-file path in parallel.** Each prompt carries the four input-contract parameters. Main chat receives ~10-token returns per Haiku.
4. **Failure handling:** if any verifier returned `VERIFY_FAILED:`, present the failure menu (§5 below) before assembly. User pick is honored before continuing: option 1 sets `verifier_enabled: false` and falls through to step 5; option 2 re-dispatches the failed verifiers (jump back to step 3); option 3 aborts the protocol.
5. **Bash assembly** of the round's per-finding files into `reviews/{step}/round-NN-verified.md` (silent stdout). Header injected via `awk` over the score lines (totals: scored/kept/dropped/failed). Verifier-disabled rounds assemble per-finding files without `## Verifier` blocks; the dispatcher in step 7 treats those as `score: 80` per §3.
6. **Read** `reviews/{step}/round-NN-verified.md`. This is the only main-chat file Read of the apply-fix phase.
7. **Filter** at score ≥80 (verifier-disabled rounds skip the score check; all findings are kept). Apply auto-apply findings via `Edit` on the artifact. For paused findings, follow the existing Review-Loop Pause Gate.
8. **Write** `reviews/{step}/round-NN-fixes.md` (main-chat-authored, ≤30 lines) listing what was changed and why.
9. **`/compact`** to shed the verified-file Read content from main-chat transcript.
10. **Per-round commit** covers the artifact, `round-NN/` subdir, `round-NN-verified.md`, and `round-NN-fixes.md`. Same diff-file mechanic as today (line 529+) for round NN+1 reviewers.

The diff-handling protocol (line 527+) is unchanged.

### `skills/{config}/SKILL.md` config-md schema additions

Add a new `verifier_enabled` field to `config.md`:
- Type: boolean
- Default: `true`
- Set by: the user's `/qrspi` invocation at run start (defaulted to `true` if not specified) or by a mid-run user pick at the verifier failure menu (option 1 sets to `false`).
- Read by: every Apply-fix protocol invocation across every step in the route.
- Validation: missing field → treat as `true` (defaults-on for backward compatibility with pre-#109 runs).

This follows the existing precedent for mid-run config mutation (`review_mode` and `review_depth` are written by Implement at phase start).

### `scripts/codex-finding-splitter.sh` (new)

Bash post-processor for the Codex async pipeline. Today's flow:
- `scripts/codex-companion-bg.sh await --artifact-dir <ABS_DIR> <jobId>` redirects Codex stdout to `reviews/{step}/round-NN-codex.md` (single multi-finding file).

New flow (post-#109):
- The Codex prompt (in every Codex-dispatching skill) is amended to instruct Codex to emit a `<<<FINDING-BOUNDARY>>>` delimiter on its own line between findings.
- After `await` returns, main chat invokes `scripts/codex-finding-splitter.sh <codex-stdout-path> <round-subdir>` which:
  - Splits the stdout file on `<<<FINDING-BOUNDARY>>>` lines.
  - Writes each segment to `reviews/{step}/round-NN/codex.finding-F<NN>.md` (or `scope-codex.finding-F<NN>.md` for scope-Codex).
  - Each segment must conform to the per-finding file format from `reviewer-protocol/SKILL.md` (Codex prompt enforces this).
  - On missing-delimiter input (Codex emitted findings without delimiters): writes the entire stream to `codex.finding-F00.md` as a single coarse finding and emits a stderr warning. Verifier still scores it (likely low) and the audit shows the malformed Codex output. Loop continues.
  - On empty input (zero findings): writes nothing, exits 0.
- Splitter is idempotent (re-running on the same input produces the same output files).

The single-file Codex artifact `round-NN-codex.md` is retained on disk as raw input for the splitter, but is NOT read by main chat. (Audit-trail compatibility with pre-#109 runs.)

### Reviewer agent files (modifications)

Every reviewer agent file under `agents/qrspi-*.md` (excluding the 5 worker agents — implementer, test-writer, research-specialist, research-collator, replan-analyzer) is updated to emit per-finding files instead of a single per-reviewer file. The change is mechanical and per-agent: locate the procedure step that today instructs `Write` to `reviews/{step}/round-NN-{reviewer}.md` and replace it with the per-finding emission contract:

- **Old (today):** "Write findings to `reviews/{step}/round-NN-{reviewer}.md`" (single multi-finding file).
- **New (post-#109):** "For each finding emitted, Write a per-finding file to `reviews/{step}/round-NN/<reviewer-tag>.finding-F<NN>.md` per the Per-Finding File Contract in `reviewer-protocol/SKILL.md`. Findings are zero-padded F01, F02, … in emission order. The reviewer's brief-return summary lists the finding IDs and the round-NN/ directory path."

**Affected files (32 total; enumerated by family for review-coverage planning):**
- 9 artifact-quality reviewers — `qrspi-{goals,questions,research,design,phasing,structure,parallelize,replan,integration}-reviewer.md`
- 7 scope-reviewers — `qrspi-{goals,design,structure,phasing,plan,parallelize,replan}-scope-reviewer.md`
- 1 plan-quality + 5 plan-artifact reviewers — `qrspi-plan-reviewer.md`, `qrspi-plan-{spec,security,silent-failure,test-coverage,goal-traceability}-reviewer.md` (note: silent-failure → `qrspi-plan-silent-failure-hunter.md`)
- 8 per-task implementation reviewers — `qrspi-{code-quality,security,silent-failure-hunter,test-coverage,goal-traceability,type-design-analyzer,code-simplifier,spec-reviewer}.md`
- 1 implement-gate reviewer — `qrspi-implement-gate-reviewer.md`
- 1 security-integration reviewer — `qrspi-security-integration-reviewer.md`

Worker agent files (implementer, test-writer, research-specialist, research-collator, replan-analyzer) are unaffected — they don't emit findings.

The Codex reviewer prompt (in every Codex-dispatching skill, e.g. `skills/goals/SKILL.md`'s Codex dispatch language) is amended to inject the per-finding-file format requirement and the `<<<FINDING-BOUNDARY>>>` delimiter instruction.

## §3 Data flow

**Round NN (post-#109):**

```
Reviewers (Sonnet/Codex)             Main chat (orchestrator)            Haiku verifiers
─────────────────────────────────    ────────────────────────────────    ─────────────────────
1. Reviewer subagents launched in
   parallel (existing dispatch)
2. Each reviewer writes per-finding
   files into reviews/{step}/round-NN/
   subdir; returns brief summary
   listing finding IDs and the
   round-NN/ directory path       ──> 3. Receives ~30-token returns per
                                       reviewer; never reads finding text
                                    4. Bash: ls reviews/{step}/round-NN/
                                       *.finding-*.md captures the path
                                       list silently (no stdout)
                                    5. Reads config.md verifier_enabled.
                                       If false: jump to step 9 with all
                                       findings kept (no scoring).
                                    6. Dispatches one Haiku verifier per
                                       per-finding-file path in parallel ──> 7. Each Haiku Reads its file +
                                                                              artifact + lazy-Reads upstreams
                                                                              + lazy-Reads referenced_files
                                                                           8. Scores against rubric, Writes
                                                                              back to same path with
                                                                              ## Verifier block appended
                                                                           9. Returns "F##: <score>" or
                                                                              "F##: VERIFY_FAILED:<reason>"
                                   10. Aggregates returns. If any
                                       VERIFY_FAILED, presents §5 menu
                                       BEFORE assembly. User pick:
                                       (1) sets verifier_enabled=false
                                           and falls through to step 11;
                                       (2) re-dispatches failed verifiers
                                           (jump back to step 6);
                                       (3) aborts the protocol.
                                   11. Bash assembly:
                                       cat reviews/{step}/round-NN/
                                       *.finding-*.md > round-NN-verified.md
                                       (with awk-injected totals header)
                                   12. Reads round-NN-verified.md ONCE
                                   13. Filters score ≥80 (or all-kept if
                                       verifier_enabled=false).
                                       Dispatches kept findings via
                                       existing apply/pause routes.
                                   14. Writes round-NN-fixes.md.
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

{message body — reviewer's prose explanation, multi-paragraph allowed}

## Verifier
score: 87
reason: confirmed — cited file does not handle the concurrency case under multi-writer pressure
```

The `## Verifier` block is absent before the verifier runs and present after. A per-finding file with no `## Verifier` block when assembled into `round-NN-verified.md` (because verifier_enabled=false or step 5 short-circuited) is treated by the apply-fix dispatcher as `score: 80, reason: verifier-disabled` (default-keep — the existing pre-#109 behavior).

## §4 Error handling

**Per-finding verifier failure** (Haiku returns `F##: VERIFY_FAILED:{reason}`): collected with all other returns. After full aggregation in step 10, present §5 menu before assembly proceeds.

**Wholesale verifier outage** (all N Haikus fail): same menu, same options, no special-casing.

**Reviewer-side schema-violation guard:** if main chat's step-4 `ls` finds zero per-finding files but a per-reviewer summary file exists (legacy shape), main chat fails loud with explicit "reviewer X did not emit per-finding files for round NN — agent file may be out of date" message. No silent fallback. This catches reviewer-agent-file regressions in the per-finding emission contract.

**Codex splitter failure:** missing-delimiter input writes the entire Codex stream to `codex.finding-F00.md` as a single coarse finding and emits a stderr warning that main chat surfaces. Verifier still scores it. Loop continues. Empty input writes nothing.

**Verifier preserves preceding content:** the verifier's Write-back step is contractually required to preserve all preceding file content verbatim and append only the `## Verifier` block. A verifier that overwrites the finding object is a contract violation, surfaced via a unit test on the verifier agent file body.

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

After 3 consecutive retries on the same round (option 2 chosen 3× in a row with continued failures), the prompt appends a one-liner: "tried 3 times — Haiku may be down."

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

1. **`test-verifier-agent-file.bats`** — `agents/qrspi-finding-verifier.md` exists; frontmatter has `model: haiku`, `tools: [Read, Write]`, name `qrspi-finding-verifier`; body cites the rubric verbatim (greps for the 0/25/50/75/100 grade definitions); body cites the false-positive examples list; body specifies the input-contract parameter names and the procedure step ordering.

2. **`test-per-finding-file-emission.bats`** — every reviewer agent file under `agents/qrspi-*reviewer*.md` (and the implement-gate reviewer) has body language instructing per-finding emission with the canonical `<reviewer-tag>.finding-F<NN>.md` filename pattern; no agent emits a single multi-finding file (greps for legacy `round-NN-{reviewer}.md` writes and asserts they are absent).

3. **`test-codex-splitter.bats`** — `scripts/codex-finding-splitter.sh` exists, is executable, handles boundary-delimited input (multi-finding split), missing-delimiter fallback (single F00 file + stderr warning), empty input (no files written, exit 0), idempotency (re-run produces same output).

4. **`test-verifier-dispatch-contract.bats`** — `skills/using-qrspi/SKILL.md` Apply-fix protocol references the verifier-enabled gate, the parallel-verifier dispatch step, the Bash assembly step in the right order; the protocol does NOT instruct main chat to read per-reviewer files; the per-round commit covers `round-NN/` subdir.

5. **`test-verifier-failure-menu.bats`** — main-chat-authored protocol body (in `using-qrspi/SKILL.md`) describes the §5 menu with the three exact option strings; no default option; option 1 mutates `config.md` `verifier_enabled: false`; option 1 writes the audit note path; the 3-retry message is present.

6. **`test-verified-file-shape.bats`** — `round-NN-verified.md` is the assembly of per-finding files with a totals-header injected by `awk` (asserts the header field set: `total_scored`, `kept`, `dropped`, `failed`); the file is the sole apply-fix dispatch source; the file format is documented in `reviewer-protocol/SKILL.md`.

7. **`test-config-verifier-enabled-field.bats`** — `verifier_enabled` field is documented in the config skill; default is `true` on missing field; the field is read by every Apply-fix protocol invocation; mid-run mutation precedent (review_mode/review_depth) is cited in the docs.

8. **`test-disabled-mode-fallthrough.bats`** — when `verifier_enabled: false`, Apply-fix skips verifier dispatch + assembly and treats every per-finding file as `score: 80, reason: verifier-disabled` for the dispatch decision (asserts via the protocol body language and a fixture).

## §8 Out of scope

- **Within-round dedup** (same finding flagged by claude AND codex). Convergent flags are signal, not noise — verifier scores both. Future v0.6+ optimization candidate.
- **Across-round dedup** (same finding re-flagged in round N+1 after surviving round N's drop). Memoization adds a cache invalidation surface (artifact edits, backward loops) that complicates the design beyond "copy first." Future v0.6+ candidate.
- **Per-per-reviewer-file dispatch refinement** (one Haiku per per-reviewer-tag instead of one Haiku per finding). Considered for attention-management at very high finding counts (>15/round); not adopted in #109. Future v0.6+ candidate if stress observed.
- **Verifier model upgrades** (Sonnet verifier, custom rubric per artifact type). The `model: haiku` choice is load-bearing for the cost math. Any upgrade lands in a separate issue.
- **Verifier-disable-by-default mode.** The default is `verifier_enabled: true`. Per-run opt-out exists via the §5 menu (option 1). A pipeline-wide opt-out via CLI flag at run start is out of scope for #109 — add when the use case appears.

## §9 Migration sequence

The implementation plan (forthcoming in `docs/superpowers/plans/`) sequences as follows:

1. **Verifier agent file.** Create `agents/qrspi-finding-verifier.md` with the rubric, false-positive examples, and procedure. Land alone with unit test #1.
2. **Per-finding file contract.** Add `## Per-Finding File Contract` section to `skills/reviewer-protocol/SKILL.md`. Land alone with a docs-only test asserting the section exists.
3. **Reviewer agent file migrations** in batches of ~5 (mechanical edit — change the Write target from per-reviewer file to per-finding files). Each batch ships with the corresponding test-per-finding-file-emission.bats coverage.
4. **Codex splitter.** Add `scripts/codex-finding-splitter.sh` and update Codex-dispatching skill prompts to inject the boundary delimiter. Land with test #3.
5. **`config.md` schema update.** Add `verifier_enabled` field with default `true`. Land with test #7.
6. **Apply-fix protocol revision in `using-qrspi/SKILL.md`.** Replace the existing protocol with the verifier-aware sequence. Land with tests #4, #5, #6, #8.
7. **Smoke test on a real artifact review.** Run Goals or Questions on a fixture spec to validate end-to-end behavior; capture findings and verifier scores; verify the audit shape on disk.

The migration is reversible at any step before step 6 (the apply-fix protocol revision). After step 6 lands, rollback requires reverting all migrations because main chat no longer reads per-reviewer files.
