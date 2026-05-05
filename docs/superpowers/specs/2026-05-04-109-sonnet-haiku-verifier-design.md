# Sonnet→Haiku Confidence Verifier Design

> **Issue:** #109. **Pattern source:** `/code-review` skill (`~/.claude/plugins/cache/claude-plugins-official/code-review/unknown/commands/code-review.md`). **Sequencing:** Tier 2 of the v0.5 plan; depends on #110 (subagents in agent files), which lands first.

**Goal:** Insert a Haiku-class confidence verifier between QRSPI's artifact-level reviewer subagents and the orchestrator's apply/pause dispatch. Auto-apply findings (`change_type` ∈ `style|clarity|correctness`) that don't survive Haiku scrutiny against a verbatim-copied 0/25/50/75/100 confidence rubric are filtered before they reach the apply path. Pause-class findings (`change_type` ∈ `scope|intent`) are NEVER filtered by score — they always reach the user, regardless of verifier verdict.

**Scope (in/out):** This issue covers ONLY the artifact-level Apply-fix protocol in `skills/using-qrspi/SKILL.md` for the 8 artifact steps `Goals / Questions / Research / Design / Phasing / Structure / Parallelize / Replan`. **Plan is excluded from #109** because the Plan apply-fix loop dispatches the unified plan-quality reviewer + plan-scope reviewer alongside 5 plan-artifact reviewers (qrspi-plan-{spec,security,silent-failure-hunter,test-coverage,goal-traceability}-reviewer); migrating only the unified reviewers would force the Apply-fix protocol to handle a mixed contract within a single round. Plan migrates atomically with its 5 plan-artifact reviewers in the follow-up issue. Per-task implementation review (the loop in `skills/implement/SKILL.md`) and the integration review (in `skills/integrate/SKILL.md`) similarly keep their existing apply/pause flows in this issue; their verifier integration is deferred to the same follow-up issue (see §8).

**Architecture (one sentence):** Reviewers emit one finding per file; main chat dispatches one Haiku verifier per file in parallel; each Haiku writes its score back into its file; main chat Bash-assembles the per-finding files into a single `round-NN-verified.md` it reads exactly once.

**Tech stack:** Existing QRSPI agent-file infrastructure (per #110), `scripts/codex-companion-bg.sh` async pipeline (extended with a finding-boundary splitter), Bash assembly with no-stdout redirects, `Read`/`Write` tools.

---

## §1 Architecture

A new Haiku-class subagent (`agents/qrspi-finding-verifier.md`, `model: haiku`) scores each finding emitted by upstream artifact-level reviewers using the verbatim 0/25/50/75/100 confidence rubric copied from `/code-review` step 5. The cutover commit (§9 step 4) also renames the `reviewer_tag` dispatch parameter for the 8 #109 artifact steps from the today-collapsed `claude`/`codex` (used identically for both quality AND scope reviews) to **role-distinct** values: `quality-claude`, `scope-claude`, `quality-codex`, `scope-codex`. The rename is the load-bearing routing-table-key fix: today the unique disambiguator between quality and scope is the output FILE PATH (`round-NN-claude.md` vs `round-NN-scope-claude.md`), and that path-based disambiguation collapses post-#109 because both quality and scope reviewers now write into the same `round-NN/` directory. Routing keys on the role-distinct tag values; per-finding filenames carry the role-distinct prefix (e.g., `quality-claude.finding-F03.md` vs `scope-claude.finding-F03.md`). Main chat dispatches one verifier per finding in parallel from `using-qrspi/SKILL.md`'s Apply-fix protocol; the verifier writes its score back into the per-finding file; main chat Bash-assembles the round's per-finding files into a single `reviews/{step}/round-NN-verified.md` and reads that file exactly once for apply/pause dispatch. The single read is the audit AND the dispatch surface — there is no second read of per-reviewer files.

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
- **Rubric** — verbatim copy of `/code-review` step 5's 0/25/50/75/100 anchor definitions (a/b/c/d/e), including the verbatim "give this rubric to the agent verbatim" prefix language. The anchors are reference points on the continuous 0–100 scale (per /code-review step 5's "score each issue on a scale from 0–100"), NOT the only valid score values; the verifier is expected to emit off-anchor integers when its confidence falls between anchors.
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
  5. Score on a continuous **0–100** integer scale, using the rubric anchor descriptions (`0`/`25`/`50`/`75`/`100` from /code-review step 5 a–e) as guidance for what each marker value represents. Off-anchor scores (e.g., `80`, `90`, `95`) are valid and expected — the anchors are reference points, not the universe of valid scores. This faithfully matches /code-review's "scale from 0 to 100" contract; the threshold filter at Apply-fix step 9 is `≥80`, which under continuous scoring filters at the documented threshold rather than collapsing to a 100-only gate.
  6. Compose new file content: original content (preserved byte-identically) + a single newline + the boundary sentinel `<!-- @@QRSPI-VERIFIER-BOUNDARY@@ -->` on its own line + the `## Verifier` block (`score: <S>`, `reason: <≤1-sentence>`).
  7. Write the new content back to `<finding_file_path>`.
  8. Return exactly: `<reviewer_tag>.<finding_id>: <score>` (e.g. `quality-claude.R3-F02: 87`, `scope-codex.R5-F00-scope-codex: 25`) where `<reviewer_tag>` is the value read from the per-finding file's YAML `reviewer:` field, and `<score>` is an integer in `0..100`. The reviewer-tag prefix is load-bearing: `finding_id` is unique only per `(round, reviewer_tag)` (per §3 line 442), so `R3-F02` alone could refer to two different per-finding files (one quality-claude, one quality-codex). The orchestrator's brief-return parser accepts any integer in `0..100`; the verifier does NOT snap or quantize. On failure, return `<reviewer_tag>.<finding_id>: VERIFY_FAILED:<reason>`.
- **Disk-write contract reference** — points at `skills/reviewer-protocol/SKILL.md` `## Disk-Write Contract` for the brief-return rationale.

### `skills/reviewer-protocol/SKILL.md` (amendments — bifurcated contract during the migration window)

Because `skills/reviewer-protocol/SKILL.md` is preloaded by EVERY reviewer agent (artifact-level + per-task implementation + plan-step + integration + implement-gate + security-integration), and #109 migrates only the 14 artifact-level reviewers in scope (§2 "Reviewer agent files"), a wholesale replacement of the existing `## Disk-Write Contract` would give the deferred reviewers contradictory instructions. The amendment below is therefore **bifurcated**: it keeps the current single-file contract intact (renamed `## Legacy Disk-Write Contract (deferred reviewers)`), and adds a new `## Per-Finding Disk-Write Contract (#109 reviewers)` alongside it. The skill body adds an explicit **Reviewer-Tag Routing Table** at the top that lists which reviewer-tag uses which contract; reviewer agent files preload the skill and follow the contract their tag is routed to.

The bifurcation is removed in the follow-up issue (§8) when the remaining deferred reviewers migrate. At that point the legacy section is deleted and the routing table collapses.

The new `## Per-Finding Disk-Write Contract (#109 reviewers)` section defines:

- **Per-finding output directory:** `reviews/{step}/round-NN/` (created by the dispatcher, not the reviewer). Reviewers `Write` only into this directory.

- **Trailing-newline mandate (with normalize-then-warn fallback):** every per-finding file emitted by a reviewer SHOULD end with EXACTLY ONE trailing newline character (POSIX-conformant). The reviewer-protocol contract documents this so the orchestrator-side preserve guard can reproduce the snapshot deterministically. **Reviewers are stochastic LLMs**, so the dispatcher's Apply-fix step 2 normalizes any per-finding file with malformed trailing-newline shape (zero, two, or more trailing newlines) to canonical one-trailing-newline form (deterministic byte-level fix: strip all trailing whitespace + append exactly one `\n`) and surfaces a one-line warning to the round audit (`normalized trailing newline on <path>`). The snapshot at step 4 is then taken over the normalized file. Hard-fail at step 2 is reserved for unrecoverable shape errors (missing frontmatter, corrupt YAML, malformed `change_type` enum, missing required fields).

- **Per-finding filename pattern:** `<reviewer-tag>.finding-F<NN>.md` (zero-padded F##; reviewer_tag ∈ `quality-claude` | `scope-claude` | `quality-codex` | `scope-codex`). Findings number from F01 in emission order.

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

The skill body adds a **Reviewer Routing Table** immediately after the frontmatter as a second-level `## Reviewer Routing Table` heading (before any other content; before the intro paragraph). The table routes by `(artifact_step, reviewer_tag)` PAIR using the **role-distinct** `reviewer_tag` values introduced by the cutover (`quality-claude`, `scope-claude`, `quality-codex`, `scope-codex` for the 8 #109 steps). Deferred reviewers retain their existing tag values (`claude`, `codex`, `plan-spec`, etc., as emitted by today's dispatch sites — unchanged for non-#109 steps) so legacy routes remain unambiguous.

The route key is the pair `<artifact_step>:<reviewer_tag>` where `artifact_step` is the QRSPI step name (`goals` | `questions` | `research` | `design` | `phasing` | `structure` | `parallelize` | `replan` for #109; `plan`, `implement`, `integrate`, `test` for deferred) and `reviewer_tag` is the value the dispatcher passes in the dispatch parameters.

```
Per-Finding Disk-Write Contract (#109 — 8 steps × 2-or-4 role-distinct tags = 28 routes):
  goals:quality-claude          goals:scope-claude          goals:quality-codex          goals:scope-codex
  questions:quality-claude                                  questions:quality-codex
  research:quality-claude                                   research:quality-codex
  design:quality-claude         design:scope-claude         design:quality-codex         design:scope-codex
  phasing:quality-claude        phasing:scope-claude        phasing:quality-codex        phasing:scope-codex
  structure:quality-claude      structure:scope-claude      structure:quality-codex      structure:scope-codex
  parallelize:quality-claude    parallelize:scope-claude    parallelize:quality-codex    parallelize:scope-codex
  replan:quality-claude         replan:scope-claude         replan:quality-codex         replan:scope-codex

Legacy Disk-Write Contract (deferred — Plan + Implement + Integrate + Test, today's tags unchanged):
  plan:claude (unified plan-quality), plan:scope-claude, plan:codex, plan:scope-codex,
  plan:plan-spec, plan:plan-security, plan:plan-silent-failure-hunter,
  plan:plan-test-coverage, plan:plan-goal-traceability,
  implement:claude, implement:codex, implement:code-quality, implement:security,
  implement:silent-failure-hunter, implement:test-coverage, implement:goal-traceability,
  implement:type-design-analyzer, implement:code-simplifier, implement:spec-reviewer,
  implement:implement-gate,
  integrate:claude, integrate:codex, integrate:security-integration, integrate:integration,
  test:claude, test:codex
```

**Unrouted-key fail-loud rule:** if a reviewer dispatch produces output keyed to a `(step, tag)` pair NOT present in either contract block, the Apply-fix step-2 schema-violation guard fails loud with "reviewer routing key `<step>:<tag>` is not listed in the Reviewer Routing Table; add it to the appropriate contract block before dispatch." This catches future-PR additions (e.g., a hypothetical `goals:claude-altitude` reviewer) that drift past the routing table.

The legacy section content is preserved verbatim from today's reviewer-protocol skill body (single-file `Write` to `reviews/{step}/round-NN-{reviewer-tag}.md`, four-line return, `Findings: 0` clean line, `WRITE_FAILED:` failure return). The follow-up issue migrates the deferred reviewers and removes the legacy section + the routing table.

**Expected-Reviewer Matrix (in the same skill, immediately following the Routing Table):** the per-step expected-reviewer set, config-aware, using the role-distinct tag values. This is the source of truth for Apply-fix step 2's per-expected-tag schema-violation guard. Format:

```
## Expected-Reviewer Matrix (#109 scope; deferred steps not enumerated)
goals:        quality-claude, scope-claude, quality-codex (if codex_reviews=true), scope-codex (if codex_reviews=true)
questions:    quality-claude, quality-codex (if codex_reviews=true)
research:     quality-claude, quality-codex (if codex_reviews=true)
design:       quality-claude, scope-claude, quality-codex (if codex_reviews=true), scope-codex (if codex_reviews=true)
phasing:      quality-claude, scope-claude, quality-codex (if codex_reviews=true), scope-codex (if codex_reviews=true)
structure:    quality-claude, scope-claude, quality-codex (if codex_reviews=true), scope-codex (if codex_reviews=true)
parallelize:  quality-claude, scope-claude, quality-codex (if codex_reviews=true), scope-codex (if codex_reviews=true)
replan:       quality-claude, scope-claude, quality-codex (if codex_reviews=true), scope-codex (if codex_reviews=true)
```

Apply-fix step 2 reads `config.md.codex_reviews` (existing field) before evaluating expected tags so codex-disabled runs and Questions/Research (which have no scope reviewer today) don't trip the guard. Plan, Implement, Integrate, and Test rounds are not subject to the matrix — they continue using the legacy single-file disk-write contract with the existing pre-#109 Apply-fix protocol path.

### `skills/using-qrspi/SKILL.md` (Apply-fix protocol revisions)

The current Apply-fix protocol (steps 1–6 at line 518+) is replaced with the verifier-aware sequence below. The Apply-fix protocol revision lands in the SAME commit as the reviewer-protocol amendment and the reviewer-agent-file migrations (see §9 — atomic landing) so main does not break between commits.

1. **List all per-reviewer outputs** for the round (nullglob-safe; unmatched globs MUST yield zero matches, not literal patterns or shell errors): the dispatcher invokes a small bash helper that runs `shopt -s nullglob` then enumerates the three patterns, all fully path-qualified to the round subdir:
   ```bash
   shopt -s nullglob
   D="reviews/{step}/round-NN"
   findings=( "$D"/*.finding-*.md )
   cleans=( "$D"/*.clean.md )
   crashes=( "$D"/*.crash.md )
   ```
   All three file kinds — finding files, clean markers, crash files — are part of the primary enumeration so a crashed reviewer never trips the schema-violation guard. An all-clean round (zero findings, all clean markers) and a no-crash round (zero crash files) are both valid; nullglob makes the empty-array case work. The combined list partitions into "to verify" (finding files), "audit-only clean" (clean markers), and "audit-only crash" (crash files).
2. **Per-expected-reviewer schema-violation guard + trailing-newline normalization:** the **Expected-Reviewer Matrix** in `skills/reviewer-protocol/SKILL.md` (defined adjacent to the Reviewer Routing Table — see §2 reviewer-protocol section) is the source of truth for the expected-tag set per artifact step, config-aware. Apply-fix step 2 evaluates the matrix row for the current step against `config.md.codex_reviews` to derive the active expected set, then for each expected tag asserts that step-1's `ls` produced AT LEAST ONE of (`<tag>.finding-*.md`, `<tag>.clean.md`, `<tag>.crash.md`). Any expected tag with zero matches fails loud with "reviewer X did not emit any output for round NN — agent file may be out of date or dispatch failed silently." Step 2 ALSO fails loud if any output file is keyed to a `(step, tag)` route that is unrouted in the Reviewer Routing Table. Crash precedence is explicit: if a tag has both a crash file and finding files, treat as reviewer failure (route to pause via the crash path; do NOT verifier-dispatch the finding files for that tag, and stage them out of the assembly globbing per step 4 below). Step 2 normalizes per-finding files with malformed trailing-newline shape per the trailing-newline-with-normalize-then-warn rule above (warning to round audit, not hard fail). Hard fails are reserved for: missing frontmatter, corrupt YAML, malformed `change_type` enum value, missing required fields, unrouted `(step, tag)` route, expected-tag with zero output files.
3. **Verifier-enabled gate:** read `verifier_enabled` from `config.md` (lives in `skills/using-qrspi/SKILL.md`'s Config-File schema). If `false`, skip steps 4–6 (no checksum snapshot, no verifier dispatch, no preserve guard). Jump to step 7 with all findings kept (no scoring).
4. **Stage out crashed-tag finding files + pre-dispatch checksum snapshot to disk.** For each tag that has BOTH a crash file and finding files, move the tag's finding files to a sibling `reviews/{step}/round-NN/.crash-skipped/` subdir (created on demand). After staging, **re-glob the round directory using the same nullglob-safe pattern arrays from step 1** to produce post-staging arrays — the original step-1 `findings` array is now stale (some entries point at moved paths) and MUST NOT be reused at step 7 assembly:
   ```bash
   shopt -s nullglob
   findings=( "$D"/*.finding-*.md )      # post-staging: excludes files moved into .crash-skipped/
   cleans=( "$D"/*.clean.md )
   crashes=( "$D"/*.crash.md )
   ```
   These post-staging arrays are what step 7 cat's (NOT the step-1 arrays). Staging keeps the audit trail intact (crashed tag's findings are still on disk under `.crash-skipped/`) while ensuring step 7 assembly doesn't pollute `round-NN-verified.md` with unverified findings from a failed reviewer. The `.crash-skipped/` subdir IS committed in the per-round commit (step 12) — it lives inside `reviews/` which is the existing audit-trail tree. Then, for each remaining `*.finding-*.md` (non-crashed-tag), compute `sha256sum` of the entire file content (pre-verifier-dispatch, ending with the mandated single trailing newline, no boundary sentinel). Write the snapshot map to disk at `reviews/{step}/round-NN/.snapshots.txt` (one `<sha256> <relative-path>` line per finding file, `sha256sum`-output format). Disk-backed snapshots survive `/compact` between steps 4 and 6 — the dispatcher can re-read the snapshot file at step 6 even after a long verifier run causes intervening compaction. The `.snapshots.txt` file is also committed in the per-round commit (audit trail of what the dispatcher checksummed; cheap to keep).

**Re-entry semantics:** if Apply-fix step 4 runs again on the same round (option-2 re-dispatch path or post-`/compact` recovery), the existing `.snapshots.txt` is PRESERVED — never truncated. Step 4 reads the existing file and uses its entries as the snapshot for any finding files that already have snapshot lines; only finding files NOT yet present get new entries appended (e.g., on re-dispatch, the failed-verifier files are still pre-verify and their existing snapshots remain valid). The helper script's `snapshot` subcommand is idempotent on already-snapshotted paths. This eliminates the failure mode of a re-entry destroying the original snapshot.

**Audit-trail asymmetry on disabled rounds:** verifier-disabled rounds skip step 4 entirely, so `.snapshots.txt` is absent from those rounds' commits. Future inspectors reading the round commit see this asymmetry as the disambiguator between an enabled-round commit (`.snapshots.txt` present, `## Verifier` blocks in finding files, `verifier_enabled: true` row in totals header) and a disabled-round commit (no `.snapshots.txt`, no `## Verifier` blocks, `verifier_enabled: false` row in totals header). The asymmetry is documented in the README's audit-shape section as part of the cutover commit.
5. **Dispatch one `qrspi-finding-verifier` per non-crashed-tag finding-file path in parallel.** (Clean markers and crash files are NOT dispatched against; finding files from a crashed reviewer-tag are NOT dispatched against.) Each prompt carries the four input-contract parameters. Main chat receives ~10-token returns per Haiku.
6. **Failure handling + preserve guard:**
   - **Verifier-failure:** if any verifier returned `VERIFY_FAILED:`, present the failure menu (§5 below) before assembly. User pick is honored before continuing: option 1 sets `verifier_enabled: false` AND runs the preserve guard against the un-failed-verifier files (those have snapshots and sentinels; option 1 must NOT silently skip the guard for files where verifiers did run and write content), then falls through to step 7; option 2 re-dispatches ONLY the failed verifiers (NOT all verifiers — the un-failed ones already wrote their `## Verifier` blocks; re-dispatching would invalidate the step-4 snapshot for files already verified). Option 2 reuses the step-4 snapshots for the un-failed verifiers (no re-snapshot); the failed verifiers' files are still pre-verify shape so their step-4 snapshots remain valid. There is no retry cap (per §8 — out of scope for #109); if option 2 keeps failing, the user can switch to option 1 or 3. Option 3 aborts the protocol.
   - **Preserve guard:** for each finding file from step 4's snapshot whose verifier did NOT return `VERIFY_FAILED:` (i.e., files the verifier was supposed to mutate), invoke `scripts/verifier-preserve-guard.sh check`. The helper script reads the post-verify file content, splits at the unique boundary sentinel `<!-- @@QRSPI-VERIFIER-BOUNDARY@@ -->`, takes everything before the sentinel, strips EXACTLY ONE trailing newline (the byte the verifier added as a separator between original content and the sentinel; per the verifier procedure step 6, the verifier writes `original-content + \n + sentinel-line + ## Verifier block`), and `sha256sum`s the result. Match to the step-4 snapshot is required. The trailing-newline mandate at the reviewer-protocol level (every per-finding file ends with exactly one newline) means: snapshot bytes = original content ending with `\n`; recovered bytes = (original content ending with `\n`) + (verifier-added `\n`) − one trailing `\n` = original content ending with `\n`. Byte-identical. The helper exits 0 on match (silent), exits 1 with stderr `verifier corrupted prefix on <path>` on mismatch, and exits 2 with stderr `verifier did not write the boundary sentinel on <path>` if the sentinel is missing where one was expected. The dispatcher surfaces the helper's stderr verbatim and aborts the protocol on any non-zero exit. Files where the verifier returned `VERIFY_FAILED:` are pre-verify shape (no sentinel) — the dispatcher knows from the verifier's brief return and skips them in the preserve-guard pass. Files staged into `.crash-skipped/` at step 4 are never input to the helper. Verifier-disabled rounds (where step 3 short-circuited and no verifier ran) skip the preserve guard entirely (no snapshot was taken).
7. **Bash assembly** of the round's finding files (post-verify) + clean markers + crash files into `reviews/{step}/round-NN-verified.md` (silent stdout). The cat operation uses the **post-staging arrays from step 4** (NOT the step-1 arrays — those reference paths that no longer exist for any crashed-tag finding files). Files staged out into `.crash-skipped/` at step 4 are not present in the post-staging arrays. Header injected via `awk` over the score lines (totals: scored/kept/dropped/failed/clean/crashed/empty-codex/crash-skipped; the empty-codex and crash-skipped rows are the surfaced signals for human review). The header also emits a top-line `verifier_enabled: <true|false>` row recording the active mode; verifier-disabled rounds keep the same row schema with `scored=0`, all findings counted under `kept`, `dropped=0`, `failed=0` — the explicit `verifier_enabled: false` row is the disambiguator for future inspectors reading verified.md from a disabled round (so kept-count is interpretable as "all findings passed through" not "score ≥80 survivor"). The dispatcher distinguishes two cases for missing `## Verifier` blocks: (a) verifier-disabled rounds (verifier did not run; no block expected; keep all findings) — the dispatcher takes this branch when `verifier_enabled=false` was the active setting at assembly time; (b) verifier-enabled rounds where a specific finding's verifier returned `VERIFY_FAILED:` — the dispatcher consults the verifier brief returns captured at step 5, sees the failure, and treats the file as kept (no scoring). Case (c) — verifier-enabled, brief returned a score, but no `## Verifier` block present in the file — is impossible because the preserve guard at step 6 would have aborted on missing sentinel. The "missing block → keep" rule applies only to (a) and (b); (c) cannot reach this step.
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
- Validation: this field is the explicit carve-out from the existing `using-qrspi/SKILL.md` "no silent defaults" rule for config fields. The carve-out is RUNTIME (not commit-time): the using-qrspi protocol code added in the cutover commit (§9 step 4) reads `verifier_enabled` from `config.md` on first verifier-aware Apply-fix invocation; if missing, it treats the value as `true`, surfaces a one-line stderr warning once per resume ("config.md verifier_enabled missing — defaulting to true; this carve-out is time-bounded"), AND backfills the field with `verifier_enabled: true` into the live `config.md` so subsequent invocations no longer hit the carve-out. The runtime backfill keeps the rollback semantics clean (revert step 4 → revert the carve-out code → no orphan mutations on user disks; the only persistent disk change is in user-managed config.md files, and only in runs that were resumed). The carve-out is documented in `using-qrspi/SKILL.md`'s no-silent-defaults section ("Exceptions: `verifier_enabled` (#109) — defaults to `true` if missing, with a one-line stderr warning surfaced once per resume; runtime-backfilled on first verifier-aware Apply-fix to make the carve-out time-bounded. There is no commit-time backfill script.").
- **Persistence semantics (intentional):** `verifier_enabled` is durable run state, written to `config.md` on disk. Once a user picks option 1 ("proceed without verifier for the rest of this run"), the setting persists across `/compact`, pauses, resume, and re-entry within the same QRSPI run directory. A "run" is scoped to the run directory under `docs/qrspi/<date>-<bundle>/` — a fresh run directory starts with `verifier_enabled: true` again. This preserves the user's mental model (one opt-out decision lasts for the rest of the work in front of them) and avoids the alternative ephemeral-state plumbing (which would require threading the choice through every resume path).

This follows the existing precedent for mid-run config mutation (`review_mode` and `review_depth` are written by Implement at phase start).

### `scripts/codex-finding-splitter.sh` (new) and Codex source-of-truth contract

**Codex source-of-truth decision (load-bearing):** post-#109, the Codex stdout stream — captured by `scripts/codex-companion-bg.sh await` — is the canonical artifact for findings. The legacy `output:` path-arg pattern in some Codex prompts (where the reviewer prompt asked Codex to also write to a path) is retired in the same commit wave (§9). Codex prompts in every dispatching skill are amended to instruct Codex to emit findings ONLY to stdout, with a `<<<FINDING-BOUNDARY>>>` delimiter on its own line BEFORE each finding (including the first). Reviewers no longer dual-write.

Today's flow:
- `scripts/codex-companion-bg.sh await --artifact-dir <ABS_DIR> <jobId>` redirects Codex stdout to `reviews/{step}/round-NN-codex.md` (single multi-finding file). Non-zero `await` exit codes (10 = ceiling, 11 = job-not-found, 12 = audit-fail, 13 = hard error, 14 = malformed JSON) cause main chat to write an explicit `round-NN-codex.crash.md` audit note today via the existing crash-note path.

New flow (post-#109):

- After `await` returns 0 (success), main chat invokes `scripts/codex-finding-splitter.sh <codex-stdout-path> <round-subdir> <reviewer-tag>` which:
  - Splits the stdout file on `<<<FINDING-BOUNDARY>>>` lines.
  - Writes each segment to `<round-subdir>/<reviewer_tag>.finding-F<NN>.md` (e.g. `quality-codex.finding-F01.md` for artifact-quality-Codex, `scope-codex.finding-F01.md` for scope-Codex).
  - Each segment must conform to the per-finding file format from `reviewer-protocol/SKILL.md` (Codex prompt enforces YAML frontmatter + body shape).
  - **Zero findings (Codex emits the literal sentinel `NO_FINDINGS` on stdout, no `<<<FINDING-BOUNDARY>>>` markers):** writes a single `<round-subdir>/<reviewer-tag>.clean.md` clean marker and exits 0. This is the codex equivalent of the per-reviewer clean sentinel.
  - **Missing-delimiter fallback (Codex emitted prose without delimiters AND without the `NO_FINDINGS` sentinel):** writes the entire stream to `<round-subdir>/<reviewer_tag>.finding-F00.md` as a single coarse finding with FULLY-VALID synthetic frontmatter (all 7 fields per the per-finding contract):
    ```
    ---
    finding_id: R{NN}-F00-{reviewer_tag}   # F-number first, tag-suffixed (matches the permissive schema-guard regex)
    severity: high
    change_type: intent                     # routes to pause gate (NEVER auto-applied)
    referenced_files: []
    artifact: <step>
    round: {NN}
    reviewer: {reviewer_tag}
    ---

    Codex emitted prose without the `<<<FINDING-BOUNDARY>>>` delimiter or the
    `NO_FINDINGS` sentinel. The raw Codex output is preserved below for
    human triage:

    {raw Codex stdout content, verbatim}
    ```
    The `change_type: intent` choice is load-bearing: it routes the malformed-Codex finding to the pause gate (so a human triages it) rather than the auto-apply path where the verifier could silently drop it. The tag-suffixed `finding_id` form (`R{NN}-F00-<reviewer-tag>`, e.g. `R3-F00-quality-codex`, `R3-F00-scope-codex`) ensures uniqueness even if both quality-codex and scope-codex hit the fallback in the same round, and matches the permissive schema-guard regex `^R\d+-F\d+(-[a-z-]+)?$` from §3. The synthetic frontmatter satisfies the schema-violation guard at Apply-fix step 2 (all 7 fields present, change_type in the canonical enum, finding_id matches the per-finding pattern). Splitter emits a stderr warning. Verifier still scores it (likely low) and the score is purely advisory — the change_type partition routes it to pause regardless of score.
  - **Empty input (Codex stdout was empty when the reviewer was expected to emit):** writes a `<round-subdir>/<reviewer-tag>.crash.md` (NOT a clean marker — empty stdout is failure, not success) whose first non-blank line is the structured marker `# @@QRSPI-EMPTY-CODEX-STDOUT@@` (on its own line), followed by a `## Splitter Note` body indicating "Codex stdout was empty; reviewer produced no output." This routes to the pause gate via the reviewer-failure path. The structured marker is what the §2 step 7 totals-header `awk` keys on to count this case as `empty-codex` (rather than the generic `crashed` count): a crash file whose first non-blank line matches `^# @@QRSPI-EMPTY-CODEX-STDOUT@@` is counted as `empty-codex`; all other crash files are counted as `crashed`. (A reviewer that genuinely surfaces no findings is contractually required to emit `NO_FINDINGS` — empty stdout is unambiguous failure.)
- On non-zero `await` exit code (10/11/12/13/14): main chat does NOT invoke the splitter. It writes a `<round-subdir>/<reviewer_tag>.crash.md` audit file directly (carrying the existing crash-note content) and short-circuits the reviewer's contribution to this round (no findings, no clean marker, no verifier dispatch for this reviewer). The apply-fix step's clean-vs-broken disambiguation rule treats `<reviewer_tag>.crash.md` as a hard reviewer failure and pauses the round via the existing pause gate. (Crash notes are NEVER fed to the splitter.)
- **Exit-0 failure-payload classifier (pre-splitter):** the existing `codex-companion-bg.sh` wrapper can exit 0 while emitting failure text on stdout from the `storedJob.rendered` / `job.errorMessage` / `storedJob.errorMessage` extraction paths (links c/d/e in `fetch_result()`'s fallback chain — render.mjs:413, 437, 439). Today those failure-source extractions emit BARE text with no distinguishing prefix (the wrapper's verified contract per `scripts/codex-companion-bg.sh:586-596` and the bats fixtures `Cancelled by user.`, `Stored-only error message.`, `Codex turn ended with failure`); a classifier that grepped for substring markers like `errorMessage:` would either miss real failures (the wrapper does not emit that string) or fire on legitimate review prose that happens to discuss errors. The fix lives **inside the wrapper**: in the cutover commit (§9 step 4), `fetch_result()` is modified to prepend a unique sentinel header line on links (c)/(d)/(e) BEFORE the bare extracted text. The marker shape is:

  ```
  # @@QRSPI-CODEX-FAILURE@@: <source>
  <bare extracted text...>
  ```

  where `<source>` is one of `storedJob.rendered`, `job.errorMessage`, `storedJob.errorMessage`. Links (a) `storedJob.result.rawOutput` and (b) `storedJob.result.codex.stdout` (the success-path review extractions) emit content as-is — no marker. The wrapper's exit code stays 0 in all five fallback paths (no breaking change for non-#109 callers; the marker is a benign decoration that they can ignore or strip). Existing wrapper bats fixtures are updated to assert the marker is emitted on links (c)/(d)/(e) and absent on links (a)/(b).

  Main chat then runs the pre-splitter classifier `scripts/codex-stdout-classify.sh`: if the first non-blank line of `await` exit-0 stdout matches the literal regex `^# @@QRSPI-CODEX-FAILURE@@:`, main chat treats the stdout as a failure payload and writes it to `<reviewer_tag>.crash.md` instead of feeding it to the splitter. The classifier's correctness rests on **wrapper-side determinism**, not on what the model emits: the wrapper prepends the marker EXCLUSIVELY on links (c)/(d)/(e), and links (a) `storedJob.result.rawOutput` / (b) `storedJob.result.codex.stdout` (the success-path extractions that pass model output through unchanged) are unmodified. So if `await` stdout begins with the marker, it MUST have come from a failure source — provided the model itself did not emit the literal marker header as the first line of its review prose. The Codex reviewer prompt template (§2 "Codex prompt template requirements" + §9 step 4) explicitly forbids the model from emitting `# @@QRSPI-CODEX-FAILURE@@:` as a literal string, and the splitter's expected first non-blank line of a successful review is `<<<FINDING-BOUNDARY>>>` (multi-finding) or the literal `NO_FINDINGS` sentinel (zero findings) — neither overlaps with the failure marker. A pathological model that ignored the prompt and emitted the marker header anyway would be caught downstream: the classifier routes to crash (false positive of the failure path, not the success path), and the user sees the crash file and triages it. The classifier and the wrapper modification ship together in the cutover commit (§9 step 4); the standalone classifier-script test that lands in step 2 uses synthetic fixtures (literal marker headers prepended to bare-text bodies) so it can validate the classifier in isolation before the wrapper actually emits the markers. Test #3 gains fixtures for each of the three failure-source markers, the two success-path first-lines (`<<<FINDING-BOUNDARY>>>`, `NO_FINDINGS`), AND a negative fixture asserting that review prose containing the substring `errorMessage:` (without the leading marker header) is NOT classified as failure.
- **Multi-template Codex sites** (`skills/integrate/SKILL.md`, `skills/test/SKILL.md` — multiple Codex dispatches per round, each with a `<template>` suffix): the splitter is invoked once per template completion, with the per-template reviewer-tag (`codex-<template>`, `scope-codex-<template>`). The per-template tags are recorded in the reviewer-protocol contract.
- Splitter is idempotent (re-running on the same input produces the same output files).

The single-file Codex stdout dump (`round-NN-codex.md`, or per-template equivalents) is retained on disk as raw input for the splitter — it is NOT a back-compat surface for pre-#109 inspectors. Post-#109, the file's semantics change: it now holds a delimiter-encoded finding stream (or the `NO_FINDINGS` sentinel), not the legacy review-file format. Existing tooling that read `round-NN-codex.md` directly will see different content shape after cutover; that tooling should be updated to read `reviews/{step}/round-NN-verified.md` (the new dispatch surface) instead. Main chat does not read either file via the Apply-fix protocol after splitter dispatch.

### Reviewer agent files (modifications — artifact-level scope only for #109)

Per the §1 scope statement, this issue migrates ONLY the artifact-level reviewer agent files for the 8 artifact steps. Plan, per-task implementation, integration, and test reviewers keep their current single-file emission shape under #109; their migration is deferred to the follow-up issue (§8).

The change is mechanical and per-agent: locate the procedure step that today instructs `Write` to `reviews/{step}/round-NN-{reviewer}.md` and replace it with the per-finding emission contract per `reviewer-protocol/SKILL.md`:

- **Old (today):** "Write findings to `reviews/{step}/round-NN-{reviewer-or-scope-reviewer}.md`" (single multi-finding file; quality and scope reviewers used the same `reviewer_tag: claude`/`codex` and disambiguated via the output filename).
- **New (post-#109):** the dispatch site passes a `reviewer_tag` parameter with one of the 4 role-distinct values (`quality-claude` | `scope-claude` | `quality-codex` | `scope-codex`). For each finding emitted, the reviewer Writes a per-finding file to `reviews/{step}/round-NN/<reviewer_tag>.finding-F<NN>.md` per the Per-Finding File Contract in `reviewer-protocol/SKILL.md`. Findings are zero-padded F01, F02, … in emission order. If zero findings, Write a single `<reviewer_tag>.clean.md` clean marker. The reviewer's brief-return summary follows the new five-line shape (Step / Round / Reviewer / Findings / Written-to-directory).

**Affected files for #109 (14 reviewer agent files):**
- 8 artifact-quality reviewers — `qrspi-{goals,questions,research,design,phasing,structure,parallelize,replan}-reviewer.md`
- 6 scope-reviewers — `qrspi-{goals,design,phasing,structure,parallelize,replan}-scope-reviewer.md`

(Plan is excluded; questions and research have no scope reviewers, hence 6 scope reviewers not 8.)

**Dispatch-site amendments for #109 (8 dispatching skills):**
`skills/{goals,questions,research,design,phasing,structure,parallelize,replan}/SKILL.md` are amended in the cutover commit to: (a) pass the role-distinct `reviewer_tag` value (`quality-claude`/`scope-claude`/`quality-codex`/`scope-codex`) instead of the today-collapsed `claude`/`codex`; (b) inject the per-finding-file format, the `NO_FINDINGS` sentinel, and the `<<<FINDING-BOUNDARY>>>` delimiter instructions into the Codex reviewer prompt with worked one-finding and zero-finding examples (see "Codex prompt template requirements" below).

**Files NOT modified by #109 (deferred to follow-up):** the 5 plan-artifact reviewers (`qrspi-plan-{spec,security,silent-failure-hunter,test-coverage,goal-traceability}-reviewer.md`), the unified plan-quality reviewer (`qrspi-plan-reviewer.md`), the plan-scope reviewer (`qrspi-plan-scope-reviewer.md`), the 8 per-task implementation reviewers, the implement-gate reviewer, the security-integration reviewer, and the integration-quality reviewer. These 18 reviewers continue emitting per-reviewer single files via the bifurcated reviewer-protocol skill's legacy section. The follow-up issue migrates Plan-step reviewers atomically (so the Plan apply-fix loop never has mixed-contract rounds).

Worker agent files (implementer, test-writer, research-specialist, research-collator, replan-analyzer) are unaffected — they don't emit findings.

**Codex prompt template requirements (#109 cutover):** every #109 Codex-dispatching skill's reviewer prompt must include:
1. A worked one-finding example showing `<<<FINDING-BOUNDARY>>>` on its own line immediately before the YAML frontmatter `---`, with all 7 frontmatter fields filled in (`finding_id`, `severity`, `change_type`, `referenced_files`, `artifact`, `round`, `reviewer`) and a multi-paragraph message body.
2. A worked zero-findings example showing the literal `NO_FINDINGS` token as the entire stdout body (no frontmatter, no prose).
3. An explicit constraint: "Emit only finding blocks (each preceded by `<<<FINDING-BOUNDARY>>>`) or the `NO_FINDINGS` sentinel. Do not emit prose outside finding bodies."
4. An explicit constraint: "Do NOT emit the literal string `# @@QRSPI-CODEX-FAILURE@@:` anywhere in your output — that header is reserved by the wrapper for failure-source classification. If your review needs to discuss a wrapper failure, paraphrase the marker name." This protects the `scripts/codex-stdout-classify.sh` first-line classifier from model-side spoofing.

The worked examples are not optional — the F00 missing-delimiter fallback exists as a safety net, but without worked examples the fallback would fire on a substantial fraction of Codex runs (LLM stochasticity around structural delimiters). The cutover-commit smoke test (§9 step 5) verifies the fallback rate stays at <5% across the 8 #109 steps.

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
                                       4. Stage crashed-tag finding files
                                          into .crash-skipped/. Re-glob
                                          to produce post-staging arrays
                                          (step-1 arrays are now stale).
                                          Pre-dispatch checksum snapshot:
                                          for each non-crashed-tag
                                          *.finding-*.md, sha256sum the
                                          full file content. Persisted
                                          to disk at reviews/{step}/
                                          round-NN/.snapshots.txt
                                          (sha256sum format; survives
                                          /compact between steps 4
                                          and 6; idempotent on re-entry).
                                       5. Dispatches one Haiku verifier per
                                          non-crashed-tag finding-file path
                                          in parallel              ──> Each Haiku Reads its file +
                                                                          artifact + lazy-Reads upstreams
                                                                          + lazy-Reads referenced_files.
                                                                          Scores 0–100 (continuous;
                                                                          0/25/50/75/100 are anchor
                                                                          descriptions, not bucket-only
                                                                          values). Writes back to same
                                                                          path with the
                                                                          @@QRSPI-VERIFIER-BOUNDARY@@
                                                                          sentinel + ## Verifier block
                                                                          appended (preceding content
                                                                          byte-identical). Returns
                                                                          "<reviewer_tag>.<finding_id>:
                                                                            <int 0..100>" or
                                                                          "<reviewer_tag>.<finding_id>:
                                                                            VERIFY_FAILED:<reason>"
                                                                          (tag prefix disambiguates
                                                                          findings that share an id
                                                                          across reviewer_tag values).
                                       6. Aggregates returns + preserve
                                          guard.
                                          - VERIFY_FAILED handling: present
                                            §5 menu. Option 1 → set
                                            verifier_enabled=false, RUN
                                            preserve guard against un-
                                            failed-verifier files first
                                            (they have snapshots and
                                            sentinels), then fall through
                                            to step 7. Option 2 → re-
                                            dispatch ONLY the failed
                                            verifiers (un-failed files
                                            are post-verify; failed files
                                            are pre-verify; both classes'
                                            step-4 snapshots remain valid
                                            and are reused — no re-
                                            snapshot). Option 3 → abort.
                                          - Preserve guard (verifier-
                                            enabled rounds only, on files
                                            whose verifier did NOT
                                            VERIFY_FAILED): invoke
                                            scripts/verifier-preserve-
                                            guard.sh check per file.
                                            Helper exit 0 = match;
                                            exit 1 = corrupted prefix;
                                            exit 2 = missing sentinel.
                                            Non-zero → surface stderr,
                                            hard abort.
                                       7. Bash assembly (nullglob-safe;
                                          uses the path-qualified arrays
                                          from step 1):
                                            cat "${findings[@]}" \
                                                "${cleans[@]}" \
                                                "${crashes[@]}" \
                                              > "$D/../round-NN-verified.md"
                                          (with awk-injected totals header
                                          carrying verifier_enabled +
                                          scored/kept/dropped/failed/
                                          clean/crashed/empty-codex/
                                          crash-skipped counts).
                                       8. Reads round-NN-verified.md ONCE.
                                       9. Partitions by change_type:
                                          - scope/intent → pause gate
                                            (NEVER score-filtered)
                                          - style/clarity/correctness:
                                            filter at score ≥80 (or
                                            all-kept if (a) verifier_
                                            enabled=false, OR (b) finding's
                                            verifier returned VERIFY_FAILED).
                                            Case (c) — missing ## Verifier
                                            block on a verifier-enabled
                                            non-VERIFY_FAILED finding —
                                            cannot reach this step (preserve
                                            guard at §2 step 6 hard-aborts
                                            on missing sentinel before
                                            assembly). Survivors →
                                            auto-apply via Edit.
                                          Crash files → pause gate
                                          (reviewer-failure path).
                                      10. Writes round-NN-fixes.md.
                                      11. /compact. 12. Per-round commit.
```

**Per-finding file format (post-verify, including the boundary sentinel the verifier MUST write):**

```markdown
---
finding_id: R3-F02
severity: high
change_type: correctness
referenced_files: [skills/design/SKILL.md]
artifact: design
round: 3
reviewer: quality-claude
---

{message body — reviewer's prose explanation; this IS the 5th schema field (`message`), transported in the body rather than the YAML frontmatter to avoid awkward YAML quoting of multi-paragraph prose; multi-paragraph allowed}

<!-- @@QRSPI-VERIFIER-BOUNDARY@@ -->
## Verifier
score: 75
reason: confirmed — cited file does not handle the concurrency case under multi-writer pressure
```

The YAML `reviewer:` field carries the role-distinct dispatcher-supplied `reviewer_tag` value (`quality-claude` | `scope-claude` | `quality-codex` | `scope-codex` for #109). It MUST equal the per-finding filename prefix and the route key the dispatcher used to launch the reviewer. The schema-violation guard at Apply-fix step 2 cross-checks all three (filename prefix, YAML `reviewer` field, dispatched route key) and fails loud on mismatch.

The `<!-- @@QRSPI-VERIFIER-BOUNDARY@@ -->` line and the `## Verifier` block are absent before the verifier runs and BOTH are present after (the verifier writes them as one atomic append). The dispatcher's filter step (Apply-fix step 9 — see §2 step 7 for assembly and §2 step 9 for the partition/filter rule that consumes the assembled file) treats absence of the `## Verifier` block as "keep this finding without scoring" via an explicit branch ONLY for case (a) verifier-disabled rounds and case (b) verifier returned `VERIFY_FAILED:`. Case (c) — verifier-enabled, brief returned a score, but no `## Verifier` block (or no boundary sentinel) — is impossible because the preserve guard at Apply-fix step 6 hard-aborts on missing sentinel before assembly. There is no "silent verifier failure → keep" path; silent failures are caught and aborted.

**Pre-verify file format (the same file before the verifier runs):**

```markdown
---
finding_id: R3-F02
severity: high
change_type: correctness
referenced_files: [skills/design/SKILL.md]
artifact: design
round: 3
reviewer: quality-claude
---

{message body}
```

(Ends with exactly one trailing newline after the last body line. Step-4 snapshots this byte content.)

**Clean-marker file format:**

```markdown
---
reviewer: quality-claude
round: 3
findings: 0
---
```

No body content. The clean marker is the audit signal that a reviewer ran and surfaced zero findings; its absence (combined with absence of any `*.finding-*.md` and `*.crash.md` from a reviewer that the dispatcher expected to run) is the schema-violation signal that a reviewer broke its emission contract.

**finding_id format (canonical and F00 fallback):**
- Canonical reviewer-emitted: `R{NN}-F<NN>` (e.g., `R3-F01`, `R3-F02`). Within a single per-finding file, `finding_id` is unique per `(round, reviewer_tag)`.
- F00 fallback (Codex missing-delimiter): `R{NN}-F00-<reviewer_tag>` (e.g., `R3-F00-quality-codex`, `R3-F00-scope-codex`). The fallback inverts the canonical pattern (F-number first, then tag suffix) so the schema-violation guard's regex `^R\d+-F\d+(-[a-z-]+)?$` accepts both shapes — canonical findings have no suffix; F00 fallback findings carry a tag suffix to disambiguate when both quality-codex and scope-codex hit the fallback in the same round.

The schema-violation guard's permissive regex is documented alongside the routing table in `reviewer-protocol/SKILL.md`.

## §4 Error handling

**Per-finding verifier failure** (Haiku returns `<reviewer_tag>.<finding_id>: VERIFY_FAILED:{reason}`, e.g. `quality-claude.R3-F02: VERIFY_FAILED:upstream missing`): collected with all other returns. After full aggregation, present §5 menu before assembly proceeds.

**Wholesale verifier outage** (all N Haikus fail): same menu, same options, no special-casing.

**Reviewer-side schema-violation guard (per-expected-tag):** the dispatching skill declares the **expected reviewer-tag set** for the step. Apply-fix step 2 enforces that EACH expected tag produced AT LEAST ONE of `<tag>.finding-*.md`, `<tag>.clean.md`, or `<tag>.crash.md`. Any expected tag with zero matches fails loud with explicit "reviewer <tag> did not emit any output for round NN — agent file may be out of date or dispatch failed silently". Legacy single-file presence (e.g. `round-NN-claude.md` for a reviewer that should be on the post-#109 contract) is also a fail-loud trigger. No silent fallback. This catches reviewer-agent-file regressions in the per-finding emission contract during the migration window AND after.

**Codex splitter failure modes:**
- `NO_FINDINGS` sentinel emitted: clean marker written, no findings.
- Missing-delimiter input (no boundary markers AND no `NO_FINDINGS` sentinel): writes the entire Codex stream to `<reviewer-tag>.finding-F00.md` as a single coarse high-severity finding with the canonical-form unique `finding_id: R{NN}-F00-<reviewer-tag>` (F-number first, then tag suffix — matches §3's permissive schema-guard regex `^R\d+-F\d+(-[a-z-]+)?$`) and `change_type: intent` (route-to-pause). Stderr warning surfaced. Verifier scores it but the score is advisory — change_type partitioning routes it to the pause gate regardless.
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

An always-on footer reminds: "If Haiku is repeatedly unavailable, option 1 is the recommended escape." Always-on means the footer renders on EVERY menu invocation including the very first verifier failure of the run. The intent is intentional warm-priming: Haiku failures are rare in practice, and when they occur the user benefits from the escape hatch being visible up front rather than discoverable only after multiple retries. (Replaces the prior 3-retry counter, which would have required cross-round state plumbing for marginal value — see §8.)

Option 1 mutates `config.md` to set `verifier_enabled: false` and writes a one-line `reviews/{step}/round-NN-verifier-disabled.md` audit note (timestamp, reason, finding count at disable). Subsequent rounds across the rest of the run skip verifier dispatch.

Option 3 follows the existing autonomous-loop abort path: writes `reviews/{step}/round-NN-aborted.md` with the failure context and surfaces to the user via the standard pause-gate UI.

## §6 Cost discipline

**Main-chat context delta vs status quo (no verifier):**
- Status quo: main chat reads per-reviewer files in apply-fix step 1 (~3–5K tokens). `/compact`-shed after fix-apply.
- Post-#109: main chat reads `round-NN-verified.md` exactly once (~3–5K tokens, includes scores). Per-reviewer files are not read by main chat at all.
- Net delta: ~N × 10 tokens (verifier brief returns from each Haiku at Apply-fix step 5 — the parallel-dispatch step). At typical N=8, ~80 tokens. Functionally a wash.

**Total Haiku token spend per round:** N × (artifact + finding + lazy-Reads). At N=8 with a 5K artifact and ~500-token findings: ~50K Haiku-billed tokens per round. At Haiku 4.5 input rates (~$0.80/MTok), $0.04 per round. Cost is negligible relative to the Sonnet review pass it gates.

**Wallclock:** N parallel Haikus complete in ~Haiku-call latency (~3–5 sec wallclock at Haiku speeds). Sequential per-finding scoring would be N× that. Parallel wins meaningfully on UX.

## §7 Tests

Added to `tests/unit/`:

1. **`test-verifier-agent-file.bats`** — `agents/qrspi-finding-verifier.md` exists; frontmatter has `model: haiku`, `tools: [Read, Write]`, name `qrspi-finding-verifier`; body cites the rubric verbatim (greps for the 0/25/50/75/100 grade-anchor definitions a–e from /code-review step 5); body asserts the rubric is described as **continuous 0–100** with the anchors as reference points (NOT discrete-bucket-only); body cites the false-positive examples list; body specifies the input-contract parameter names and the procedure step ordering; body asserts the preserve-preceding-content requirement is documented; body asserts the brief-return shape is `<reviewer_tag>.<finding_id>: <int 0..100>` (with the reviewer-tag prefix that disambiguates findings sharing an id across reviewer_tag values), and uses an integer in `0..100` (not a bucket label).

2. **`test-per-finding-file-emission.bats`** — every reviewer agent file under `agents/qrspi-*reviewer*.md` IN THE #109 SCOPE (the 14 artifact-level reviewers enumerated in §2: 8 quality + 6 scope) has body language instructing per-finding emission with the canonical `<reviewer_tag>.finding-F<NN>.md` filename pattern AND the `<reviewer_tag>.clean.md` clean-sentinel pattern using the role-distinct tag values; the same files do NOT emit a single multi-finding file (greps for legacy `round-NN-{reviewer}.md` writes and asserts they are absent). The 18 deferred reviewers (Plan-step 7 + per-task 8 + implement-gate 1 + security-integration 1 + integration-quality 1) are explicitly skipped with a comment citing the follow-up issue number (filed BEFORE the cutover commit per §9 step 0).

3. **`test-codex-splitter.bats`** — `scripts/codex-finding-splitter.sh` exists, is executable, handles boundary-delimited input (multi-finding split with role-distinct tag flowing through into per-finding filenames), `NO_FINDINGS`-sentinel input (writes clean marker), missing-delimiter fallback (single F00 file + stderr warning + FULL 7-field synthetic frontmatter passing the schema-violation guard), **empty input (writes `<reviewer_tag>.crash.md`, NOT a clean marker — empty Codex stdout is failure)**, idempotency (re-run produces same output). Also asserts the splitter is NOT invoked when `await` returns non-zero (covered via the dispatch-site test #4). Also asserts the Codex prompt template in each #109 dispatching skill includes the worked one-finding example, the worked zero-findings example, and the no-prose-outside-finding-blocks constraint (greps the prompt template for these features).

4. **`test-verifier-dispatch-contract.bats`** — `skills/using-qrspi/SKILL.md` Apply-fix protocol body references the verifier-enabled gate, the pre-dispatch checksum snapshot, the parallel-verifier dispatch step, the Bash assembly step (with preserve-guard re-checksum), the `change_type`-partition rule (scope/intent always pause; style/clarity/correctness score-filtered), and the per-round commit covering `round-NN/` subdir — all in the documented order. Also asserts the protocol does NOT instruct main chat to read per-reviewer single files for #109-scope artifacts. Also asserts that `await` non-zero exit codes route to the crash-file path, not the splitter.

5. **`test-verifier-failure-menu.bats`** — main-chat-authored protocol body (in `using-qrspi/SKILL.md`) describes the §5 menu with the three exact option strings; no default option; option 1 mutates `config.md` `verifier_enabled: false` and writes the audit note path; the always-on footer about repeated unavailability is present.

6. **`test-verified-file-shape.bats`** — `round-NN-verified.md` is the assembly of `*.finding-*.md` + `*.clean.md` + `*.crash.md` with a totals-header injected by `awk` (asserts the header field set: `verifier_enabled`, `scored`, `kept`, `dropped`, `failed`, `clean`, `crashed`, `empty-codex`, `crash-skipped` — the canonical field name is the singular `scored`, matching §2 step 7 and §3 data-flow). The `awk` totals counter distinguishes `empty-codex` from `crashed` by the structured first-non-blank-line marker `# @@QRSPI-EMPTY-CODEX-STDOUT@@` that the splitter writes into empty-stdout crash files (per §2 splitter "Empty input" subsection): crash files matching that marker count as `empty-codex`; all other crash files count as `crashed`. The file is the sole apply-fix dispatch Read source; the file format is documented in `reviewer-protocol/SKILL.md`. Includes a verifier-enabled fixture (asserts `verifier_enabled: true` row + non-zero `scored`), a verifier-disabled fixture (asserts `verifier_enabled: false` row + `scored: 0` + all findings under `kept`), AND an empty-codex fixture (asserts a crash file with the `@@QRSPI-EMPTY-CODEX-STDOUT@@` marker bumps the `empty-codex` counter NOT the `crashed` counter).

7. **`test-config-verifier-enabled-field.bats`** — `verifier_enabled` field is documented in `skills/using-qrspi/SKILL.md`'s Config-File schema (NOT a hypothetical `skills/config/` skill); default is `true` on missing field; the field is read by every artifact-level Apply-fix protocol invocation; the run-scope persistence semantics (durable across `/compact` and resume within the same run directory) are documented; mid-run mutation precedent (`review_mode`/`review_depth`) is cited.

8. **`test-disabled-mode-fallthrough.bats`** — when `verifier_enabled: false`, Apply-fix protocol body skips verifier dispatch but STILL assembles `round-NN-verified.md` from the per-finding files (without `## Verifier` blocks); the dispatch step keeps all findings via the explicit "no `## Verifier` block → keep" branch (NOT a synthetic 80 score); the orchestrator-side preserve guard is skipped on disabled rounds (no verifier ran). Asserts via protocol body language plus a fixture round directory.

9. **`test-change-type-partition.bats`** (NEW) — Apply-fix dispatch protocol body asserts that `scope` and `intent` findings flow to the pause gate REGARDLESS of verifier score (no score-based suppression of user-surfacing); `style`/`clarity`/`correctness` findings are score-filtered at ≥80 in verifier-enabled rounds; the canonical 5-value `change_type` enum (`style|clarity|correctness|scope|intent`) is cited from `skills/reviewer-protocol/SKILL.md`; out-of-enum values trigger loud failure. Includes a fixture verified.md with mixed `change_type`s and asserts the routing comment in the protocol body.

10. **`test-clean-sentinel-and-schema-guard.bats`** (NEW) — `reviewer-protocol/SKILL.md` defines the `<reviewer-tag>.clean.md` sentinel format and the dispatcher's "zero-files-and-no-clean-and-no-crash → fail loud" rule; `using-qrspi/SKILL.md` Apply-fix step 1+6 cites the rule; legacy `round-NN-{reviewer}.md` single-file presence in a #109-scope round is also a loud-failure trigger. Includes negative fixtures (legacy file present, all-three-empty) asserting the failure path.

11. **`test-preserve-guard.bats`** (NEW) — exercises `scripts/verifier-preserve-guard.sh` directly with bats fixtures:
    - `snapshot`/`check` happy path on a file the verifier wrote correctly (sentinel present, prefix unchanged) → exit 0.
    - Corrupted prefix: a fixture where the post-verify file's pre-sentinel content differs from snapshot → exit 1, offending path on stderr.
    - Missing sentinel: a fixture where the verifier wrote `## Verifier` without the boundary sentinel → exit 2.
    - Sentinel-collision robustness: a realistic fixture where a round-2 finding's `message` body quotes a round-1 verifier output verbatim — the round-1 verifier output (with its `## Verifier` heading) is on disk under `reviews/{step}/round-01/`, the round-2 reviewer Read it while preparing its diff-review, and the round-2 finding's message body quotes it (heading and all). The round-2 finding has been correctly verified → exit 0 (sentinel-based truncation must succeed; heading-based truncation would have failed because the message body contains the literal `## Verifier` heading). Asserts the chosen sentinel is unique enough to survive realistic reviewer prose.
    Additionally asserts: `using-qrspi/SKILL.md` Apply-fix protocol body invokes the helper script at the documented steps; the `qrspi-finding-verifier` agent file body documents the byte-identical-preservation requirement and the sentinel form; the guard is documented as skipped on verifier-disabled rounds.

## §8 Out of scope

- **Plan-step verifier integration (entire Plan dispatching skill).** The Plan apply-fix loop dispatches the unified `qrspi-plan-reviewer` and `qrspi-plan-scope-reviewer` ALONGSIDE 5 plan-artifact reviewers (`qrspi-plan-{spec,security,silent-failure-hunter,test-coverage,goal-traceability}-reviewer`); migrating only the unified pair would force the Apply-fix protocol to handle a mixed contract within a single round. The follow-up issue migrates all 7 Plan-step reviewers atomically. The follow-up should also evaluate whether the Expected-Reviewer Matrix textual representation (currently a per-step row of comma-separated tags) composes well when Plan adds 7 tags + Implement adds 8-per-task tag families; the matrix may want a per-step subsection or fenced-YAML representation post-deferred-migration.
- **Per-task implementation review verifier integration.** The `skills/implement/SKILL.md` per-task review loop (8 reviewer agents per task) keeps its existing single-file emission and its existing apply/pause flow under #109. Verifier integration there requires a parallel migration of those 8 reviewer agents + the per-task aggregation path at `reviews/tasks/task-NN-review.md`; same follow-up.
- **Integration / security-integration review verifier integration.** The `skills/integrate/SKILL.md` review/fix loop and the `qrspi-security-integration-reviewer` keep their existing flow under #109. Same follow-up.
- **Implement-gate review verifier integration.** The `qrspi-implement-gate-reviewer` (Implement batch gate) keeps its existing flow under #109. Same follow-up.
- **3-retry counter for the failure menu.** Earlier draft proposed a "tried 3 times — Haiku may be down" hint after 3 consecutive option-2 picks. Implementing this requires either persisting a retry counter in `config.md` or threading it through the orchestrator's transcript memory; both add scope and the always-on footer (§5) covers the user-guidance need.
- **Within-round dedup** (same finding flagged by claude AND codex). Convergent flags are signal, not noise — verifier scores both. Future v0.6+ optimization candidate.
- **Across-round dedup** (same finding re-flagged in round N+1 after surviving round N's drop). Memoization adds a cache invalidation surface (artifact edits, backward loops) that complicates the design beyond "copy first." Future v0.6+ candidate.
- **Per-per-reviewer-file dispatch refinement** (one Haiku per per-reviewer-tag instead of one Haiku per finding). Considered for attention-management at very high finding counts (>15/round); not adopted in #109. Future v0.6+ candidate if stress observed.
- **Verifier model upgrades** (Sonnet verifier, custom rubric per artifact type, alternative scoring scales). The `model: haiku` + verbatim-/code-review-rubric choice is load-bearing for the cost math and the faithful-copy-of-`/code-review` argument. Any upgrade lands in a separate issue.
- **Verifier-disable-by-default mode.** The default is `verifier_enabled: true`. Per-run opt-out exists via the §5 menu (option 1). A pipeline-wide opt-out via CLI flag at run start is out of scope for #109 — add when the use case appears.

## §9 Migration sequence

The implementation plan (forthcoming in `docs/superpowers/plans/`) sequences as follows. The cutover commit (step 4) is the load-bearing atomicity boundary: it ships every runtime-behavior change in one commit. Pre-cutover commits add infrastructure not yet wired up; post-cutover steps validate.

**Step 0: file the follow-up issue BEFORE any code commits.** The follow-up issue covers the 18 deferred reviewers (Plan-step: 1 unified plan-quality + 1 plan-scope + 5 plan-artifact = 7; per-task implementation × 8; implement-gate × 1; security-integration × 1; integration-quality × 1) plus the corresponding apply-fix flows in `skills/{plan,implement,integrate}/SKILL.md`. The follow-up will collapse the bifurcated reviewer-protocol skill back to a single contract. Filing this BEFORE step 4 means tests #2 and other deferred-reviewer comments can cite a real issue number at test-write time. The follow-up issue body cites the spec by stable path (`docs/superpowers/specs/2026-05-04-109-sonnet-haiku-verifier-design.md §8`) — not by merged-commit file paths — so the issue stays self-coherent if step 4 is rolled back and re-landed.

1. **Verifier agent file.** Create `agents/qrspi-finding-verifier.md` with the rubric, false-positive examples, and procedure. Land alone with unit test #1. Not yet referenced by any skill — purely additive.

2. **Codex splitter + classifier (scripts only, no prompt or wrapper changes yet).** Add `scripts/codex-finding-splitter.sh` and `scripts/codex-stdout-classify.sh` and a NARROWED `tests/unit/test-codex-splitter.bats` that exercises ONLY the splitter and classifier scripts directly with **synthetic** inputs (boundary-delimited, NO_FINDINGS sentinel, missing-delimiter fallback, empty input, and synthetic `# @@QRSPI-CODEX-FAILURE@@:` marker headers prepended to bare-text bodies — the synthetic fixtures stand in for what `codex-companion-bg.sh` will emit AFTER step 4 modifies it). The Codex prompts in dispatching skills are NOT changed in this commit; the wrapper itself is NOT yet modified to emit the marker (that lands in step 4); and the test does NOT grep dispatching skill prompts (that assertion moves to a test that lands in the cutover commit). The splitter and classifier are dead code until step 4 wires them up.

3. **`config.md` schema update (documentation only, no protocol changes).** Add `verifier_enabled` field (default `true`) to `skills/using-qrspi/SKILL.md` Config-File schema. Land with a NARROWED `tests/unit/test-config-verifier-enabled-field.bats` that asserts the schema documentation exists (default-on, persistence semantics, runtime-backfill carve-out documented) — it does NOT yet assert the field is read by any protocol (that assertion moves to a test that lands in the cutover commit, since the runtime-backfill code itself lands at step 4).

4. **Atomic cutover commit (the load-bearing one).** This single commit lands EVERY runtime-behavior change together — including the failure-menu mutation logic and the `reviewer_tag` rename in the dispatching skills. Splitting any of these out would leave main in a contradictory runtime state:
   - The bifurcated reviewer-protocol amendment in `skills/reviewer-protocol/SKILL.md` (Reviewer Routing Table + Expected-Reviewer Matrix + new `## Per-Finding Disk-Write Contract` keyed on the 4 role-distinct #109 tags + renamed `## Legacy Disk-Write Contract` preserved verbatim for deferred tags).
   - All 14 #109-scope reviewer agent file migrations (per-finding emission + clean sentinel + new brief-return shape, using the dispatcher-supplied role-distinct `reviewer_tag` value) under `agents/qrspi-{goals,questions,research,design,phasing,structure,parallelize,replan}-reviewer.md` (8 quality) and `agents/qrspi-{goals,design,phasing,structure,parallelize,replan}-scope-reviewer.md` (6 scope).
   - The Codex prompt + dispatch-parameter amendments in the 8 #109 artifact-level dispatching skills (`skills/{goals,questions,research,design,phasing,structure,parallelize,replan}/SKILL.md`) to: (a) pass the role-distinct `reviewer_tag` values (`quality-claude`/`scope-claude`/`quality-codex`/`scope-codex`) instead of today's collapsed `claude`/`codex`; (b) inject the `<<<FINDING-BOUNDARY>>>` delimiter and the `NO_FINDINGS` sentinel into the Codex reviewer prompt with worked one-finding and zero-finding examples; (c) retire the `output:` path-arg.
   - `scripts/verifier-preserve-guard.sh` (new helper, with `snapshot` and `check` subcommands per §4; reads/writes `reviews/{step}/round-NN/.snapshots.txt` for `/compact`-resilience).
   - `scripts/codex-companion-bg.sh` `fetch_result()` modification: prepend `# @@QRSPI-CODEX-FAILURE@@: <source>\n` (where `<source>` ∈ `storedJob.rendered`/`job.errorMessage`/`storedJob.errorMessage`) to the extracted text on links (c)/(d)/(e); leave links (a)/(b) unchanged; keep exit code 0 in all five paths. Existing `tests/unit/test-codex-companion-bg.bats` fixtures updated to assert the marker is emitted on links (c)/(d)/(e) and absent on links (a)/(b). This is the live-emission half of the classifier contract that step 2 stubbed in.
   - The Apply-fix protocol revision in `skills/using-qrspi/SKILL.md` (verifier-aware sequence with all 12 steps, including the per-expected-tag schema-violation guard, the orchestrator-side preserve guard via the helper script, the change_type partition, the new clean-vs-broken disambiguation, AND the runtime backfill code for the `verifier_enabled` carve-out).
   - The §5 failure-menu mutation logic in `skills/using-qrspi/SKILL.md` (option 1 → write `verifier_enabled: false` to `config.md` + write the `reviews/{step}/round-NN-verifier-disabled.md` audit note + the always-on footer text).
   - All `using-qrspi`/`reviewer-protocol`/script test updates that pin the new contracts (tests #2, #3, #4, #5, #6, #7, #8, #9, #10, #11).

   The commit is large by design (~50 files: 14 agent files + 8 dispatching skills + 1 reviewer-protocol skill + 1 using-qrspi skill + 1 helper script + ~10 test files + a few touched README/docs). Every smaller cut would leave main with contradictory runtime behavior between commits. Pre-merge validation gates: (i) every existing bats passes; (ii) every new bats passes; (iii) the §9 step-5 smoke matrix passes for ALL 8 #109 steps (not just one), demonstrating end-to-end through the routing-table disambiguation, the matrix's config-aware tag exclusions for Questions/Research, and the option-1 mid-run mutation path.

5. **Smoke matrix on real artifact reviews.** Run a real review round for AT LEAST one representative from each behavior class:
   - Questions or Research (no scope reviewer; matrix excludes scope tags) — verifies the config-aware matrix doesn't false-fail.
   - Goals or Design (full 4-reviewer set) — verifies the routing-table disambiguates quality vs scope via the role-distinct `reviewer_tag`.
   - One run with `verifier_enabled: false` from start — verifies the disabled-mode totals header shape with the explicit `verifier_enabled: false` row.
   - One run with `codex_reviews: false` — verifies the matrix excludes codex tags without false-failing.
   - One run with a synthesized `<reviewer_tag>.crash.md` AND matching `<reviewer_tag>.finding-*.md` files in the round dir — verifies step-4 moves the finding files into `.crash-skipped/` and assembly stays clean.
   - One run that triggers the F00 missing-delimiter fallback — verifies the synthetic full-frontmatter file passes the schema-violation guard.
   - One run with a verifier hitting `VERIFY_FAILED:` followed by an option-1 mid-run mutation — verifies the preserve guard runs against un-failed-verifier files before fall-through.

Rollback contract: steps 1–3 are individually revertible (purely additive). Step 4 must be reverted as a whole (it is the cutover; every behavior change ships together). Step 5 is not a code change (smoke). Step 0's follow-up-issue filing is non-revertible (a GitHub issue) but its body is written defensively (cites the spec by stable path, not by merged-commit file paths) so it remains coherent across rollback/re-land cycles. After step 4 lands, the pre-#109 reviewer-output shape is gone for #109-scope reviewers; Plan and the other deferred steps retain their existing shape (via the legacy section in reviewer-protocol) until the follow-up issue.
