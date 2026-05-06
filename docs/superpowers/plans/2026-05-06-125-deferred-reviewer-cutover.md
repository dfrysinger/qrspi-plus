# Deferred Reviewer Migration Cutover (#125) — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Migrate the remaining 18 deferred reviewers (Plan-stage, per-task, implement-gate, integration-class) from the legacy single-file disk-write contract to the per-finding contract, then collapse the reviewer-protocol bifurcation. The merge to main MUST be a single squash-merged commit (atomicity constraint per spec §2 — Plan dispatches up to 7 reviewers in parallel, so a mixed-contract transition window corrupts the Expected-Reviewer Matrix).

**Architecture:** Dispatcher SKILLs change their `output` parameter from a per-file path (`reviews/{step}/round-NN-{tag}.md`) to a directory path (`reviews/{step}/round-NN/`); reviewer agents construct per-finding filenames per the protocol contract. Three agent files with explicit legacy path prose (implement-gate + 2 integration) get surgically updated; the other 15 already defer to the protocol via deferral language and pick up the new contract automatically when the protocol's bifurcation collapses. The reviewer-protocol skill drops its routing table + legacy contract section, renames the per-finding section to remove the "(#109 reviewers)" qualifier, and extends its Expected-Reviewer Matrix from 8 steps to 12 (adding plan, implement-gate, integrate, test).

**Tech Stack:** Markdown (agent files, SKILL.md), bats (tests), bash grep guards. Pure prose-and-prompts edits — no Python or shell logic changes.

**Spec:** [`docs/superpowers/specs/2026-05-05-125-deferred-reviewer-migration-design.md`](../specs/2026-05-05-125-deferred-reviewer-migration-design.md)

**Predecessor:** PR #127 (#109) migrated 14 of 32 reviewers. This plan migrates the remaining 18 + collapses the bifurcation.

---

## Implementer notes — read before starting

**Atomicity.** The 4 commits below produce intermediate states where the bats suite WILL fail (e.g., after Task 1 alone, the 3 newly-migrated agent files reference per-finding emission while the protocol still bifurcates). This is expected. Bats green is a precondition for PR-tip only, not for every intermediate commit. The PR squash-merges all 4 commits into a single cutover on main. Document this in the PR body.

**Reconnaissance baseline (verified 2026-05-06).** The spec §3.2 anticipates that some agent files will need contract prose surgery and others will only need the protocol redirect. Recon found that **only 3 of 18 agent files** have explicit legacy path prose:
- `agents/qrspi-implement-gate-reviewer.md` line 19
- `agents/qrspi-integration-reviewer.md` line 18
- `agents/qrspi-security-integration-reviewer.md` line 18

The other 15 already use the deferral pattern (e.g., "Write findings to the `output` path provided in your dispatch prompt per the disk-write contract from the reviewer-protocol skill"). They need no agent-file edit — they pick up the new contract when the protocol's per-finding section becomes authoritative.

**Test scope correction.** Spec §6 lists 4 #109 tests as needing extension (`test-per-finding-file-emission.bats`, `test-clean-sentinel-and-schema-guard.bats`, `test-change-type-partition.bats`, `test-failure-menu.bats`). Recon found that **only `test-per-finding-file-emission.bats` carries an explicit `#125` skip block** (lines 4–6 header comment, lines 13–31 `deferred_files` array, lines 85–100 the skip test). The other three tests are universal — their assertions don't currently scope to specific reviewer tags. Verify by greppping for `125` in each test file before assuming you need to edit them. If a test has no `125` reference, no edit is required.

**Reviewer-tag inventory (authoritative for §4.2 matrix extension).** Derived by grepping every `reviewer_tag:` value in dispatcher SKILLs:

| Step | `codex_reviews: true` | `codex_reviews: false` |
|---|---|---|
| `plan` | `quality-claude`, `scope-claude`, `spec-claude`, `security-claude`, `goal-traceability-claude`, `test-coverage-claude`, `silent-failure-claude`, `quality-codex`, `scope-codex`, `spec-codex`, `security-codex`, `goal-traceability-codex`, `test-coverage-codex`, `silent-failure-codex` | the 7 `*-claude` only |
| `implement-gate` | `implement-gate-claude`, `implement-gate-codex` | `implement-gate-claude` |
| `integrate` | `integration-claude`, `security-integration-claude`, `integration-codex`, `security-integration-codex` | the 2 `*-claude` only |
| `test` | `spec-claude`, `code-quality-claude`, `goal-traceability-claude`, `spec-codex`, `code-quality-codex`, `goal-traceability-codex` | the 3 `*-claude` only |

(The 8 #109-migrated step rows already in the matrix — `goals/questions/research/design/phasing/structure/parallelize/replan` — stay unchanged.)

**Reconcile-against-grep gate.** Before authoring the matrix extension in Task 3, the implementer MUST grep dispatcher SKILLs for `reviewer_tag:` values and reconcile against the table above. If any tag in the actual dispatcher disagrees with the table, the dispatcher's value wins (the matrix asserts what the dispatcher actually emits).

---

## File Structure

**Modified files (all via Edit tool, no creates except the new test):**

| File | Edit shape | Lines affected (approx) |
|---|---|---|
| `agents/qrspi-implement-gate-reviewer.md` | Rewrite output param doc to directory + protocol deferral | line 19 |
| `agents/qrspi-integration-reviewer.md` | Rewrite output param doc to directory + protocol deferral | line 18 |
| `agents/qrspi-security-integration-reviewer.md` | Rewrite output param doc to directory + protocol deferral | line 18 |
| `skills/plan/SKILL.md` | Switch `Output file: ...round-NN-{tag}.md` → `Output directory: ...round-NN/` across 7 Claude + 7 Codex dispatch sites | lines ~258–344 |
| `skills/implement/SKILL.md` | Same switch across 8 per-task Claude sites + Codex parallels + implement-gate site | lines ~395–643 |
| `skills/integrate/SKILL.md` | Same switch across 2 Claude + 2 Codex sites | lines ~102–132 |
| `skills/test/SKILL.md` | Same switch across 3 Claude + 3 Codex sites | lines ~120–167 |
| `skills/replan/SKILL.md` | Update line 272 doc reference (no dispatch code) | line 272 |
| `skills/using-qrspi/SKILL.md` | Restructure `## Review Output Handling` to single-contract documentation | lines ~475–525 |
| `skills/reviewer-protocol/SKILL.md` | Remove routing table + legacy contract; extend matrix; rename per-finding section header | see Task 3 detail |
| `tests/unit/test-per-finding-file-emission.bats` | Remove skip block; extend assertions to all 32 reviewer tags via either inline-ref OR protocol-deferral check | see Task 4 detail |
| `tests/unit/test-no-legacy-disk-write-references.bats` | **CREATE** — 3 grep guard assertions | new file, ~30 lines |

**No fixture changes required.** Recon found existing `tests/fixtures/issue-109/*` cover only role-distinct tags (`quality-*`, `scope-*`); none of the test extensions in this plan dispatch reviewers against fixtures, so no new fixtures are needed. (If a future test extension requires per-step fixtures for plan/implement-gate/integrate/test rounds, that's out of scope — file as a follow-up issue.)

---

## Task 1: Migrate 3 explicit-path agent files

**Atomicity note:** This is the first of four logical commits inside the PR. The bats suite will be in an inconsistent state after this commit alone — that's expected; the PR squash-merges all four into one cutover on main.

**Files:**
- Modify: `agents/qrspi-implement-gate-reviewer.md:19`
- Modify: `agents/qrspi-integration-reviewer.md:18`
- Modify: `agents/qrspi-security-integration-reviewer.md:18`

- [ ] **Step 1: Verify current state of the 3 files**

Run: `grep -n 'round-NN-' agents/qrspi-implement-gate-reviewer.md agents/qrspi-integration-reviewer.md agents/qrspi-security-integration-reviewer.md`

Expected output (exact):
```
agents/qrspi-implement-gate-reviewer.md:19:- `output` — absolute path (`<ABS_ARTIFACT_DIR>/reviews/integration/round-NN-implement-gate-claude.md`)
agents/qrspi-integration-reviewer.md:18:- `output` — absolute path (`<ABS_ARTIFACT_DIR>/reviews/integration/round-NN-integration-claude.md`)
agents/qrspi-security-integration-reviewer.md:18:- `output` — absolute path (`<ABS_ARTIFACT_DIR>/reviews/integration/round-NN-security-claude.md`)
```

If output diverges, **stop and reconcile** — the assumed lines and exact strings drive the Edit calls below. Don't proceed until confirmed.

- [ ] **Step 2: Edit `agents/qrspi-implement-gate-reviewer.md` line 19**

Use Edit tool. Old string (one line):

```
- `output` — absolute path (`<ABS_ARTIFACT_DIR>/reviews/integration/round-NN-implement-gate-claude.md`)
```

New string (one line):

```
- `output` — absolute path to the round directory (`<ABS_ARTIFACT_DIR>/reviews/integration/round-NN/`); the reviewer constructs per-finding filenames per the disk-write contract in the reviewer-protocol skill
```

- [ ] **Step 3: Edit `agents/qrspi-integration-reviewer.md` line 18**

Use Edit tool. Old string (one line):

```
- `output` — absolute path (`<ABS_ARTIFACT_DIR>/reviews/integration/round-NN-integration-claude.md`)
```

New string (one line):

```
- `output` — absolute path to the round directory (`<ABS_ARTIFACT_DIR>/reviews/integration/round-NN/`); the reviewer constructs per-finding filenames per the disk-write contract in the reviewer-protocol skill
```

- [ ] **Step 4: Edit `agents/qrspi-security-integration-reviewer.md` line 18**

Use Edit tool. Old string (one line):

```
- `output` — absolute path (`<ABS_ARTIFACT_DIR>/reviews/integration/round-NN-security-claude.md`)
```

New string (one line):

```
- `output` — absolute path to the round directory (`<ABS_ARTIFACT_DIR>/reviews/integration/round-NN/`); the reviewer constructs per-finding filenames per the disk-write contract in the reviewer-protocol skill
```

- [ ] **Step 5: Verify no legacy `round-NN-` references remain in the 3 files**

Run: `grep -n 'round-NN-' agents/qrspi-implement-gate-reviewer.md agents/qrspi-integration-reviewer.md agents/qrspi-security-integration-reviewer.md ; echo done`

Expected: only `done` line (no matches). If grep finds any `round-NN-` reference in these 3 files, the edits are incomplete — fix before proceeding.

- [ ] **Step 6: Verify other 15 deferred-reviewer agents are unchanged**

Run: `git diff --stat agents/`

Expected: exactly 3 files changed, 3 insertions(+), 3 deletions(-) (one line per file).

If more than 3 agent files changed, **stop and revert** — only those 3 should be touched in this task.

- [ ] **Step 7: Commit**

Write commit message to `/tmp/cm-125-task1-agents.txt`:

```
refactor(agents): #125 migrate 3 deferred reviewers to per-finding output param doc

Updates the `output` dispatch-param documentation in three reviewer
agent files that carried explicit legacy `round-NN-{tag}.md` path prose:

  - agents/qrspi-implement-gate-reviewer.md
  - agents/qrspi-integration-reviewer.md
  - agents/qrspi-security-integration-reviewer.md

The other 15 deferred reviewer agent files use the existing
"per the disk-write contract from the reviewer-protocol skill"
deferral pattern and need no agent-file edit; they pick up the new
contract automatically when the protocol's bifurcation collapses
(Task 3 of this PR).

Note: this is one of four logical commits in PR #125's atomic cutover.
The bats suite is in an intentionally inconsistent state at this point;
final state is verified after Task 4. The PR squash-merges all four
commits into one cutover on main per spec §2.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
```

Then run:

```
git add agents/qrspi-implement-gate-reviewer.md agents/qrspi-integration-reviewer.md agents/qrspi-security-integration-reviewer.md
git commit -F /tmp/cm-125-task1-agents.txt
```

Expected: clean commit message, 3 files changed, 3 insertions, 3 deletions.

---

## Task 2: Switch dispatching SKILLs to per-finding output paths

**Files:**
- Modify: `skills/plan/SKILL.md` (14 dispatch sites)
- Modify: `skills/implement/SKILL.md` (8 per-task Claude + Codex parallels + 2 implement-gate sites = ~17 sites)
- Modify: `skills/integrate/SKILL.md` (4 sites)
- Modify: `skills/test/SKILL.md` (6 sites)
- Modify: `skills/replan/SKILL.md:272` (doc reference only)
- Modify: `skills/using-qrspi/SKILL.md` (`## Review Output Handling` section, lines ~475–525)

**Edit pattern across all dispatchers.** For every reviewer-dispatch site that currently passes a legacy file path, change the parameter name from `output` (or `Output file:`) where it points at a file, to a directory parameter pointing at the round directory. Two minor variants exist depending on dispatch shape:

**Variant A — Claude reviewer dispatch (Task tool param):** rewrite the `- output: <ABS>/reviews/{step}/round-NN-{tag}.md` line to `- output: <ABS>/reviews/{step}/round-NN/` (drop the filename suffix; the `{tag}` is communicated via the existing `reviewer_tag` parameter and the reviewer constructs per-finding filenames per protocol).

**Variant B — Codex reviewer dispatch (printf into `codex-companion-bg.sh`):** in the printf format string the `output:` field follows the same rule — rewrite the path to the round directory, drop the filename suffix.

Both variants preserve the `reviewer_tag:` parameter unchanged.

- [ ] **Step 1: Inventory all legacy-path dispatch sites**

Run: `grep -nE 'reviews/[a-z-]+/round-NN-[a-z-]+\.md' skills/plan/SKILL.md skills/implement/SKILL.md skills/integrate/SKILL.md skills/test/SKILL.md skills/replan/SKILL.md skills/using-qrspi/SKILL.md`

Expected: ~30+ matches across the 6 files. Save the inventory as a checklist; each match must be edited (or, for `using-qrspi` doc, contextually rewritten — see Step 6).

- [ ] **Step 2: Edit `skills/plan/SKILL.md` — replace 14 legacy paths**

Read the full file first (it's ~400 lines). For each of the 14 dispatch sites identified by recon (lines ~258–344), apply Variant A or B as appropriate.

For each site, the Edit transformation has the shape:

Old: `<ABS_ARTIFACT_DIR>/reviews/plan/round-NN-{TAG}.md`
New: `<ABS_ARTIFACT_DIR>/reviews/plan/round-NN/`

Where `{TAG}` is the reviewer's existing tag (e.g., `claude`, `spec-claude`, `security-codex`). The `{TAG}` value is preserved elsewhere in the dispatch as `reviewer_tag:`; only the `output` path drops the filename.

After all 14 edits, verify:

Run: `grep -nE 'round-NN-[a-z-]+\.md' skills/plan/SKILL.md ; echo done`

Expected: only `done` (no matches).

- [ ] **Step 3: Edit `skills/implement/SKILL.md` — replace per-task + implement-gate paths**

Two distinct path patterns in this file:

**Per-task pattern** (lines ~395–550, repeated across 8 Claude + Codex parallels):
- Old: `reviews/tasks/task-NN-{REVIEWER}-round-NN-{tag}.md` (note: includes `-reviewer` suffix in some, not others — preserve the existing reviewer-name segment)
- New: `reviews/tasks/task-NN/round-NN/`

**Implement-gate pattern** (lines ~631, ~643):
- Old: `reviews/integration/round-NN-implement-gate-{tag}.md`
- New: `reviews/integration/round-NN/`

After all edits, verify:

Run: `grep -nE 'round-NN-[a-z-]+\.md|task-NN-.*-round-NN-' skills/implement/SKILL.md ; echo done`

Expected: only `done`.

- [ ] **Step 4: Edit `skills/integrate/SKILL.md` — replace 4 paths**

Sites at lines ~102, 110, 124, 132. Pattern:
- Old: `reviews/integration/round-NN-{TAG}.md`
- New: `reviews/integration/round-NN/`

After edits, verify:

Run: `grep -nE 'round-NN-[a-z-]+\.md' skills/integrate/SKILL.md ; echo done`

Expected: only `done`.

- [ ] **Step 5: Edit `skills/test/SKILL.md` — replace 6 paths**

Sites at lines ~120, 128, 136, 151, 159, 167. Pattern:
- Old: `reviews/test/round-NN-{TAG}.md`
- New: `reviews/test/round-NN/`

After edits, verify:

Run: `grep -nE 'round-NN-[a-z-]+\.md' skills/test/SKILL.md ; echo done`

Expected: only `done`.

- [ ] **Step 6: Edit `skills/using-qrspi/SKILL.md` — restructure `## Review Output Handling`**

This is documentation, not dispatch code. Recon identified lines ~475–525 as the `## Review Output Handling` section, currently describing both contracts.

Read lines 470–530. The section currently:
1. Names two paths (legacy single-file + per-finding round-directory)
2. Describes the orchestrator's read pattern for each

Rewrite the section to describe ONLY the per-finding round-directory contract. The replacement should:
- Drop any "deferred reviewers use single-file output" language
- Drop the `reviews/{step}/round-NN-{tag}.md` legacy path examples
- Keep the `reviews/{step}/round-NN/<reviewer_tag>.finding-F<NN>.md` pattern as the universal contract
- Keep the orchestrator-side rationale (cost optimization, conversation-history bloat avoidance) — that's contract-shape-independent

Authoring guidance: before rewriting, read the post-cutover form of `skills/reviewer-protocol/SKILL.md` `## Per-Finding Disk-Write Contract` (after Task 3 it'll be the renamed authoritative section; in the current pre-Task-3 state it's at lines 204–256 under the "(#109 reviewers)" qualifier). The using-qrspi documentation should reference that section by name and describe the *orchestrator's* obligations, not duplicate the contract spec.

After edit, verify:

Run: `grep -nE 'round-NN-[a-z-]+\.md|legacy disk-write|deferred reviewer' skills/using-qrspi/SKILL.md ; echo done`

Expected: only `done`.

- [ ] **Step 7: Edit `skills/replan/SKILL.md:272` — update doc reference**

Read line 272 in context. The line currently:

```
- `reviews/replan/round-NN-{reviewer}.md` — per-round per-reviewer review findings (`{reviewer}` is `claude`, `scope`, or `codex`); reviewer-authored per the disk-write contract
```

This is artifact-tree documentation referencing the legacy filename pattern. Replan's own reviewers were #109-migrated, so this line is internally inconsistent today (the replan-reviewer actually emits per-finding files). Rewrite to the per-finding shape:

Old:
```
- `reviews/replan/round-NN-{reviewer}.md` — per-round per-reviewer review findings (`{reviewer}` is `claude`, `scope`, or `codex`); reviewer-authored per the disk-write contract
```

New:
```
- `reviews/replan/round-NN/<reviewer_tag>.finding-F<NN>.md` — per-finding files (one per reviewer-emitted finding); `<reviewer_tag>` is `quality-claude`, `scope-claude`, `quality-codex`, or `scope-codex`; reviewer-authored per the disk-write contract in the reviewer-protocol skill
```

Verify:

Run: `grep -n 'round-NN-' skills/replan/SKILL.md ; echo done`

Expected: only `done` (the line above was the only match).

- [ ] **Step 8: Cross-file legacy-pattern grep — confirm zero residual references in dispatching skills**

Run: `grep -rnE 'round-NN-[a-z-]+\.md' skills/ ; echo done`

Expected: only `done`. If grep reports any match outside `skills/reviewer-protocol/SKILL.md` (which legitimately references the pattern in its `## Legacy Disk-Write Contract` section that gets removed in Task 3), fix the residual.

A match inside `skills/reviewer-protocol/SKILL.md` is OK — Task 3 removes that section.

- [ ] **Step 9: Commit**

Write commit message to `/tmp/cm-125-task2-skills.txt`:

```
refactor(skills): #125 switch dispatching skills to per-finding output paths

Replaces all `Output file: reviews/{step}/round-NN-{tag}.md` legacy
dispatch params with `Output directory: reviews/{step}/round-NN/` per
the per-finding contract:

  - skills/plan/SKILL.md          — 14 sites (7 Claude + 7 Codex)
  - skills/implement/SKILL.md     — per-task (8 Claude + Codex parallels)
                                    + implement-gate (Claude + Codex)
  - skills/integrate/SKILL.md     — 4 sites (2 Claude + 2 Codex)
  - skills/test/SKILL.md          — 6 sites (3 Claude + 3 Codex)
  - skills/replan/SKILL.md:272    — artifact-tree doc reference
  - skills/using-qrspi/SKILL.md   — Review Output Handling section
                                    restructured to single-contract doc

The reviewer agents (Task 1 of this PR + the 15 protocol-deferring
agents) construct per-finding filenames per the protocol contract.

Note: second of four logical commits in PR #125's atomic cutover.
PR squash-merges into one cutover on main per spec §2.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
```

Then run:

```
git add skills/plan/SKILL.md skills/implement/SKILL.md skills/integrate/SKILL.md skills/test/SKILL.md skills/replan/SKILL.md skills/using-qrspi/SKILL.md
git commit -F /tmp/cm-125-task2-skills.txt
```

Expected: 6 files changed.

---

## Task 3: Collapse reviewer-protocol bifurcation

**Files:**
- Modify: `skills/reviewer-protocol/SKILL.md` (single file, 4 surgical edits)

**The 4 edits (in order):**
1. Remove `## Reviewer-Tag Routing Table` section in entirety (lines ~19–29 + the line 21 bifurcation-window paragraph that introduces it).
2. Extend `## Expected-Reviewer Matrix` (lines ~31–46) — add 4 rows for plan, implement-gate, integrate, test; remove line 46's "out of scope for #109" parenthetical.
3. Remove `## Legacy Disk-Write Contract (deferred reviewers)` section in entirety (lines ~160–202).
4. Rename `## Per-Finding Disk-Write Contract (#109 reviewers)` (line ~204) to `## Per-Finding Disk-Write Contract` — strip the qualifier. Also strip the line 206 sentence that says "Reviewer subagents tagged `quality-claude`, `scope-claude`, `quality-codex`, or `scope-codex` use this per-finding contract (see `## Reviewer-Tag Routing Table` above)" and replace with a sentence that names this as the universal contract.

- [ ] **Step 1: Read full `skills/reviewer-protocol/SKILL.md`**

Recon identified line ranges as approximate; the actual line numbers may have shifted slightly. Read the full file once before editing — line numbers below are approximate, exact strings are authoritative.

- [ ] **Step 2: Reconcile reviewer-tag inventory against actual dispatcher values**

Run: `grep -nE '^reviewer_tag:|reviewer_tag: [a-z-]+' skills/plan/SKILL.md skills/implement/SKILL.md skills/integrate/SKILL.md skills/test/SKILL.md`

Compare the unique tag values against the inventory in this plan's "Implementer notes — Reviewer-tag inventory" table. If any tag in the dispatcher is not in the table, or vice versa, the table loses — the dispatcher emits the canonical value. Reconcile before authoring the matrix extension.

Note common edge cases:
- `silent-failure-claude` (NOT `silent-failure-hunter-claude`) — agent file is `qrspi-plan-silent-failure-hunter.md` but the tag drops the `-hunter` suffix
- Test step reuses `spec-claude`, `code-quality-claude`, `goal-traceability-claude` tags (same names as Implement per-task) — that's intentional, per spec; the matrix should list them under both Implement-gate's per-task adjacent rows and Test
- `integration-claude` (NOT `integration-reviewer-claude`)
- `security-integration-claude` (NOT `security-integration-reviewer-claude`)

Document the reconciled tag set as a working note before proceeding.

- [ ] **Step 3: Remove `## Reviewer-Tag Routing Table` section**

Edit `skills/reviewer-protocol/SKILL.md`. Old string (the full section, ~lines 19–29):

```
## Reviewer-Tag Routing Table

The reviewer protocol bifurcates during the #109 migration window. The follow-up issue (#125 per Task 0) collapses this back to a single per-finding contract.

| `reviewer_tag` | Contract section | Filename pattern |
|---|---|---|
| `quality-claude` | `## Per-Finding Disk-Write Contract (#109 reviewers)` | `reviews/{step}/round-NN/quality-claude.finding-F<NN>.md` |
| `scope-claude` | `## Per-Finding Disk-Write Contract (#109 reviewers)` | `reviews/{step}/round-NN/scope-claude.finding-F<NN>.md` |
| `quality-codex` | `## Per-Finding Disk-Write Contract (#109 reviewers)` | `reviews/{step}/round-NN/quality-codex.finding-F<NN>.md` |
| `scope-codex` | `## Per-Finding Disk-Write Contract (#109 reviewers)` | `reviews/{step}/round-NN/scope-codex.finding-F<NN>.md` |
| every other reviewer (5 plan-artifact, plan quality/scope, 8 per-task, implement-gate, security-integration, integration-quality) | `## Legacy Disk-Write Contract (deferred reviewers)` | `reviews/{step}/round-NN-{reviewer-tag}.md` (single file per reviewer) |

```

(Note the trailing blank line after the table — preserve the spacing pattern of the file.)

New string: empty (deletes the section).

If the actual file content differs from the above (likely: minor formatting variations), use a smaller chunk per Edit call until the section is fully removed.

After edit, verify:

Run: `grep -nE '## Reviewer-Tag Routing Table' skills/reviewer-protocol/SKILL.md ; echo done`

Expected: only `done`.

- [ ] **Step 4: Extend `## Expected-Reviewer Matrix`**

Read the post-removal file. Find `## Expected-Reviewer Matrix`. Currently has 8 rows (`goals/questions/research/design/phasing/structure/parallelize/replan`) and a closing parenthetical "(Plan, Implement-gate, Integrate, Test are out of scope for #109 — see follow-up issue.)".

Two changes:

(a) Remove the parenthetical line entirely.

(b) Add 4 new rows, AFTER the `replan` row, BEFORE the (now-removed) parenthetical. Use the reconciled tag inventory from Step 2. Default tag set (verified against recon):

| Step | `codex_reviews: true` | `codex_reviews: false` |
|---|---|---|
| `plan` | `quality-claude`, `scope-claude`, `spec-claude`, `security-claude`, `goal-traceability-claude`, `test-coverage-claude`, `silent-failure-claude`, `quality-codex`, `scope-codex`, `spec-codex`, `security-codex`, `goal-traceability-codex`, `test-coverage-codex`, `silent-failure-codex` | `quality-claude`, `scope-claude`, `spec-claude`, `security-claude`, `goal-traceability-claude`, `test-coverage-claude`, `silent-failure-claude` |
| `implement-gate` | `implement-gate-claude`, `implement-gate-codex` | `implement-gate-claude` |
| `integrate` | `integration-claude`, `security-integration-claude`, `integration-codex`, `security-integration-codex` | `integration-claude`, `security-integration-claude` |
| `test` | `spec-claude`, `code-quality-claude`, `goal-traceability-claude`, `spec-codex`, `code-quality-codex`, `goal-traceability-codex` | `spec-claude`, `code-quality-claude`, `goal-traceability-claude` |

If Step 2 reconciliation surfaced different tag names, use the dispatcher's actual values.

After edit, verify:

Run: `grep -c '^| ' skills/reviewer-protocol/SKILL.md`

Expected: at least 12 + N (where N is the original matrix-table separator and routing-table residue lines, if any). The exact count matters less than the qualitative confirmation that 4 new rows landed.

Run: `grep -nE 'out of scope for #109|see follow-up issue' skills/reviewer-protocol/SKILL.md ; echo done`

Expected: only `done`.

- [ ] **Step 5: Remove `## Legacy Disk-Write Contract (deferred reviewers)` section**

This is the largest deletion — ~lines 160–202, the full section from the heading down to (but not including) the next `## ...` heading.

Use Edit tool. The section runs from the heading line through the line immediately before `## Per-Finding Disk-Write Contract`.

Strategy: Edit by replacing the full section body (heading + content) with an empty string. If the section is too large for a single Edit call's old-string match, split into 2–3 sequential Edits — first delete the body paragraphs, then delete the heading.

After edit, verify:

Run: `grep -nE '## Legacy Disk-Write Contract' skills/reviewer-protocol/SKILL.md ; echo done`

Expected: only `done`.

Run: `grep -nE 'round-NN-\{reviewer-tag\}\.md|round-NN-\{tag\}\.md' skills/reviewer-protocol/SKILL.md ; echo done`

Expected: only `done` (no residual legacy filename references).

- [ ] **Step 6: Rename per-finding section header + update intro sentence**

Find the line `## Per-Finding Disk-Write Contract (#109 reviewers)` (currently line ~204).

Edit. Old string (one line):

```
## Per-Finding Disk-Write Contract (#109 reviewers)
```

New string (one line):

```
## Per-Finding Disk-Write Contract
```

Then find the line that opens this section's body (currently line ~206):

```
Reviewer subagents tagged `quality-claude`, `scope-claude`, `quality-codex`, or `scope-codex` use this per-finding contract (see `## Reviewer-Tag Routing Table` above).
```

Old string (one line):

```
Reviewer subagents tagged `quality-claude`, `scope-claude`, `quality-codex`, or `scope-codex` use this per-finding contract (see `## Reviewer-Tag Routing Table` above).
```

New string (one line):

```
All reviewer subagents use this per-finding contract — there is no bifurcation, and no per-tag routing.
```

After edit, verify:

Run: `grep -nE '\(#109 reviewers\)|Routing Table' skills/reviewer-protocol/SKILL.md ; echo done`

Expected: only `done`.

- [ ] **Step 7: Final cross-section grep — verify no transitional language remains**

Run: `grep -nE '#109 migration window|deferred reviewers|reviewer protocol bifurcates|out of scope for #109|see follow-up issue' skills/reviewer-protocol/SKILL.md ; echo done`

Expected: only `done`.

If any match remains, find and remove (or rewrite, if it's a legitimate historical mention in a different section that doesn't claim current truth).

- [ ] **Step 8: Commit**

Write commit message to `/tmp/cm-125-task3-protocol.txt`:

```
refactor(reviewer-protocol): #125 collapse bifurcation to single per-finding contract

  - Removes `## Reviewer-Tag Routing Table` section entirely.
  - Extends `## Expected-Reviewer Matrix` from 8 step rows to 12, adding
    plan, implement-gate, integrate, test with their full reviewer-tag
    sets (reconciled against dispatcher SKILLs). Drops the
    "out of scope for #109" parenthetical.
  - Removes `## Legacy Disk-Write Contract (deferred reviewers)` section
    entirely.
  - Renames `## Per-Finding Disk-Write Contract (#109 reviewers)` to
    `## Per-Finding Disk-Write Contract`. Updates the section's intro
    sentence to name this as the universal contract for all reviewer
    tags (no bifurcation, no per-tag routing).

Note: third of four logical commits in PR #125's atomic cutover.
PR squash-merges into one cutover on main per spec §2.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
```

Then run:

```
git add skills/reviewer-protocol/SKILL.md
git commit -F /tmp/cm-125-task3-protocol.txt
```

Expected: 1 file changed.

---

## Task 4: Extend tests + add legacy-pattern guard

**Files:**
- Modify: `tests/unit/test-per-finding-file-emission.bats` (remove skip block, extend assertions)
- Create: `tests/unit/test-no-legacy-disk-write-references.bats` (new file, ~30 lines, 3 grep guard assertions)

**Verification of spec §6 scope:** The spec lists 4 tests as candidates for extension. Recon found only `test-per-finding-file-emission.bats` carries an explicit `#125` skip block; the other 3 (`test-clean-sentinel-and-schema-guard.bats`, `test-change-type-partition.bats`, `test-failure-menu.bats`) have universal assertions that don't need editing. Confirm this with one grep before scoping the work.

- [ ] **Step 1: Verify which tests carry `#125` references**

Run: `grep -lE '#125|125\)' tests/unit/test-per-finding-file-emission.bats tests/unit/test-clean-sentinel-and-schema-guard.bats tests/unit/test-change-type-partition.bats tests/unit/test-failure-menu.bats`

Expected: only `tests/unit/test-per-finding-file-emission.bats`. If any other file matches, read it and assess whether the match is a real skip block requiring removal — if so, extend this Task with additional steps.

- [ ] **Step 2: Read `tests/unit/test-per-finding-file-emission.bats` in full**

Note the structure:
- Header comment block (lines 1–6) — references "follow-up issue (#125)"
- Setup section with `deferred_files=()` array (lines 13–31)
- 14-reviewer `#109-scope` per-finding assertion tests (lines ~35–83)
- The deferred-reviewer skip test (lines ~85–100)

- [ ] **Step 3: Edit `test-per-finding-file-emission.bats` — remove skip block + adjust header**

Three edits in sequence:

(a) Edit header comment (lines ~4–6). Old string:

```
# Deferred reviewers are skipped per the follow-up issue (see body comment).
# When the follow-up issue (#125) lands, extend this test to
# cover the deferred reviewers too.
```

New string: empty (delete the comment).

(b) Edit `deferred_files=()` array (lines ~13–31). Old string: the entire `deferred_files=(...)` block. New string: empty (delete it).

(c) Edit the deferred-reviewer skip test (lines ~85–100). Old string: the full `@test "deferred reviewer agent files remain on the legacy contract..." { ... }` block. New string: empty (delete the test).

- [ ] **Step 4: Edit `test-per-finding-file-emission.bats` — extend the 3 existing #109-scope assertions**

The existing tests iterate over the 14 #109-migrated reviewer agent files. Extend each to also check the 18 newly-migrated reviewers, with two acceptable patterns per agent: (a) inline per-finding reference (existing #109 pattern), or (b) protocol-deferral language (the 15 deferred agents that defer to the protocol skill).

Replace the 14-element array with the full 32-element set. Find the existing `migrated_files=(...)` array (or equivalent — name varies; recon called it the "14 #109-scope reviewers" set). After the rename to `all_reviewer_files=(...)`, the array contents are:

```bash
all_reviewer_files=(
  # 14 #109-migrated (already pass with inline per-finding refs)
  agents/qrspi-goals-reviewer.md
  agents/qrspi-goals-scope-reviewer.md
  agents/qrspi-questions-reviewer.md
  agents/qrspi-research-reviewer.md
  agents/qrspi-design-reviewer.md
  agents/qrspi-design-scope-reviewer.md
  agents/qrspi-phasing-reviewer.md
  agents/qrspi-phasing-scope-reviewer.md
  agents/qrspi-structure-reviewer.md
  agents/qrspi-structure-scope-reviewer.md
  agents/qrspi-parallelize-reviewer.md
  agents/qrspi-parallelize-scope-reviewer.md
  agents/qrspi-replan-reviewer.md
  agents/qrspi-replan-scope-reviewer.md
  # 18 #125-migrated (this PR)
  agents/qrspi-plan-reviewer.md
  agents/qrspi-plan-scope-reviewer.md
  agents/qrspi-plan-spec-reviewer.md
  agents/qrspi-plan-security-reviewer.md
  agents/qrspi-plan-silent-failure-hunter.md
  agents/qrspi-plan-goal-traceability-reviewer.md
  agents/qrspi-plan-test-coverage-reviewer.md
  agents/qrspi-spec-reviewer.md
  agents/qrspi-code-quality-reviewer.md
  agents/qrspi-security-reviewer.md
  agents/qrspi-silent-failure-hunter.md
  agents/qrspi-goal-traceability-reviewer.md
  agents/qrspi-test-coverage-reviewer.md
  agents/qrspi-type-design-analyzer.md
  agents/qrspi-code-simplifier.md
  agents/qrspi-implement-gate-reviewer.md
  agents/qrspi-integration-reviewer.md
  agents/qrspi-security-integration-reviewer.md
)
```

(If the actual reviewer set differs from recon, use what's on disk — `ls agents/qrspi-*reviewer.md agents/qrspi-*hunter*.md agents/qrspi-*analyzer*.md agents/qrspi-code-simplifier.md` is authoritative.)

For each of the 3 existing assertion tests (per-finding-emission, clean-sentinel, no-legacy-Write), update the assertion body to:
1. For each agent file in `all_reviewer_files`:
2. Read the body (`awk '/^---$/{n++; next} n>=2{print}' "$f"`)
3. Accept if EITHER:
   - The body matches the per-finding pattern (`finding-F[0-9]+\.md` or similar inline reference), OR
   - The body matches the protocol-deferral pattern (`disk-write contract from the reviewer-protocol skill` or similar deferral phrase)
4. Fail if neither matches — that means the agent file lacks both inline contract prose AND a protocol redirect, which means the cutover is incomplete.

Concrete bash assertion shape:

```bash
@test "every reviewer agent body references either inline per-finding emission or protocol deferral" {
  for f in "${all_reviewer_files[@]}"; do
    [[ -f "$f" ]] || { echo "missing: $f"; return 1; }
    local body
    body=$(awk '/^---$/{n++; next} n>=2{print}' "$f")
    if echo "$body" | grep -qE 'finding-F[0-9]+\.md'; then
      continue   # inline per-finding ref present
    fi
    if echo "$body" | grep -qF 'disk-write contract from the reviewer-protocol skill'; then
      continue   # protocol deferral present
    fi
    echo "$f has neither inline per-finding ref nor protocol-deferral language"
    return 1
  done
}
```

Apply the same accept-either-pattern logic to the clean-sentinel and no-legacy-Write existing assertions where the spec calls for them. The exact assertion bodies depend on the test's current shape — read the file and adapt; the principle is "extend over all 32 reviewers, accept either inline-ref or protocol-deferral."

- [ ] **Step 5: Run extended test in isolation**

Run: `bats tests/unit/test-per-finding-file-emission.bats`

Expected: all assertions pass. If any fail:
- Inspect the failing agent file's body
- Either the body genuinely lacks both patterns (a Task 1 bug — fix the agent file), OR the assertion regex is too strict (refine the regex)

- [ ] **Step 6: Create `tests/unit/test-no-legacy-disk-write-references.bats`**

Use Write tool. Full file content:

```bash
#!/usr/bin/env bats

# Grep guards for the deferred-reviewer migration cutover (#125).
# Asserts the post-cutover state: no agent or skill file references
# the legacy single-file `round-NN-{tag}.md` path pattern, and
# `skills/reviewer-protocol/SKILL.md` carries no Reviewer-Tag Routing
# Table or Legacy Disk-Write Contract section.

@test "no agent or skill file references the legacy round-NN-{tag}.md path pattern" {
  local offenders
  offenders=$(grep -rE 'round-NN-[a-z][a-z0-9-]*\.md' agents/ skills/ \
    || true)
  if [ -n "$offenders" ]; then
    echo "legacy single-file path references remain:"
    echo "$offenders"
    return 1
  fi
}

@test "reviewer-protocol skill carries no Legacy Disk-Write Contract section" {
  ! grep -qE '^## Legacy Disk-Write Contract' skills/reviewer-protocol/SKILL.md
}

@test "reviewer-protocol skill carries no Reviewer-Tag Routing Table" {
  ! grep -qE '^## Reviewer-Tag Routing Table' skills/reviewer-protocol/SKILL.md
}
```

Note the first assertion does NOT exclude `reviewer-protocol/SKILL.md` (unlike the spec §6 sketch) — by Task 3 the legacy section is fully removed, so the protocol skill should also be free of legacy path patterns. If a residual mention persists in the protocol skill (e.g., a paragraph cross-referencing the now-removed section), Task 3 missed it; fail loud.

- [ ] **Step 7: Run the new test in isolation**

Run: `bats tests/unit/test-no-legacy-disk-write-references.bats`

Expected: 3/3 pass. If any assertion fails:
- Assertion 1 fail → grep output shows where legacy patterns remain. Trace back to which Task missed the site (likely Task 2 or 3) and fix.
- Assertion 2 or 3 fail → Task 3 didn't fully remove the named section. Re-edit the protocol skill.

- [ ] **Step 8: Run full bats suite — first PR-tip green checkpoint**

Run: `bats tests/unit/`

Expected: all tests in this PR's edit scope pass. Pre-existing failures unrelated to this PR (recon noted the parent commit had pre-existing fails in settings-installer + using-qrspi-doc-contract suites; verify the PR doesn't regress those by comparing fail counts to a clean main checkout).

If new failures appear that are not on the parent's pre-existing list:
- Inspect each — likely a cascade from Tasks 1–3
- Fix the underlying issue in the relevant prior task's edits (do NOT amend; create a follow-up commit on this PR)
- Re-run bats

- [ ] **Step 9: Commit**

Write commit message to `/tmp/cm-125-task4-tests.txt`:

```
test: #125 extend per-finding tests to all 32 reviewers + add legacy-pattern guard

  - tests/unit/test-per-finding-file-emission.bats: removes the
    #125 deferred-reviewer skip block (header comment, deferred_files
    array, deferred-reviewer skip test). Extends the 3 existing
    per-finding assertions to iterate over all 32 reviewer tags
    (14 #109-migrated + 18 newly-migrated). Each assertion accepts
    either inline per-finding contract prose OR
    protocol-deferral language ("disk-write contract from the
    reviewer-protocol skill"), since 15 of the 18 newly-migrated
    reviewers defer to the protocol rather than carrying inline prose.

  - tests/unit/test-no-legacy-disk-write-references.bats: NEW. Three
    grep guards: no agent/skill file references the legacy
    `round-NN-{tag}.md` pattern, and the reviewer-protocol skill
    carries no `## Legacy Disk-Write Contract` section or
    `## Reviewer-Tag Routing Table`. Catches future regression to
    the bifurcated state.

Note: fourth of four logical commits in PR #125's atomic cutover.
PR squash-merges into one cutover on main per spec §2.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
```

Then run:

```
git add tests/unit/test-per-finding-file-emission.bats tests/unit/test-no-legacy-disk-write-references.bats
git commit -F /tmp/cm-125-task4-tests.txt
```

Expected: 2 files changed (1 modify + 1 add).

---

## Task 5: Final verification + PR creation

**Files:**
- No code changes — verification + PR-creation only

- [ ] **Step 1: Final full-suite bats run**

Run: `bats tests/unit/`

Expected: all PR-scope tests pass. Capture the output for the PR description.

If any test in the PR-edit scope fails, return to the relevant earlier task and fix in a follow-up commit on this branch (do NOT amend).

- [ ] **Step 2: Cross-file legacy-pattern grep — final sanity check**

Run: `grep -rnE 'round-NN-[a-z][a-z0-9-]*\.md' agents/ skills/ docs/superpowers/specs/ ; echo done`

Expected: only matches inside `docs/superpowers/specs/` (historical spec text) plus only `done`. Any match in `agents/` or `skills/` is a missed site — fix it.

- [ ] **Step 3: Push branch + open PR**

Run: `git push -u origin qrspi-echo/issue-125-deferred-reviewer-cutover`

Then create the PR. Write the PR body to `/tmp/pr-spec-c-body.md`:

```
## Summary

v0.5 Spec C (deferred-reviewer-migration cutover) — migrates the remaining 18 reviewers from the legacy single-file disk-write contract to the per-finding contract, then collapses the reviewer-protocol bifurcation. Single atomic cutover (squash-merge required per spec §2).

Spec at `docs/superpowers/specs/2026-05-05-125-deferred-reviewer-migration-design.md`.

## Atomicity (squash-merge required)

The 4 commits in this PR produce intermediate states where the bats suite is intentionally inconsistent. The final state (PR-tip) is verified green. The PR MUST squash-merge to land as a single cutover commit on main.

**Why.** Plan-stage dispatches up to 7 reviewers in parallel. A mixed-contract round (some reviewers using legacy single-file output, some using per-finding) corrupts the apply-fix Expected-Reviewer Matrix schema-violation guard. The transition window must be one commit.

## Commits

1. `refactor(agents)` — 3 explicit-path agent files (implement-gate + 2 integration). The other 15 deferred reviewers defer to the protocol via existing language and need no edit.
2. `refactor(skills)` — Plan/Implement/Integrate/Test/Replan/using-qrspi switch from `Output file: ...round-NN-{tag}.md` to `Output directory: ...round-NN/`.
3. `refactor(reviewer-protocol)` — collapse the bifurcation: remove routing table + legacy contract section, extend matrix to 12 steps, rename per-finding header.
4. `test` — extend per-finding-emission test to all 32 reviewers + add legacy-pattern grep guard.

## Scope

- Pure prose-and-prompts edits across markdown files. No Python or shell logic changes.
- 18 deferred reviewers migrated; 0 net new reviewers, 0 reviewer renames (per spec §10 out-of-scope).
- New test file: `tests/unit/test-no-legacy-disk-write-references.bats`.

## Test plan

- [x] `bats tests/unit/test-per-finding-file-emission.bats` — pass after extension
- [x] `bats tests/unit/test-no-legacy-disk-write-references.bats` — 3/3 pass
- [x] `bats tests/unit/` — no regressions vs. parent commit's pre-existing fail set
- [x] Final cross-file grep: zero `round-NN-{tag}.md` references in `agents/` or `skills/`

## In-flight artifact dirs (per spec §9)

A `reviews/{step}/` directory authored before cutover contains legacy `round-NN-{tag}.md` files. After cutover, new rounds in the same artifact dir create `round-NN+1/` per-finding directories. Reading older legacy rounds is not affected — they remain on disk untouched. The apply-fix protocol only reads the most recent round.

A user rebasing a review-round branch onto the cutover commit must restart the in-flight review round from scratch (a fresh round on the new contract). Mid-round files cannot mix contracts.

## Closes

- Closes #125

🤖 Generated with [Claude Code](https://claude.com/claude-code)
```

Then run:

```
gh pr create --title "v0.5 #125: deferred-reviewer migration cutover" --body-file /tmp/pr-spec-c-body.md
```

Expected: PR URL printed. Capture the URL.

- [ ] **Step 4: Mark merge as squash-only**

After PR creation, set merge method to squash for this PR (if the repo's default is not already squash). The atomicity constraint is non-negotiable.

Run: `gh pr view <PR-URL>` and confirm the auto-merge / mergeable settings allow squash. The repo's default merge method is squash (per memory: prior v0.5 PRs all squash-merged), so usually no action needed — but verify.

---

## Self-Review (run before declaring plan done)

**1. Spec coverage check.** Walk spec §1–§11 and verify every requirement maps to a task:

| Spec section | Task |
|---|---|
| §2 Atomicity constraint | Header + Task 5 squash-merge note + every commit message |
| §3.1 18 deferred reviewers list | Task 1 (3 files) + recon shows 15 are no-ops |
| §3.2 Per-agent edit shape | Task 1 step 2/3/4 |
| §4.1 Bifurcation collapse | Task 3 |
| §4.2 Expected-Reviewer Matrix extension | Task 3 step 4 |
| §5 Dispatching-SKILL updates | Task 2 |
| §6 Test updates (4 tests) | Task 4 step 1 verification + Task 4 step 4 extension |
| §6 New test grep guard | Task 4 step 6 |
| §7 Sequence (4 commits) | Tasks 1, 2, 3, 4 |
| §8 Test plan | Task 5 step 1 + step 2 |
| §9 Backwards compat | PR body in Task 5 step 3 |
| §10 Out of scope | PR body |
| §11 Closes #125 | PR body |

All sections covered. ✓

**2. Placeholder scan.** Search the plan for "TBD", "TODO", "implement later", "fill in details", "add appropriate error handling", "Similar to Task N" patterns. Result: none found. ✓

**3. Type consistency.** Reviewer-tag names referenced in Tasks 1, 2, 3, 4 all match: `quality-claude`, `scope-claude`, `quality-codex`, `scope-codex` for #109; the 18 newly-migrated tags match recon's dispatcher inventory. The agent file paths in Task 4's `all_reviewer_files` array match Task 1's affected files + the 15 deferring agents from recon. ✓

**4. Authoritative-source flagging.** The plan flags two reconciliation points where the implementer must trust the actual filesystem over the plan's tables: (a) Task 3 step 2 reconciles tag inventory against dispatcher SKILLs; (b) Task 4 step 4 trusts `ls agents/qrspi-*` over the listed array if they diverge. ✓

**5. Atomicity discipline.** Every commit message in Tasks 1–4 includes the "intentionally inconsistent intermediate state" note. The PR body in Task 5 enforces squash-merge. ✓
