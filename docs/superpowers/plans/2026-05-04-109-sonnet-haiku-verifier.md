# Issue #109 — Sonnet→Haiku Confidence Verifier Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Insert a Haiku-class confidence verifier between QRSPI's artifact-level reviewer subagents and the orchestrator's apply/pause dispatch, so style/clarity/correctness findings that score <80 against the verbatim `/code-review` 0–100 rubric are filtered before they reach the apply path. Scope/intent findings are NEVER score-filtered.

**Architecture:** Reviewers emit one finding per file under `reviews/{step}/round-NN/<reviewer_tag>.finding-F<NN>.md`; main chat dispatches one Haiku verifier (`agents/qrspi-finding-verifier.md`) per finding-file in parallel; each Haiku writes a sidecar `.score.yml` next to the finding (never mutates the original); main chat Bash-assembles findings + sidecars + clean markers into `round-NN-verified.md` it reads exactly once before partitioning by `change_type`.

**Tech Stack:** Existing QRSPI agent-file infrastructure (per #110), `scripts/codex-companion-bg.sh` async pipeline (extended with a finding-boundary splitter), Bash assembly with no-stdout redirects, `Read`/`Write` tools, bats tests.

**Spec:** `docs/superpowers/specs/2026-05-04-109-sonnet-haiku-verifier-design.md` — converged after 15 review rounds. The spec is the authoritative reference for the verifier rubric body, per-finding file shape, sidecar YAML schema, splitter contract, Apply-fix 10-step sequence, §3 failure menu, and pre-merge smoke matrix; this plan translates the spec's §7 migration sequence into bite-sized tasks but does NOT re-paste content the spec already documents.

**Branch:** `qrspi-echo/issue-109-sonnet-haiku-verifier` (HEAD `4e4dcf1`, 16 commits, PR not yet created). Spec itself already committed.

**Path convention.** The bash blocks below repeat the absolute path `/Users/dfrysinger/Library/CloudStorage/Dropbox/claude-workspace/qrspi-plus` for explicitness — that's where the qrspi-plus checkout lives on the user's workstation today. If the repo is cloned elsewhere, the implementer should set `REPO_ROOT="$(git -C <other-checkout> rev-parse --show-toplevel)"` once at the top of execution and substitute `$REPO_ROOT` for the hardcoded path everywhere it appears (the plan does not pre-substitute because the literal path is the user's actual workstation, and rewriting every block to use a variable would obscure the canonical paths).

**Prerequisite:** Issue #110 (`docs/superpowers/plans/2026-05-04-110-subagents-in-agent-files.md`) must merge to main before this plan's commits go out for review — #109 consumes the agent-file infrastructure, the `skills/reviewer-protocol/SKILL.md` skill, and the `scripts/codex-companion-bg.sh` stdin pipeline that #110 lands. Implementation work on #109 can begin on the post-#110 main; if #110 is still in flight when #109 starts, rebase #109's branch onto #110's branch as needed.

---

## File Structure

### New files

**Agent (1):**
- `agents/qrspi-finding-verifier.md` — Haiku verifier (model `haiku`, tools `[Read, Write]`).

**Script (1):**
- `scripts/codex-finding-splitter.sh` — Splits Codex stdout on `<<<FINDING-BOUNDARY>>>` into per-finding files; handles `NO_FINDINGS` sentinel; writes nothing on malformed/empty input.

**Bats tests (10 — per spec §5):**
- `tests/unit/test-verifier-agent-file.bats`
- `tests/unit/test-per-finding-file-emission.bats`
- `tests/unit/test-codex-splitter.bats`
- `tests/unit/test-verifier-dispatch-contract.bats`
- `tests/unit/test-failure-menu.bats`
- `tests/unit/test-verified-file-shape.bats`
- `tests/unit/test-config-verifier-enabled-field.bats`
- `tests/unit/test-disabled-mode-fallthrough.bats`
- `tests/unit/test-change-type-partition.bats`
- `tests/unit/test-clean-sentinel-and-schema-guard.bats`

**Test fixtures:**
- `tests/fixtures/issue-109/round-enabled-clean/` — populated `round-NN/` directory with mixed findings + sidecars + clean files (used by tests #6, #9).
- `tests/fixtures/issue-109/round-disabled-from-start/` — finding files only, no sidecars (used by tests #6, #8).
- `tests/fixtures/issue-109/codex-stdout/` — synthetic Codex stdout samples (boundary-delimited, NO_FINDINGS, malformed, empty) for test #3.
- `tests/fixtures/issue-109/menu-cases/{verify-failed,missing-codex-output,missing-claude-output,missing-sidecar}/round-NN/` — four abnormality-class fixtures backing test #5 (spec §5 explicitly: "Fixture covers each abnormality the menu handles (VERIFY_FAILED, missing reviewer output, missing sidecar)"). Each fixture is a populated `round-NN/` subdir exhibiting one abnormality.
- `tests/fixtures/issue-109/round-mixed-change-types/round-04/` — populated `round-NN/` directory with findings spanning all five `change_type` values (style, clarity, correctness, scope, intent) plus matching `.score.yml` sidecars; backs test #9 (spec §5: "Fixture verified.md with mixed `change_type`s + assertion of routing").
- `tests/fixtures/issue-109/round-missing-tag/round-05/` — round directory missing one expected tag's output (no `quality-codex.*` files); backs test #10's negative-fixture failure path (spec §5: "Negative fixtures assert the failure path").
- `tests/fixtures/issue-109/round-schema-violations/round-03/` — five per-file fixtures covering spec §1 step 2's schema-guard branches: malformed YAML frontmatter, missing required field, malformed `change_type` enum value, unrouted reviewer-tag, and trailing-newline malformation. The implementer wires these into a runtime parser test at commit-4 time; the bats prose-greps in `test-verifier-dispatch-contract.bats` pin the documented contract independent of these fixtures.

### Modified files (commit 4 — atomic cutover)

- `skills/reviewer-protocol/SKILL.md` — Add a Routing Table at the top, an Expected-Reviewer Matrix, rename the existing single-file disk-write contract to `## Legacy Disk-Write Contract (deferred reviewers)`, and add a new `## Per-Finding Disk-Write Contract (#109 reviewers)` alongside it. The bifurcation is removed in the deferred follow-up issue (filed in commit 0).
- `skills/using-qrspi/SKILL.md` — Replace the current Apply-fix protocol section with the 10-step verifier-aware sequence; add the §3 failure-menu logic; add the `verifier_enabled` field documentation to the Config-File schema (the field doc itself was added in commit 3 — this commit adds the runtime-backfill code that consumes it).
- 14 reviewer agent files in `agents/` — 8 artifact-quality reviewers + 6 scope reviewers per spec §1 ("Reviewer agent files (modifications)"):
  - Quality: `qrspi-{goals,questions,research,design,phasing,structure,parallelize,replan}-reviewer.md`
  - Scope: `qrspi-{goals,design,phasing,structure,parallelize,replan}-scope-reviewer.md`
- 8 dispatching skills — `skills/{goals,questions,research,design,phasing,structure,parallelize,replan}/SKILL.md`. Add the role-distinct `reviewer_tag` value, inject the per-finding-file format + `NO_FINDINGS` sentinel + `<<<FINDING-BOUNDARY>>>` delimiter into the Codex reviewer prompt with worked examples, and retire the legacy `output:` path argument.

### Modified files (commit 5)

- `docs/qrspi/CHANGELOG.md` — Verifier addition + follow-up-issue reference.

### Files NOT modified by #109 (deferred)

Per spec §1 "Files NOT modified by #109" and §6 "Out of scope":
- 5 plan-artifact reviewers, the unified plan-quality + plan-scope reviewers, 8 per-task implementation reviewers, the implement-gate reviewer, the security-integration reviewer, the integration-quality reviewer (18 reviewers total).
- The `skills/{plan,implement,integrate,test}/SKILL.md` dispatching skills.
- The plan-artifact `skills/plan/SKILL.md` reviewer dispatching code.

The follow-up issue migrates these atomically (so Plan never has mixed-contract rounds) and collapses the bifurcated `reviewer-protocol/SKILL.md` back to a single contract.

### Decomposition rationale

The spec's §7 migration sequence already establishes the file-structure plan: one purely-additive commit each for the verifier agent (commit 1), the splitter script (commit 2), and the config-doc field (commit 3); one atomic cutover commit that lands every runtime-behavior change at once (commit 4); one CHANGELOG commit (commit 5). The cutover MUST be atomic — splitting it would leave main with mixed-contract rounds that the schema-violation guard in apply-fix step 2 would reject. The pre-merge smoke matrix (§7 step 4) is a verification gate inside commit 4, not a separately-shippable step.

---

## Task 0: File the two follow-up issues (no commit)

**Files:** none modified locally — this task creates two GitHub issues and captures their numbers for downstream tasks.

**Spec reference:** §7 step 0 ("File the follow-up issue BEFORE any code commits"), §6 (out-of-scope reviewer set), §1 ("Files NOT modified by #109").

Two follow-up issues are filed before any code commits: (1) the deferred-reviewer migration tracker (used by commit 1's test #2 deferred-reviewer skip-comment, the bifurcated-protocol Routing Table prose, the CHANGELOG, and the PR body), and (2) the smoke-matrix end-to-end-coverage tracker (records the deliberate narrowing where commit-4 cases (e)/(f)/(g) are pinned by the unit suite rather than executed as real review rounds — see Task 5 step 15).

- [ ] **Step 1: Confirm the issue title and body**

The follow-up issue migrates the 18 deferred reviewers (5 plan-artifact + unified plan quality/scope + 8 per-task + implement-gate + security-integration + integration-quality) atomically and collapses `skills/reviewer-protocol/SKILL.md` back to a single per-finding contract.

Title: `Migrate deferred reviewers to per-finding emission + collapse reviewer-protocol bifurcation`

Body (paste verbatim — references the spec by stable path, NOT by merged-commit file paths, so the link survives any future repo reorganization):

```markdown
Tracks the deferred reviewer migration scoped out of #109.

#109 migrates only the 14 artifact-level reviewers (8 quality + 6 scope) for `goals/questions/research/design/phasing/structure/parallelize/replan`. The remaining 18 reviewers — 5 plan-artifact, unified plan quality/scope, 8 per-task, implement-gate, security-integration, integration-quality — must migrate atomically (in a single cutover commit) so the Plan step never has mixed-contract rounds.

When this issue lands, the bifurcated reviewer-protocol skill (currently carrying both `## Legacy Disk-Write Contract` and `## Per-Finding Disk-Write Contract` sections per #109) collapses back to a single per-finding contract. The Routing Table and Expected-Reviewer Matrix added in #109 stay; only the Legacy section is removed.

Source spec: `docs/superpowers/specs/2026-05-04-109-sonnet-haiku-verifier-design.md` §6 ("Out of scope") + §1 ("Files NOT modified by #109").

Tests #2, #4, #6, and #10 in `tests/unit/` (added by #109) currently skip the deferred reviewers with a comment citing this issue number. When this issue lands, those tests must extend to cover the migrated reviewers as well.
```

- [ ] **Step 2: File the issue and capture the number**

```bash
gh issue create \
  --repo dfrysinger/qrspi-plus \
  --title "Migrate deferred reviewers to per-finding emission + collapse reviewer-protocol bifurcation" \
  --body-file /tmp/issue-109-followup-body.md
```

(Write the body block above to `/tmp/issue-109-followup-body.md` first.) Capture the issue number reported by `gh issue create` (e.g. `#127`) — it must be used inside the deferred-reviewer skip-comment in test #2 (Task 5 step 7).

- [ ] **Step 3: Record the issue number for the rest of the plan**

Write the integer issue number (no `#`) to `/tmp/issue-109-followup-num.txt` so subsequent tasks can substitute it without re-asking GitHub:

```bash
gh issue list --repo dfrysinger/qrspi-plus --search "Migrate deferred reviewers to per-finding emission" --json number --jq '.[0].number' > /tmp/issue-109-followup-num.txt
```

Verify:

```bash
cat /tmp/issue-109-followup-num.txt
```
Expected: a positive integer on a single line.

- [ ] **Step 4: File the smoke-matrix end-to-end coverage follow-up issue**

Body (write to `/tmp/issue-109-smoke-followup-body.md`):

```markdown
Tracks the deferred end-to-end smoke coverage for #109's commit-4 cutover.

#109 commit 4 lands the Sonnet→Haiku confidence verifier. Spec §7 step 4 enumerates a 7-case pre-merge smoke matrix; cases (a)–(d) are real review rounds, but cases (e) (splitter malformed input), (f) (VERIFY_FAILED → skip), and (g) (VERIFY_FAILED → retry) are pinned by the unit suite rather than executed as real review rounds. The narrowing is documented at the top of #109's plan Task 5 step 15.

End-to-end coverage of (e)/(f)/(g) requires either:
- Adding a `QRSPI_CODEX_STDOUT_OVERRIDE` (or equivalent) env-hook to `scripts/codex-companion-bg.sh launch` so a fixture stdout file can replace the live Codex call (out of scope for #109's atomic cutover — wrapper not in commit 4's file inventory).
- Adding a deterministic verifier-failure stub agent file (e.g. `agents/qrspi-finding-verifier-stub-fail.md`) and a synchronization point in the Apply-fix protocol that lets the smoke harness swap the agent atomically between the menu render and the retry dispatch.

Source spec: `docs/superpowers/specs/2026-05-04-109-sonnet-haiku-verifier-design.md` §7 step 4 (smoke matrix).

When this issue lands, the unit-test equivalence in #109's plan Task 5 step 15 should be replaced with real review-round invocations for cases (e)/(f)/(g).
```

```bash
gh issue create \
  --repo dfrysinger/qrspi-plus \
  --title "Smoke-matrix end-to-end coverage for #109 cutover failure paths (e)/(f)/(g)" \
  --body-file /tmp/issue-109-smoke-followup-body.md
```

- [ ] **Step 5: Capture the smoke follow-up issue number**

```bash
gh issue list --repo dfrysinger/qrspi-plus --search "Smoke-matrix end-to-end coverage" --json number --jq '.[0].number' > /tmp/issue-109-smoke-followup-num.txt
cat /tmp/issue-109-smoke-followup-num.txt
```
Expected: a positive integer on a single line.

This task does NOT commit anything — it only creates two tracking issues. The first code commit is Task 1.

---

## Task 1: Add the Haiku verifier agent file (commit 1)

**Files:**
- Create: `agents/qrspi-finding-verifier.md`
- Create: `tests/unit/test-verifier-agent-file.bats`

**Spec reference:** §1 (`agents/qrspi-finding-verifier.md` (new)), §5 test #1, §7 step 1.

- [ ] **Step 1: Read the `/code-review` rubric source**

Use the `Read` tool against:

```
~/.claude/plugins/cache/claude-plugins-official/code-review/unknown/commands/code-review.md
```

If the local plugin cache is missing on this workstation (the path resolves under `$HOME/.claude/plugins/cache/`; older shells may not have it), fall back to fetching the file from its canonical source via `gh api repos/anthropics/claude-plugins-official/contents/code-review/commands/code-review.md --jq .content | base64 -d` and Read the result.

Locate the step-5 anchor block (verbatim "give this rubric to the agent verbatim" prefix language plus the 0/25/50/75/100 anchor definitions a/b/c/d/e). The verifier body must include this block byte-for-byte. Also locate the step-4–5 false-positive list — the verifier body adapts that list and augments it with the three QRSPI-specific entries from spec §1 ("Pre-existing issues", "altitude mismatches", etc.).

- [ ] **Step 2: Create `agents/qrspi-finding-verifier.md`**

Write the file with the frontmatter from spec §1 verbatim:

```yaml
---
name: qrspi-finding-verifier
model: haiku
tools: [Read, Write]
description: "Score a single reviewer finding 0–100 against the /code-review confidence rubric. Read the per-finding file + artifact + lazy-Read upstreams; Write a sidecar score file; return a brief <reviewer_tag>.<finding_id>: <score> line."
---
```

…followed by the body sections in this order, all sourced from spec §1:

1. **`## Rubric`** — verbatim copy of `/code-review` step 5's "give this rubric to the agent verbatim" prefix language plus the 0/25/50/75/100 anchor definitions (a/b/c/d/e). Anchors are reference points on the continuous 0–100 scale; the verifier emits any integer in `0..100`.
2. **`## False-positive examples`** — the seven adapted entries from spec §1 (pre-existing issues, pedantic nitpicks, linter/typechecker-catchable, general code-quality not in CLAUDE.md or upstream artifacts, CLAUDE.md silenced issues, real-but-unmodified-line issues, plus the three QRSPI augmentations: altitude mismatches, "X is missing" where X is in the artifact, findings contradicting `feedback/*.md`).
3. **`## Input contract`** — the five prompt parameters (`<finding_file_path>`, `<sidecar_path>`, `<artifact_path>`, `<diff_file_path>`, `<upstream_paths>`) with the spec-§1 descriptions including the verbatim sidecar-path-construction rule (`<finding_file_path>` with `.md` → `.score.yml`) and the rationale (avoid `*.finding-*.md` glob conflicts; YAML highlighting).
4. **`## Procedure`** — the 7-step procedure from spec §1 verbatim (Read finding → Read artifact + diff → Read referenced_files → lazy-Read upstreams → score → Write sidecar (success or VERIFY_FAILED form) → return brief).
5. **Final paragraph (verbatim from spec §1):** "The verifier never edits the finding file — only ever writes a sibling sidecar. This eliminates the entire 'verifier mutates source-of-truth' hazard surface (no preserve guard, no checksum snapshot, no boundary sentinel needed)."

The brief-return shape is `<reviewer_tag>.<finding_id>: <score>` (e.g. `quality-claude.R3-F02: 87`) on success or `<reviewer_tag>.<finding_id>: VERIFY_FAILED:<reason>` on failure.

- [ ] **Step 3: Write the failing bats test `tests/unit/test-verifier-agent-file.bats`**

```bash
#!/usr/bin/env bats

@test "verifier agent file exists" {
  [ -f agents/qrspi-finding-verifier.md ]
}

@test "frontmatter declares model: haiku" {
  awk '/^---$/{n++; next} n==1{print}' agents/qrspi-finding-verifier.md \
    | grep -qE '^model:\s*haiku'
}

@test "frontmatter declares tools: [Read, Write]" {
  awk '/^---$/{n++; next} n==1{print}' agents/qrspi-finding-verifier.md \
    | grep -qE '^tools:\s*\[\s*Read\s*,\s*Write\s*\]'
}

@test "body cites the 0/25/50/75/100 anchors verbatim" {
  local body
  body=$(awk '/^---$/{n++; next} n>=2{print}' agents/qrspi-finding-verifier.md)
  for anchor in 0 25 50 75 100; do
    echo "$body" | grep -qE "(^|[^0-9])${anchor}([^0-9]|$)" \
      || { echo "missing anchor $anchor"; return 1; }
  done
}

@test "body describes the 0–100 scale as continuous" {
  awk '/^---$/{n++; next} n>=2{print}' agents/qrspi-finding-verifier.md \
    | grep -qE 'continuous (0|0-|0–)100|integer in 0\.\.100|any integer in'
}

@test "sidecar path construction rule is documented (.md -> .score.yml)" {
  awk '/^---$/{n++; next} n>=2{print}' agents/qrspi-finding-verifier.md \
    | grep -qE '\.md.*->.*\.score\.yml|\.md.*→.*\.score\.yml|replacing .* \.md.*\.score\.yml'
}

@test "brief-return shape is <reviewer_tag>.<finding_id>: <int>" {
  local body
  body=$(awk '/^---$/{n++; next} n>=2{print}' agents/qrspi-finding-verifier.md)
  echo "$body" | grep -qF '<reviewer_tag>.<finding_id>:' \
    && (echo "$body" | grep -qE 'VERIFY_FAILED' )
}

@test "false-positive list includes the three QRSPI-specific entries" {
  local body
  body=$(awk '/^---$/{n++; next} n>=2{print}' agents/qrspi-finding-verifier.md)
  echo "$body" | grep -qiE 'altitude mismatch'
  echo "$body" | grep -qF 'feedback/'
  # "X is missing" where X is in the artifact
  echo "$body" | grep -qiE "is missing|missing.*where"
}
```

- [ ] **Step 4: Run the test, expect green**

```bash
bats tests/unit/test-verifier-agent-file.bats
```
Expected: 8 tests pass. (If a test fails, edit the agent file body to satisfy the contract — do NOT loosen the test.)

- [ ] **Step 5: Run the full unit suite to confirm no regressions**

```bash
bats tests/unit/
```
Expected: green. The new agent file is purely additive — nothing dispatches to it yet.

- [ ] **Step 6: Commit**

Write the commit message to `/tmp/commit-msg-109-c01.txt`:

```
feat(verifier-agent): #109 add Haiku confidence verifier agent file (commit 1/5)

Adds agents/qrspi-finding-verifier.md per spec §1. Frontmatter declares
model: haiku and tools: [Read, Write]. Body carries the verbatim 0/25/50/75/100
rubric from /code-review step 5, the false-positive list adapted for QRSPI,
the input contract (finding/sidecar/artifact/diff/upstream paths), and the
7-step procedure including the success and VERIFY_FAILED sidecar shapes.

The agent is purely additive in this commit — nothing dispatches to it
until commit 4 lands the Apply-fix protocol revision in using-qrspi.

Tests: tests/unit/test-verifier-agent-file.bats.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
```

```bash
git -C /Users/dfrysinger/Library/CloudStorage/Dropbox/claude-workspace/qrspi-plus add agents/qrspi-finding-verifier.md tests/unit/test-verifier-agent-file.bats
git -C /Users/dfrysinger/Library/CloudStorage/Dropbox/claude-workspace/qrspi-plus commit -F /tmp/commit-msg-109-c01.txt
```

---

## Task 2: Add the Codex finding-boundary splitter (commit 2)

**Files:**
- Create: `scripts/codex-finding-splitter.sh`
- Create: `tests/unit/test-codex-splitter.bats` (NARROWED — splitter-only, does NOT grep dispatching skill prompts; that grep is added in Task 5)
- Create: `tests/fixtures/issue-109/codex-stdout/{boundary-delimited,no-findings,malformed,empty}.txt`

**Spec reference:** §1 (`scripts/codex-finding-splitter.sh` (new)), §5 test #3, §7 step 2.

- [ ] **Step 1: Create the script directory entry and write the splitter**

```bash
touch scripts/codex-finding-splitter.sh
chmod +x scripts/codex-finding-splitter.sh
```

Script body — enforce the spec §1 contract:
- Args: `<stdout-path> <round-subdir> <reviewer_tag>`.
- Read `<stdout-path>`. If it equals the literal `NO_FINDINGS` (after a single trailing-newline strip), write `<round-subdir>/<reviewer_tag>.clean.md` (frontmatter-only body: `reviewer:`, `round:`, `findings: 0`) and exit 0.
- Else split on lines that match exactly `<<<FINDING-BOUNDARY>>>`. Discard anything before the first boundary. Each segment between boundaries → `<round-subdir>/<reviewer_tag>.finding-F<NN>.md`, NN zero-padded (`F01`, `F02`, …) in encounter order.
- If no boundaries AND not `NO_FINDINGS` (or stdin empty): write nothing to `<round-subdir>`, print a one-line diagnostic to stderr (`splitter: malformed input — no <<<FINDING-BOUNDARY>>> and no NO_FINDINGS sentinel`), exit non-zero.
- Idempotent on success: re-running the splitter against the same stdout-path overwrites the per-finding files but does not duplicate them. (The `NN` numbering is deterministic from segment order in the input.)

Concrete shape:

```bash
#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 3 ]]; then
  echo "usage: codex-finding-splitter.sh <stdout-path> <round-subdir> <reviewer_tag>" >&2
  exit 2
fi

stdout_path=$1
round_subdir=$2
tag=$3

if [[ ! -d "$round_subdir" ]]; then
  echo "splitter: round subdir does not exist: $round_subdir" >&2
  exit 2
fi

# Round-subdir basename must match the canonical round-NN convention so the
# NO_FINDINGS branch's `basename | sed 's/round-//'` extraction yields a real
# integer. Test fixtures bypass this with a different mktemp basename — those
# tests never inspect the extracted round value, so the assertion is gated on
# basename starting with `round-`.
round_basename=$(basename "$round_subdir")
case "$round_basename" in
  round-[0-9]*) round_field=${round_basename#round-} ;;
  *)            round_field=$round_basename ;;   # tolerated for fixtures
esac

# Detect the NO_FINDINGS sentinel by exact-byte comparison: the file must
# contain either the literal string "NO_FINDINGS" or "NO_FINDINGS\n" — nothing
# else. Using $(<"$stdout_path") would strip ALL trailing newlines via command
# substitution semantics, accepting "NO_FINDINGS\n\n…" as a sentinel match,
# which is too permissive. Use cmp/wc instead.
size=$(wc -c < "$stdout_path" | tr -d ' ')
if { [[ "$size" -eq 11 ]] && [[ "$(head -c 11 "$stdout_path")" == "NO_FINDINGS" ]]; } \
   || { [[ "$size" -eq 12 ]] && [[ "$(head -c 12 "$stdout_path")" == $'NO_FINDINGS\n' ]]; }; then
  cat > "$round_subdir/${tag}.clean.md" <<EOF
---
reviewer: ${tag}
round: ${round_field}
findings: 0
---
EOF
  exit 0
fi

# Empty input → malformed.
if [[ "$size" -eq 0 ]] || { [[ "$size" -eq 1 ]] && [[ "$(head -c 1 "$stdout_path")" == $'\n' ]]; }; then
  echo "splitter: malformed input — empty stdout" >&2
  exit 1
fi

# Count boundaries. If zero, malformed (and not NO_FINDINGS).
if ! grep -qxF '<<<FINDING-BOUNDARY>>>' "$stdout_path"; then
  echo "splitter: malformed input — no <<<FINDING-BOUNDARY>>> and no NO_FINDINGS sentinel" >&2
  exit 1
fi

# Split. awk pulls each between-boundary segment, prints to a per-segment temp,
# then the loop renames into the final per-finding files in encounter order.
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

awk -v out="$tmpdir" '
  BEGIN { n=0 }
  /^<<<FINDING-BOUNDARY>>>$/ {
    if (started) close(f)
    n++
    # Zero-pad to 4 digits so the lexicographic glob-and-sort below preserves
    # encounter order even at high finding counts (>99). Spec §1 does not cap
    # the per-round finding count, so 99 would have been a silent truncation.
    f = sprintf("%s/seg-%04d", out, n)
    started = 1
    next
  }
  started { print > f }
  END { if (started) close(f) }
' "$stdout_path"

i=0
for seg in "$tmpdir"/seg-*; do
  [[ -e "$seg" ]] || continue
  # Skip empty segment files — Codex stdout ending with a stray trailing
  # `<<<FINDING-BOUNDARY>>>` (no content after) would create a zero-byte seg
  # file via the awk loop's `started=1` flag firing on the boundary alone;
  # writing that to disk would violate spec §1's "exactly one `\n`" contract.
  [[ -s "$seg" ]] || continue
  i=$((i + 1))
  printf -v num '%02d' "$i"
  out="$round_subdir/${tag}.finding-F${num}.md"
  # Strip leading blank lines via awk; awk's `print` emits a trailing newline
  # for every output line, so a non-empty awk output is guaranteed to end in
  # exactly one `\n` already.
  awk 'BEGIN{started=0} {if (!started && NF==0) next; started=1; print}' "$seg" > "$out"
  # Defense-in-depth: if the awk output is empty (segment was all blank
  # lines), drop the file rather than ship a zero-byte finding.
  [[ -s "$out" ]] || rm -f "$out"
done
```

(The `round-[0-9]*` basename match handles the production `round-NN` convention; non-matching basenames — e.g. mktemp fixtures — are tolerated by passing the basename through to the YAML field.)

- [ ] **Step 2: Create the four fixture files**

`tests/fixtures/issue-109/codex-stdout/boundary-delimited.txt`:

```
some preamble Codex emitted before the first finding (must be discarded)
<<<FINDING-BOUNDARY>>>
---
finding_id: R3-F01
severity: high
change_type: correctness
referenced_files: [skills/design/SKILL.md]
artifact: design
round: 3
reviewer: quality-codex
---

First finding body prose.
<<<FINDING-BOUNDARY>>>
---
finding_id: R3-F02
severity: medium
change_type: clarity
referenced_files: [docs/qrspi/example/design.md]
artifact: design
round: 3
reviewer: quality-codex
---

Second finding body prose.
```

`tests/fixtures/issue-109/codex-stdout/no-findings.txt`:

```
NO_FINDINGS
```

`tests/fixtures/issue-109/codex-stdout/malformed.txt`:

```
Codex emitted prose with no boundary markers and no sentinel — implementer should treat this as a failure.
```

`tests/fixtures/issue-109/codex-stdout/empty.txt`:

```
```

(Truly empty — zero bytes.)

```bash
mkdir -p tests/fixtures/issue-109/codex-stdout
# write each file via Write tool with the bodies above
```

- [ ] **Step 3: Write the failing bats test `tests/unit/test-codex-splitter.bats`**

This test is NARROWED per spec §7 step 2: it exercises the splitter directly with synthetic inputs but does NOT grep dispatching skill prompts (those greps live in Task 5's expansion of this same file).

```bash
#!/usr/bin/env bats

setup() {
  ROUND_DIR=$(mktemp -d)
  TAG=quality-codex
}

teardown() {
  rm -rf "$ROUND_DIR"
}

@test "splitter exists and is executable" {
  [ -x scripts/codex-finding-splitter.sh ]
}

@test "boundary-delimited input writes per-finding files with role-distinct tag" {
  scripts/codex-finding-splitter.sh \
    tests/fixtures/issue-109/codex-stdout/boundary-delimited.txt \
    "$ROUND_DIR" \
    "$TAG"
  [ -f "$ROUND_DIR/${TAG}.finding-F01.md" ]
  [ -f "$ROUND_DIR/${TAG}.finding-F02.md" ]
  grep -qF 'finding_id: R3-F01' "$ROUND_DIR/${TAG}.finding-F01.md"
  grep -qF 'finding_id: R3-F02' "$ROUND_DIR/${TAG}.finding-F02.md"
  # Preamble before the first boundary must be discarded.
  ! grep -qF 'must be discarded' "$ROUND_DIR/${TAG}.finding-F01.md"
}

@test "NO_FINDINGS sentinel writes a clean marker (and only a clean marker)" {
  scripts/codex-finding-splitter.sh \
    tests/fixtures/issue-109/codex-stdout/no-findings.txt \
    "$ROUND_DIR" \
    "$TAG"
  [ -f "$ROUND_DIR/${TAG}.clean.md" ]
  ! ls "$ROUND_DIR"/${TAG}.finding-*.md 2>/dev/null
}

@test "malformed input writes nothing and exits non-zero with stderr diagnostic" {
  run scripts/codex-finding-splitter.sh \
    tests/fixtures/issue-109/codex-stdout/malformed.txt \
    "$ROUND_DIR" \
    "$TAG"
  [ "$status" -ne 0 ]
  echo "$stderr" | grep -qiE 'malformed|FINDING-BOUNDARY|NO_FINDINGS'
  ! ls "$ROUND_DIR"/${TAG}.finding-*.md 2>/dev/null
  ! ls "$ROUND_DIR"/${TAG}.clean.md 2>/dev/null
}

@test "empty input writes nothing and exits non-zero with stderr diagnostic" {
  run scripts/codex-finding-splitter.sh \
    tests/fixtures/issue-109/codex-stdout/empty.txt \
    "$ROUND_DIR" \
    "$TAG"
  [ "$status" -ne 0 ]
  echo "$stderr" | grep -qiE 'malformed|empty'
  ! ls "$ROUND_DIR"/${TAG}.finding-*.md 2>/dev/null
}

@test "splitter is idempotent on the success path" {
  scripts/codex-finding-splitter.sh \
    tests/fixtures/issue-109/codex-stdout/boundary-delimited.txt \
    "$ROUND_DIR" \
    "$TAG"
  local first_sha
  first_sha=$(shasum "$ROUND_DIR/${TAG}.finding-F01.md" "$ROUND_DIR/${TAG}.finding-F02.md")
  scripts/codex-finding-splitter.sh \
    tests/fixtures/issue-109/codex-stdout/boundary-delimited.txt \
    "$ROUND_DIR" \
    "$TAG"
  local second_sha
  second_sha=$(shasum "$ROUND_DIR/${TAG}.finding-F01.md" "$ROUND_DIR/${TAG}.finding-F02.md")
  [ "$first_sha" = "$second_sha" ]
}
```

- [ ] **Step 4: Run the test, expect green**

```bash
bats tests/unit/test-codex-splitter.bats
```
Expected: 6 tests pass. (If a test fails, fix the splitter — do NOT loosen the test.)

- [ ] **Step 5: Run the full unit suite to confirm no regressions**

```bash
bats tests/unit/
```
Expected: green. The splitter is dead code in this commit (no dispatching skill calls it yet); only the unit test exercises it.

- [ ] **Step 6: Commit**

Write `/tmp/commit-msg-109-c02.txt`:

```
feat(codex-splitter): #109 add finding-boundary splitter (commit 2/5)

Adds scripts/codex-finding-splitter.sh per spec §1. Splits Codex stdout
on lines matching exactly <<<FINDING-BOUNDARY>>> into per-finding files
named <round-subdir>/<reviewer_tag>.finding-F<NN>.md, zero-padded in
encounter order. Discards anything before the first boundary.

Special cases:
- NO_FINDINGS sentinel → writes <reviewer_tag>.clean.md only, exit 0.
- Malformed input (no boundaries, no NO_FINDINGS) → writes nothing,
  one-line stderr diagnostic, exit non-zero.
- Empty input → same: nothing written, non-zero exit, stderr diagnostic.

The splitter is dead code in this commit. Commit 4 wires it into the
8 dispatching skills (goals/questions/research/design/phasing/structure/
parallelize/replan) by injecting the <<<FINDING-BOUNDARY>>> + NO_FINDINGS
contract into the Codex reviewer prompts.

Tests: tests/unit/test-codex-splitter.bats — splitter-only, does NOT
grep dispatching skill prompts (deferred to commit 4's expansion).

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
```

```bash
git -C /Users/dfrysinger/Library/CloudStorage/Dropbox/claude-workspace/qrspi-plus add scripts/codex-finding-splitter.sh tests/unit/test-codex-splitter.bats tests/fixtures/issue-109/codex-stdout/
git -C /Users/dfrysinger/Library/CloudStorage/Dropbox/claude-workspace/qrspi-plus commit -F /tmp/commit-msg-109-c02.txt
```

---

## Task 3: Document the `verifier_enabled` config field (commit 3)

**Files:**
- Modify: `skills/using-qrspi/SKILL.md` (Config-File schema section)
- Create: `tests/unit/test-config-verifier-enabled-field.bats` (NARROWED — schema-doc-only)

**Spec reference:** §1 (`skills/using-qrspi/SKILL.md` config schema additions), §5 test #7, §7 step 3.

This commit is documentation-only. It adds the `verifier_enabled` field to the Config-File schema with default `true`, persistence semantics, and the runtime-backfill carve-out — but does NOT yet add the runtime code that READS the field. The runtime-backfill code lands atomically in commit 4.

- [ ] **Step 1: Locate the Config-File schema region**

```bash
grep -n '^## Config File\|^### Fields that' skills/using-qrspi/SKILL.md
```
Expected: line numbers for `## Config File (\`config.md\`)`, `### Fields that affect pipeline behavior (must be validated)`, and `### Fields that do NOT require validation (informational only)`. The `verifier_enabled` field belongs under "Fields that affect pipeline behavior".

- [ ] **Step 2: Add the `verifier_enabled` entry**

Insert under `### Fields that affect pipeline behavior (must be validated)`. The exact text:

```markdown
- **`verifier_enabled`** (boolean, default `true`) — when `true`, the artifact-level Apply-fix protocol dispatches one `qrspi-finding-verifier` (Haiku) per finding-file in parallel and filters style/clarity/correctness findings at score ≥80 before applying. When `false`, the protocol skips verifier dispatch entirely (no sidecars are written) and keeps all findings via the "no sidecar → keep" branch in step 7. The field is durable across `/compact`, pause, resume, and re-entry within the run directory under `docs/qrspi/<date>-<bundle>/`. Fresh run directories start with `verifier_enabled: true` (set by the `using-qrspi` run-init code at run creation). The §3 menu's `skip` option disables the verifier for the CURRENT round only (it does NOT mutate `config.md`); to disable across the whole run, edit `config.md` directly between rounds. CLI-flag opt-out at `/qrspi` invocation is out of scope for #109 (deferred).
```

Then add a new subsection `### Exceptions` (or extend an existing one if present) with the runtime-backfill carve-out — this is a deliberate carve-out from the no-silent-defaults rule documented above:

```markdown
### Exceptions to the no-silent-defaults rule

- **`verifier_enabled` runtime backfill.** If the field is missing from `config.md` on the first verifier-aware Apply-fix invocation in a resumed run created before the verifier landed, the runtime treats it as `true`, surfaces a one-line stderr warning once per resume (form: `verifier_enabled missing from config.md — backfilling default 'true' for this run`), and writes the field back to `config.md`. This is the only carve-out from the no-silent-defaults rule (`### No silent defaults` above). The carve-out exists because pre-existing run directories on disk pre-date the field's introduction and the alternative — failing the run on a missing field — would prevent users from resuming any in-flight run after upgrading.
```

(Confirm there is not already a `### Exceptions` subsection. If there is, append to it instead of creating a duplicate.)

- [ ] **Step 3: Write the failing bats test `tests/unit/test-config-verifier-enabled-field.bats`**

NARROWED — asserts schema-doc presence only. Does NOT yet assert the field is read by any protocol (that assertion lands in Task 5).

```bash
#!/usr/bin/env bats

@test "verifier_enabled field is documented under Fields that affect pipeline behavior" {
  awk '
    /^### Fields that affect pipeline behavior/ { in_section=1; next }
    /^### / { in_section=0 }
    in_section { print }
  ' skills/using-qrspi/SKILL.md \
    | grep -qE '^\s*-\s+\*\*`verifier_enabled`\*\*' \
    || { echo "verifier_enabled not documented under Fields that affect pipeline behavior"; return 1; }
}

@test "verifier_enabled default is true" {
  awk '/verifier_enabled/{print; getline; print; getline; print}' skills/using-qrspi/SKILL.md \
    | grep -qE 'default\s*`true`'
}

@test "persistence semantics documented (durable across /compact + resume)" {
  grep -A5 -B0 'verifier_enabled' skills/using-qrspi/SKILL.md \
    | grep -qE 'durable across.*compact|persists across|resume.*re-entry'
}

@test "runtime-backfill carve-out documented in Exceptions" {
  awk '
    /^### Exceptions/ { in_section=1; next }
    /^### / && in_section { in_section=0 }
    in_section { print }
  ' skills/using-qrspi/SKILL.md \
    | grep -qE 'verifier_enabled.*runtime backfill|runtime backfill.*verifier_enabled' \
    || { echo "runtime-backfill carve-out not in ### Exceptions section"; return 1; }
}

@test "round-scoped skip does NOT mutate config.md" {
  grep -A6 -B0 'verifier_enabled' skills/using-qrspi/SKILL.md \
    | grep -qE 'does NOT mutate.*config\.md|round only|CURRENT round only'
}
```

- [ ] **Step 4: Run the test, expect green**

```bash
bats tests/unit/test-config-verifier-enabled-field.bats
```
Expected: 5 tests pass. If a test fails, edit the schema documentation — do NOT loosen the test.

- [ ] **Step 5: Run the full unit suite to confirm no regressions**

```bash
bats tests/unit/
```
Expected: green. This commit is doc-only; no runtime code reads the field yet (commit 4 adds that).

- [ ] **Step 6: Commit**

`/tmp/commit-msg-109-c03.txt`:

```
docs(config): #109 add verifier_enabled field to Config-File schema (commit 3/5)

Adds verifier_enabled (boolean, default true) to the Config-File
schema in skills/using-qrspi/SKILL.md per spec §1. Documents persistence
semantics (durable across /compact + resume + re-entry within the run
directory), the round-scoped skip behavior (§3 menu's `skip` does NOT
mutate config.md), and the runtime-backfill carve-out from the
no-silent-defaults rule.

This commit is documentation-only. The runtime code that reads the
field lands in commit 4 alongside the Apply-fix protocol revision.

Tests: tests/unit/test-config-verifier-enabled-field.bats — schema-doc
assertions only. Commit 4 expands this test to assert the field is
read by Apply-fix.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
```

```bash
git -C /Users/dfrysinger/Library/CloudStorage/Dropbox/claude-workspace/qrspi-plus add skills/using-qrspi/SKILL.md tests/unit/test-config-verifier-enabled-field.bats
git -C /Users/dfrysinger/Library/CloudStorage/Dropbox/claude-workspace/qrspi-plus commit -F /tmp/commit-msg-109-c03.txt
```

---

## Task 4: Pre-cutover verification (no commit)

**Files:** none modified — this task verifies that commits 1–3 are individually revertible per spec §7's rollback contract.

**Spec reference:** §7 final paragraph ("Rollback contract: steps 1–3 are individually revertible (purely additive).").

- [ ] **Step 1: Verify each of commits 1–3 is individually revertible (the operational meaning of "purely additive")**

Spec §7's "Rollback contract: steps 1–3 are individually revertible (purely additive)" frames "purely additive" as the *means* by which the commits are individually revertible — i.e. the parenthetical is the explanation, not a separate stricter contract. For commits 1 and 2 the means is literal ("only new files added"); for commit 3 it is "the only modification is a doc-only addition to a schema region the runtime does not yet read, which is operationally equivalent to additive-only behavior under revert". The revertibility check below allows commit 3 to modify exactly `skills/using-qrspi/SKILL.md` (the field doc) and nothing else; commits 1 and 2 must be only-create.

A non-destructive `git show --stat` check is sufficient and avoids mutating the working tree:

```bash
for ref in HEAD~2 HEAD~1 HEAD; do
  echo "=== checking $ref ==="
  git -C /Users/dfrysinger/Library/CloudStorage/Dropbox/claude-workspace/qrspi-plus show --stat --format= "$ref"
done
```

Expected: every line in each commit's stat starts with `create mode` (or, equivalently, the `git show --name-status $ref` output shows only `A` entries — no `M`, `D`, or `R`). Spot-check the three commits:

- **HEAD~2** (commit 1, verifier agent): should add `agents/qrspi-finding-verifier.md` and `tests/unit/test-verifier-agent-file.bats` only.
- **HEAD~1** (commit 2, splitter): should add `scripts/codex-finding-splitter.sh`, `tests/unit/test-codex-splitter.bats`, and 4 fixture files under `tests/fixtures/issue-109/codex-stdout/` only.
- **HEAD** (commit 3, config doc): should add `tests/unit/test-config-verifier-enabled-field.bats` AND modify `skills/using-qrspi/SKILL.md`. Commit 3 is the one exception to "only new files" — it appends a documented field to the schema, but the field is doc-only and is not yet read by any runtime, so reverting it cannot break any test.

A stricter assertion that catches truly non-additive drift. Use `--format=` to suppress the commit-message header (otherwise the header's first word — `commit`, `Author:`, `Date:` — would falsely match the awk filter as a "non-additive entry"):

```bash
git -C /Users/dfrysinger/Library/CloudStorage/Dropbox/claude-workspace/qrspi-plus show --name-status --format= HEAD~2 | awk 'NF>0 && $1!~/^A/' | grep -q . && { echo "commit 1 is not additive"; exit 1; } || true
git -C /Users/dfrysinger/Library/CloudStorage/Dropbox/claude-workspace/qrspi-plus show --name-status --format= HEAD~1 | awk 'NF>0 && $1!~/^A/' | grep -q . && { echo "commit 2 is not additive"; exit 1; } || true
# Commit 3 is allowed to modify skills/using-qrspi/SKILL.md (schema doc) but nothing else:
git -C /Users/dfrysinger/Library/CloudStorage/Dropbox/claude-workspace/qrspi-plus show --name-status --format= HEAD | awk 'NF>0 && $1!~/^A/ && $2!="skills/using-qrspi/SKILL.md"' | grep -q . && { echo "commit 3 modifies files beyond the config-schema doc"; exit 1; } || true
echo "all three commits are purely additive (per the rollback contract)"
```

If any of the three checks fails, STOP — that commit was not purely additive. Split the offending commit (move runtime-coupling to commit 4) before proceeding.

- [ ] **Step 2: Confirm `git status` is clean before starting commit 4**

```bash
git -C /Users/dfrysinger/Library/CloudStorage/Dropbox/claude-workspace/qrspi-plus status
```
Expected: `nothing to commit, working tree clean` and `HEAD = $HEAD_SHA`.

This task does NOT commit anything. It is a verification gate before the load-bearing atomic cutover.

---

## Task 5: Atomic cutover commit (commit 4 — the load-bearing one)

**Files:** ~50 files modified or created in a single commit. See File Structure section "Modified files (commit 4 — atomic cutover)" plus the test creations enumerated below.

**Spec reference:** §1 (entire — every component lands here), §5 tests #2 + #4 + #5 + #6 + #8 + #9 + #10 (and the expansion of #3 + #7), §7 step 4 (including the pre-merge smoke matrix).

This commit is intentionally large (~50 files). Splitting it would leave main with mixed-contract rounds the schema-violation guard would reject. All edits here MUST stage together and land in a single commit.

The 14 reviewer agent files and 8 dispatching skills are mechanical migrations from a known prior shape — the spec specifies the textual contracts (per-finding emission, role-distinct `reviewer_tag`, finding-boundary delimiter, NO_FINDINGS sentinel, worked one-finding and zero-findings examples) but does NOT pre-script the per-file diffs. The implementer writes those diffs against the live #110-merged main file contents. The TDD discipline for those 22 prose/prompt edits is structural (the bats tests in steps 7–13 enforce the contracts globally) — no red-then-green per-file unit test ceremony, per the project's lightweight prose-handling convention.

**Bash-invocation friction (`$()` and `$(<file)`) note for the implementing agent.** The bash blocks below use shell command-substitution (`$()`, `$(<file)`) in several places — Task 5 step 16's substitution sweep, Task 5 step 15's smoke-matrix `RD=$(ls -d ...)` captures, and Task 6 step 2's `TODAY=$(date +...)`. The user's global CLAUDE.md (`~/.claude/CLAUDE.md`) flags these as patterns that trigger safety-heuristic approval prompts on every invocation (no permanent approval). The implementing agent will see those prompts and must approve them per-invocation; this is expected friction, NOT a sign the plan is wrong. (Rewriting every `$()` to a two-step `cmd > /tmp/x; read VAR < /tmp/x` form across 30+ shell blocks would dwarf the substantive plan content; the friction is accepted in exchange for readable plan prose.)

- [ ] **Step 1: Edit `skills/reviewer-protocol/SKILL.md` — bifurcate the disk-write contract**

Per spec §1 ("`skills/reviewer-protocol/SKILL.md` (amendments — bifurcated contract during the migration window)"):

(a) Add a `## Reviewer-Tag Routing Table` section near the top of the skill (after the introductory delivery paragraphs, before `## Finding Schema`). The table enumerates which reviewer-tag uses which contract. The four #109-scope role-distinct tags route to the new Per-Finding contract; every other tag (the 18 deferred reviewers from Task 0's follow-up issue) routes to Legacy. Concrete content:

```markdown
## Reviewer-Tag Routing Table

The reviewer protocol bifurcates during the #109 migration window. The follow-up issue (#${FOLLOWUP_ISSUE} per Task 0) collapses this back to a single per-finding contract.

| `reviewer_tag` | Contract section | Filename pattern |
|---|---|---|
| `quality-claude` | `## Per-Finding Disk-Write Contract (#109 reviewers)` | `reviews/{step}/round-NN/quality-claude.finding-F<NN>.md` |
| `scope-claude` | `## Per-Finding Disk-Write Contract (#109 reviewers)` | `reviews/{step}/round-NN/scope-claude.finding-F<NN>.md` |
| `quality-codex` | `## Per-Finding Disk-Write Contract (#109 reviewers)` | `reviews/{step}/round-NN/quality-codex.finding-F<NN>.md` |
| `scope-codex` | `## Per-Finding Disk-Write Contract (#109 reviewers)` | `reviews/{step}/round-NN/scope-codex.finding-F<NN>.md` |
| every other reviewer (5 plan-artifact, plan quality/scope, 8 per-task, implement-gate, security-integration, integration-quality) | `## Legacy Disk-Write Contract (deferred reviewers)` | `reviews/{step}/round-NN-{reviewer-tag}.md` (single file per reviewer) |

(Substitute `${FOLLOWUP_ISSUE}` with the integer captured in `/tmp/issue-109-followup-num.txt` from Task 0.)
```

(b) Immediately under the Routing Table, add the `## Expected-Reviewer Matrix` section. It enumerates the expected `reviewer_tag` set per artifact step and is config-aware (respects `codex_reviews: false`; no scope reviewer for Questions/Research):

```markdown
## Expected-Reviewer Matrix

For each artifact step, the apply-fix step-2 schema-violation guard asserts the round directory contains at least one of `<tag>.finding-*.md` or `<tag>.clean.md` for every expected tag in the row below — based on the run's `config.md`.

| Step | `codex_reviews: true` | `codex_reviews: false` |
|---|---|---|
| `goals` | `quality-claude`, `scope-claude`, `quality-codex`, `scope-codex` | `quality-claude`, `scope-claude` |
| `questions` | `quality-claude`, `quality-codex` | `quality-claude` |
| `research` | `quality-claude`, `quality-codex` | `quality-claude` |
| `design` | `quality-claude`, `scope-claude`, `quality-codex`, `scope-codex` | `quality-claude`, `scope-claude` |
| `phasing` | `quality-claude`, `scope-claude`, `quality-codex`, `scope-codex` | `quality-claude`, `scope-claude` |
| `structure` | `quality-claude`, `scope-claude`, `quality-codex`, `scope-codex` | `quality-claude`, `scope-claude` |
| `parallelize` | `quality-claude`, `scope-claude`, `quality-codex`, `scope-codex` | `quality-claude`, `scope-claude` |
| `replan` | `quality-claude`, `scope-claude`, `quality-codex`, `scope-codex` | `quality-claude`, `scope-claude` |

(Plan, Implement-gate, Integrate, Test are out of scope for #109 — see follow-up issue.)
```

(c) Rename the existing single-file disk-write contract section heading from `## Disk-Write Contract` to `## Legacy Disk-Write Contract (deferred reviewers)` — the body content is unchanged.

(d) Add the new `## Per-Finding Disk-Write Contract (#109 reviewers)` section immediately after the renamed Legacy section. Body sourced verbatim from spec §1 ("`skills/reviewer-protocol/SKILL.md` (amendments — bifurcated contract during the migration window)" sub-bullets):

- Per-finding emission contract — file path = `reviews/{step}/round-NN/<reviewer_tag>.finding-F<NN>.md`, F-numbered zero-padded in emission order.
- Per-finding file format (YAML frontmatter with the 4 schema fields + 3 audit fields; body is the prose `message`). Show the worked example from spec §1.
- Schema fields — the canonical 5-field finding schema names + valid values for `severity` and `change_type`.
- Audit fields — `artifact`, `round`, `reviewer` (must equal `<reviewer_tag>` and the filename prefix).
- `finding_id` uniqueness — unique per `(round, reviewer_tag)`. Canonical form `R{NN}-F{NN}`. Schema-guard regex: `^R\d+-F\d+$`. Add the prose: "(No splitter-fallback form: malformed Codex output now produces zero finding files for the tag, caught at apply-fix step 2.)"
- Clean-round sentinel — `<reviewer_tag>.clean.md` file with frontmatter-only body (`reviewer:`, `round:`, `findings: 0`).
- Reviewer brief-return shape — five lines: `Step / Round / Reviewer / Findings / Written to`. Include the spec §1 parenthetical noting partial-write failures are not separately signaled (mirrors `/code-review`).
- Trailing newline — every per-finding file ends with exactly one `\n` (deterministic byte-level normalize-then-warn at apply-fix step 2 if malformed).

- [ ] **Step 2: Edit `skills/using-qrspi/SKILL.md` — replace the Apply-fix protocol with the 10-step verifier-aware sequence**

Per spec §1 (`skills/using-qrspi/SKILL.md` (Apply-fix protocol — verifier-aware revision)").

Locate the existing `**Apply-fix protocol.** When main chat applies fixes after a round:` block under `## Review Output Handling` (around line 518 today). Replace its 6-step body with the spec's 10-step sequence verbatim — including the bash code blocks for step 1 (nullglob-safe enumeration), step 5 (the full pre-pass + per-finding interleaved emission with HTML boundary comments), and the verifier-enabled gate's runtime backfill code.

The runtime-backfill code lives in step 3 (verifier-enabled gate) and reads `verifier_enabled` from `config.md`. If the field is missing, treat as `true`, write a one-line stderr warning (`verifier_enabled missing from config.md — backfilling default 'true' for this run`), and append `verifier_enabled: true` to `config.md`. Concrete shape:

```bash
cfg=docs/qrspi/<bundle>/config.md   # absolute path resolved at runtime
verifier_enabled=$(awk -F': *' '/^verifier_enabled:/ {print $2; exit}' "$cfg")
if [[ -z "$verifier_enabled" ]]; then
  echo "verifier_enabled missing from config.md — backfilling default 'true' for this run" >&2
  # config.md's trailing-newline invariant lets us append directly without a
  # leading \n. (If the invariant ever breaks, the YAML parser still tolerates
  # the missing newline — the backfill is correctness-soft on this edge.)
  printf 'verifier_enabled: true\n' >> "$cfg"
  verifier_enabled=true
fi
if [[ "$verifier_enabled" != "true" ]]; then
  : # skip dispatch — jump to step 5 with no sidecars on disk
fi
```

Step 4 (verifier dispatch) instructs main chat to issue one Task tool call per finding-file in parallel, with the `qrspi-finding-verifier` subagent type and an explicit prompt that supplies the 5 input parameters spec §1 enumerates VERBATIM. The parameter shapes below are copied from spec §1 (`agents/qrspi-finding-verifier.md` `## Input contract`); the implementer MUST NOT alter them — `<diff_file_path>` is the per-round diff file (round-NN.diff), NOT the prior-round fixes file, and `<upstream_paths>` is a newline-separated list that includes SKILL paths the verifier may lazy-Read.

Concrete dispatch sketch (sub-block to paste into the Apply-fix protocol body):

```markdown
Step 4 — parallel verifier dispatch.

For each finding-file enumerated in Step 1, dispatch one Task call:

  subagent_type: qrspi-finding-verifier
  description:   verify <reviewer_tag>.<finding_id>
  prompt: |
    finding_file_path: <abs_path>/reviews/{step}/round-NN/<reviewer_tag>.finding-F<NN>.md
    sidecar_path:      <abs_path>/reviews/{step}/round-NN/<reviewer_tag>.finding-F<NN>.score.yml
    artifact_path:     <abs_path>/<step>.md
    diff_file_path:    <abs_path>/reviews/{step}/round-NN.diff   # empty string on round 1
    upstream_paths: |
      <abs_path>/<upstream-artifact-1>.md
      <abs_path>/<upstream-artifact-2>.md
      ...
      skills/<step>/SKILL.md
      skills/using-qrspi/SKILL.md

Parameter derivation (per spec §1 `## Input contract`, verbatim):
  - finding_file_path: enumerated by Step 1's nullglob loop (absolute path).
  - sidecar_path:      finding_file_path with `.md` → `.score.yml`.
  - artifact_path:     `<run_dir>/<step>.md` where <step> ∈
                       {goals, questions, research, design, phasing,
                        structure, parallelize, replan}.
  - diff_file_path:    `<run_dir>/reviews/{step}/round-NN.diff`. Empty
                       string on round 1 (no prior round, no diff yet);
                       round 2+ uses the diff file produced by Step 1's
                       diff-handling protocol against the prior round's
                       fixes.
  - upstream_paths:    NEWLINE-separated list. Includes (a) the upstream
                       artifacts the current step consumes per the QRSPI
                       pipeline order, AND (b) the SKILL paths the
                       verifier may lazy-Read for context (the dispatching
                       skill's SKILL.md and skills/using-qrspi/SKILL.md).
                       Per-step upstream-artifact lists:
                         Goals:       (no upstream artifacts; SKILL paths only)
                         Questions:   goals.md
                         Research:    goals.md, questions.md
                         Design:      goals.md, questions.md, research/summary.md
                         Phasing:     goals.md, design.md
                         Structure:   goals.md, design.md, phasing.md
                         Parallelize: goals.md, design.md, structure.md
                         Replan:      plan.md, replan-trigger-source
                       SKILL paths appended on every step:
                         skills/<step>/SKILL.md
                         skills/using-qrspi/SKILL.md
```

Each Task subagent returns a brief `<reviewer_tag>.<finding_id>: <score>` line (or `: VERIFY_FAILED:<reason>` on failure); main chat ignores the return text (the sidecar on disk is the source of truth) but does inspect for the `VERIFY_FAILED:` prefix to route into the §3 menu. Spec §1 (`agents/qrspi-finding-verifier.md` `## Procedure`) defines the verifier's internal behavior; this dispatch sketch only documents the orchestrator side.

Step 7 (filter and dispatch) handles four routing branches per spec §1:
- `scope` and `intent` → bypass score filter, flow directly to the existing pause gate.
- `style` / `clarity` / `correctness` with sidecar score ≥80 OR no sidecar OR sidecar VERIFY_FAILED OR verifier_enabled=false → keep, Edit on artifact.
- `style` / `clarity` / `correctness` with sidecar score <80 → drop.
- Out-of-enum `change_type` → loud failure (caught at step 2 already, but step 7 reasserts).

Step 10 (per-round commit) covers the artifact, the entire `round-NN/` subdir (including sidecars), `round-NN-verified.md`, and `round-NN-fixes.md`. The diff-handling protocol (today's lines 527+) is unchanged.

Additionally, locate the run-init code in `skills/using-qrspi/SKILL.md` that creates `config.md` for fresh runs (per spec §1: "Fresh run directories start with `verifier_enabled: true` (set by the `using-qrspi` run-init code at run creation)") and amend it to include `verifier_enabled: true` in the initial config-template. Today's run-init writes `config.md` with the existing fields (e.g. `codex_reviews:`, `route:`); add a `verifier_enabled: true` line in the same template region. This means fresh runs persist the field immediately on disk, NOT via the runtime-backfill carve-out — backfill is only for resumed pre-#109 runs.

Verification: the test-config-verifier-enabled-field.bats expansion (Task 5 step 11) asserts the run-init template includes the field — see the new test case "fresh-run config init writes verifier_enabled: true" in step 11.

- [ ] **Step 3: Edit `skills/using-qrspi/SKILL.md` — add the §3 failure-menu logic**

Add a new bold-paragraph subsection `**Verifier-round failure menu.**` directly under the Apply-fix protocol you just rewrote in step 2 (matching the local `**Apply-fix protocol.**` / `**Diff handling between rounds.**` style of the surrounding `## Review Output Handling` H2 — do NOT introduce a `### ` H3 here, since this region uses bold-paragraph subheaders). Body sourced verbatim from spec §3 (`§3 Failure handling (single generic menu)`). Include:

- The full menu text with the three options (`skip`, `retry`, `stop`) and their exact semantics:
  - `skip` — proceed without scoring THIS ROUND (kept-all assembly), writes `reviews/{step}/round-NN-verifier-disabled.md` with the concrete YAML body shape below (per spec §3: "timestamp + reason + finding count"), does NOT mutate `config.md`.

  The `round-NN-verifier-disabled.md` write contract (paste this YAML body shape verbatim into the failure-menu prose so the implementer has an unambiguous template):

  ```yaml
  ---
  timestamp: <ISO-8601 UTC, e.g. 2026-05-05T15:30:00Z>
  reason: <one-line summary identical to the menu's diagnostic line>
  finding_count: <integer total of *.finding-*.md files in the round directory>
  abnormality_class: <one of: VERIFY_FAILED | reviewer_no_output | sidecar_missing>
  ---
  ```

  Three fields are mandatory per spec §3 (timestamp, reason, finding_count); `abnormality_class` is added by the plan to give the audit record a routable taxonomy that mirrors the menu's diagnostic-line classes (the menu prose uses the same four classes; a fifth would indicate a menu/protocol drift). The file is written exactly once per round at `skip` selection. `skip` is a during-round control flow, not a cross-round signal: after the file is written, the same Apply-fix invocation jumps to step 5 (kept-all assembly with no sidecars on disk). The next round starts fresh from step 1 and re-reads `config.md` at step 3 — if `verifier_enabled: true`, the next round IS verifier-enabled. The `round-NN-verifier-disabled.md` artifact is purely the audit record of what happened on the round it was written for; it does not affect any subsequent round's gate behavior.
  - `retry` — re-dispatch only the failing verifiers; for "reviewer produced no output", delete the tag's stale `*.finding-*.md`, `*.score.yml`, `*.clean.md` first, then re-prompt the reviewer.
  - `stop` — abort the protocol with no commit; round directory remains on disk.
- The four abnormality classes the menu's diagnostic line covers:
  - VERIFY_FAILED return from one or more verifiers
  - Codex reviewer no-output (cite `await` exit + wrapper `--artifact-dir`)
  - Claude reviewer no-output (cite verbatim subagent return)
  - Sidecar missing for a finding
- The always-on footer: `If the same path keeps failing, picking 'skip' is the safe escape.`
- The constraints: no default option, no retry counter, no `config.md` mutation.

- [ ] **Step 4: Edit each of the 14 reviewer agent files**

Per spec §1 ("Reviewer agent files (modifications)"). All 14 agents receive the same per-finding-emission replacement block; copy it verbatim into each one (the only per-file variation is the artifact name in the brief-return template — `goals` for `qrspi-goals-reviewer.md`, etc.). The replacement block:

````markdown
### Step N — write findings (per-finding emission contract, #109)

For each finding the analysis surfaces, write one file:

```
reviews/{step}/round-NN/<reviewer_tag>.finding-F<NN>.md
```

`<reviewer_tag>` is delivered by the dispatcher (`quality-claude` for the artifact-quality reviewer, `scope-claude` for the dedicated scope reviewer). `F<NN>` is zero-padded in emission order (`F01`, `F02`, …). The file body uses YAML frontmatter for the 5-field schema + 3 audit fields, with the prose `message` after the closing `---`:

```markdown
---
finding_id: R<round>-F<NN>
severity: <low|medium|high>
change_type: <style|clarity|correctness|scope|intent>
referenced_files: [<repo-relative-path>, ...]
artifact: <artifact-name>
round: <round-number>
reviewer: <reviewer_tag>
---

<prose message — what is wrong, why it matters, how to fix>
```

When the analysis surfaces zero findings, write a single clean-sentinel file instead of any `finding-*.md`:

```
reviews/{step}/round-NN/<reviewer_tag>.clean.md
```

with this frontmatter-only body (no prose):

```markdown
---
reviewer: <reviewer_tag>
round: <round-number>
findings: 0
---
```

Return only the brief — exactly five lines, in this order:

```
Step: <artifact-name>
Round: <round-number>
Reviewer: <reviewer_tag>
Findings: N (high=X, medium=Y, low=Z)
Written to: reviews/{step}/round-NN/
```

Do NOT include per-finding detail in the return — the per-finding files on disk are the source of truth. Partial-write failures (some finding files persisted, some not — e.g. ENOSPC mid-write) are NOT separately signaled in the brief return; the per-finding files that did persist are accepted as-is. The apply-fix step 2 schema-violation guard catches only the all-or-nothing case where the expected tag produced ZERO output (no `*.finding-*.md` and no `*.clean.md`); intermediate F-number gaps are NOT a guard failure. (This mirrors `/code-review`'s partial-write tolerance — the spec accepts the visible files at face value and does not attempt gap detection.)

The legacy `Output file:` dispatch parameter (which targeted `round-NN-<reviewer-tag>.md`) is removed; the per-finding contract uses the `<round_subdir>` parameter (the absolute path to `reviews/{step}/round-NN/`) instead.
````

For each file in:

```
agents/qrspi-goals-reviewer.md
agents/qrspi-questions-reviewer.md
agents/qrspi-research-reviewer.md
agents/qrspi-design-reviewer.md
agents/qrspi-phasing-reviewer.md
agents/qrspi-structure-reviewer.md
agents/qrspi-parallelize-reviewer.md
agents/qrspi-replan-reviewer.md
agents/qrspi-goals-scope-reviewer.md
agents/qrspi-design-scope-reviewer.md
agents/qrspi-phasing-scope-reviewer.md
agents/qrspi-structure-scope-reviewer.md
agents/qrspi-parallelize-scope-reviewer.md
agents/qrspi-replan-scope-reviewer.md
```

Locate the procedure step in the agent body that today writes `reviews/{step}/round-NN-{reviewer}.md` (this is the legacy single-file pattern that #110 introduced) and replace it with the verbatim block above. Substitution rules:

- **Substitute** `<artifact-name>` with the per-file artifact value (e.g. `goals` for `qrspi-goals-reviewer.md`, `design` for `qrspi-design-reviewer.md`, `parallelize` for `qrspi-parallelize-reviewer.md`, etc.). This appears in the brief-return template's `Step:` line.
- **Keep verbatim** (do NOT substitute these — they are runtime-supplied or schema-shape placeholders the agent body documents to the reviewer): `<reviewer_tag>`, `<round>`, `<round-number>`, `<NN>`, `<low|medium|high>`, `<style|clarity|correctness|scope|intent>`, `<repo-relative-path>`. Test-#2 (Step 7 below) greps for `finding-F<NN>` and `<reviewer_tag>.clean.md` LITERALLY — substituting these would fail the test.

The 6 scope-reviewer agent files keep their existing Step-1 Read of `skills/{name}/owns-defers.md` (introduced by #110); only the disk-write contract changes — replace the same procedure step with the same verbatim block, again substituting `<artifact-name>` per file.

The Codex-side `quality-codex` / `scope-codex` tag values are NOT injected into the agent files (those are Claude-only reviewers); they are injected into the Codex prompt template by Step 5 below.

- [ ] **Step 5: Edit each of the 8 dispatching skills**

Per spec §1 ("Dispatch-site amendments"). For each file in:

```
skills/goals/SKILL.md
skills/questions/SKILL.md
skills/research/SKILL.md
skills/design/SKILL.md
skills/phasing/SKILL.md
skills/structure/SKILL.md
skills/parallelize/SKILL.md
skills/replan/SKILL.md
```

(a) Update the dispatch-parameter list to pass the role-distinct `reviewer_tag` value to each reviewer dispatch — `quality-claude` / `quality-codex` for the artifact-quality reviewer pair, `scope-claude` / `scope-codex` for the dedicated scope-reviewer pair (where present per the Expected-Reviewer Matrix). This replaces today's collapsed `claude` / `codex` values.

(b) Update the dispatch-parameter list to pass `<round_subdir>` (the absolute path to `reviews/{step}/round-NN/`) instead of the legacy `Output file:` single-file path.

(a)+(b) Concrete before→after replacement shape (the implementer locates each pre-cutover dispatch block in the 8 skill files and applies this transform). The exact YAML keys may differ between skills (some use `output:` not `Output file:`; some embed the value inline) — the contract is structural: replace any line/key that names a per-tag SINGLE FILE PATH with a per-tag DIRECTORY PATH, and rename `claude`/`codex` to `quality-claude`/`quality-codex` (or `scope-claude`/`scope-codex` for scope-reviewer dispatches).

```diff
 # Pre-cutover dispatch (representative — exact keys vary per skill):
-  reviewer_tag: claude
-  output: reviews/{step}/round-NN-claude.md
+  reviewer_tag: quality-claude
+  round_subdir: reviews/{step}/round-NN/
 ...
-  reviewer_tag: codex
-  output: reviews/{step}/round-NN-codex.md
+  reviewer_tag: quality-codex
+  round_subdir: reviews/{step}/round-NN/

 # And for skills that ALSO have a scope-reviewer dispatch
 # (goals, design, phasing, structure, parallelize, replan):
-  reviewer_tag: scope-claude
-  output: reviews/{step}/round-NN-scope-claude.md
+  reviewer_tag: scope-claude
+  round_subdir: reviews/{step}/round-NN/
 ...
-  reviewer_tag: scope-codex
-  output: reviews/{step}/round-NN-scope-codex.md
+  reviewer_tag: scope-codex
+  round_subdir: reviews/{step}/round-NN/
```

Notes:
- The `scope-claude` / `scope-codex` tags do NOT change names (they were already role-distinct on the scope side); only the quality-side `claude` / `codex` rename to `quality-claude` / `quality-codex` for the role-distinct symmetry the spec calls "load-bearing" (per spec §1 "The role-distinct rename is load-bearing").
- The `round_subdir` value is the SAME for every reviewer in a given round — they all write into the same directory. Per-finding filenames carry the role-distinct prefix, so directory collision is eliminated.
- If a pre-cutover skill embedded the output path inline inside a Codex prompt (rather than as a separate `output:` parameter), the inline reference must also be removed; the role-distinct `<reviewer_tag>` is the only path-component the post-cutover prompt needs to mention (the splitter is told the round_subdir separately at invocation time per sub-step (d) below).

(c) Inject the per-finding-file format + `NO_FINDINGS` sentinel + `<<<FINDING-BOUNDARY>>>` delimiter into the Codex reviewer prompt. Paste the following block VERBATIM into each of the 8 dispatching skills — the worked example uses concrete `design` / `quality-codex` values that all 8 skills inherit literally; the example is a teaching artifact, not a per-skill template. (Reviewers reading the prompt understand that real findings vary the `artifact:` and `reviewer:` fields per the dispatcher's parameters; the literal example does not need to be skill-specific.)

````markdown
**Output format (per-finding emission, #109).** Emit ONLY finding blocks (each preceded by exactly the literal line `<<<FINDING-BOUNDARY>>>`) or the literal sentinel `NO_FINDINGS` on its own line. No prose outside finding bodies. No preamble, no summary, no commentary between findings. The orchestrator's splitter (`scripts/codex-finding-splitter.sh`) treats anything before the first boundary as discardable preamble; anything that is neither boundary-prefixed nor the `NO_FINDINGS` sentinel is malformed and produces zero finding files for this tag (caught at apply-fix step 2 as "expected tag produced no output").

**Worked one-finding example** (the example uses concrete `design` / `quality-codex` values to keep the prompt template fully literal — the implementer should NOT swap these to other artifact names; only the per-skill `artifact:` field of REAL findings emitted at runtime varies. Substitution-tokens like `<round>` and `<NN>` are placeholders Codex itself fills in at emission time):

```
<<<FINDING-BOUNDARY>>>
---
finding_id: R3-F01
severity: high
change_type: correctness
referenced_files: [skills/design/SKILL.md]
artifact: design
round: 3
reviewer: quality-codex
---

The artifact's "Default action" sentence contradicts the change-type classifier in skills/reviewer-protocol/SKILL.md (which lists `style|clarity|correctness` as auto-apply and `scope|intent` as pause). Fix: rewrite the sentence to cite the classifier verbatim.
```

**Worked zero-findings example.** When the analysis surfaces no findings, the entire output is exactly one line:

```
NO_FINDINGS
```

Nothing else — no boundary, no frontmatter, no commentary.

**Constraint reminder.** Emit only finding blocks (each preceded by `<<<FINDING-BOUNDARY>>>`) or the literal `NO_FINDINGS` sentinel; no prose outside finding bodies.
````

The `<<<FINDING-BOUNDARY>>>` delimiter and the `NO_FINDINGS` sentinel are the two contracts the splitter recognizes; the constraint reminder above is what foils Codex's tendency to wrap output in conversational scaffolding.

(d) Wire the splitter into the Codex pipeline. Today's pipeline is:

```bash
scripts/codex-companion-bg.sh await --artifact-dir <ABS_DIR> <jobId> > reviews/{step}/round-NN-codex.md
```

The new form (per spec §1, `scripts/codex-finding-splitter.sh` (new)):

```bash
scripts/codex-companion-bg.sh await --artifact-dir <ABS_DIR> <jobId> > /tmp/codex-stdout-<jobId>.txt
if [[ $? -eq 0 ]]; then
  scripts/codex-finding-splitter.sh /tmp/codex-stdout-<jobId>.txt reviews/{step}/round-NN/ <reviewer_tag>
fi
# On either failure path (await non-zero OR splitter non-zero), the round
# directory has zero output for the tag — step 2's schema guard catches it.
```

(e) Remove the legacy single-reviewer-file `output:` path argument from the per-skill review dispatch language.

- [ ] **Step 6: Expand `tests/unit/test-codex-splitter.bats` to grep dispatching skill prompts**

Per spec §5 test #3, second part: assert each #109 dispatching skill includes the worked one-finding example, the zero-findings example, and the no-prose-outside-finding-blocks constraint in its Codex prompt template.

Append to the existing `tests/unit/test-codex-splitter.bats`:

```bash
@test "each #109 dispatching skill embeds the FINDING-BOUNDARY + NO_FINDINGS contract in its Codex prompt" {
  for skill in goals questions research design phasing structure parallelize replan; do
    local f="skills/${skill}/SKILL.md"
    grep -qF '<<<FINDING-BOUNDARY>>>' "$f" \
      || { echo "<<<FINDING-BOUNDARY>>> missing from $f"; return 1; }
    grep -qF 'NO_FINDINGS' "$f" \
      || { echo "NO_FINDINGS sentinel missing from $f"; return 1; }
    grep -qiE 'no prose outside finding blocks|emit only finding blocks' "$f" \
      || { echo "no-prose constraint missing from $f"; return 1; }
  done
}

@test "each #109 dispatching skill wires the splitter on the success path" {
  for skill in goals questions research design phasing structure parallelize replan; do
    local f="skills/${skill}/SKILL.md"
    grep -qF 'codex-finding-splitter.sh' "$f" \
      || { echo "splitter not wired in $f"; return 1; }
  done
}

@test "every #109 dispatching skill passes <round_subdir> as the dispatch parameter (Claude AND Codex sides)" {
  for skill in goals questions research design phasing structure parallelize replan; do
    local f="skills/${skill}/SKILL.md"
    grep -qE '<round_subdir>|round_subdir|round-NN/' "$f" \
      || { echo "<round_subdir> dispatch parameter missing in $f"; return 1; }
  done
}

@test "every #109 dispatching skill removes the legacy 'output:' single-file path argument" {
  for skill in goals questions research design phasing structure parallelize replan; do
    local f="skills/${skill}/SKILL.md"
    # The legacy form passed `output: reviews/{step}/round-NN-{tag}.md` to the
    # reviewer dispatch. Post-cutover, the parameter is `<round_subdir>` and
    # the legacy `output:` path argument is gone. Tolerate the word "output"
    # appearing in unrelated contexts (e.g. "Codex output"); only fail if a
    # path-shaped legacy `output:` argument with `round-NN-` survives.
    ! grep -qE 'output:[[:space:]]*reviews/.*round-NN-(claude|codex|scope-(claude|codex))' "$f" \
      || { echo "legacy 'output:' single-file path argument still present in $f"; return 1; }
  done
}

@test "every #109 dispatching skill passes role-distinct reviewer_tag values (quality- and scope-prefixed)" {
  for skill in goals questions research design phasing structure parallelize replan; do
    local f="skills/${skill}/SKILL.md"
    grep -qE 'quality-claude|quality-codex' "$f" \
      || { echo "quality-tag dispatch parameter missing in $f"; return 1; }
  done
  # Goals/Design/Phasing/Structure/Parallelize/Replan also dispatch a scope reviewer.
  for skill in goals design phasing structure parallelize replan; do
    local f="skills/${skill}/SKILL.md"
    grep -qE 'scope-claude|scope-codex' "$f" \
      || { echo "scope-tag dispatch parameter missing in $f"; return 1; }
  done
  # Questions/Research do NOT dispatch a scope reviewer (per spec). Verify the
  # legacy collapsed `claude`/`codex` tags are gone (replaced by quality-prefixed).
  for skill in questions research; do
    local f="skills/${skill}/SKILL.md"
    ! grep -qE 'reviewer_tag:[[:space:]]*(claude|codex)[[:space:]]*$' "$f" \
      || { echo "legacy collapsed tag (no role prefix) still in $f"; return 1; }
  done
}

@test "no #109 dispatching skill retains the legacy single-file Codex stdout redirect" {
  for skill in goals questions research design phasing structure parallelize replan; do
    local f="skills/${skill}/SKILL.md"
    # The legacy form redirected await stdout straight to round-NN-{tag}.md.
    # Post-cutover, await stdout goes to /tmp and the splitter handles the round dir.
    ! grep -qE 'await.*> *reviews/\{?step\}?/round-NN-(claude|codex|scope-(claude|codex))\.md' "$f" \
      || { echo "legacy single-file redirect still present in $f"; return 1; }
  done
}

@test "each #109 dispatching skill gates the splitter call on await success (no splitter call on non-zero exit)" {
  # Spec §1's pipeline contract: when scripts/codex-companion-bg.sh await exits
  # non-zero (any of 1/10/11/12/13/14), the splitter MUST NOT run, so the round
  # directory has zero output for the tag and step 2's schema guard catches it.
  # Each dispatching skill encodes this as an `if [[ $? -eq 0 ]]; then splitter`
  # gate (or equivalent — `&&` pipeline, explicit exit-code variable).
  #
  # Multi-line search uses awk (portable across BSD/GNU grep) — `grep -Pzo` is
  # GNU-only and breaks on macOS Darwin BSD grep, so we extract the slice
  # between `await` and `codex-finding-splitter.sh` and check for a gate token
  # within it.
  for skill in goals questions research design phasing structure parallelize replan; do
    local f="skills/${skill}/SKILL.md"
    local marker
    marker=$(awk '
      /codex-finding-splitter\.sh/ && capturing == 0 { saw_splitter_pre_await=1 }
      /codex-companion-bg\.sh await/ { capturing=1; saw_await=1 }
      capturing { buf = buf $0 "\n" }
      /codex-finding-splitter\.sh/ && capturing {
        if (buf ~ /\$\? -eq 0/ || buf ~ /&&/ || buf ~ /if .*\$\?/) {
          print "GATE_OK"; capturing=0; exit
        }
        print "GATE_MISSING"; capturing=0; exit
      }
      END {
        if (saw_await == 0 && saw_splitter_pre_await == 0) print "AWAIT_NOT_FOUND"
        else if (saw_await == 0 && saw_splitter_pre_await == 1) print "SPLITTER_BEFORE_AWAIT"
        else if (capturing == 1 && saw_splitter_pre_await == 1) print "SPLITTER_BEFORE_AWAIT"
        else if (capturing == 1) print "SPLITTER_NOT_FOUND"
      }
    ' "$f")
    case "$marker" in
      GATE_OK)              ;;  # pass
      GATE_MISSING)         echo "splitter not gated on await success in $f"; return 1 ;;
      AWAIT_NOT_FOUND)      echo "codex-companion-bg.sh await invocation missing entirely in $f"; return 1 ;;
      SPLITTER_NOT_FOUND)   echo "await line found but no codex-finding-splitter.sh invocation reachable in $f"; return 1 ;;
      SPLITTER_BEFORE_AWAIT) echo "splitter invocation precedes await line in $f — re-order so splitter is gated on await success"; return 1 ;;
      *)                    echo "unrecognized marker '$marker' from gate-detection awk in $f"; return 1 ;;
    esac
  done
}
```

- [ ] **Step 7: Create `tests/unit/test-per-finding-file-emission.bats`**

Per spec §5 test #2. The 14 #109-scope reviewer agent files must instruct per-finding emission with the canonical filename pattern using role-distinct `reviewer_tag` values; the 18 deferred reviewer agent files must remain on the legacy single-file contract.

```bash
#!/usr/bin/env bats

# #109-scope reviewer agent files (14): per-finding emission required.
# Deferred reviewers are skipped per the follow-up issue (see body comment).
# When the follow-up issue (#${FOLLOWUP_ISSUE}) lands, extend this test to
# cover the deferred reviewers too.

setup() {
  scope_files=(
    agents/qrspi-{goals,questions,research,design,phasing,structure,parallelize,replan}-reviewer.md
    agents/qrspi-{goals,design,phasing,structure,parallelize,replan}-scope-reviewer.md
  )
  deferred_files=(
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
}

@test "every #109-scope reviewer agent body specifies per-finding filename pattern" {
  for f in "${scope_files[@]}"; do
    [[ -f "$f" ]] || { echo "missing #109-scope agent file: $f"; return 1; }
    local body
    body=$(awk '/^---$/{n++; next} n>=2{print}' "$f")
    echo "$body" | grep -qE 'finding-F[0-9]+\.md|finding-F<[Nn][Nn]>' \
      || { echo "per-finding pattern missing in $f"; return 1; }
  done
}

@test "every #109-scope reviewer agent body specifies the clean sentinel pattern" {
  for f in "${scope_files[@]}"; do
    [[ -f "$f" ]] || { echo "missing #109-scope agent file: $f"; return 1; }
    local body
    body=$(awk '/^---$/{n++; next} n>=2{print}' "$f")
    echo "$body" | grep -qE '<reviewer_tag>\.clean\.md|\.clean\.md.*<reviewer_tag>|clean-round sentinel' \
      || { echo "clean-sentinel pattern missing in $f"; return 1; }
  done
}

@test "no #109-scope reviewer agent retains the legacy round-NN-{reviewer-tag}.md write" {
  for f in "${scope_files[@]}"; do
    [[ -f "$f" ]] || { echo "missing #109-scope agent file: $f"; return 1; }
    local body
    body=$(awk '/^---$/{n++; next} n>=2{print}' "$f")
    # Look for the literal legacy filename pattern as a Write target.
    ! echo "$body" | grep -qE 'Write[^.]*round-NN-(claude|codex|scope-(claude|codex))\.md' \
      || { echo "legacy single-file Write still present in $f"; return 1; }
  done
}

@test "deferred reviewer agent files remain on the legacy contract (per follow-up issue)" {
  # Deferred reviewers (18) — see spec §1 "Files NOT modified by #109". Migration
  # is tracked in the follow-up issue. When that lands, this test extends.
  for f in "${deferred_files[@]}"; do
    [[ -f "$f" ]] || continue   # tolerate missing optional reviewers in #110-only main
    local body
    body=$(awk '/^---$/{n++; next} n>=2{print}' "$f")
    # Deferred reviewers must NOT have been migrated to per-finding emission.
    # Acceptable: legacy round-NN-{tag}.md mention OR no Write directive at all
    # (some agent files have their disk-write semantics in the protocol skill only).
    if echo "$body" | grep -qE 'finding-F[0-9]+\.md'; then
      echo "deferred reviewer $f appears to use per-finding pattern — should be on legacy contract"
      return 1
    fi
  done
}
```

(Substitute `${FOLLOWUP_ISSUE}` with the integer from `/tmp/issue-109-followup-num.txt`.)

- [ ] **Step 8: Create `tests/unit/test-verifier-dispatch-contract.bats`**

Per spec §5 test #4. Asserts the Apply-fix protocol body in `using-qrspi/SKILL.md` references the 10 documented steps in order and does NOT instruct main chat to read per-reviewer single files for #109-scope artifacts.

```bash
#!/usr/bin/env bats

setup() {
  # Extract the Apply-fix protocol body — from "Apply-fix protocol." through
  # the start of the next major **bold** section (Diff handling).
  PROTOCOL=$(awk '
    /\*\*Apply-fix protocol\.\*\*/ { in_block=1 }
    in_block && /\*\*Diff handling between rounds/ { exit }
    in_block { print }
  ' skills/using-qrspi/SKILL.md)
}

@test "Apply-fix protocol enumerates the 10 documented steps in order" {
  local prev=0
  for marker in 'List per-reviewer outputs' \
                'schema-violation guard' \
                'Verifier-enabled gate' \
                'Dispatch one .qrspi-finding-verifier' \
                'Bash assembly' \
                'Read.*round-NN-verified\.md' \
                'Filter and dispatch' \
                'Write.*round-NN-fixes\.md' \
                '/compact' \
                'Per-round commit'; do
    local pos
    pos=$(echo "$PROTOCOL" | grep -nE "$marker" | head -1 | cut -d: -f1)
    [[ -n "$pos" ]] || { echo "marker missing: $marker"; return 1; }
    [[ "$pos" -gt "$prev" ]] || { echo "marker out of order: $marker (pos=$pos, prev=$prev)"; return 1; }
    prev=$pos
  done
}

@test "Apply-fix protocol does NOT read per-reviewer single files for #109-scope artifacts" {
  # The pre-#109 form read each round-NN-{reviewer-tag}.md per reviewer. The new
  # form reads only round-NN-verified.md (assembled from the round-NN/ subdir).
  ! echo "$PROTOCOL" | grep -qE 'Read .*round-NN-(claude|codex|scope-(claude|codex))\.md'
}

@test "Apply-fix protocol reads round-NN-verified.md exactly once" {
  # Spec §1/§5: the verified file is read EXACTLY once by main chat (this is a
  # load-bearing cache-control contract). Multiple reads would re-pollute main
  # chat's context with the assembled body. The Apply-fix prose body must
  # reference the read exactly one time.
  local count
  count=$(echo "$PROTOCOL" | grep -cE 'Read.*round-NN-verified\.md')
  [[ "$count" -eq 1 ]] || { echo "expected exactly 1 Read of round-NN-verified.md, found $count"; return 1; }
}

@test "verifier-enabled gate jumps to step 5 when verifier_enabled=false" {
  echo "$PROTOCOL" | grep -qE 'verifier_enabled.*false.*step 5|step 5.*verifier_enabled.*false|jump to step 5'
}

@test "step 2 schema guard catches the await-non-zero / splitter-malformed path" {
  echo "$PROTOCOL" | grep -qiE 'expected tag.*no output|expected tag produced no output|expected tag with zero'
}

# Spec §1 step 2 enumerates FIVE schema-guard branches that must fail loud
# (or normalize, in the trailing-newline case). One was pinned above; the
# remaining four below pin the branches Codex r6-F05 flagged as missing.
# These tests grep the prose body of the Apply-fix step-2 paragraph for the
# documented behavior — they enforce the spec contract is COMMUNICATED to the
# implementer, not that the bash code is semantically correct (that's the job
# of the implementer's runtime tests at execution time, but those tests cannot
# exist until the prose says what to test against).

@test "step 2 schema guard fails loud on malformed YAML frontmatter" {
  # Spec §1 step 2: "Step 2 also fails loud on: malformed YAML, ..."
  echo "$PROTOCOL" | grep -qiE 'malformed YAML|invalid YAML|YAML.*malformed'
}

@test "step 2 schema guard fails loud on missing required fields" {
  # Spec §1 step 2: "...missing required fields, ..."
  echo "$PROTOCOL" | grep -qiE 'missing required field|required field.*missing|missing field'
}

@test "step 2 schema guard fails loud on malformed change_type enum" {
  # Spec §1 step 2: "...malformed change_type enum, ..."
  echo "$PROTOCOL" | grep -qiE 'change_type.*enum|out-of-enum.*change_type|invalid change_type'
}

@test "step 2 schema guard fails loud on unrouted (step, tag) route" {
  # Spec §1 step 2: "...unrouted (step, tag) route."
  echo "$PROTOCOL" | grep -qiE 'unrouted|route.*not found|no route|unknown route'
}

@test "step 2 normalizes trailing-newline malformations with audit warning (NOT hard fail)" {
  # Spec §1 step 2: "Trailing-newline malformations are normalized
  # (deterministic strip+append-`\n`) with a one-line audit warning, NOT a
  # hard fail." Pin both directions: the normalize action AND the warning,
  # AND the explicit non-fail.
  echo "$PROTOCOL" | grep -qiE 'trailing.newline.*normaliz|normaliz.*trailing.newline'
  echo "$PROTOCOL" | grep -qiE 'audit warning|warning.*audit|one.line.*warning'
  echo "$PROTOCOL" | grep -qiE 'NOT.*hard fail|not.*hard.fail|warn.*not.*fail'
}
```

The five new schema-guard tests need ONE additional fixture covering the malformed-YAML + missing-field + bad-change_type + unrouted-tag input cases (the trailing-newline case is tested via the prose-grep alone, since the normalization is on disk content not in the prose itself). Add this fixture inventory to commit 4's File Structure:

- `tests/fixtures/issue-109/round-schema-violations/round-03/quality-claude.finding-F01.md` — malformed YAML frontmatter (e.g. unclosed `---`, tab where space expected). One file per branch is sufficient because step 2 fails on the first violation it sees and the test's purpose is to PIN the prose contract, not exercise the runtime parser.
- `tests/fixtures/issue-109/round-schema-violations/round-03/quality-claude.finding-F02.md` — missing required field (`change_type:` line removed from frontmatter).
- `tests/fixtures/issue-109/round-schema-violations/round-03/quality-claude.finding-F03.md` — bad-enum `change_type: maintenance` (out of `style|clarity|correctness|scope|intent`).
- `tests/fixtures/issue-109/round-schema-violations/round-03/quality-unknown.finding-F01.md` — unrouted reviewer-tag (`quality-unknown` is not in the Routing Table).
- `tests/fixtures/issue-109/round-schema-violations/round-03/quality-claude.finding-F04.md` — trailing-newline malformation (file ends with `\n\n` or no `\n`).

(These fixtures are NOT consumed by the bats prose-greps above — those are pure documentation tests against `using-qrspi/SKILL.md`. The fixtures exist so the implementer can wire them into a runtime parser test at commit-4 implementation time. Tracking them in the staging list ensures they ship with the cutover commit, not as orphans.)

- [ ] **Step 9: Create `tests/unit/test-failure-menu.bats` + the four `menu-cases/` fixtures**

Per spec §5 test #5 ("Fixture covers each abnormality the menu handles (VERIFY_FAILED, missing reviewer output, missing sidecar)"). Create four fixture round directories — one per abnormality class — each populated with the file shape that triggers that class, and a `cited-diagnostic.txt` file naming the diagnostic line the menu's prose must produce when this fixture is the failing input:

Each fixture's `cited-diagnostic.txt` carries a regex that must match the verbatim spec §3 menu prose (NOT plan-Step-3 explanatory bullets — the test enforces the spec text itself). Spec §3's diagnostic-line shapes are:

- VERIFY_FAILED branch: `verifier returned VERIFY_FAILED`
- Codex no-output branch: `wrote no per-finding files` and `await` / `--artifact-dir` references
- Claude no-output branch: `wrote no per-finding files` and `subagent return:`
- Sidecar missing branch: `sidecar missing` (or `expected sidecar missing` per spec §3)

The `cited-diagnostic.txt` file lives at the case-directory root (NOT inside `round-03/`) — the test's `${case_dir}cited-diagnostic.txt` lookup is one level above the round subdir. Each case directory has the structure:

```
tests/fixtures/issue-109/menu-cases/<case>/
  cited-diagnostic.txt       # case-level regex
  round-03/                  # round contents exhibiting the abnormality
    <per-case files…>
```

Create `tests/fixtures/issue-109/menu-cases/verify-failed/`:
- `cited-diagnostic.txt` — single line: `VERIFY_FAILED`
- `round-03/quality-claude.finding-F01.md` (frontmatter `change_type: correctness`, sample body)
- `round-03/quality-claude.finding-F01.score.yml` — two-line YAML per spec §1 (sidecar shape, NOT the brief-return shape):
  ```yaml
  score: VERIFY_FAILED
  reason: upstream not readable
  ```
  Per spec §1, the failure sidecar is always exactly these two fields. The single-scalar form `score: VERIFY_FAILED:<reason>` is the brief-return shape (returned by the verifier subagent over stdout to main chat) and is NOT what lands on disk. The Apply-fix step-5 assembly grep `^score: VERIFY_FAILED` matches both prefixes, but pinning the wrong sidecar shape in the fixture would push the implementer's parser away from spec.

Create `tests/fixtures/issue-109/menu-cases/missing-codex-output/`:
- `cited-diagnostic.txt` — single line: `wrote no per-finding files|await.*exit|--artifact-dir`
- `round-03/quality-claude.finding-F01.md` + `round-03/quality-claude.finding-F01.score.yml` (real, score 87)
- (NO `round-03/quality-codex.*` files — the Codex tag was expected per the matrix but produced nothing)

Create `tests/fixtures/issue-109/menu-cases/missing-claude-output/`:
- `cited-diagnostic.txt` — single line: `wrote no per-finding files|subagent return:`
- `round-03/quality-codex.finding-F01.md` + `round-03/quality-codex.finding-F01.score.yml` (real, score 90)
- (NO `round-03/quality-claude.*` files)

Create `tests/fixtures/issue-109/menu-cases/missing-sidecar/`:
- `cited-diagnostic.txt` — single line: `sidecar missing|expected sidecar`
- `round-03/quality-claude.finding-F01.md` (real)
- (NO `round-03/quality-claude.finding-F01.score.yml` — verifier was expected to produce a sidecar but didn't)

```bash
#!/usr/bin/env bats

setup() {
  MENU=$(awk '
    /\*\*Verifier-round failure menu\.\*\*/ { in_block=1; next }
    in_block && /^\*\*[A-Z]/ { exit }
    in_block && /^## / { exit }
    in_block { print }
  ' skills/using-qrspi/SKILL.md)
}

@test "menu describes three exact options: skip, retry, stop" {
  echo "$MENU" | grep -qE '^\s*1\.\s*skip\b'
  echo "$MENU" | grep -qE '^\s*2\.\s*retry\b'
  echo "$MENU" | grep -qE '^\s*3\.\s*stop\b'
}

@test "menu has no default option" {
  echo "$MENU" | grep -qE 'no default|user must pick|must select'
}

@test "skip writes round-NN-verifier-disabled.md and does NOT mutate config.md" {
  echo "$MENU" | grep -qF 'verifier-disabled.md'
  echo "$MENU" | grep -qE 'does NOT mutate.*config\.md|no config\.md mutation'
}

@test "skip's round-NN-verifier-disabled.md write contract pins the four required fields" {
  # Spec §3: "timestamp + reason + finding count". Plan adds abnormality_class
  # for routable audit taxonomy. The bats test pins all four fields are
  # documented in the menu prose (which is sourced from the spec text the
  # implementer pasted into using-qrspi/SKILL.md). If a future edit drops one
  # of these fields from the documented schema, this test fails — preventing
  # the implementer from authoring a schema-incomplete write contract.
  echo "$MENU" | grep -qE 'timestamp:|^[[:space:]]*timestamp\b'
  echo "$MENU" | grep -qE 'reason:|^[[:space:]]*reason\b'
  echo "$MENU" | grep -qE 'finding_count:|finding count'
  echo "$MENU" | grep -qE 'abnormality_class:|abnormality class'
}

@test "retry for reviewer-no-output deletes stale tag files before re-dispatch" {
  echo "$MENU" | grep -qE '\*\.finding-\*\.md.*\*\.score\.yml.*\*\.clean\.md|delete.*tag.*finding.*score.*clean|retry.*clean.*stale'
}

@test "always-on footer is present" {
  echo "$MENU" | grep -qF "the safe escape"
}

@test "menu covers the four abnormality classes" {
  echo "$MENU" | grep -qiE 'VERIFY_FAILED'
  echo "$MENU" | grep -qiE 'reviewer.*no output|produced no output'
  echo "$MENU" | grep -qiE 'sidecar missing|missing sidecar'
}

@test "each menu-cases fixture's cited diagnostic appears verbatim in the menu prose" {
  # Spec §5 test #5: "Fixture covers each abnormality the menu handles." Each
  # fixture carries a cited-diagnostic.txt naming the regex the menu prose
  # must contain to handle that abnormality. Iterating over the fixtures
  # asserts the menu is fixture-backed, not just a static prose match.
  for case_dir in tests/fixtures/issue-109/menu-cases/*/; do
    [[ -d "$case_dir" ]] || continue
    local cited
    cited=$(cat "${case_dir}cited-diagnostic.txt")
    echo "$MENU" | grep -qiE "$cited" \
      || { echo "menu prose does not match cited diagnostic for $case_dir: $cited"; return 1; }
  done
}
```

- [ ] **Step 10: Create `tests/unit/test-verified-file-shape.bats` + the two round-directory fixtures**

Per spec §5 test #6.

Create `tests/fixtures/issue-109/round-enabled-clean/round-03/`:
- `quality-claude.finding-F01.md` (frontmatter `change_type: correctness`, sample body)
- `quality-claude.finding-F01.score.yml` (`score: 87`, `reason: real defect`)
- `quality-claude.finding-F02.md` (frontmatter `change_type: clarity`)
- `quality-claude.finding-F02.score.yml` (`score: 60`, `reason: low confidence`)  ← will be dropped at score <80 with style/clarity/correctness change_type
- `scope-claude.finding-F01.md` (frontmatter `change_type: scope`)
- `scope-claude.finding-F01.score.yml` (`score: 75` — but scope is never score-filtered, so still kept)
- `quality-codex.clean.md` (no findings)

Create `tests/fixtures/issue-109/round-disabled-from-start/round-01/`:
- `quality-claude.finding-F01.md` (frontmatter `change_type: correctness`)
- `quality-claude.finding-F02.md` (frontmatter `change_type: clarity`)
- (NO sidecars at all — verifier_enabled was false from start)

Then write the test:

```bash
#!/usr/bin/env bats

# This test exercises a faithful MIRROR of the Bash assembly snippet
# documented in skills/using-qrspi/SKILL.md (Apply-fix step 5). It does not
# extract or source the SKILL.md snippet directly because the snippet is
# embedded inside Markdown prose. To prevent silent drift between the
# documented protocol and the tested behavior, the test below ALSO asserts
# that the SKILL.md snippet still contains the structural markers this
# mirror depends on (nullglob, the @@FINDING/@@SCORE/@@CLEAN HTML boundary
# comments, the YAML totals header, the score < 80 + change_type partition).
# If the SKILL.md snippet drifts, the structural-marker assertion fails and
# the implementer must re-sync the mirror.

source_assembly() {
  local round_dir=$1
  local out=$2
  local cfg=$3
  local D=$round_dir
  shopt -s nullglob
  findings=( "$D"/*.finding-*.md )
  cleans=( "$D"/*.clean.md )

  scored=0; failed=0; dropped=0
  clean_count=${#cleans[@]}
  for f in "${findings[@]}"; do
    sc="${f%.md}.score.yml"
    [[ -f $sc ]] || continue
    if grep -q '^score: VERIFY_FAILED' "$sc"; then
      failed=$((failed + 1)); continue
    fi
    score=$(awk -F': *' '/^score:/ {print $2; exit}' "$sc")
    scored=$((scored + 1))
    ct=$(awk -F': *' '/^change_type:/ {print $2; exit}' "$f")
    if (( score < 80 )) && [[ $ct =~ ^(style|clarity|correctness)$ ]]; then
      dropped=$((dropped + 1))
    fi
  done
  kept=$(( ${#findings[@]} - dropped ))
  verifier_enabled_str=$(awk -F': *' '/^verifier_enabled:/ {print $2; exit}' "$cfg")

  {
    printf '%s\n' \
      '---' \
      "verifier_enabled: ${verifier_enabled_str:-true}" \
      "scored: $scored" \
      "kept: $kept" \
      "dropped: $dropped" \
      "failed: $failed" \
      "clean: $clean_count" \
      '---' \
      ''
    for f in "${findings[@]}"; do
      echo "<!-- @@FINDING: $(basename "$f" .md) @@ -->"
      cat "$f"
      sc="${f%.md}.score.yml"
      if [[ -f $sc ]]; then
        echo "<!-- @@SCORE: $(basename "$sc" .yml) @@ -->"
        cat "$sc"
      fi
    done
    for c in "${cleans[@]}"; do
      echo "<!-- @@CLEAN: $(basename "$c" .md) @@ -->"
      cat "$c"
    done
  } > "$out"
}

@test "enabled-clean fixture: scored=3, kept=2, dropped=1 (F02 clarity score 60)" {
  local out
  out=$(mktemp)
  local cfg
  cfg=$(mktemp)
  echo 'verifier_enabled: true' > "$cfg"
  source_assembly tests/fixtures/issue-109/round-enabled-clean/round-03 "$out" "$cfg"
  grep -qE '^scored: 3$' "$out"
  grep -qE '^kept: 2$' "$out"
  grep -qE '^dropped: 1$' "$out"
  grep -qE '^failed: 0$' "$out"
  grep -qE '^clean: 1$' "$out"
}

@test "enabled-clean fixture: assembly contains @@FINDING / @@SCORE / @@CLEAN boundary comments" {
  local out
  out=$(mktemp)
  local cfg
  cfg=$(mktemp)
  echo 'verifier_enabled: true' > "$cfg"
  source_assembly tests/fixtures/issue-109/round-enabled-clean/round-03 "$out" "$cfg"
  grep -qF '<!-- @@FINDING:' "$out"
  grep -qF '<!-- @@SCORE:' "$out"
  grep -qF '<!-- @@CLEAN:' "$out"
}

@test "disabled-from-start fixture: scored=0, kept=2, no sidecars referenced" {
  local out
  out=$(mktemp)
  local cfg
  cfg=$(mktemp)
  echo 'verifier_enabled: false' > "$cfg"
  source_assembly tests/fixtures/issue-109/round-disabled-from-start/round-01 "$out" "$cfg"
  grep -qE '^scored: 0$' "$out"
  grep -qE '^kept: 2$' "$out"
  grep -qE '^dropped: 0$' "$out"
  grep -qE '^failed: 0$' "$out"
  ! grep -qF '<!-- @@SCORE:' "$out"
}

@test "skills/using-qrspi/SKILL.md still contains the structural markers this mirror depends on" {
  # Drift guard: if any of these markers disappears from the documented
  # snippet, the in-test mirror above is no longer testing the documented
  # behavior. The implementer must either (a) update both the mirror and
  # this assertion to match the new documented snippet or (b) restore the
  # missing marker.
  local protocol
  protocol=$(awk '
    /\*\*Apply-fix protocol\.\*\*/ { in_block=1 }
    in_block && /\*\*Diff handling between rounds/ { exit }
    in_block { print }
  ' skills/using-qrspi/SKILL.md)
  echo "$protocol" | grep -qF 'shopt -s nullglob' || { echo "nullglob marker missing"; return 1; }
  echo "$protocol" | grep -qF '@@FINDING:' || { echo "@@FINDING boundary marker missing"; return 1; }
  echo "$protocol" | grep -qF '@@SCORE:' || { echo "@@SCORE boundary marker missing"; return 1; }
  echo "$protocol" | grep -qF '@@CLEAN:' || { echo "@@CLEAN boundary marker missing"; return 1; }
  echo "$protocol" | grep -qE 'verifier_enabled:|scored:|kept:|dropped:|failed:|clean:' \
    || { echo "YAML totals header markers missing"; return 1; }
  echo "$protocol" | grep -qE 'score *< *80|< *80.*style.*clarity.*correctness' \
    || { echo "score-<-80 + change_type partition logic missing"; return 1; }
}
```

- [ ] **Step 11: Expand `tests/unit/test-config-verifier-enabled-field.bats` to assert the field is read by Apply-fix**

Append to the existing test file (created in commit 3):

```bash
@test "Apply-fix protocol body reads verifier_enabled from config.md" {
  local protocol
  protocol=$(awk '
    /\*\*Apply-fix protocol\.\*\*/ { in_block=1 }
    in_block && /\*\*Diff handling between rounds/ { exit }
    in_block { print }
  ' skills/using-qrspi/SKILL.md)
  echo "$protocol" | grep -qF 'verifier_enabled' \
    || { echo "Apply-fix protocol does not reference verifier_enabled"; return 1; }
}

@test "runtime-backfill code is present in Apply-fix protocol" {
  local protocol
  protocol=$(awk '
    /\*\*Apply-fix protocol\.\*\*/ { in_block=1 }
    in_block && /\*\*Diff handling between rounds/ { exit }
    in_block { print }
  ' skills/using-qrspi/SKILL.md)
  echo "$protocol" | grep -qE 'verifier_enabled missing from config\.md|backfilling default'
}

@test "fresh-run config init writes verifier_enabled: true to config.md" {
  # Spec §1: "Fresh run directories start with verifier_enabled: true (set by
  # the using-qrspi run-init code at run creation)." Shape-agnostic check —
  # the run-init prose lists at least the legacy fields (codex_reviews, route)
  # and must now also include verifier_enabled: true somewhere in the same
  # SKILL.md file. The three field names appear together nowhere else in
  # using-qrspi/SKILL.md (codex_reviews / route / verifier_enabled), so a
  # whole-file presence triple is sufficient and shape-independent.
  grep -qE '^[[:space:]]*[-*][[:space:]]*`?codex_reviews`?:|codex_reviews:[[:space:]]+(true|false)' skills/using-qrspi/SKILL.md \
    || { echo "codex_reviews not present in using-qrspi/SKILL.md"; return 1; }
  grep -qE '^[[:space:]]*[-*][[:space:]]*`?route`?:|route:[[:space:]]+' skills/using-qrspi/SKILL.md \
    || { echo "route not present in using-qrspi/SKILL.md"; return 1; }
  # The new field must appear with a literal `true` default in a run-init
  # context — the simplest shape-agnostic check is "verifier_enabled: true"
  # appearing somewhere in the file (the schema doc + the run-init template
  # both contain it; if either is missing, this fails).
  grep -qE 'verifier_enabled:[[:space:]]*true' skills/using-qrspi/SKILL.md \
    || { echo "verifier_enabled: true not present in using-qrspi/SKILL.md (run-init template missing the field)"; return 1; }
  # Stronger shape: the run-init template region typically appears in a
  # fenced code block. Assert at least one ```yaml/```bash/```markdown fenced
  # block contains both `route:` and `verifier_enabled:` together — that's the
  # template-shape signal.
  awk '
    /^```/ { in_fence = !in_fence; if (!in_fence) { if (has_route && has_ve) { print "TEMPLATE_FENCE_OK"; exit }; has_route=0; has_ve=0 } }
    in_fence && /^[[:space:]]*route:/ { has_route=1 }
    in_fence && /^[[:space:]]*verifier_enabled:[[:space:]]*true/ { has_ve=1 }
  ' skills/using-qrspi/SKILL.md | grep -q '^TEMPLATE_FENCE_OK$' \
    || { echo "no fenced code block in using-qrspi/SKILL.md contains both 'route:' and 'verifier_enabled: true' (the run-init template fence)"; return 1; }
}
```

- [ ] **Step 12: Create `tests/unit/test-disabled-mode-fallthrough.bats`**

Per spec §5 test #8.

```bash
#!/usr/bin/env bats

@test "Apply-fix step 3 jumps to step 5 when verifier_enabled is false" {
  local protocol
  protocol=$(awk '
    /\*\*Apply-fix protocol\.\*\*/ { in_block=1 }
    in_block && /\*\*Diff handling between rounds/ { exit }
    in_block { print }
  ' skills/using-qrspi/SKILL.md)
  echo "$protocol" | grep -qE 'verifier_enabled.*false.*jump.*step 5|verifier_enabled.*false.*skip dispatch'
}

@test "Apply-fix step 7 keeps all findings via no-sidecar branch (NOT a synthetic 80 score)" {
  local protocol
  protocol=$(awk '
    /\*\*Apply-fix protocol\.\*\*/ { in_block=1 }
    in_block && /\*\*Diff handling between rounds/ { exit }
    in_block { print }
  ' skills/using-qrspi/SKILL.md)
  echo "$protocol" | grep -qE 'no sidecar.*keep|sidecar absent.*keep|keep-all'
  ! echo "$protocol" | grep -qE 'synthetic.*80|inject.*score.*80|default score 80'
}

@test "Apply-fix step 7 keeps findings whose sidecar is VERIFY_FAILED (degraded-but-uncertain → favor surfacing)" {
  # Spec §3 retry-skip flow depends on this routing: a verifier that returns
  # VERIFY_FAILED degrades to "no useful score" — the safe default is to keep
  # the finding (let the user see it) rather than drop it. Without this branch
  # documented in the prose, the §3 menu's `skip` option would have nothing
  # to fall through to.
  local protocol
  protocol=$(awk '
    /\*\*Apply-fix protocol\.\*\*/ { in_block=1 }
    in_block && /\*\*Diff handling between rounds/ { exit }
    in_block { print }
  ' skills/using-qrspi/SKILL.md)
  echo "$protocol" | grep -qE 'VERIFY_FAILED.*keep|keep.*VERIFY_FAILED|VERIFY_FAILED.*flow.*apply|VERIFY_FAILED.*surface' \
    || { echo "Apply-fix step 7 does not document the VERIFY_FAILED → keep routing"; return 1; }
}

@test "disabled-from-start fixture has NO sidecars on disk" {
  ! ls tests/fixtures/issue-109/round-disabled-from-start/round-01/*.score.yml 2>/dev/null
}
```

- [ ] **Step 13: Create `tests/unit/test-change-type-partition.bats` and `tests/unit/test-clean-sentinel-and-schema-guard.bats`** — both fixture-backed per spec §5

Per spec §5 tests #9 ("Fixture verified.md with mixed `change_type`s + assertion of routing") and #10 ("Negative fixtures assert the failure path"). Both tests combine prose-grep assertions on the protocol body with fixture-backed runtime assertions on the routing/guard logic.

First create the fixtures:

Create `tests/fixtures/issue-109/round-mixed-change-types/round-04/` populated as:

- `quality-claude.finding-F01.md` (`change_type: style`) + `.score.yml` `score: 90`
- `quality-claude.finding-F02.md` (`change_type: clarity`) + `.score.yml` `score: 70`
- `quality-claude.finding-F03.md` (`change_type: correctness`) + `.score.yml` `score: 85`
- `quality-claude.finding-F04.md` (`change_type: scope`) + `.score.yml` `score: 30` (scope is never score-filtered → kept)
- `quality-claude.finding-F05.md` (`change_type: intent`) + `.score.yml` `score: 50` (intent is never score-filtered → kept)

Expected partition with verifier_enabled=true: kept=4 (F01 style@90, F03 correctness@85, F04 scope, F05 intent), dropped=1 (F02 clarity@70 < 80).

Create `tests/fixtures/issue-109/round-missing-tag/round-05/` populated as:

- `quality-claude.finding-F01.md` + `.score.yml` (real, score 88)
- `scope-claude.clean.md` (clean sentinel)
- (NO `quality-codex.*` and NO `scope-codex.*` files — both were expected per the Goals/Design 4-reviewer matrix when `codex_reviews: true`, but neither produced output)

Expected schema-guard verdict: at least one expected tag has zero files → would route to §3 menu.

Create `tests/fixtures/issue-109/round-schema-violations/round-03/` populated as five per-file fixtures, one per spec §1 step-2 schema-guard branch:

- `quality-claude.finding-F01.md` — malformed YAML frontmatter. Body starts with `---` but no closing `---` before the prose body; the YAML parser must reject this.
- `quality-claude.finding-F02.md` — missing required field. Frontmatter has `finding_id`, `severity`, `referenced_files`, `artifact`, `round`, `reviewer` — but NO `change_type` line.
- `quality-claude.finding-F03.md` — bad-enum `change_type: maintenance`. All other fields well-formed; the enum check must reject the unknown value.
- `quality-unknown.finding-F01.md` — unrouted reviewer-tag. Filename uses `quality-unknown` (not in the Routing Table); per-finding contents may be well-formed YAML.
- `quality-claude.finding-F04.md` — trailing-newline malformation. Either no trailing `\n` at all, or `\n\n` (two trailing newlines). Per spec §1 step 2 this is normalized + warning, NOT a hard fail.

Sample first fixture (the others follow the same shape, varying only the violation):

```yaml
---
finding_id: R3-F01
severity: high
change_type: correctness
referenced_files: [skills/design/SKILL.md]
artifact: design
round: 3
reviewer: quality-claude
# (missing closing --- to trigger the malformed-YAML branch)

Sample finding body — the YAML above is unclosed so a parser will not accept it.
```

These fixtures ship with commit 4. The implementer wires them into a runtime parser test at execution time; the bats prose-greps in `test-verifier-dispatch-contract.bats` (Step 8) pin the documented contract independent of these fixtures.

Then write the tests.

`tests/unit/test-change-type-partition.bats`:

```bash
#!/usr/bin/env bats

setup() {
  PROTOCOL=$(awk '
    /\*\*Apply-fix protocol\.\*\*/ { in_block=1 }
    in_block && /\*\*Diff handling between rounds/ { exit }
    in_block { print }
  ' skills/using-qrspi/SKILL.md)
}

@test "scope and intent flow to pause gate REGARDLESS of score" {
  echo "$PROTOCOL" | grep -qE 'scope.*intent.*bypass.*score|scope.*intent.*pause gate.*regardless|scope.*intent.*never.*score-filtered'
}

@test "style/clarity/correctness are score-filtered at >=80" {
  echo "$PROTOCOL" | grep -qE 'style.*clarity.*correctness.*(>=|≥)\s*80|score\s*(>=|≥)\s*80.*style.*clarity.*correctness'
}

@test "out-of-enum change_type triggers loud failure" {
  echo "$PROTOCOL" | grep -qE 'out-of-enum.*loud failure|change_type.*loud failure|schema guard.*change_type'
}

@test "the canonical 5-value change_type enum is cited from reviewer-protocol" {
  grep -qE 'style.*clarity.*correctness.*scope.*intent' skills/reviewer-protocol/SKILL.md
}

@test "fixture-backed partition: scope/intent kept regardless of score, style/clarity/correctness filtered at >=80" {
  # Run the partition logic against the mixed-change-types fixture and assert
  # the spec routing rule: scope/intent always-keep; SCC score-filtered at 80.
  local D=tests/fixtures/issue-109/round-mixed-change-types/round-04
  shopt -s nullglob
  local kept=0 dropped=0
  for f in "$D"/*.finding-*.md; do
    local sc="${f%.md}.score.yml"
    local ct score
    ct=$(awk -F': *' '/^change_type:/ {print $2; exit}' "$f")
    score=$(awk -F': *' '/^score:/ {print $2; exit}' "$sc")
    if [[ "$ct" == "scope" || "$ct" == "intent" ]]; then
      kept=$((kept + 1))
    elif (( score >= 80 )); then
      kept=$((kept + 1))
    else
      dropped=$((dropped + 1))
    fi
  done
  [[ "$kept" -eq 4 ]] || { echo "expected kept=4, got $kept"; return 1; }
  [[ "$dropped" -eq 1 ]] || { echo "expected dropped=1, got $dropped"; return 1; }
}
```

`tests/unit/test-clean-sentinel-and-schema-guard.bats`:

```bash
#!/usr/bin/env bats

@test "reviewer-protocol defines <reviewer_tag>.clean.md sentinel format" {
  grep -qE '<reviewer_tag>\.clean\.md' skills/reviewer-protocol/SKILL.md
  awk '
    /^## Per-Finding Disk-Write Contract/ { in_block=1 }
    in_block && /^## / && !/Per-Finding Disk-Write Contract/ { exit }
    in_block { print }
  ' skills/reviewer-protocol/SKILL.md \
    | grep -qE 'frontmatter-only|reviewer:.*round:.*findings: 0|findings: 0'
}

@test "schema-violation guard fails loud on expected tag with zero finding/clean files" {
  awk '
    /\*\*Apply-fix protocol\.\*\*/ { in_block=1 }
    in_block && /\*\*Diff handling between rounds/ { exit }
    in_block { print }
  ' skills/using-qrspi/SKILL.md \
    | grep -qiE 'expected tag.*no output|expected tag.*zero|fail loud.*§3 menu|§3 menu.*expected tag'
}

@test "Expected-Reviewer Matrix exists in reviewer-protocol" {
  grep -qE '^## Expected-Reviewer Matrix' skills/reviewer-protocol/SKILL.md
}

@test "Reviewer-Tag Routing Table enumerates the four #109 role-distinct tags" {
  awk '
    /^## Reviewer-Tag Routing Table/ { in_block=1 }
    in_block && /^## / && !/Reviewer-Tag Routing Table/ { exit }
    in_block { print }
  ' skills/reviewer-protocol/SKILL.md > /tmp/routing.txt
  grep -qF 'quality-claude' /tmp/routing.txt
  grep -qF 'scope-claude' /tmp/routing.txt
  grep -qF 'quality-codex' /tmp/routing.txt
  grep -qF 'scope-codex' /tmp/routing.txt
}

@test "fixture-backed schema-guard: missing-tag fixture would surface §3 menu" {
  # Spec §5 test #10: "Negative fixtures assert the failure path." The
  # missing-tag fixture has zero quality-codex.* and zero scope-codex.* files.
  # Per the Expected-Reviewer Matrix for the Goals/Design step under
  # codex_reviews:true, both tags are required. A simulated schema-guard
  # invocation against this fixture must detect at least one missing expected
  # tag (the actual guard is implemented in skills/using-qrspi/SKILL.md and
  # validated in test #4 — this fixture-backed assertion verifies the negative
  # fixture exhibits the file shape that triggers the guard).
  local D=tests/fixtures/issue-109/round-missing-tag/round-05
  local found_missing=0
  for tag in quality-claude scope-claude quality-codex scope-codex; do
    if ! ls "$D/${tag}".finding-*.md "$D/${tag}.clean.md" 2>/dev/null | grep -q .; then
      echo "missing expected tag: $tag (would surface §3 menu)"
      found_missing=1
    fi
  done
  [[ "$found_missing" -eq 1 ]] || { echo "negative fixture did not exhibit a missing tag"; return 1; }
}
```

- [ ] **Step 14: Run the full unit suite — every test must pass**

```bash
bats tests/unit/
```

Expected: green. The 7 new tests added in this commit (#2, #4, #5, #6, #8, #9, #10), plus the 2 expansions (#3 dispatching-skill grep, #7 Apply-fix-reads-the-field), plus all pre-existing tests, plus the 3 tests landed in commits 1–3, all pass.

If anything fails, fix the cutover edits — do NOT loosen the tests. The cutover is atomic; any test failure is a real contract violation.

- [ ] **Step 15: Pre-merge smoke matrix**

Per spec §7 step 4. Run a real review round per behavior class. ALL must pass before the commit may merge to main. Use a fresh QRSPI run directory per case so the cases don't pollute each other; the cases share a small set of pre-built fixture artifacts (`docs/qrspi/2026-04-29-v0.4-bundle/` already on disk has a working `goals.md`, `design.md`, etc. — clone its directory under a new bundle name per case).

Setup helper (run once before the cases). Smoke run-bundles MUST live under `docs/qrspi/` because that's where `using-qrspi`'s resume-discovery code scans for `config.md` files; relocating them to `/tmp/` would break the slash-command invocation. To keep `git status` clean, the bundles are gitignored for the duration of the matrix run:

```bash
SMOKE_ROOT=docs/qrspi/_smoke-issue-109   # underscore prefix sorts to top + clearly scratch
rm -rf "$SMOKE_ROOT"   # idempotent — re-running the matrix starts clean
mkdir -p "$SMOKE_ROOT"
# Add a temporary gitignore line so smoke bundles don't pollute git status.
# (Strip on teardown so the gitignore tail doesn't drift across runs.)
printf '\n# Issue #109 smoke matrix — temporary, removed at teardown\n/docs/qrspi/_smoke-issue-109/\n' >> /Users/dfrysinger/Library/CloudStorage/Dropbox/claude-workspace/qrspi-plus/.gitignore
echo "case | outcome | notes" > /tmp/issue-109-smoke-results.txt
```

Teardown (run after the matrix completes — even on failure — to free disk and restore the gitignore):

```bash
# After all cases recorded:
rm -rf docs/qrspi/_smoke-issue-109
# Strip the temporary gitignore line.
sed -i.bak '/# Issue #109 smoke matrix/,/_smoke-issue-109/d' /Users/dfrysinger/Library/CloudStorage/Dropbox/claude-workspace/qrspi-plus/.gitignore
rm -f /Users/dfrysinger/Library/CloudStorage/Dropbox/claude-workspace/qrspi-plus/.gitignore.bak
```

For each case below, the `setup` block creates the per-case run directory, the `command` block triggers the review round, and the `assertion` block is a single grep/test that produces PASS or FAIL into `/tmp/issue-109-smoke-results.txt`.

**How to trigger a real review round.** The `/qrspi resume <step>` references below are slash-command invocations the implementing agent types in its Claude Code session — they are NOT bash commands. The plan annotates these as `# IMPLEMENTING-AGENT-ACTION:` comments to make the invocation site explicit. Each case proceeds in three stages:

1. Run the `setup` bash block to clone and configure the run directory.
2. **Implementing-agent action:** invoke the slash command, which loads the `using-qrspi` Skill and walks the resume protocol against the configured run directory. Wait for the review round to complete (a fresh `round-NN/` subdir is created with new finding/sidecar files; the round number increments past whatever was already in the cloned bundle).
3. Run the `assertion` bash block, which inspects the LATEST round directory (NOT the pre-existing one in the cloned bundle) — the assertion uses `ls -d "$RUN/reviews/<step>/round-"* | tail -1` to find the newly-created round.

Pre-cutover, the cloned bundle's youngest round is round-NN; post-cutover invocation of `/qrspi resume` creates round-(NN+1). Each case captures `BEFORE_COUNT` (count of round directories in the cloned bundle) BEFORE the slash-command, then asserts `AFTER_COUNT > BEFORE_COUNT` BEFORE running the contents grep. Without this enforced numerically, the contents grep could pass against the stale pre-cutover round directory `tail -1` happens to select.

**Case (a) — Questions or Research (no scope reviewer):**

```bash
# setup
RUN=$SMOKE_ROOT/case-a; cp -R docs/qrspi/2026-04-29-v0.4-bundle "$RUN"
sed -i.bak 's/^codex_reviews: .*/codex_reviews: true/' "$RUN/config.md"
BEFORE_A=$(ls -d "$RUN/reviews/questions/round-"* 2>/dev/null | wc -l | tr -d ' ')
# IMPLEMENTING-AGENT-ACTION: /qrspi resume questions   (await new round-NN before running assertion)
# assertion — first verify a NEW round was created (staleness guard), then check the matrix shape.
AFTER_A=$(ls -d "$RUN/reviews/questions/round-"* 2>/dev/null | wc -l | tr -d ' ')
RD=$(ls -d "$RUN/reviews/questions/round-"* 2>/dev/null | sort -V | tail -1)
if [[ "$AFTER_A" -le "$BEFORE_A" ]]; then
  echo "(a) | FAIL | /qrspi resume did not create a new round (BEFORE=$BEFORE_A AFTER=$AFTER_A)" >> /tmp/issue-109-smoke-results.txt
elif ls "$RD"/quality-claude.finding-*.md "$RD"/quality-codex.finding-*.md >/dev/null 2>&1 \
  && ! ls "$RD"/scope-claude.*.md "$RD"/scope-codex.*.md 2>/dev/null; then
  echo "(a) | PASS | quality-only matrix, no scope tag files (round $(basename "$RD"))" >> /tmp/issue-109-smoke-results.txt
else
  echo "(a) | FAIL | matrix mismatch in $RD" >> /tmp/issue-109-smoke-results.txt
fi
```

**Case (b) — Goals or Design (full 4-reviewer set):**

```bash
RUN=$SMOKE_ROOT/case-b; cp -R docs/qrspi/2026-04-29-v0.4-bundle "$RUN"
sed -i.bak 's/^codex_reviews: .*/codex_reviews: true/' "$RUN/config.md"
BEFORE_B=$(ls -d "$RUN/reviews/design/round-"* 2>/dev/null | wc -l | tr -d ' ')
# IMPLEMENTING-AGENT-ACTION: /qrspi resume design   (await new round-NN before running assertion)
AFTER_B=$(ls -d "$RUN/reviews/design/round-"* 2>/dev/null | wc -l | tr -d ' ')
RD=$(ls -d "$RUN/reviews/design/round-"* 2>/dev/null | sort -V | tail -1)
if [[ "$AFTER_B" -le "$BEFORE_B" ]]; then
  echo "(b) | FAIL | /qrspi resume did not create a new round (BEFORE=$BEFORE_B AFTER=$AFTER_B)" >> /tmp/issue-109-smoke-results.txt
elif ls "$RD/quality-claude."*.md "$RD/scope-claude."*.md "$RD/quality-codex."*.md "$RD/scope-codex."*.md >/dev/null 2>&1; then
  echo "(b) | PASS | full 4-reviewer matrix with role-distinct prefixes ($(basename "$RD"))" >> /tmp/issue-109-smoke-results.txt
else
  echo "(b) | FAIL | missing one of the four role-distinct tags in $RD" >> /tmp/issue-109-smoke-results.txt
fi
```

**Case (c) — `verifier_enabled: false` from start:**

```bash
RUN=$SMOKE_ROOT/case-c; cp -R docs/qrspi/2026-04-29-v0.4-bundle "$RUN"
grep -q '^verifier_enabled:' "$RUN/config.md" \
  && sed -i.bak 's/^verifier_enabled: .*/verifier_enabled: false/' "$RUN/config.md" \
  || printf 'verifier_enabled: false\n' >> "$RUN/config.md"
BEFORE_C=$(ls -d "$RUN/reviews/design/round-"* 2>/dev/null | wc -l | tr -d ' ')
# IMPLEMENTING-AGENT-ACTION: /qrspi resume design   (await new round-NN before running assertion)
AFTER_C=$(ls -d "$RUN/reviews/design/round-"* 2>/dev/null | wc -l | tr -d ' ')
RD=$(ls -d "$RUN/reviews/design/round-"* 2>/dev/null | sort -V | tail -1)
VF="$RUN/reviews/design/round-$(basename "$RD" | sed 's/round-//')-verified.md"
if [[ "$AFTER_C" -le "$BEFORE_C" ]]; then
  echo "(c) | FAIL | /qrspi resume did not create a new round (BEFORE=$BEFORE_C AFTER=$AFTER_C)" >> /tmp/issue-109-smoke-results.txt
elif ! ls "$RD"/*.score.yml 2>/dev/null \
  && grep -qE '^verifier_enabled: false$' "$VF" \
  && grep -qE '^scored: 0$' "$VF"; then
  echo "(c) | PASS | no sidecars, header confirms disabled-from-start ($(basename "$RD"))" >> /tmp/issue-109-smoke-results.txt
else
  echo "(c) | FAIL | sidecars present or header malformed in $VF" >> /tmp/issue-109-smoke-results.txt
fi
```

**Case (d) — `codex_reviews: false`:**

```bash
RUN=$SMOKE_ROOT/case-d; cp -R docs/qrspi/2026-04-29-v0.4-bundle "$RUN"
sed -i.bak 's/^codex_reviews: .*/codex_reviews: false/' "$RUN/config.md"
BEFORE_D=$(ls -d "$RUN/reviews/design/round-"* 2>/dev/null | wc -l | tr -d ' ')
# IMPLEMENTING-AGENT-ACTION: /qrspi resume design   (await new round-NN before running assertion)
AFTER_D=$(ls -d "$RUN/reviews/design/round-"* 2>/dev/null | wc -l | tr -d ' ')
RD=$(ls -d "$RUN/reviews/design/round-"* 2>/dev/null | sort -V | tail -1)
if [[ "$AFTER_D" -le "$BEFORE_D" ]]; then
  echo "(d) | FAIL | /qrspi resume did not create a new round (BEFORE=$BEFORE_D AFTER=$AFTER_D)" >> /tmp/issue-109-smoke-results.txt
elif ls "$RD/quality-claude."*.md "$RD/scope-claude."*.md >/dev/null 2>&1 \
  && ! ls "$RD/quality-codex."*.md "$RD/scope-codex."*.md 2>/dev/null; then
  echo "(d) | PASS | claude-only matrix, no codex tags ($(basename "$RD"))" >> /tmp/issue-109-smoke-results.txt
else
  echo "(d) | FAIL | codex tags leaked under codex_reviews:false" >> /tmp/issue-109-smoke-results.txt
fi
```

**Cases (e)/(f)/(g) — failure-path coverage via the unit suite.**

Spec §7 step 4 calls for "a real review round per behavior class" for the smoke matrix. Cases (a)–(d) are real review rounds (cloned bundles, `/qrspi resume`). Cases (e), (f), and (g) — splitter malformed input, `VERIFY_FAILED → skip`, and `VERIFY_FAILED → retry` — would require either an `QRSPI_CODEX_STDOUT_OVERRIDE` env-hook in `scripts/codex-companion-bg.sh launch` (out of scope for #109's cutover — that wrapper is not in the File Structure inventory) or a mid-run swap of `agents/qrspi-finding-verifier.md` (race-prone — there is no synchronization point between menu render and retry dispatch).

Because the underlying behaviors ARE pinned by the unit suite, cases (e)/(f)/(g) are recorded as **PASS via unit-test equivalence**, not as separate end-to-end runs. This is a conscious narrowing of spec §7's smoke gate — accepted because (a) inserting the env-hook would expand the cutover scope beyond the spec's listed file changes and (b) the live-swap timing would produce non-deterministic outcomes that obscure real failures. The narrowing is tracked in the smoke-matrix follow-up issue filed at Task 0 step 4 (number captured in `/tmp/issue-109-smoke-followup-num.txt`); when that issue lands, the PASS-via-unit shortcut is replaced with real review rounds for cases (e)/(f)/(g).

```bash
# (e) — splitter malformed input. Equivalent: tests/unit/test-codex-splitter.bats
# already exercises malformed-input behavior end-to-end (writes nothing, exits
# non-zero, stderr diagnostic). Plus the dispatching-skill grep tests assert
# the splitter is gated on `await` success, so a non-zero `await` exit-or
# malformed stdout cannot reach the splitter side-by-side.
bats /Users/dfrysinger/Library/CloudStorage/Dropbox/claude-workspace/qrspi-plus/tests/unit/test-codex-splitter.bats \
  && echo "(e) | PASS-via-unit | malformed-input behavior pinned by test-codex-splitter.bats" >> /tmp/issue-109-smoke-results.txt \
  || echo "(e) | FAIL-via-unit | test-codex-splitter.bats failed" >> /tmp/issue-109-smoke-results.txt

# (f) — VERIFY_FAILED → skip. Equivalent: test-failure-menu.bats asserts the
# menu prose for the `skip` option (writes round-NN-verifier-disabled.md, does
# NOT mutate config.md). test-disabled-mode-fallthrough.bats asserts the
# kept-all-via-no-sidecar branch the skip path falls through to.
bats /Users/dfrysinger/Library/CloudStorage/Dropbox/claude-workspace/qrspi-plus/tests/unit/test-failure-menu.bats \
  && bats /Users/dfrysinger/Library/CloudStorage/Dropbox/claude-workspace/qrspi-plus/tests/unit/test-disabled-mode-fallthrough.bats \
  && echo "(f) | PASS-via-unit | skip-path semantics pinned by test-failure-menu + test-disabled-mode-fallthrough" >> /tmp/issue-109-smoke-results.txt \
  || echo "(f) | FAIL-via-unit | one of the two unit tests failed" >> /tmp/issue-109-smoke-results.txt

# (g) — VERIFY_FAILED → retry. Equivalent: test-failure-menu.bats asserts the
# menu prose for the `retry` option (re-dispatch the failing verifier; the
# retry-cleanup contract is tested for the reviewer-no-output branch only).
bats /Users/dfrysinger/Library/CloudStorage/Dropbox/claude-workspace/qrspi-plus/tests/unit/test-failure-menu.bats \
  && echo "(g) | PASS-via-unit | retry semantics pinned by test-failure-menu" >> /tmp/issue-109-smoke-results.txt \
  || echo "(g) | FAIL-via-unit | test-failure-menu.bats failed" >> /tmp/issue-109-smoke-results.txt
```

Record results:

```bash
cat /tmp/issue-109-smoke-results.txt
```
Expected: 7 cases listed, all `PASS` or `PASS-via-unit`. If any line shows `FAIL`, do NOT commit. Fix the cutover to address the failure; re-run the affected case. Cases (e)/(f)/(g) honestly record `PASS-via-unit` rather than being claimed as real-round results — this preserves spec §7's intent (every behavior class is verified) while staying within the cutover scope.

- [ ] **Step 16: Substitute `${FOLLOWUP_ISSUE}` everywhere it appears**

The plan uses the literal token `${FOLLOWUP_ISSUE}` in several places that land in shipped files. As of commit-4 staging time, those include: the `## Reviewer-Tag Routing Table` prose body inside `skills/reviewer-protocol/SKILL.md` (Step 1(a)), the deferred-reviewer skip-comment in the freshly-created `tests/unit/test-per-finding-file-emission.bats` (Step 7), and any other file the implementer pasted the token into. (The CHANGELOG body in Task 6 and the PR body in Final integration are addressed by sub-step (c) below; do not skip those.)

Use **plain recursive `grep`** over the working tree — NOT `git grep`, which only sees tracked files and would silently miss the freshly-created untracked test file:

(a) Read the captured follow-up issue number:

```bash
read NUM < /tmp/issue-109-followup-num.txt
[[ "$NUM" =~ ^[0-9]+$ ]] || { echo "follow-up issue number missing or invalid: '$NUM'"; exit 1; }
```

(b) Substitute the token across the working tree (including untracked files), excluding the plan and the spec themselves (which keep the literal token as documentation), the `.git/` directory, and the smoke run-bundles in `/tmp/issue-109-smoke/`:

```bash
# Use find for path-shape exclusion (grep --exclude is glob-shaped per file basename
# and does NOT honor full paths reliably across GNU/BSD); pipe candidate files into
# a token-presence grep, then substitute only files that contain the token. The
# plan and spec themselves are excluded by exact-path -not -path tests, NOT by
# basename globs (which would silently miss files whose basenames happened to match).
REPO=/Users/dfrysinger/Library/CloudStorage/Dropbox/claude-workspace/qrspi-plus
find "$REPO" \
  -type f \
  -not -path "*/.git/*" \
  -not -path "*/node_modules/*" \
  -not -path "$REPO/reviews/*" \
  -not -path "$REPO/docs/superpowers/plans/2026-05-04-109-sonnet-haiku-verifier.md" \
  -not -path "$REPO/docs/superpowers/specs/2026-05-04-109-sonnet-haiku-verifier-design.md" \
  -print0 \
  | xargs -0 grep -lF '${FOLLOWUP_ISSUE}' \
  | xargs -I{} sed -i.bak "s/\${FOLLOWUP_ISSUE}/${NUM}/g" "{}"
# Clean up sed-backup siblings.
find "$REPO" -name '*.bak' -newer /tmp/issue-109-followup-num.txt -delete
```

The `reviews/` exclusion is essential: the `reviews/plan-109/` directory carries past-round finding records that QUOTE the plan's literal `${FOLLOWUP_ISSUE}` token. Substituting it there would corrupt the audit record of those rounds and pollute `git status` with modified-but-unstaged files an implementer might mistake for legitimate cutover changes.

(c) Verify BOTH literal tokens are gone from the shipping working tree (excluding the plan, spec, and reviews — all of which retain them as documentation/audit). The two-token check is load-bearing because the helper at sub-step (d) substitutes both `${FOLLOWUP_ISSUE}` and `${SMOKE_FOLLOWUP_ISSUE}` whenever it runs; if Tasks 6/Final author files containing only the smoke token, a single-token verification would not catch a regression in the helper or a file authored after the helper ran:

```bash
REPO=/Users/dfrysinger/Library/CloudStorage/Dropbox/claude-workspace/qrspi-plus
LEAKED=$(find "$REPO" \
  -type f \
  -not -path "*/.git/*" \
  -not -path "$REPO/reviews/*" \
  -not -path "$REPO/docs/superpowers/plans/2026-05-04-109-sonnet-haiku-verifier.md" \
  -not -path "$REPO/docs/superpowers/specs/2026-05-04-109-sonnet-haiku-verifier-design.md" \
  -print0 \
  | xargs -0 grep -lE '\$\{FOLLOWUP_ISSUE\}|\$\{SMOKE_FOLLOWUP_ISSUE\}' || true)
[[ -z "$LEAKED" ]] || { echo "literal token(s) still present — substitution failed in: $LEAKED"; exit 1; }
echo "all '\${FOLLOWUP_ISSUE}' and '\${SMOKE_FOLLOWUP_ISSUE}' tokens (outside plan/spec/reviews) substituted with their issue numbers"
```

(d) **Reusable helper for Tasks 6 and Final integration.** Save the substitution logic as `/tmp/issue-109-substitute-followup.sh` so Task 6 (CHANGELOG) and Final integration (PR body) can re-run it after they author new files containing the token:

```bash
cat > /tmp/issue-109-substitute-followup.sh <<'HELPER'
#!/usr/bin/env bash
set -euo pipefail
read NUM < /tmp/issue-109-followup-num.txt
[[ "$NUM" =~ ^[0-9]+$ ]] || { echo "follow-up issue number missing or invalid: '$NUM'"; exit 1; }
read SMOKE_NUM < /tmp/issue-109-smoke-followup-num.txt
[[ "$SMOKE_NUM" =~ ^[0-9]+$ ]] || { echo "smoke follow-up issue number missing or invalid: '$SMOKE_NUM'"; exit 1; }
target="${1:-}"
if [[ -n "$target" ]]; then
  sed -i.bak "s/\${FOLLOWUP_ISSUE}/${NUM}/g; s/\${SMOKE_FOLLOWUP_ISSUE}/${SMOKE_NUM}/g" "$target" && rm -f "${target}.bak"
else
  echo "usage: $0 <file>"; exit 2
fi
HELPER
chmod +x /tmp/issue-109-substitute-followup.sh
```

Tasks 6 and Final invoke this helper against the specific file they just authored (CHANGELOG.md and `/tmp/issue-109-pr-body.md` respectively). The helper substitutes BOTH `${FOLLOWUP_ISSUE}` (deferred-reviewer migration) and `${SMOKE_FOLLOWUP_ISSUE}` (smoke-matrix end-to-end coverage gap) so both follow-up issues are linked from the shipped record (CHANGELOG + PR body).

- [ ] **Step 17: Stage all cutover changes**

```bash
git -C /Users/dfrysinger/Library/CloudStorage/Dropbox/claude-workspace/qrspi-plus add \
  skills/reviewer-protocol/SKILL.md \
  skills/using-qrspi/SKILL.md \
  agents/qrspi-goals-reviewer.md \
  agents/qrspi-questions-reviewer.md \
  agents/qrspi-research-reviewer.md \
  agents/qrspi-design-reviewer.md \
  agents/qrspi-phasing-reviewer.md \
  agents/qrspi-structure-reviewer.md \
  agents/qrspi-parallelize-reviewer.md \
  agents/qrspi-replan-reviewer.md \
  agents/qrspi-goals-scope-reviewer.md \
  agents/qrspi-design-scope-reviewer.md \
  agents/qrspi-phasing-scope-reviewer.md \
  agents/qrspi-structure-scope-reviewer.md \
  agents/qrspi-parallelize-scope-reviewer.md \
  agents/qrspi-replan-scope-reviewer.md \
  skills/goals/SKILL.md \
  skills/questions/SKILL.md \
  skills/research/SKILL.md \
  skills/design/SKILL.md \
  skills/phasing/SKILL.md \
  skills/structure/SKILL.md \
  skills/parallelize/SKILL.md \
  skills/replan/SKILL.md \
  tests/unit/test-codex-splitter.bats \
  tests/unit/test-per-finding-file-emission.bats \
  tests/unit/test-verifier-dispatch-contract.bats \
  tests/unit/test-failure-menu.bats \
  tests/unit/test-verified-file-shape.bats \
  tests/unit/test-config-verifier-enabled-field.bats \
  tests/unit/test-disabled-mode-fallthrough.bats \
  tests/unit/test-change-type-partition.bats \
  tests/unit/test-clean-sentinel-and-schema-guard.bats \
  tests/fixtures/issue-109/round-enabled-clean/ \
  tests/fixtures/issue-109/round-disabled-from-start/ \
  tests/fixtures/issue-109/menu-cases/ \
  tests/fixtures/issue-109/round-mixed-change-types/ \
  tests/fixtures/issue-109/round-missing-tag/ \
  tests/fixtures/issue-109/round-schema-violations/
```

Verify the staging matches the file inventory:

```bash
git -C /Users/dfrysinger/Library/CloudStorage/Dropbox/claude-workspace/qrspi-plus diff --cached --stat
```

Expected: ~50 files staged (2 protocol skills + 14 agents + 8 dispatching skills + 9 test files + several fixtures).

- [ ] **Step 18: Commit**

`/tmp/commit-msg-109-c04.txt`:

```
feat(verifier): #109 atomic cutover — Haiku verifier wired into Apply-fix (commit 4/5)

The load-bearing atomic cutover commit. Lands every runtime-behavior change
required for the Sonnet→Haiku confidence verifier in a single commit so main
never has mixed-contract review rounds.

What lands:
- skills/reviewer-protocol/SKILL.md: bifurcated contract (Routing Table +
  Expected-Reviewer Matrix + new Per-Finding Disk-Write Contract for the four
  #109 role-distinct tags + renamed Legacy section for the 18 deferred reviewers).
- 14 reviewer agent files migrated to per-finding emission + clean sentinel +
  five-line brief return (8 quality + 6 scope reviewers for goals/questions/
  research/design/phasing/structure/parallelize/replan).
- 8 dispatching skills updated to pass the role-distinct reviewer_tag, inject
  <<<FINDING-BOUNDARY>>> + NO_FINDINGS + worked examples into Codex prompts,
  and wire scripts/codex-finding-splitter.sh into the await pipeline.
- skills/using-qrspi/SKILL.md Apply-fix protocol replaced with the 10-step
  verifier-aware sequence (enumerate, schema guard, verifier-enabled gate +
  runtime backfill, parallel verifier dispatch, Bash assembly with HTML
  boundary comments, single Read of round-NN-verified.md, change_type
  partition, write fixes, /compact, per-round commit).
- §3 failure menu (skip/retry/stop) added with round-scoped skip,
  retry-cleanup contract, always-on footer, and reviewer-kind-branched
  diagnostic line.

Pre-merge smoke matrix (7 cases):
1. Questions/Research no-scope path — real review round (PASS)
2. Goals/Design full 4-reviewer set — real review round (PASS)
3. verifier_enabled: false from start (kept-all fall-through) — real review round (PASS)
4. codex_reviews: false — real review round (PASS)
5. Splitter malformed input → §3 menu (Codex branch) — PASS-via-unit
   (test-codex-splitter.bats + test-failure-menu.bats pin the behavior;
   real-round execution requires a Codex stdout override outside #109's
   cutover scope; tracked in #${SMOKE_FOLLOWUP_ISSUE})
6. VERIFY_FAILED → skip — PASS-via-unit
   (test-failure-menu.bats + test-disabled-mode-fallthrough.bats; same
   tracking as case 5)
7. VERIFY_FAILED → retry — PASS-via-unit
   (test-failure-menu.bats; same tracking as case 5)

Tests landing in this commit (10 total under tests/unit/):
- test-codex-splitter.bats expanded with the dispatching-skill greps.
- test-config-verifier-enabled-field.bats expanded with Apply-fix-reads-the-field.
- New: test-per-finding-file-emission.bats, test-verifier-dispatch-contract.bats,
  test-failure-menu.bats, test-verified-file-shape.bats,
  test-disabled-mode-fallthrough.bats, test-change-type-partition.bats,
  test-clean-sentinel-and-schema-guard.bats.

Out of scope (per spec §6, tracked in follow-up issue): the 18 deferred
reviewers (5 plan-artifact + plan quality/scope + 8 per-task + implement-gate
+ security-integration + integration-quality). Their reviewer agent files
remain on the legacy single-file contract via the renamed Legacy section.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
```

The commit message above references `${SMOKE_FOLLOWUP_ISSUE}` (case 5's tracking note). Substitute the follow-up issue number into the commit-message file before committing — `git commit -F` does not expand shell variables, so the literal token would otherwise land in permanent history. Re-use the helper from Task 5 step 16(d):

```bash
/tmp/issue-109-substitute-followup.sh /tmp/commit-msg-109-c04.txt
grep -E '\$\{FOLLOWUP_ISSUE\}|\$\{SMOKE_FOLLOWUP_ISSUE\}' /tmp/commit-msg-109-c04.txt \
  && { echo "follow-up token(s) not substituted in commit message"; exit 1; } \
  || echo "commit message: both follow-up tokens substituted"
```

```bash
git -C /Users/dfrysinger/Library/CloudStorage/Dropbox/claude-workspace/qrspi-plus commit -F /tmp/commit-msg-109-c04.txt
```

- [ ] **Step 19: Post-commit verification**

```bash
bats /Users/dfrysinger/Library/CloudStorage/Dropbox/claude-workspace/qrspi-plus/tests/unit/
```
Expected: green. Same suite that was green before the commit must remain green after — the commit did not slip in a regression.

```bash
git -C /Users/dfrysinger/Library/CloudStorage/Dropbox/claude-workspace/qrspi-plus log --oneline -1
```
Expected: shows the new commit at HEAD.

---

## Task 6: Update CHANGELOG (commit 5)

**Files:**
- Modify: `docs/qrspi/CHANGELOG.md`

**Spec reference:** §7 step 5.

- [ ] **Step 1: Confirm the CHANGELOG path; create the file if missing**

```bash
ls /Users/dfrysinger/Library/CloudStorage/Dropbox/claude-workspace/qrspi-plus/docs/qrspi/
test -f /Users/dfrysinger/Library/CloudStorage/Dropbox/claude-workspace/qrspi-plus/docs/qrspi/CHANGELOG.md \
  && head -30 /Users/dfrysinger/Library/CloudStorage/Dropbox/claude-workspace/qrspi-plus/docs/qrspi/CHANGELOG.md \
  || echo "CHANGELOG.md does not yet exist — will create with the verbatim header below"
```

If the CHANGELOG file does not exist (the typical case at #109's commit time, since `docs/qrspi/` carries only run-bundle directories — no neighbor CHANGELOG to mirror), create it with this verbatim two-line header (no blank line before the first entry — the entries themselves carry their own H2 headers and a leading blank line):

```markdown
# QRSPI Changelog

Reverse-chronological list of notable changes to the QRSPI pipeline (skills, agents, scripts, configuration, and pipeline contracts). Newest entry on top. Entries cite the issue number and the spec/plan paths under `docs/superpowers/specs/` and `docs/superpowers/plans/`.
```

The entry from Step 2 below appends directly after this header (with one blank line between).

- [ ] **Step 2: Add the verifier entry to the top of the CHANGELOG**

The new entry text:

```markdown
## 2026-05-DD — Sonnet→Haiku confidence verifier (#109)

Added a Haiku-class confidence verifier between artifact-level reviewer subagents and the orchestrator's apply/pause dispatch. Reviewers now emit one finding per file under `reviews/{step}/round-NN/<reviewer_tag>.finding-F<NN>.md`; main chat dispatches one `qrspi-finding-verifier` (Haiku) per finding-file in parallel; each verifier writes a sidecar `.score.yml` (it never mutates the original); main chat assembles findings + sidecars + clean markers into `round-NN-verified.md` and reads it exactly once.

Findings with `change_type` ∈ {`style`, `clarity`, `correctness`} are filtered at score ≥80 against the verbatim 0–100 rubric from `/code-review`. Findings with `change_type` ∈ {`scope`, `intent`} are NEVER score-filtered — they always reach the user via the existing pause gate.

Configuration: `verifier_enabled` (boolean, default `true`) in `config.md`. The §3 menu's `skip` option disables the verifier for the current round only (no `config.md` mutation); to disable across the whole run, edit `config.md` directly between rounds. CLI-flag opt-out at `/qrspi` invocation is out of scope.

Scope: 14 artifact-level reviewers for `goals`, `questions`, `research`, `design`, `phasing`, `structure`, `parallelize`, `replan`. The 18 deferred reviewers (plan-artifact, plan quality/scope, per-task, implement-gate, security-integration, integration-quality) migrate atomically in follow-up issue #${FOLLOWUP_ISSUE}, which also collapses the bifurcated `reviewer-protocol/SKILL.md` back to a single per-finding contract. Pre-merge smoke-matrix cases (e)/(f)/(g) are pinned by the unit suite rather than executed as real review rounds; end-to-end coverage of those failure paths is tracked in #${SMOKE_FOLLOWUP_ISSUE}.

Wallclock cost: ~3–5 sec per round (parallel Haiku dispatch); token cost: ~$0.045/round at typical N=8 finding-file count. Negligible.

Spec: `docs/superpowers/specs/2026-05-04-109-sonnet-haiku-verifier-design.md`.
```

After writing the CHANGELOG entry, substitute the follow-up issue number using the helper saved by Task 5 step 16(d):

```bash
/tmp/issue-109-substitute-followup.sh /Users/dfrysinger/Library/CloudStorage/Dropbox/claude-workspace/qrspi-plus/docs/qrspi/CHANGELOG.md
```

Then substitute `2026-05-DD` with today's date at commit-creation time:

```bash
TODAY=$(date +%Y-%m-%d)
sed -i.bak "s/2026-05-DD/${TODAY}/g" /Users/dfrysinger/Library/CloudStorage/Dropbox/claude-workspace/qrspi-plus/docs/qrspi/CHANGELOG.md \
  && rm -f /Users/dfrysinger/Library/CloudStorage/Dropbox/claude-workspace/qrspi-plus/docs/qrspi/CHANGELOG.md.bak
```

Verify both substitutions landed:

```bash
CHANGELOG=/Users/dfrysinger/Library/CloudStorage/Dropbox/claude-workspace/qrspi-plus/docs/qrspi/CHANGELOG.md
grep -E '\$\{FOLLOWUP_ISSUE\}|\$\{SMOKE_FOLLOWUP_ISSUE\}' "$CHANGELOG" && { echo "follow-up issue token(s) not substituted in CHANGELOG"; exit 1; } || true
grep -F '2026-05-DD' "$CHANGELOG" && { echo "date placeholder not substituted"; exit 1; } || true
```

- [ ] **Step 3: Commit**

`/tmp/commit-msg-109-c05.txt`:

```
docs(changelog): #109 record Sonnet→Haiku verifier addition (commit 5/5)

Adds the verifier entry to docs/qrspi/CHANGELOG.md. Cites the spec by
stable path, the follow-up issue for deferred reviewers, the cost +
wallclock characterization, and the verifier_enabled configuration.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
```

```bash
git -C /Users/dfrysinger/Library/CloudStorage/Dropbox/claude-workspace/qrspi-plus add docs/qrspi/CHANGELOG.md
git -C /Users/dfrysinger/Library/CloudStorage/Dropbox/claude-workspace/qrspi-plus commit -F /tmp/commit-msg-109-c05.txt
```

- [ ] **Step 4: Confirm clean state**

```bash
git -C /Users/dfrysinger/Library/CloudStorage/Dropbox/claude-workspace/qrspi-plus status
git -C /Users/dfrysinger/Library/CloudStorage/Dropbox/claude-workspace/qrspi-plus log --oneline -6
```
Expected: clean working tree; HEAD shows commits 1–5 of #109 above the spec commits, all on `qrspi-echo/issue-109-sonnet-haiku-verifier`.

---

## Final integration: PR creation

After commit 5 lands and the suite is green:

- [ ] **Step 1: Write the PR body, substitute, then push and open the PR**

The bash blocks below run in this order: (a) push the branch, (b) write the PR body file, (c) substitute the follow-up issue number, (d) verify substitution, (e) invoke `gh pr create`. The PR body file MUST exist (with all `${FOLLOWUP_ISSUE}` tokens replaced) before `gh pr create` runs.

(a) Push the branch:

```bash
git -C /Users/dfrysinger/Library/CloudStorage/Dropbox/claude-workspace/qrspi-plus push -u origin qrspi-echo/issue-109-sonnet-haiku-verifier
```

(b) Write the PR body to `/tmp/issue-109-pr-body.md` (use the Write tool with this content):

```markdown
## Summary

Inserts a Haiku-class confidence verifier between QRSPI's artifact-level reviewer subagents and the orchestrator's apply/pause dispatch. Style/clarity/correctness findings that score <80 against the verbatim `/code-review` rubric are filtered before the apply path. Scope/intent findings are never score-filtered — they always reach the user.

## Test plan

- [ ] Spec self-review (15 codex/claude rounds → NO_FINDINGS at r15)
- [ ] Verifier agent file unit tests
- [ ] Codex splitter unit tests (boundary, NO_FINDINGS, malformed, empty, idempotency)
- [ ] Per-finding emission contract unit test (14 #109-scope agents migrated; 18 deferred remain on legacy)
- [ ] Apply-fix protocol unit test (10-step ordering, single read of round-NN-verified.md, no per-reviewer single-file Read)
- [ ] §3 failure menu unit test (skip/retry/stop, no default, round-scoped skip, always-on footer)
- [ ] Verified-file shape unit test (enabled-clean + disabled-from-start fixtures)
- [ ] Config field unit test (schema doc + Apply-fix-reads-the-field + runtime-backfill carve-out)
- [ ] Disabled-mode fallthrough unit test (no synthetic 80 score)
- [ ] Change-type partition unit test (scope/intent bypass score filter)
- [ ] Clean sentinel + schema guard unit test
- [ ] Pre-merge smoke matrix (7 cases) — see commit 4 message

Closes #109.

Spec: `docs/superpowers/specs/2026-05-04-109-sonnet-haiku-verifier-design.md`.
Plan: `docs/superpowers/plans/2026-05-04-109-sonnet-haiku-verifier.md`.
Follow-ups:
- #${FOLLOWUP_ISSUE} — deferred reviewer migration + reviewer-protocol bifurcation collapse
- #${SMOKE_FOLLOWUP_ISSUE} — smoke-matrix end-to-end coverage of failure paths (e)/(f)/(g)

🤖 Generated with [Claude Code](https://claude.com/claude-code)
```

(c) Substitute the follow-up issue number using the helper from Task 5 step 16(d):

```bash
/tmp/issue-109-substitute-followup.sh /tmp/issue-109-pr-body.md
```

(d) Verify the substitution landed:

```bash
grep -E '\$\{FOLLOWUP_ISSUE\}|\$\{SMOKE_FOLLOWUP_ISSUE\}' /tmp/issue-109-pr-body.md && { echo "follow-up issue token(s) not substituted in PR body"; exit 1; } || echo "PR body substitution OK (both follow-up tokens replaced)"
```

(e) Open the PR:

```bash
gh pr create \
  --repo dfrysinger/qrspi-plus \
  --base main \
  --head qrspi-echo/issue-109-sonnet-haiku-verifier \
  --title "v0.5: #109 — Sonnet→Haiku confidence verifier" \
  --body-file /tmp/issue-109-pr-body.md \
  --draft
```

- [ ] **Step 2: Rebase onto current main and mark PR ready**

At plan-execution time, derive #110's PR number from the issue itself (rather than trusting a hardcoded number that may have been re-assigned during force-pushes), then confirm it merged and rebase #109's branch onto current main:

```bash
PR110=$(gh issue view 110 --repo dfrysinger/qrspi-plus --json closedByPullRequestsReferences --jq '.closedByPullRequestsReferences[0].number')
[[ "$PR110" =~ ^[0-9]+$ ]] || { echo "could not derive PR number for #110"; exit 1; }
echo "deriving #110's PR as #${PR110}"
gh pr view "$PR110" --repo dfrysinger/qrspi-plus --json state --jq '.state' | grep -qx MERGED \
  || { echo "PR #${PR110} for issue #110 is not yet MERGED — wait before rebasing"; exit 1; }
git -C /Users/dfrysinger/Library/CloudStorage/Dropbox/claude-workspace/qrspi-plus fetch origin main
git -C /Users/dfrysinger/Library/CloudStorage/Dropbox/claude-workspace/qrspi-plus rebase origin/main
git -C /Users/dfrysinger/Library/CloudStorage/Dropbox/claude-workspace/qrspi-plus push --force-with-lease origin qrspi-echo/issue-109-sonnet-haiku-verifier
bats /Users/dfrysinger/Library/CloudStorage/Dropbox/claude-workspace/qrspi-plus/tests/unit/
```

Expected: rebase clean (no conflicts — #109 only consumes #110's infrastructure, doesn't overlap on the same files); bats green post-rebase.

```bash
gh pr ready --repo dfrysinger/qrspi-plus   # marks the current branch's PR as ready
```

---

## Risk-driven contingencies

Per spec §7 + §3:

- **If the pre-merge smoke matrix case (e) fails** (splitter-malformed → §3 menu Codex branch): the diagnostic-line wording in `using-qrspi/SKILL.md` does not match the test's regex. Inspect the actual output at the menu render site, update either the wording or the test regex to match (preserving spec §3's reviewer-kind-branched contract).

- **If smoke matrix case (g) fails** (VERIFY_FAILED → retry): the retry path may have re-cleaned files the spec says it should NOT clean (retry for VERIFY_FAILED only re-dispatches the failing verifier; cleanup is for the reviewer-no-output path only). Inspect the retry implementation against spec §3.

- **If commit 4's smoke matrix case (b) shows the routing-table disambiguation failing** (e.g. scope-claude finding files getting mis-routed to quality-claude): the role-distinct rename is not load-bearing in the runtime code — verify all 8 dispatching skills pass the per-role tag and the agent files preserve it in their per-finding filenames.

- **If a reviewer agent file's brief return is too verbose post-migration** (re-introducing the cache-read bloat #110 fixed): re-read the spec §1 brief-return shape (five lines: `Step / Round / Reviewer / Findings / Written to`) and ensure the reviewer agent body explicitly forbids per-finding detail in the return.

- **If the runtime-backfill warning fires on every `/compact`** (instead of once per resume): the warning state is not being persisted across `/compact`. Wire the warning to fire only when the field is genuinely missing from `config.md`, not when the in-memory state is empty post-compact. After backfill, the field is on disk; subsequent `/compact` cycles re-read the file.

- **If `verifier_enabled: false` from start produces an unparseable `round-NN-verified.md`** (smoke case c): the assembly bash is treating the missing-sidecar branch differently from the disabled-from-start branch. Both must produce a well-formed verified file with `scored: 0` and `kept` equal to total finding count — see spec §1 step 5 ("Sidecars are emitted only when present on disk").
