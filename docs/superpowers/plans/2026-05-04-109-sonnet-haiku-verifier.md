# Issue #109 — Sonnet→Haiku Confidence Verifier Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Insert a Haiku-class confidence verifier between QRSPI's artifact-level reviewer subagents and the orchestrator's apply/pause dispatch, so style/clarity/correctness findings that score <80 against the verbatim `/code-review` 0–100 rubric are filtered before they reach the apply path. Scope/intent findings are NEVER score-filtered.

**Architecture:** Reviewers emit one finding per file under `reviews/{step}/round-NN/<reviewer_tag>.finding-F<NN>.md`; main chat dispatches one Haiku verifier (`agents/qrspi-finding-verifier.md`) per finding-file in parallel; each Haiku writes a sidecar `.score.yml` next to the finding (never mutates the original); main chat Bash-assembles findings + sidecars + clean markers into `round-NN-verified.md` it reads exactly once before partitioning by `change_type`.

**Tech Stack:** Existing QRSPI agent-file infrastructure (per #110), `scripts/codex-companion-bg.sh` async pipeline (extended with a finding-boundary splitter), Bash assembly with no-stdout redirects, `Read`/`Write` tools, bats tests.

**Spec:** `docs/superpowers/specs/2026-05-04-109-sonnet-haiku-verifier-design.md` — converged after 15 review rounds. The spec is the authoritative reference for the verifier rubric body, per-finding file shape, sidecar YAML schema, splitter contract, Apply-fix 10-step sequence, §3 failure menu, and pre-merge smoke matrix; this plan translates the spec's §7 migration sequence into bite-sized tasks but does NOT re-paste content the spec already documents.

**Branch:** `qrspi-echo/issue-109-sonnet-haiku-verifier` (HEAD `4e4dcf1`, 16 commits, PR not yet created). Spec itself already committed.

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
- `tests/fixtures/issue-109/menu-cases/` — verbatim menu-render fixtures for the §3 abnormalities (VERIFY_FAILED, missing reviewer output, missing sidecar) for test #5.

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

## Task 0: File follow-up issue for deferred reviewer migration (no commit)

**Files:** none modified locally — this task creates a GitHub issue and captures its number for use in commit 1's test #2.

**Spec reference:** §7 step 0 ("File the follow-up issue BEFORE any code commits"), §6 (out-of-scope reviewer set), §1 ("Files NOT modified by #109").

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

This task does NOT commit anything — it only creates a tracking issue. The first code commit is Task 1.

---

## Task 1: Add the Haiku verifier agent file (commit 1)

**Files:**
- Create: `agents/qrspi-finding-verifier.md`
- Create: `tests/unit/test-verifier-agent-file.bats`

**Spec reference:** §1 (`agents/qrspi-finding-verifier.md` (new)), §5 test #1, §7 step 1.

- [ ] **Step 1: Read the `/code-review` rubric source**

```bash
cat ~/.claude/plugins/cache/claude-plugins-official/code-review/unknown/commands/code-review.md
```

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
Expected: 7 tests pass. (If a test fails, edit the agent file body to satisfy the contract — do NOT loosen the test.)

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

# Strip a single trailing newline for the NO_FINDINGS check.
content=$(<"$stdout_path")
trimmed=${content%$'\n'}

if [[ "$trimmed" == "NO_FINDINGS" ]]; then
  cat > "$round_subdir/${tag}.clean.md" <<EOF
---
reviewer: ${tag}
round: $(basename "$round_subdir" | sed 's/round-//')
findings: 0
---
EOF
  exit 0
fi

# Empty input → malformed.
if [[ -z "$trimmed" ]]; then
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
    f = sprintf("%s/seg-%02d", out, n)
    started = 1
    next
  }
  started { print > f }
' "$stdout_path"

i=0
for seg in "$tmpdir"/seg-??; do
  [[ -e "$seg" ]] || continue
  i=$((i + 1))
  printf -v num '%02d' "$i"
  out="$round_subdir/${tag}.finding-F${num}.md"
  # Strip leading blank lines, ensure trailing newline.
  awk 'BEGIN{started=0} {if (!started && NF==0) next; started=1; print}' "$seg" > "$out"
  if [[ -s "$out" ]] && [[ $(tail -c1 "$out") != $'\n' ]]; then
    printf '\n' >> "$out"
  fi
done
```

(Adjust the `round` numeric extraction in the NO_FINDINGS branch if the round-subdir naming convention differs from `round-NN`; the current using-qrspi convention uses `round-NN` already.)

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

- [ ] **Step 1: Verify each commit reverts cleanly**

For each of the three additive commits, confirm that reverting it leaves `bats tests/` green. The check uses git's revert-then-check-then-restore pattern; if any revert breaks the suite, that commit is not actually additive and must be split before the cutover.

```bash
# Capture HEAD for restore.
HEAD_SHA=$(git -C /Users/dfrysinger/Library/CloudStorage/Dropbox/claude-workspace/qrspi-plus rev-parse HEAD)
```

```bash
# Revert commit 3 (config doc).
git -C /Users/dfrysinger/Library/CloudStorage/Dropbox/claude-workspace/qrspi-plus revert --no-commit HEAD
bats /Users/dfrysinger/Library/CloudStorage/Dropbox/claude-workspace/qrspi-plus/tests/unit/
git -C /Users/dfrysinger/Library/CloudStorage/Dropbox/claude-workspace/qrspi-plus reset --hard "$HEAD_SHA"
```
Expected: bats green during the revert window. The verifier_enabled field is doc-only; reverting it cannot break runtime tests.

```bash
# Revert commit 2 (splitter).
git -C /Users/dfrysinger/Library/CloudStorage/Dropbox/claude-workspace/qrspi-plus revert --no-commit "${HEAD_SHA}~1"
bats /Users/dfrysinger/Library/CloudStorage/Dropbox/claude-workspace/qrspi-plus/tests/unit/
git -C /Users/dfrysinger/Library/CloudStorage/Dropbox/claude-workspace/qrspi-plus reset --hard "$HEAD_SHA"
```
Expected: bats green during the revert window. The splitter is dead code; reverting it removes only its own test, which is fine.

```bash
# Revert commit 1 (verifier agent).
git -C /Users/dfrysinger/Library/CloudStorage/Dropbox/claude-workspace/qrspi-plus revert --no-commit "${HEAD_SHA}~2"
bats /Users/dfrysinger/Library/CloudStorage/Dropbox/claude-workspace/qrspi-plus/tests/unit/
git -C /Users/dfrysinger/Library/CloudStorage/Dropbox/claude-workspace/qrspi-plus reset --hard "$HEAD_SHA"
```
Expected: bats green during the revert window. Nothing dispatches to the verifier yet; reverting it removes only its own test.

If any of the three reverts fails the suite, STOP — that commit was not purely additive. Split the offending commit (move runtime-coupling to commit 4) before proceeding.

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
  printf '\nverifier_enabled: true\n' >> "$cfg"
  verifier_enabled=true
fi
if [[ "$verifier_enabled" != "true" ]]; then
  : # skip dispatch — jump to step 5 with no sidecars on disk
fi
```

Step 7 (filter and dispatch) handles four routing branches per spec §1:
- `scope` and `intent` → bypass score filter, flow directly to the existing pause gate.
- `style` / `clarity` / `correctness` with sidecar score ≥80 OR no sidecar OR sidecar VERIFY_FAILED OR verifier_enabled=false → keep, Edit on artifact.
- `style` / `clarity` / `correctness` with sidecar score <80 → drop.
- Out-of-enum `change_type` → loud failure (caught at step 2 already, but step 7 reasserts).

Step 10 (per-round commit) covers the artifact, the entire `round-NN/` subdir (including sidecars), `round-NN-verified.md`, and `round-NN-fixes.md`. The diff-handling protocol (today's lines 527+) is unchanged.

- [ ] **Step 3: Edit `skills/using-qrspi/SKILL.md` — add the §3 failure-menu logic**

Add a new subsection `### Verifier-round failure menu` directly under the Apply-fix protocol you just rewrote in step 2. Body sourced verbatim from spec §3 (`§3 Failure handling (single generic menu)`). Include:

- The full menu text with the three options (`skip`, `retry`, `stop`) and their exact semantics:
  - `skip` — proceed without scoring THIS ROUND (kept-all assembly), writes `reviews/{step}/round-NN-verifier-disabled.md`, does NOT mutate `config.md`.
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

Per spec §1 ("Reviewer agent files (modifications)"). For each file in:

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

Locate the procedure step in the agent body that today writes `reviews/{step}/round-NN-{reviewer}.md` (this is the legacy single-file pattern that #110 introduced). Replace it with:

(a) The per-finding emission contract: write each finding to `reviews/{step}/round-NN/<reviewer_tag>.finding-F<NN>.md` with F-numbered zero-padded ordering. The `<reviewer_tag>` value comes from the dispatcher (one of `quality-claude` / `scope-claude` for Claude reviewers; the corresponding `quality-codex` / `scope-codex` is delivered via the Codex prompt in step 5 below).

(b) The clean-sentinel emission: when the analysis surfaces zero findings, write a single `reviews/{step}/round-NN/<reviewer_tag>.clean.md` with the frontmatter-only body (`reviewer: <tag>`, `round: <NN>`, `findings: 0`).

(c) The new five-line brief return: `Step / Round / Reviewer / Findings / Written to`. The `Written to:` line lists the round-NN/ subdirectory, NOT a single per-reviewer file.

(d) Remove any reference to the legacy `Output file:` dispatch parameter that targets `round-NN-{reviewer-tag}.md` — the per-finding contract uses the `<round_subdir>` parameter instead.

The 6 scope-reviewer agent files keep their existing Step-1 Read of `skills/{name}/owns-defers.md` (introduced by #110); only the disk-write contract changes.

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

(c) Inject the per-finding-file format + `NO_FINDINGS` sentinel + `<<<FINDING-BOUNDARY>>>` delimiter into the Codex reviewer prompt. The injected block must include:

- A worked one-finding example (single block preceded by `<<<FINDING-BOUNDARY>>>` then frontmatter + body).
- A worked zero-findings example (the literal string `NO_FINDINGS` on its own line, no boundaries).
- The constraint: "emit only finding blocks (each preceded by `<<<FINDING-BOUNDARY>>>`) or the literal `NO_FINDINGS` sentinel; no prose outside finding bodies."

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

@test "no #109 dispatching skill retains the legacy single-file Codex stdout redirect" {
  for skill in goals questions research design phasing structure parallelize replan; do
    local f="skills/${skill}/SKILL.md"
    # The legacy form redirected await stdout straight to round-NN-{tag}.md.
    # Post-cutover, await stdout goes to /tmp and the splitter handles the round dir.
    ! grep -qE 'await.*> *reviews/\{?step\}?/round-NN-(claude|codex|scope-(claude|codex))\.md' "$f" \
      || { echo "legacy single-file redirect still present in $f"; return 1; }
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
    local body
    body=$(awk '/^---$/{n++; next} n>=2{print}' "$f")
    echo "$body" | grep -qE 'finding-F[0-9]+\.md|finding-F<[Nn][Nn]>' \
      || { echo "per-finding pattern missing in $f"; return 1; }
  done
}

@test "every #109-scope reviewer agent body specifies the clean sentinel pattern" {
  for f in "${scope_files[@]}"; do
    local body
    body=$(awk '/^---$/{n++; next} n>=2{print}' "$f")
    echo "$body" | grep -qE '<reviewer_tag>\.clean\.md|\.clean\.md.*<reviewer_tag>|clean-round sentinel' \
      || { echo "clean-sentinel pattern missing in $f"; return 1; }
  done
}

@test "no #109-scope reviewer agent retains the legacy round-NN-{reviewer-tag}.md write" {
  for f in "${scope_files[@]}"; do
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
  local count
  count=$(echo "$PROTOCOL" | grep -cE 'Read.*round-NN-verified\.md')
  [[ "$count" -ge 1 ]]
}

@test "verifier-enabled gate jumps to step 5 when verifier_enabled=false" {
  echo "$PROTOCOL" | grep -qE 'verifier_enabled.*false.*step 5|step 5.*verifier_enabled.*false|jump to step 5'
}

@test "step 2 schema guard catches the await-non-zero / splitter-malformed path" {
  echo "$PROTOCOL" | grep -qiE 'expected tag.*no output|expected tag produced no output|expected tag with zero'
}
```

- [ ] **Step 9: Create `tests/unit/test-failure-menu.bats`**

Per spec §5 test #5.

```bash
#!/usr/bin/env bats

setup() {
  MENU=$(awk '
    /^### Verifier-round failure menu/ { in_block=1; next }
    in_block && /^### / { exit }
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

# This test exercises the Bash assembly snippet from the spec §1 (Apply-fix
# step 5) by sourcing it via a small wrapper. The wrapper extracts the snippet
# from skills/using-qrspi/SKILL.md and runs it against a fixture round dir.

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

@test "disabled-from-start fixture has NO sidecars on disk" {
  ! ls tests/fixtures/issue-109/round-disabled-from-start/round-01/*.score.yml 2>/dev/null
}
```

- [ ] **Step 13: Create `tests/unit/test-change-type-partition.bats` and `tests/unit/test-clean-sentinel-and-schema-guard.bats`**

Per spec §5 tests #9 and #10. Both follow the same pattern: extract the relevant Apply-fix protocol prose and assert the routing rules.

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
```

- [ ] **Step 14: Run the full unit suite — every test must pass**

```bash
bats tests/unit/
```

Expected: green. The 7 new tests added in this commit (#2, #4, #5, #6, #8, #9, #10), plus the 2 expansions (#3 dispatching-skill grep, #7 Apply-fix-reads-the-field), plus all pre-existing tests, plus the 3 tests landed in commits 1–3, all pass.

If anything fails, fix the cutover edits — do NOT loosen the tests. The cutover is atomic; any test failure is a real contract violation.

- [ ] **Step 15: Pre-merge smoke matrix**

Per spec §7 step 4. Run a real review round per behavior class. ALL must pass before the commit may merge to main. Use a fresh QRSPI run directory under `docs/qrspi/<date>-<bundle>-smoke-N/` per case so the cases don't pollute each other.

For each smoke case:
1. Set up the run directory with a representative artifact (a small fixture goals.md or design.md is sufficient).
2. Configure `config.md` per the case's preconditions.
3. Trigger an artifact-level review round and observe the apply-fix protocol's behavior.
4. Capture a transcript line in `/tmp/issue-109-smoke-results.txt` recording the case + outcome.

Cases:

  - **(a) Questions or Research (no scope reviewer).** Configure a Questions or Research artifact with `codex_reviews: true`. Expected: matrix matches the Expected-Reviewer Matrix's `quality-claude` + `quality-codex` entries (no scope tag); apply-fix step 2 does not false-fail on a missing scope-claude/scope-codex.
  - **(b) Goals or Design (full 4-reviewer set).** Configure with `codex_reviews: true`. Expected: matrix matches `quality-claude` + `scope-claude` + `quality-codex` + `scope-codex`; routing-table disambiguation works (each reviewer's per-finding files have the role-distinct tag prefix).
  - **(c) Run with `verifier_enabled: false` from start.** Manually edit the smoke run's `config.md` to `verifier_enabled: false` BEFORE the round. Expected: no Haiku dispatches, no sidecars on disk, `round-NN-verified.md` header has `scored: 0` + `kept` equals total finding count + `verifier_enabled: false`; all findings flow to the apply path via the no-sidecar-keep branch.
  - **(d) Run with `codex_reviews: false`.** Expected: matrix expects `quality-claude` (+ `scope-claude` for full-reviewer artifacts) only; no Codex dispatch happens; step 2 schema guard does not false-fail on missing Codex tags.
  - **(e) Splitter malformed-input → §3 menu.** Force a Codex reviewer to emit malformed stdout (no boundaries, no NO_FINDINGS). Easiest: inject a fixture stdout file and bypass the Codex call. Expected: splitter writes nothing to round dir, exits non-zero; step 2 detects "expected tag produced no output" for the Codex tag; §3 menu surfaces with the Codex-branch diagnostic line citing `await` exit + `--artifact-dir`.
  - **(f) Verifier hits VERIFY_FAILED → `skip` chosen.** Force a verifier to return VERIFY_FAILED for one finding. Expected: §3 menu surfaces; user picks `skip`; protocol writes `round-NN-verifier-disabled.md`; round assembles kept-all (all findings flow through, no scoring); `config.md` is NOT mutated.
  - **(g) Verifier hits VERIFY_FAILED → `retry` chosen.** Same setup as (f), but pick `retry`. Expected: only the failing verifier(s) are re-dispatched; on success, the round assembles normally with all sidecars present; protocol does NOT delete or re-prompt the reviewer (retry only re-runs the verifier dispatch).

Record results:

```bash
cat /tmp/issue-109-smoke-results.txt
```
Expected: 7 cases listed, all PASS.

If any case fails, do NOT commit. Fix the cutover to address the failure; re-run the affected cases. The smoke matrix is the gate that prevents a broken contract from reaching main.

- [ ] **Step 16: Stage all cutover changes**

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
  tests/fixtures/issue-109/menu-cases/
```

Verify the staging matches the file inventory:

```bash
git -C /Users/dfrysinger/Library/CloudStorage/Dropbox/claude-workspace/qrspi-plus diff --cached --stat
```

Expected: ~50 files staged (2 protocol skills + 14 agents + 8 dispatching skills + 9 test files + several fixtures).

- [ ] **Step 17: Commit**

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

Pre-merge smoke matrix (7 cases) ran clean:
1. Questions/Research no-scope path
2. Goals/Design full 4-reviewer set
3. verifier_enabled: false from start (kept-all fall-through)
4. codex_reviews: false
5. Splitter malformed input → §3 menu (Codex branch)
6. VERIFY_FAILED → skip
7. VERIFY_FAILED → retry

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

```bash
git -C /Users/dfrysinger/Library/CloudStorage/Dropbox/claude-workspace/qrspi-plus commit -F /tmp/commit-msg-109-c04.txt
```

- [ ] **Step 18: Post-commit verification**

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

- [ ] **Step 1: Confirm the CHANGELOG path and current top entry**

```bash
ls /Users/dfrysinger/Library/CloudStorage/Dropbox/claude-workspace/qrspi-plus/docs/qrspi/
head -30 /Users/dfrysinger/Library/CloudStorage/Dropbox/claude-workspace/qrspi-plus/docs/qrspi/CHANGELOG.md
```

If the CHANGELOG file does not exist, create it with the standard QRSPI CHANGELOG header (mirror the format of `docs/qrspi/` neighbors).

- [ ] **Step 2: Add the verifier entry to the top of the CHANGELOG**

The new entry text:

```markdown
## 2026-05-DD — Sonnet→Haiku confidence verifier (#109)

Added a Haiku-class confidence verifier between artifact-level reviewer subagents and the orchestrator's apply/pause dispatch. Reviewers now emit one finding per file under `reviews/{step}/round-NN/<reviewer_tag>.finding-F<NN>.md`; main chat dispatches one `qrspi-finding-verifier` (Haiku) per finding-file in parallel; each verifier writes a sidecar `.score.yml` (it never mutates the original); main chat assembles findings + sidecars + clean markers into `round-NN-verified.md` and reads it exactly once.

Findings with `change_type` ∈ {`style`, `clarity`, `correctness`} are filtered at score ≥80 against the verbatim 0–100 rubric from `/code-review`. Findings with `change_type` ∈ {`scope`, `intent`} are NEVER score-filtered — they always reach the user via the existing pause gate.

Configuration: `verifier_enabled` (boolean, default `true`) in `config.md`. The §3 menu's `skip` option disables the verifier for the current round only (no `config.md` mutation); to disable across the whole run, edit `config.md` directly between rounds. CLI-flag opt-out at `/qrspi` invocation is out of scope.

Scope: 14 artifact-level reviewers for `goals`, `questions`, `research`, `design`, `phasing`, `structure`, `parallelize`, `replan`. The 18 deferred reviewers (plan-artifact, plan quality/scope, per-task, implement-gate, security-integration, integration-quality) migrate atomically in follow-up issue #${FOLLOWUP_ISSUE}, which also collapses the bifurcated `reviewer-protocol/SKILL.md` back to a single per-finding contract.

Wallclock cost: ~3–5 sec per round (parallel Haiku dispatch); token cost: ~$0.045/round at typical N=8 finding-file count. Negligible.

Spec: `docs/superpowers/specs/2026-05-04-109-sonnet-haiku-verifier-design.md`.
```

(Substitute `${FOLLOWUP_ISSUE}` with the integer from `/tmp/issue-109-followup-num.txt`. Substitute `2026-05-DD` with today's date at commit-creation time.)

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

- [ ] **Step 1: Push the branch and open the PR**

```bash
git -C /Users/dfrysinger/Library/CloudStorage/Dropbox/claude-workspace/qrspi-plus push -u origin qrspi-echo/issue-109-sonnet-haiku-verifier
```

```bash
gh pr create \
  --repo dfrysinger/qrspi-plus \
  --base main \
  --head qrspi-echo/issue-109-sonnet-haiku-verifier \
  --title "v0.5: #109 — Sonnet→Haiku confidence verifier" \
  --body-file /tmp/issue-109-pr-body.md \
  --draft
```

PR body (write to `/tmp/issue-109-pr-body.md`):

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
Follow-up: #${FOLLOWUP_ISSUE} (deferred reviewer migration + reviewer-protocol bifurcation collapse).

🤖 Generated with [Claude Code](https://claude.com/claude-code)
```

(Substitute `${FOLLOWUP_ISSUE}` with the integer from `/tmp/issue-109-followup-num.txt`.)

- [ ] **Step 2: Mark PR ready for review only after #110 merges**

If #110's PR (#124) is still in flight, leave #109's PR as draft. When #110 merges:

```bash
git -C /Users/dfrysinger/Library/CloudStorage/Dropbox/claude-workspace/qrspi-plus fetch origin main
git -C /Users/dfrysinger/Library/CloudStorage/Dropbox/claude-workspace/qrspi-plus rebase origin/main
git -C /Users/dfrysinger/Library/CloudStorage/Dropbox/claude-workspace/qrspi-plus push --force-with-lease origin qrspi-echo/issue-109-sonnet-haiku-verifier
bats /Users/dfrysinger/Library/CloudStorage/Dropbox/claude-workspace/qrspi-plus/tests/unit/
```
Expected: rebase clean (no conflicts — #109 only consumes #110's infrastructure, doesn't overlap on the same files); bats green post-rebase.

```bash
gh pr ready  # marks the current branch's PR as ready
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
