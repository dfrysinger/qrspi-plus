#!/usr/bin/env bats
#
# Plan-level acceptance tests for G7 (Narrow-round ref selection robust
# under multi-commit-per-round patterns — HEAD~1 replaced with anchor-file
# lookup).
#
# Maps to design.md § G7 Acceptance and plan.md Phase 1 Acceptance Criteria
# bullet 13 (every step-12 narrow-round dispatch resolves its diff ref by
# reading reviews/<step>/round-<NN-1>-commit.txt).
#
# Per-script behaviour is covered by tests/unit/test-narrow-round-anchor-lookup.bats;
# this file proves the anchor-file replacement landed in using-qrspi step 12
# prose, no surviving HEAD~1 narrative remains in skills/ (G9 trim audit
# overlap is intentional — G7 is a precondition for the trim audit to be
# meaningful), and the divergence-sanity-check named diagnostic is preserved.

setup_file() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")"/../../.. && pwd)"
  export REPO_ROOT
  export USING_QRSPI="$REPO_ROOT/skills/using-qrspi/SKILL.md"
}

@test "acceptance: using-qrspi step 12 carries the anchor-file lookup incantation (cat reviews/<step>/round-<NN-1>-commit.txt)" {
  # G7 acceptance bullet 1 — literal `git diff "$(cat reviews/` substring.
  grep -qF 'git diff "$(cat reviews/' "$USING_QRSPI" \
    || grep -qE 'cat reviews/.*round-.*-commit\.txt' "$USING_QRSPI"
}

@test "acceptance: using-qrspi step 12 carries no surviving 'git diff HEAD~1 --' narrative" {
  # G7 acceptance bullet 1 — no occurrence of git diff HEAD~1 -- in step-12 narrative.
  # (Concrete script names in process-step calls are fine; the narrow-ref
  # mechanism MUST be the anchor file, not HEAD~1.)
  ! grep -qE 'git diff HEAD~1[[:space:]]+--' "$USING_QRSPI"
}

@test "acceptance: anchor-file-missing: and sha-format-invalid: named diagnostics are preserved" {
  # G7 acceptance bullet 3 — divergence-sanity-check halt diagnostics named.
  grep -qF 'anchor-file-missing:' "$USING_QRSPI"
  grep -qF 'sha-format-invalid:' "$USING_QRSPI"
}

@test "acceptance: narrow-round-empty-diff: divergence-sanity-check diagnostic is preserved" {
  # G7 acceptance bullet 3 third sub-bullet — empty narrow diff fires named diagnostic.
  grep -qF 'narrow-round-empty-diff' "$USING_QRSPI"
}

@test "acceptance: no other active SKILL inlines the deprecated HEAD~1 narrow incantation" {
  # design.md § G7 Acceptance bullet 2 — sweep across skills/.
  # Allow `HEAD~1` mentions inside skills/_shared/* (legitimate post-trim
  # citations of the deprecated form for historical-context tightening) and
  # narrative restatements caught separately by G9's trim audit; this gate
  # is the narrower "step-12 inline incantation" form.
  matches="$(grep -rnE 'git diff HEAD~1[[:space:]]+--' "$REPO_ROOT/skills" 2>/dev/null || true)"
  if [ -n "$matches" ]; then
    echo "Surviving HEAD~1 narrow-incantation inlines in skills/:" >&2
    echo "$matches" >&2
    false
  fi
}
