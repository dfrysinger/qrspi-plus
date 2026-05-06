#!/usr/bin/env bats
#
# #112 PR-1 — Mechanism A regression: orchestrator-generated round-NN.diff
# wired into the reviewer dispatch contract.
#
# Test scope is intentionally narrow per the PR-1 spec test plan:
#   1. using-qrspi/SKILL.md documents the orchestrator's
#      `git diff <base-branch> -- <artifact> > reviews/{step}/round-NN.diff`
#      step.
#   2. reviewer-protocol/SKILL.md documents the `<diff_file_path>` reviewer
#      dispatch parameter.
#   3. All 12 in-scope per-step SKILL.md files reference `round-NN.diff`
#      somewhere in their reviewer-dispatch prose (`skills/test/SKILL.md`
#      opts out per spec §2.6 and is verified absent).
#   4. All in-scope reviewer agents under `agents/` mention the
#      `diff_file_path` parameter or the `round-NN.diff` Read pattern
#      (excluding `qrspi-test-coverage-reviewer.md` per the spec opt-out
#      and `qrspi-finding-verifier.md` which already documented the
#      contract from #109).
#   5. `skills/test/SKILL.md` does NOT add diff-file wiring — explicit
#      regression guard for the spec opt-out.
#
# Anti-vacuous-pass discipline:
#   - String match on "round-NN.diff" is the load-bearing surface (the
#     literal path the orchestrator writes and reviewers read).
#   - Per-file assertion failures print the offending file path so a
#     missed sweep surfaces a clear diagnostic.
#
# This file deliberately does NOT assert anything about HEAD~1, scope-set,
# scope_hint, qrspi-scope-tagger, or convergence narrowing — those live in
# PR-2 of #112 and must remain absent from PR-1.

setup() {
  REPO_ROOT="$BATS_TEST_DIRNAME/../.."
  export REPO_ROOT
  # The PR-1 changeset surface is enumerated symmetrically across both
  # negative scans below. Globbing agents/qrspi-*-reviewer.md is overbroad;
  # this list mirrors the positive Read-pattern enumeration above so
  # positive and negative assertions are scope-aligned.
  PR1_CHANGESET_SURFACE=(
    skills/using-qrspi/SKILL.md
    skills/reviewer-protocol/SKILL.md
    skills/goals/SKILL.md
    skills/questions/SKILL.md
    skills/research/SKILL.md
    skills/design/SKILL.md
    skills/phasing/SKILL.md
    skills/structure/SKILL.md
    skills/parallelize/SKILL.md
    skills/replan/SKILL.md
    skills/plan/SKILL.md
    skills/integrate/SKILL.md
    skills/implement/SKILL.md
    skills/test/SKILL.md
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
    agents/qrspi-plan-reviewer.md
    agents/qrspi-plan-scope-reviewer.md
    agents/qrspi-plan-spec-reviewer.md
    agents/qrspi-plan-security-reviewer.md
    agents/qrspi-plan-goal-traceability-reviewer.md
    agents/qrspi-plan-test-coverage-reviewer.md
    agents/qrspi-plan-silent-failure-hunter.md
    agents/qrspi-implement-gate-reviewer.md
    agents/qrspi-integration-reviewer.md
    agents/qrspi-security-integration-reviewer.md
    agents/qrspi-spec-reviewer.md
    agents/qrspi-code-quality-reviewer.md
    agents/qrspi-goal-traceability-reviewer.md
    agents/qrspi-security-reviewer.md
    agents/qrspi-silent-failure-hunter.md
    agents/qrspi-code-simplifier.md
    agents/qrspi-type-design-analyzer.md
  )
}

# -----------------------------------------------------------------------------
# 1. using-qrspi/SKILL.md documents the orchestrator step
# -----------------------------------------------------------------------------

@test "[112-PR1] using-qrspi/SKILL.md documents orchestrator-emitted round-NN.diff" {
  local f="$REPO_ROOT/skills/using-qrspi/SKILL.md"
  [ -f "$f" ]
  # Literal path the orchestrator writes.
  grep -qF "round-NN.diff" "$f"
  # The git-diff-against-base-branch redirect is the load-bearing mechanic.
  # Co-occurrence on a single line: `git diff` (or `git -C ... diff`) +
  # `<base-branch>` + redirect into round-NN.diff. Tolerate both the
  # un-quoted prose form and the fail-loud quoted-placeholder form
  # introduced by BLOCKING-3 (`git -C "<repo>" diff "<base-branch>" --
  # "<artifact_path>" > "<ABS_ARTIFACT_DIR>/...round-NN.diff"`).
  grep -E "git( -C [^ ]*)? diff.*<base-branch>.*>.*round-NN\.diff" "$f" >/dev/null
}

@test "[112-PR1] using-qrspi/SKILL.md artifact-tree includes round-NN.diff entry" {
  local f="$REPO_ROOT/skills/using-qrspi/SKILL.md"
  # The artifact tree per-round directory listing must include round-01.diff
  # (or round-NN.diff) so a reader auditing the run layout knows the file is
  # an expected per-round artifact.
  grep -qE "round-(NN|01)\.diff" "$f"
}

# -----------------------------------------------------------------------------
# 2. reviewer-protocol/SKILL.md documents the <diff_file_path> parameter
# -----------------------------------------------------------------------------

@test "[112-PR1] reviewer-protocol/SKILL.md ## Reviewer Dispatch Contract heading is present" {
  local f="$REPO_ROOT/skills/reviewer-protocol/SKILL.md"
  [ -f "$f" ]
  run grep -c "^## Reviewer Dispatch Contract$" "$f"
  [ "$status" -eq 0 ]
  [ "$output" = "1" ]
}

@test "[112-PR1] reviewer-protocol/SKILL.md ## Reviewer Dispatch Contract names diff_file_path" {
  local f="$REPO_ROOT/skills/reviewer-protocol/SKILL.md"
  # Section-scoped extraction: pull the Reviewer Dispatch Contract section
  # and require diff_file_path to appear inside it (not just elsewhere in
  # the file). Mirrors the section-scoped pattern in
  # tests/unit/test-reviewer-boilerplate-embed.bats.
  local section
  section="$(awk '
    $0 == "## Reviewer Dispatch Contract" { in_section = 1; print; next }
    in_section && /^## / { in_section = 0 }
    in_section { print }
  ' "$f")"
  [ -n "$section" ]
  echo "$section" | grep -q "diff_file_path"
  echo "$section" | grep -qF "round-NN.diff"
}

@test "[112-PR1] reviewer-protocol/SKILL.md formalizes line-range citation in referenced_files" {
  local f="$REPO_ROOT/skills/reviewer-protocol/SKILL.md"
  local section
  section="$(awk '
    $0 == "## Reviewer Dispatch Contract" { in_section = 1; print; next }
    in_section && /^## / { in_section = 0 }
    in_section { print }
  ' "$f")"
  [ -n "$section" ]
  # Must mention referenced_files + line range / line-range citation.
  echo "$section" | grep -q "referenced_files"
  echo "$section" | grep -qiE "line[- ]range|line range"
}

# -----------------------------------------------------------------------------
# 3. Per-step SKILL.md files reference round-NN.diff (12 in-scope steps)
# -----------------------------------------------------------------------------

@test "[112-PR1] every in-scope per-step SKILL.md references round-NN.diff" {
  local in_scope=(
    goals
    questions
    research
    design
    phasing
    structure
    parallelize
    replan
    plan
    integrate
    implement
  )
  local missing=()
  local skill
  for skill in "${in_scope[@]}"; do
    local f="$REPO_ROOT/skills/${skill}/SKILL.md"
    if [ ! -f "$f" ]; then
      missing+=("$f (file missing)")
      continue
    fi
    if ! grep -qF "round-NN.diff" "$f"; then
      missing+=("$f")
    fi
  done
  if [ "${#missing[@]}" -gt 0 ]; then
    printf 'FAIL: per-step SKILL.md missing round-NN.diff reference:\n%s\n' "${missing[@]}" >&2
    return 1
  fi
}

@test "[112-PR1] every in-scope per-step SKILL.md names diff_file_path on the contract surface" {
  # Couple the per-step prose check to the contract parameter name itself
  # (diff_file_path) rather than the PR-identifier marker phrase. Three
  # occurrences is the floor: 1 prose mention + ≥1 Claude-dispatch bullet
  # + ≥1 Codex printf. A SKILL that drops the dispatch wiring while leaving
  # the prose paragraph would fall below the floor and surface as a
  # regression. test/SKILL.md is excluded by the opt-out and asserted
  # separately at floor=1.
  local in_scope=(
    goals
    questions
    research
    design
    phasing
    structure
    parallelize
    replan
    plan
    integrate
    implement
  )
  local missing=()
  local skill
  for skill in "${in_scope[@]}"; do
    local f="$REPO_ROOT/skills/${skill}/SKILL.md"
    local n
    n=$(grep -c "diff_file_path" "$f")
    if [ "$n" -lt 3 ]; then
      missing+=("$f (count=$n)")
    fi
  done
  if [ "${#missing[@]}" -gt 0 ]; then
    printf 'FAIL: per-step SKILL.md has fewer than 3 diff_file_path occurrences (1 prose + Claude bullet + Codex printf):\n%s\n' "${missing[@]}" >&2
    return 1
  fi
}

@test "[112-PR1] every in-scope per-step SKILL.md wires diff_file_path into Claude dispatch bullets (per-dispatch)" {
  # Per-DISPATCH assertion: for each in-scope SKILL.md the count of bulleted
  # `- diff_file_path:` parameter lines MUST be >= the count of bulleted
  # `- reviewer_tag:` parameter lines. The reviewer_tag bullet uniquely
  # identifies a reviewer dispatch's parameter block (the analyzer/worker
  # in replan has no reviewer_tag and is correctly excluded). Earlier
  # iterations of this test required only ONE diff_file_path bullet per
  # SKILL — for multi-dispatch SKILLs (plan, implement, integrate, design,
  # phasing, structure, parallelize, replan) a future edit could drop the
  # bullet from all but one Claude dispatch and still pass; the per-dispatch
  # parity check below catches that regression. Mirrors the per-printf
  # parity check below (which iterates each Codex `printf '...##
  # Dispatch parameters'` line filtered by reviewer_tag).
  local in_scope=(
    goals
    questions
    research
    design
    phasing
    structure
    parallelize
    replan
    plan
    integrate
    implement
  )
  local missing=()
  local skill
  for skill in "${in_scope[@]}"; do
    local f="$REPO_ROOT/skills/${skill}/SKILL.md"
    # Bulleted reviewer_tag — leading whitespace, dash, optional whitespace,
    # then backticked or bare `reviewer_tag:`. Excludes Codex printf-format
    # occurrences (those are not bulleted list items).
    local n_tag n_diff
    n_tag=$(grep -cE '^[[:space:]]*-[[:space:]]+`?reviewer_tag`?:' "$f" || true)
    n_diff=$(grep -cE '^[[:space:]]*-[[:space:]]+`?diff_file_path`?:' "$f" || true)
    if [ "$n_tag" -eq 0 ]; then
      # No bulleted reviewer dispatch in this SKILL. The per-step round-NN.diff
      # prose check + the floor-of-3 diff_file_path-count check + the Codex
      # printf check together cover the surface; nothing to assert here.
      continue
    fi
    if [ "$n_diff" -lt "$n_tag" ]; then
      missing+=("$f (reviewer_tag bullets=$n_tag, diff_file_path bullets=$n_diff)")
    fi
  done
  if [ "${#missing[@]}" -gt 0 ]; then
    printf 'FAIL: per-step SKILL.md has fewer diff_file_path bullets than reviewer_tag bullets (per-dispatch parity broken):\n%s\n' "${missing[@]}" >&2
    return 1
  fi
}

@test "[112-PR1] every in-scope per-step SKILL.md wires diff_file_path into Codex printf format strings" {
  # Per-step assertion: when a SKILL.md contains a Codex `printf '...##
  # Dispatch parameters\n...' ...` payload, the format string MUST embed
  # `diff_file_path:` so the Codex pipeline carries the parameter alongside
  # the Claude bullets. This is the second half of the BLOCKING-1 surface.
  local in_scope=(
    goals
    questions
    research
    design
    phasing
    structure
    parallelize
    replan
    plan
    integrate
    implement
  )
  local missing=()
  local skill
  for skill in "${in_scope[@]}"; do
    local f="$REPO_ROOT/skills/${skill}/SKILL.md"
    # Find lines that are Codex printf dispatch parameter blocks and assert
    # they carry diff_file_path. Lines look like:
    #   printf '...## Dispatch parameters...reviewer_tag: <tag>\ndiff_file_path: ...\n' ...
    local printf_lines
    printf_lines=$(grep -E "printf '.*## Dispatch parameters" "$f" || true)
    if [ -z "$printf_lines" ]; then
      # No Codex printf block in this SKILL — skip (e.g. some SKILLs may
      # delegate Codex dispatch differently). Plan/integrate/implement all
      # carry printf blocks; if all 11 in-scope SKILLs lacked them this
      # assertion would silently no-op, which is acceptable here because
      # the previous bulleted-Claude assertion already covers the dispatch
      # surface and the diff_file_path-count floor catches the case.
      continue
    fi
    # Each printf line that mentions `## Dispatch parameters` AND a
    # `reviewer_tag:` (i.e. is a reviewer dispatch, not a worker/analyzer
    # like replan's qrspi-replan-analyzer which is a non-reviewer worker
    # with no reviewer_tag and no diff_file_path) MUST also carry
    # `diff_file_path:` somewhere in its format string. A reviewer printf
    # block missing diff_file_path is a regression.
    local bad
    bad=$(grep -E "printf '.*## Dispatch parameters" "$f" | grep -E "reviewer_tag:" | grep -vE "diff_file_path:" || true)
    if [ -n "$bad" ]; then
      missing+=("$f")
    fi
  done
  if [ "${#missing[@]}" -gt 0 ]; then
    printf 'FAIL: per-step SKILL.md has Codex printf block without diff_file_path:\n%s\n' "${missing[@]}" >&2
    return 1
  fi
}

@test "[112-PR1] skills/test/SKILL.md Codex printf blocks do NOT carry diff_file_path" {
  # Defense-in-depth on the test-step opt-out: any Codex printf dispatch
  # parameter block in skills/test/SKILL.md must NOT carry diff_file_path,
  # because the test step is explicitly out-of-scope for #112 Mechanism A.
  local f="$REPO_ROOT/skills/test/SKILL.md"
  [ -f "$f" ]
  local bad
  bad=$(grep -E "printf '.*## Dispatch parameters" "$f" | grep -E "diff_file_path:" || true)
  if [ -n "$bad" ]; then
    printf 'FAIL: skills/test/SKILL.md Codex printf carries diff_file_path (opt-out broken):\n%s\n' "$bad" >&2
    return 1
  fi
}

# -----------------------------------------------------------------------------
# 4. Reviewer agents under agents/ document the diff_file_path Read pattern
# -----------------------------------------------------------------------------

@test "[112-PR1] every in-scope reviewer agent file documents the diff-file Read pattern" {
  # Spec exclusions:
  #   - qrspi-test-coverage-reviewer.md: explicit per-spec opt-out
  #   - qrspi-finding-verifier.md: already documents diff_file_path from #109
  # Non-reviewer agents are out of scope (implementer, test-writer,
  # research-specialist, research-collator, replan-analyzer): they do not
  # emit findings, so they do not consume diff_file_path.
  local in_scope=(
    qrspi-goals-reviewer
    qrspi-goals-scope-reviewer
    qrspi-questions-reviewer
    qrspi-research-reviewer
    qrspi-design-reviewer
    qrspi-design-scope-reviewer
    qrspi-phasing-reviewer
    qrspi-phasing-scope-reviewer
    qrspi-structure-reviewer
    qrspi-structure-scope-reviewer
    qrspi-parallelize-reviewer
    qrspi-parallelize-scope-reviewer
    qrspi-replan-reviewer
    qrspi-replan-scope-reviewer
    qrspi-plan-reviewer
    qrspi-plan-scope-reviewer
    qrspi-plan-spec-reviewer
    qrspi-plan-security-reviewer
    qrspi-plan-goal-traceability-reviewer
    qrspi-plan-test-coverage-reviewer
    qrspi-plan-silent-failure-hunter
    qrspi-implement-gate-reviewer
    qrspi-integration-reviewer
    qrspi-security-integration-reviewer
    qrspi-spec-reviewer
    qrspi-code-quality-reviewer
    qrspi-goal-traceability-reviewer
    qrspi-security-reviewer
    qrspi-silent-failure-hunter
    qrspi-code-simplifier
    qrspi-type-design-analyzer
  )
  local missing=()
  local agent
  for agent in "${in_scope[@]}"; do
    local f="$REPO_ROOT/agents/${agent}.md"
    if [ ! -f "$f" ]; then
      missing+=("$f (file missing)")
      continue
    fi
    # Either the parameter name OR the diff path must appear; the section
    # heading we appended uses both, so this is a defense-in-depth check.
    if ! grep -qE "diff_file_path|round-NN\.diff" "$f"; then
      missing+=("$f")
    fi
  done
  if [ "${#missing[@]}" -gt 0 ]; then
    printf 'FAIL: reviewer agent file missing diff_file_path/round-NN.diff reference:\n%s\n' "${missing[@]}" >&2
    return 1
  fi
}

@test "[112-PR1] reviewer agents needing diff Read have Read in their tools list" {
  # The diff-file Read pattern requires the Read tool. Every in-scope
  # reviewer agent that documents the pattern MUST declare Read in its
  # frontmatter `tools:` list — otherwise the documented Read would fail
  # at runtime with a tool-not-permitted error.
  local in_scope=(
    qrspi-goals-reviewer
    qrspi-goals-scope-reviewer
    qrspi-questions-reviewer
    qrspi-research-reviewer
    qrspi-design-reviewer
    qrspi-design-scope-reviewer
    qrspi-phasing-reviewer
    qrspi-phasing-scope-reviewer
    qrspi-structure-reviewer
    qrspi-structure-scope-reviewer
    qrspi-parallelize-reviewer
    qrspi-parallelize-scope-reviewer
    qrspi-replan-reviewer
    qrspi-replan-scope-reviewer
    qrspi-plan-reviewer
    qrspi-plan-scope-reviewer
    qrspi-plan-spec-reviewer
    qrspi-plan-security-reviewer
    qrspi-plan-goal-traceability-reviewer
    qrspi-plan-test-coverage-reviewer
    qrspi-plan-silent-failure-hunter
    qrspi-implement-gate-reviewer
    qrspi-integration-reviewer
    qrspi-security-integration-reviewer
    qrspi-spec-reviewer
    qrspi-code-quality-reviewer
    qrspi-goal-traceability-reviewer
    qrspi-security-reviewer
    qrspi-silent-failure-hunter
    qrspi-code-simplifier
    qrspi-type-design-analyzer
  )
  local missing=()
  local agent
  for agent in "${in_scope[@]}"; do
    local f="$REPO_ROOT/agents/${agent}.md"
    # Frontmatter `tools:` line must enumerate Read.
    if ! grep -qE "^tools:[[:space:]]*.*\bRead\b" "$f"; then
      missing+=("$f")
    fi
  done
  if [ "${#missing[@]}" -gt 0 ]; then
    printf 'FAIL: reviewer agent missing Read in tools: list:\n%s\n' "${missing[@]}" >&2
    return 1
  fi
}

# -----------------------------------------------------------------------------
# 5. Test-step opt-out — explicit regression guard
# -----------------------------------------------------------------------------

@test "[112-PR1] skills/test/SKILL.md opts out of #112 diff-file wiring (no round-NN.diff dispatch)" {
  local f="$REPO_ROOT/skills/test/SKILL.md"
  [ -f "$f" ]
  # The opt-out marker must be present and the test step must NOT carry the
  # PR-1 Mechanism A dispatch marker phrase. (The opt-out paragraph itself
  # may name #112 PR-1 — but only inside a "Diff-file wiring opt-out"
  # context; if the file ever added the dispatch wiring proper, the
  # generic per-step marker phrase from in-scope SKILLs would appear.)
  grep -qiE "Diff-file wiring opt-out|test-step.*opt[- ]out|out-of-scope.*diff|opt out.*#112" "$f"
}

@test "[112-PR1] qrspi-test-coverage-reviewer is NOT in the diff-file Read pattern set" {
  # Spec opt-out regression guard: the test-coverage reviewer agent must
  # NOT carry the Diff-File Read Pattern section we added to in-scope
  # reviewers. (It is permitted to gain the pattern in a future PR if the
  # spec is revisited; until then, the absence is the load-bearing signal
  # that the opt-out was honored in PR-1.)
  local f="$REPO_ROOT/agents/qrspi-test-coverage-reviewer.md"
  [ -f "$f" ]
  ! grep -qF "Diff-File Read Pattern (#112 PR-1 Mechanism A)" "$f"
}

# -----------------------------------------------------------------------------
# 6. Self-review checklist — PR-1 must contain ZERO mention of PR-2 surfaces
# -----------------------------------------------------------------------------
#
# Per the spec self-review checklist, PR-1 must contain ZERO mention of:
#   qrspi-scope-tagger, scope_tagger_enabled, scope-set, scope_hint,
#   convergence, narrowing, HEAD~1.
#
# These tests scan ONLY the files PR-1 touches (using-qrspi, reviewer-protocol,
# the 12 in-scope step SKILLs, and the 31 reviewer agents we added the note
# to) — they do NOT scan unrelated tree files where these terms may appear
# (e.g. CHANGELOG, prior round notes). The negative scan is anchored to the
# PR-1 changeset surface to avoid false positives.

# Symmetric scoping — both negative scans below enumerate the SAME PR-1
# changeset surface (the 14 SKILLs and 31 reviewer agents) via the
# `PR1_CHANGESET_SURFACE` array initialized in setup() above. Globbing
# agents/qrspi-*-reviewer.md would be overbroad; the explicit enumeration
# keeps positive and negative assertions scope-aligned.

@test "[112-PR1] PR-1 changeset surface contains no qrspi-scope-tagger / scope_tagger_enabled mentions" {
  local hits=()
  local rel
  for rel in "${PR1_CHANGESET_SURFACE[@]}"; do
    local f="$REPO_ROOT/$rel"
    [ -f "$f" ] || continue
    if grep -lE "qrspi-scope-tagger|scope_tagger_enabled" "$f" >/dev/null 2>&1; then
      hits+=("$f")
    fi
  done
  if [ "${#hits[@]}" -gt 0 ]; then
    printf 'FAIL: PR-1 changeset surface mentions PR-2 tagger/config:\n%s\n' "${hits[@]}" >&2
    return 1
  fi
}

@test "[112-PR1] PR-1 additions contain no scope_hint / scope-set / convergence / narrowing / HEAD~1 tokens" {
  # PR-2 forward-reference tokens that must remain absent from PR-1
  # additions. scope_hint is the PR-2 reviewer-prompt parameter; scope-set
  # is the tagger output file; convergence and narrowing describe the
  # PR-2 round-NN-vs-round-(NN-1) ref-selection mechanic; HEAD~1 is the
  # ref shorthand PR-2 will introduce.
  #
  # This test scans PR-1 additions only via `git diff <base>..HEAD` rather
  # than the whole file, because pre-existing prose unrelated to #112
  # (e.g. fix-loop convergence in implement/integrate, the 5-round
  # converge-in-1-2-rounds note in using-qrspi) legitimately contains the
  # `converg` substring. Anchoring on additions catches any new PR-2
  # leakage without flagging benign pre-existing copy.
  #
  # CI-aware skip policy: in CI (`$CI` non-empty — set by GitHub Actions,
  # GitLab CI, CircleCI, etc.) the negative-token scan is load-bearing and a
  # missing base ref or empty additions diff is a setup error, not a no-op.
  # Fail loud in that case so CI flags the broken assertion instead of
  # greening silently. CI is expected to fetch full history (e.g.
  # `actions/checkout@v4` with `fetch-depth: 0`); if that's not configured
  # the test will fail and the diagnostic points to the checkout config.
  # Locally (CI unset), `skip` is acceptable for developer convenience —
  # a shallow clone or a checkout without the base ref reachable simply
  # opts out of the additions scan rather than blocking the run.
  local base="a1db28d"
  if ! git -C "$REPO_ROOT" rev-parse --verify "$base" >/dev/null 2>&1; then
    if [ -n "${CI:-}" ]; then
      printf 'FAIL: base commit %s not reachable in CI (fetch full history, e.g. actions/checkout@v4 fetch-depth: 0)\n' "$base" >&2
      return 1
    fi
    skip "base commit $base not reachable from this checkout"
  fi
  local additions
  # Lines that begin with `+` but not `+++` — i.e. content additions, not
  # the unified-diff `+++ b/<path>` file headers. Use awk for portability
  # across BSD/GNU grep regex dialect differences.
  additions=$(git -C "$REPO_ROOT" diff "$base..HEAD" -- ':!tests/' | awk '/^\+\+\+/{next} /^\+/{print}')
  if [ -z "$additions" ]; then
    if [ -n "${CI:-}" ]; then
      printf 'FAIL: no PR-1 additions to scan in CI (expected non-empty diff vs base %s)\n' "$base" >&2
      return 1
    fi
    skip "no PR-1 additions to scan"
  fi
  local hits
  hits=$(echo "$additions" | grep -iE 'scope_hint|scope-set|qrspi-scope-tagger|scope_tagger_enabled|converg|narrowing|HEAD~1' || true)
  if [ -n "$hits" ]; then
    printf 'FAIL: PR-1 additions contain PR-2 forward-reference token:\n%s\n' "$hits" >&2
    return 1
  fi
}
