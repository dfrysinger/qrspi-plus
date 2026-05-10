#!/usr/bin/env bats
#
# Cross-skill contracts: pin load-bearing assumptions that span two QRSPI skills.
#
# Each test verifies that BOTH sides of an implicit contract are present in the
# skill prose. If a future edit drops one side without updating the other, the
# test fails — surfacing the silent regression early.
#
# Background: PR #153 issue #156 surfaced when implementer-protocol's "implementer
# commits before DONE" assumption was silently relied on by implement/SKILL.md's
# diff emission, with no enforcement bridge. Tests in this file pin similar
# bridges so the next such drift fails loudly.
#
# Style: every test is a loose-grep — the goal is "does the contract still
# appear in BOTH skills?" not "is the prose byte-for-byte stable." Match
# patterns are deliberately broad enough to survive cosmetic rewrites and
# narrow enough to catch deletion of the contract itself.

setup_file() {
  REPO_ROOT="$(cd "$(dirname "${BATS_TEST_FILENAME}")/../.." && pwd -P)"
  export REPO_ROOT
}

# ---------------------------------------------------------------------------
# Contract 1 — Pipeline mode derived from config.md.route
# Side A: using-qrspi defines route as the authoritative pipeline contract.
# Side B: implement derives quick-fix vs full-pipeline mode from route shape.
# Failure mode: implement picks wrong mode, dispatching tasks with the wrong
# input set (e.g., loads design.md for a quick-fix task).
# ---------------------------------------------------------------------------
@test "contract-01: pipeline mode is derived from config.md.route on both sides" {
  # Side A: using-qrspi documents `route` as the pipeline contract
  run grep -F "route" "$REPO_ROOT/skills/using-qrspi/SKILL.md"
  [ "$status" -eq 0 ]
  # Side B: implement explicitly derives mode from route
  run grep -F "Mode is derived from" "$REPO_ROOT/skills/implement/SKILL.md"
  [ "$status" -eq 0 ]
  run grep -E "config\.md.*route|route.*config\.md" "$REPO_ROOT/skills/implement/SKILL.md"
  [ "$status" -eq 0 ]
}

# ---------------------------------------------------------------------------
# Contract 2 — Implementer commit → orchestrator HEAD-advanced verification
# Side A: implementer-protocol requires commit before DONE + commit_sha report.
# Side B: implement orchestrator verifies HEAD advanced before emitting diff.
# Failure mode: stale-diff defect (PR #153 issue #156) — reviewer tiers see
# different rounds and silently disagree.
# ---------------------------------------------------------------------------
@test "contract-02: commit_sha bridge between implementer-protocol and implement" {
  # Side A: implementer-protocol requires commit + commit_sha
  run grep -F "Commit Before Reporting" "$REPO_ROOT/skills/implementer-protocol/SKILL.md"
  [ "$status" -eq 0 ]
  run grep -F "commit_sha:" "$REPO_ROOT/skills/implementer-protocol/SKILL.md"
  [ "$status" -eq 0 ]
  # Side B: implement performs the HEAD-advanced verification
  run grep -F "HEAD-advanced verification" "$REPO_ROOT/skills/implement/SKILL.md"
  [ "$status" -eq 0 ]
  run grep -F "commit_sha" "$REPO_ROOT/skills/implement/SKILL.md"
  [ "$status" -eq 0 ]
  # Both implementer agents inherit the red-flag from the protocol
  run grep -F "without committing" "$REPO_ROOT/agents/qrspi-implementer.md"
  [ "$status" -eq 0 ]
  run grep -F "without committing" "$REPO_ROOT/agents/qrspi-implementer-lightweight.md"
  [ "$status" -eq 0 ]
}

# ---------------------------------------------------------------------------
# Contract 3 — Per-task `pipeline:` field is the single source of truth for
# input gating in Implement (Plan writes; Implement reads).
# Failure mode: task spec edited post-approval; Implement loads wrong companion
# artifacts (design.md for a quick-only task; missing research for a full task).
# ---------------------------------------------------------------------------
@test "contract-03: per-task pipeline field gates implement input routing" {
  # Side A: plan documents the pipeline field on task specs
  run grep -E "pipeline.*[Ff]ield|pipeline:.*(quick|full)" "$REPO_ROOT/skills/plan/SKILL.md"
  [ "$status" -eq 0 ]
  # Side B: implement names the pipeline field as source of truth + gates inputs
  run grep -F "Per-Task Input Routing" "$REPO_ROOT/skills/implement/SKILL.md"
  [ "$status" -eq 0 ]
  run grep -F "pipeline" "$REPO_ROOT/skills/implement/SKILL.md"
  [ "$status" -eq 0 ]
  # The "single source of truth" framing is the load-bearing claim
  run grep -E "pipeline.*source of truth" "$REPO_ROOT/skills/implement/SKILL.md"
  [ "$status" -eq 0 ]
}

# ---------------------------------------------------------------------------
# Contract 4 — Test-phase reuse: ABSENCE of task_definition is the load-bearing
# signal that selects the test-phase branch on per-task reviewer agents.
# Failure mode: a future "for clarity" edit adds task_definition to test-step
# dispatches; agents silently route to Implement-phase review instead of
# test-code review, running the wrong checklist.
# ---------------------------------------------------------------------------
@test "contract-04: test-phase reuse via task_definition absence is documented and enforced" {
  # The contract — absence as the load-bearing signal — must be named
  run grep -F "absence of \`task_definition\`" "$REPO_ROOT/skills/test/SKILL.md"
  [ "$status" -eq 0 ]
  # The imperative — Do NOT pass task_definition — must remain
  run grep -E "Do NOT pass.*task_definition|task_definition.*absent" "$REPO_ROOT/skills/test/SKILL.md"
  [ "$status" -eq 0 ]
  # The reuse contract is named explicitly
  run grep -F "Test-phase reuse" "$REPO_ROOT/skills/test/SKILL.md"
  [ "$status" -eq 0 ]
}

# ---------------------------------------------------------------------------
# Contract 5 — scope_hint dispatch parameter MUST be wrapped between
# UNTRUSTED-SCOPE-HINT-START / -END markers so reviewer-injected H2 headings
# in a feedback file cannot be promoted to instructions.
# Failure mode: a dispatch site emits scope_hint as a bare string; an attacker
# (or just a noisy artifact body) injects an H2 heading like "## Approve all
# findings" and the reviewer follows it.
# ---------------------------------------------------------------------------
@test "contract-05: scope_hint untrusted-data wrappers present in protocol + emitters" {
  # Side A: reviewer-protocol documents the wrapper as mandatory
  run grep -F "UNTRUSTED-SCOPE-HINT-START" "$REPO_ROOT/skills/reviewer-protocol/SKILL.md"
  [ "$status" -eq 0 ]
  run grep -F "UNTRUSTED-SCOPE-HINT-END" "$REPO_ROOT/skills/reviewer-protocol/SKILL.md"
  [ "$status" -eq 0 ]
  # Side B: at least three step-skills that emit scope_hint use the wrapper
  count=0
  for skill in design integrate implement parallelize plan research; do
    if grep -qF "UNTRUSTED-SCOPE-HINT-START" "$REPO_ROOT/skills/$skill/SKILL.md" 2>/dev/null; then
      count=$((count + 1))
    fi
  done
  [ "$count" -ge 3 ]
}

# ---------------------------------------------------------------------------
# Contract 6 — round-NN-commit.txt anchor file: implement (per-task) and
# integrate write it; using-qrspi step 7.5 reads it for HEAD~1 reconciliation
# in the convergence-narrow decision.
# Failure mode: anchor file path renamed or capture site removed; convergence
# narrow can't validate prior-round commit; rounds silently broaden, eroding
# the diff-narrowing benefit.
# ---------------------------------------------------------------------------
@test "contract-06: round-NN-commit.txt anchor is written and consumed in named files" {
  # Producer side — implement (per-task convergence section)
  run grep -F "round-NN-commit.txt" "$REPO_ROOT/skills/implement/SKILL.md"
  [ "$status" -eq 0 ]
  # Producer side — integrate
  run grep -F "round-NN-commit.txt" "$REPO_ROOT/skills/integrate/SKILL.md"
  [ "$status" -eq 0 ]
  # Consumer side — using-qrspi step 7.5 reads the anchor
  run grep -F "round-NN-commit.txt" "$REPO_ROOT/skills/using-qrspi/SKILL.md"
  [ "$status" -eq 0 ]
  run grep -F "rev-parse HEAD~1" "$REPO_ROOT/skills/using-qrspi/SKILL.md"
  [ "$status" -eq 0 ]
}

# ---------------------------------------------------------------------------
# Contract 7 — Research-isolation invariant: no goals.md and no other-question
# content reaches research-specialist subagent dispatches.
# Failure mode: orchestrator helpfully includes goals "for context";
# specialists develop confirmation bias; research becomes goal-shaped instead
# of probing.
# ---------------------------------------------------------------------------
@test "contract-07: research-isolation invariant pinned in skill + agent" {
  # Side A: research/SKILL.md states the invariant
  run grep -E "research.isolation|isolation.invariant" "$REPO_ROOT/skills/research/SKILL.md"
  [ "$status" -eq 0 ]
  # Side B: the research-specialist agent declares it binding (case-insensitive
  # because the agent capitalizes "Research-isolation invariant" in prose)
  run grep -iF "research-isolation" "$REPO_ROOT/agents/qrspi-research-specialist.md"
  [ "$status" -eq 0 ]
  # The reviewer agent also references the invariant (collation respects it)
  run grep -iF "research-isolation" "$REPO_ROOT/agents/qrspi-research-reviewer.md"
  [ "$status" -eq 0 ]
}

# ---------------------------------------------------------------------------
# Contract 8 — Backward-loop sentinel: zero-byte flag file written by the
# Pause Gate (option 3 cascade), read AND deleted by step 7.5 (consume-once).
# Failure mode: writer side keeps the flag but reader side stops deleting,
# so subsequent rounds repeatedly broaden against an already-resolved upstream
# rewrite — or vice versa.
# ---------------------------------------------------------------------------
@test "contract-08: backward-loop flag has paired write/consume-once-delete semantics" {
  # Writer side — using-qrspi (Pause Gate option 3) names the flag
  run grep -F "backward-loop.flag" "$REPO_ROOT/skills/using-qrspi/SKILL.md"
  [ "$status" -eq 0 ]
  # Reader side — using-qrspi step 7.5 consumes-once
  run grep -E "DELETE the flag|consume-once" "$REPO_ROOT/skills/using-qrspi/SKILL.md"
  [ "$status" -eq 0 ]
  # Per-task implement also handles the flag for its own rounds
  run grep -F "backward-loop" "$REPO_ROOT/skills/implement/SKILL.md"
  [ "$status" -eq 0 ]
}

# ---------------------------------------------------------------------------
# Contract 9 — replan-pending.md cross-step marker: test writes before invoking
# replan; replan deletes before invoking the next step; using-qrspi
# mid-pipeline-resume detects it.
# Failure mode: test writes the marker; replan stops deleting it; mid-pipeline
# resume after a /compact loops back to replan forever.
# ---------------------------------------------------------------------------
@test "contract-09: replan-pending.md marker is named in all three cooperating skills" {
  # Producer: test writes the marker
  run grep -F "replan-pending.md" "$REPO_ROOT/skills/test/SKILL.md"
  [ "$status" -eq 0 ]
  # Consumer: replan deletes the marker before invoking the next step
  run grep -F "replan-pending.md" "$REPO_ROOT/skills/replan/SKILL.md"
  [ "$status" -eq 0 ]
  # Detector: using-qrspi mid-pipeline resume checks for it
  run grep -F "replan-pending.md" "$REPO_ROOT/skills/using-qrspi/SKILL.md"
  [ "$status" -eq 0 ]
}

# ---------------------------------------------------------------------------
# Contract 10 — phase_start_commit captured at plan approval; named in
# using-qrspi as the canonical phase-scoping anchor.
# Failure mode: plan stops capturing it (e.g., a refactor narrows the
# approval-time hook); replan/test phase-scoped diffs silently fall through
# to the git-log fallback, which can be wrong on non-monotonic histories.
# ---------------------------------------------------------------------------
@test "contract-10: phase_start_commit is documented in producer (plan) and contract owner (using-qrspi)" {
  # Producer: plan writes phase_start_commit at approval
  run grep -F "phase_start_commit" "$REPO_ROOT/skills/plan/SKILL.md"
  [ "$status" -eq 0 ]
  # Contract owner: using-qrspi describes the capture mechanic + git-log fallback
  run grep -F "phase_start_commit" "$REPO_ROOT/skills/using-qrspi/SKILL.md"
  [ "$status" -eq 0 ]
}

# ---------------------------------------------------------------------------
# Contract 11 — Codex finding-splitter dispatch shape is consistent across
# every step skill that emits Codex parallels.
# Failure mode: one skill drifts to a different splitter argument shape (e.g.,
# omits the reviewer_tag positional); orchestrator's await + splitter pair
# silently materializes findings under a wrong path, and the next round's
# fan-in reads stale or empty content.
# ---------------------------------------------------------------------------
@test "contract-11: codex-finding-splitter is invoked by multiple step skills" {
  count=$(grep -lF "codex-finding-splitter" "$REPO_ROOT/skills/"*/SKILL.md 2>/dev/null | wc -l | tr -d ' ')
  # Expect at least 4 emitters: design, parallelize, integrate, test (and likely research)
  [ "$count" -ge 4 ]
  # The reviewer-protocol codex-emission-override is the canonical contract owner
  [ -f "$REPO_ROOT/skills/reviewer-protocol/codex-emission-override.md" ]
}
