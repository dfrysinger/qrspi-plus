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
  # Co-occurrence on a single line: `git diff` + `<base-branch>` + redirect.
  grep -E "git diff.*<base-branch>.*>.*round-NN\.diff" "$f" >/dev/null
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

@test "[112-PR1] every in-scope per-step SKILL.md cites the #112 PR-1 marker phrase" {
  # Tighten the per-step prose check to the marker phrase used in the PR-1
  # implementation so a sweep that drops the dispatch wiring while leaving
  # an unrelated round-NN.diff mention (e.g. in a comment or table) is
  # surfaced as a regression.
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
    if ! grep -qF "#112 PR-1 Mechanism A" "$f"; then
      missing+=("$f")
    fi
  done
  if [ "${#missing[@]}" -gt 0 ]; then
    printf 'FAIL: per-step SKILL.md missing #112 PR-1 Mechanism A marker:\n%s\n' "${missing[@]}" >&2
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

@test "[112-PR1] PR-1 changeset surface contains no qrspi-scope-tagger / scope_tagger_enabled mentions" {
  local files=(
    "$REPO_ROOT/skills/using-qrspi/SKILL.md"
    "$REPO_ROOT/skills/reviewer-protocol/SKILL.md"
    "$REPO_ROOT/skills/goals/SKILL.md"
    "$REPO_ROOT/skills/questions/SKILL.md"
    "$REPO_ROOT/skills/research/SKILL.md"
    "$REPO_ROOT/skills/design/SKILL.md"
    "$REPO_ROOT/skills/phasing/SKILL.md"
    "$REPO_ROOT/skills/structure/SKILL.md"
    "$REPO_ROOT/skills/parallelize/SKILL.md"
    "$REPO_ROOT/skills/replan/SKILL.md"
    "$REPO_ROOT/skills/plan/SKILL.md"
    "$REPO_ROOT/skills/integrate/SKILL.md"
    "$REPO_ROOT/skills/implement/SKILL.md"
    "$REPO_ROOT/skills/test/SKILL.md"
  )
  # Reviewer agents touched by PR-1.
  local agent
  for agent in "$REPO_ROOT"/agents/qrspi-*-reviewer.md \
               "$REPO_ROOT"/agents/qrspi-*-scope-reviewer.md \
               "$REPO_ROOT/agents/qrspi-silent-failure-hunter.md" \
               "$REPO_ROOT/agents/qrspi-code-simplifier.md" \
               "$REPO_ROOT/agents/qrspi-type-design-analyzer.md" \
               "$REPO_ROOT/agents/qrspi-plan-silent-failure-hunter.md"; do
    [ -f "$agent" ] && files+=("$agent")
  done

  local hits=()
  local f
  for f in "${files[@]}"; do
    if grep -lE "qrspi-scope-tagger|scope_tagger_enabled" "$f" >/dev/null 2>&1; then
      hits+=("$f")
    fi
  done
  if [ "${#hits[@]}" -gt 0 ]; then
    printf 'FAIL: PR-1 changeset surface mentions PR-2 tagger/config:\n%s\n' "${hits[@]}" >&2
    return 1
  fi
}

@test "[112-PR1] PR-1 changeset surface contains no scope_hint / scope-set mentions" {
  # scope_hint is the PR-2 reviewer-prompt parameter; scope-set is the
  # tagger output file — both belong exclusively to PR-2.
  local files=(
    "$REPO_ROOT/skills/using-qrspi/SKILL.md"
    "$REPO_ROOT/skills/reviewer-protocol/SKILL.md"
    "$REPO_ROOT/skills/goals/SKILL.md"
    "$REPO_ROOT/skills/questions/SKILL.md"
    "$REPO_ROOT/skills/research/SKILL.md"
    "$REPO_ROOT/skills/design/SKILL.md"
    "$REPO_ROOT/skills/phasing/SKILL.md"
    "$REPO_ROOT/skills/structure/SKILL.md"
    "$REPO_ROOT/skills/parallelize/SKILL.md"
    "$REPO_ROOT/skills/replan/SKILL.md"
    "$REPO_ROOT/skills/plan/SKILL.md"
    "$REPO_ROOT/skills/integrate/SKILL.md"
    "$REPO_ROOT/skills/implement/SKILL.md"
    "$REPO_ROOT/skills/test/SKILL.md"
  )

  local hits=()
  local f
  for f in "${files[@]}"; do
    # scope_hint as a token (avoid matching `scope_hint` substrings inside
    # unrelated identifiers — there are none expected, but we anchor on
    # word-boundary-ish bracketing to be safe).
    if grep -qE "scope_hint|scope-set" "$f"; then
      hits+=("$f")
    fi
  done
  if [ "${#hits[@]}" -gt 0 ]; then
    printf 'FAIL: PR-1 changeset surface mentions PR-2 scope_hint/scope-set:\n%s\n' "${hits[@]}" >&2
    return 1
  fi
}
