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
  # The git-diff redirect is the load-bearing mechanic. PR-2 made <ref>
  # dynamic (rounds 1-2 always use <base-branch>; HEAD~1 only fires when
  # the convergence rule narrows). Co-occurrence on a single line:
  # `git diff` (or `git -C ... diff`) + `<ref>` placeholder OR `<base-branch>`
  # (PR-1's static literal still appears in some prose paragraphs that
  # describe the broaden case) + redirect into round-NN.diff.
  grep -E "git( -C [^ ]*)? diff.*<(ref|base-branch)>.*>.*round-NN\.diff" "$f" >/dev/null
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
  # Couple the per-step prose check to the contract parameter name itself.
  # After the run-codex-review.sh migration, Codex dispatches use `--diff-file`
  # instead of the literal `diff_file_path:` printf format, but the contract
  # surface is the union: prose mentions + Claude dispatch bullets (still
  # `diff_file_path:`) + Codex wrapper invocations (`--diff-file`). Floor:
  # 3 combined occurrences (1 prose + ≥1 Claude bullet + ≥1 Codex --diff-file).
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
    local n_diff_file_path n_diff_file_flag n
    n_diff_file_path=$(grep -c "diff_file_path" "$f")
    n_diff_file_flag=$(grep -cE '^\s*--diff-file ' "$f")
    n=$((n_diff_file_path + n_diff_file_flag))
    if [ "$n" -lt 3 ]; then
      missing+=("$f (combined count=$n: diff_file_path=$n_diff_file_path, --diff-file=$n_diff_file_flag)")
    fi
  done
  if [ "${#missing[@]}" -gt 0 ]; then
    printf 'FAIL: per-step SKILL.md has fewer than 3 combined diff_file_path/--diff-file occurrences (1 prose + Claude bullet + Codex wrapper invocation):\n%s\n' "${missing[@]}" >&2
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

@test "[112-PR1] every in-scope per-step SKILL.md wires --diff-file into Codex wrapper invocations" {
  # Per-step assertion: every Codex reviewer dispatch (run-codex-review.sh
  # invocation) in in-scope SKILLs MUST carry the --diff-file flag. After the
  # wrapper migration, the dispatch shape is `scripts/run-codex-review.sh \`
  # followed by flags including `--diff-file`. Plan/SKILL.md uses elision
  # (`[...same flags as above...]`) for repeated reviewer blocks; those
  # elided blocks inherit --diff-file from their canonical sibling and don't
  # need a literal flag — so the floor is "≥1 --diff-file per skill".
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
    local n_wrapper n_diff_flag
    n_wrapper=$(grep -cE '^\s*scripts/run-codex-review\.sh \\$' "$f" || true)
    n_diff_flag=$(grep -cE '^\s*--diff-file ' "$f" || true)
    if [ "$n_wrapper" -lt 1 ]; then
      missing+=("$f (zero run-codex-review.sh invocations)")
      continue
    fi
    if [ "$n_diff_flag" -lt 1 ]; then
      missing+=("$f (zero --diff-file flags but $n_wrapper wrapper invocations)")
    fi
  done
  if [ "${#missing[@]}" -gt 0 ]; then
    printf 'FAIL: per-step SKILL.md missing --diff-file in Codex wrapper invocations:\n%s\n' "${missing[@]}" >&2
    return 1
  fi
}

@test "[112-PR1] skills/test/SKILL.md Codex wrapper invocations do NOT carry --diff-file" {
  # Defense-in-depth on the test-step opt-out: skills/test/SKILL.md is
  # explicitly out-of-scope for #112 Mechanism A, so its run-codex-review.sh
  # invocations must NOT pass --diff-file (Test-phase reuse signal).
  local f="$REPO_ROOT/skills/test/SKILL.md"
  [ -f "$f" ]
  local n_wrapper n_diff_flag
  n_wrapper=$(grep -cE '^\s*scripts/run-codex-review\.sh \\$' "$f" || true)
  n_diff_flag=$(grep -cE '^\s*--diff-file ' "$f" || true)
  if [ "$n_wrapper" -lt 1 ]; then
    echo "FAIL: skills/test/SKILL.md has zero run-codex-review.sh invocations (expected ≥1)"
    return 1
  fi
  if [ "$n_diff_flag" -ne 0 ]; then
    printf 'FAIL: skills/test/SKILL.md has %d --diff-file flag(s) (opt-out broken; expected 0)\n' "$n_diff_flag" >&2
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
# 6. PR-2-forbidden-token negative scans — REMOVED in PR-2
# -----------------------------------------------------------------------------
#
# PR-1 originally carried two negative scans asserting that PR-1 changes did
# not mention PR-2's forward-reference tokens (qrspi-scope-tagger,
# scope_tagger_enabled, scope-set, scope_hint, convergence, narrowing,
# HEAD~1). Those scans were correct in the PR-1 timeframe — they prevented
# scope creep from PR-2 leaking back into PR-1.
#
# PR-2 IS now introducing those tokens by design: the agent file
# qrspi-scope-tagger.md, the scope_tagger_enabled config field, the
# scope_hint reviewer dispatch parameter, the round-NN-scope-set.txt
# output file, the convergence rule (step 7.5), the auto-broaden semantics,
# and HEAD~1 as the narrowed-round diff ref are all PR-2 surfaces. Keeping
# the scans here would block every PR-2 commit on a tautological violation.
#
# The PR-2 surface is now positively asserted in two new bats files:
#   - tests/unit/test-scope-tagger-dispatch.bats (20 tests)
#   - tests/unit/test-convergence-narrowing.bats (18 tests)
#
# Those files take over the responsibility this scan held — the
# enumeration is positive ("the spec mechanic IS documented in the right
# places") rather than negative ("PR-1 didn't mention PR-2"). Negative
# scans were a temporal artifact; positive scans are the durable contract.
#
# The PR1_CHANGESET_SURFACE array in setup() is retained because tests 1-14
# above still use it for positive PR-1 surface assertions.
