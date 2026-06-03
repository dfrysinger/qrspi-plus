#!/usr/bin/env bats
# Unit tests for skills/_shared/verifier-dispatch-prose.md — the shared
# verifier-dispatch snippet `!cat`-included by using-qrspi/SKILL.md and
# implement/SKILL.md per CD-4 §H / structure.md Slice 1.1.

setup() {
  REPO_ROOT="$(git rev-parse --show-toplevel)"
  SNIPPET="$REPO_ROOT/skills/_shared/verifier-dispatch-prose.md"
}

@test "snippet file exists" {
  [ -f "$SNIPPET" ]
}

@test "snippet declares the dispatch-agent.sh --verifier-fanout invocation" {
  grep -qE 'scripts/dispatch-agent\.sh.*--verifier-fanout' "$SNIPPET"
}

@test "snippet documents one Task call per emitted spec line (verbatim DISPATCH_FILE)" {
  grep -qE 'one Task call per .*spec line|one Task per .*spec line|exactly once per .*spec line' "$SNIPPET"
  grep -qE 'DISPATCH_FILE=' "$SNIPPET"
}

@test "snippet calls await-round.sh after the verifier dispatch" {
  grep -qE 'scripts/await-round\.sh' "$SNIPPET"
}

@test "snippet calls scripts/verifier-fan-in.sh after await" {
  grep -qE 'scripts/verifier-fan-in\.sh' "$SNIPPET"
}

@test "snippet does NOT contain a per-finding verifier loop (eliminated by CD-4)" {
  [ -f "$SNIPPET" ]  # guard: negative-grep on a missing file would vacuously pass
  ! grep -qE 'loop per finding|for each finding.*verifier' "$SNIPPET"
}

@test "snippet does NOT echo verifier payloads to stdout/stderr" {
  [ -f "$SNIPPET" ]  # guard against vacuous pass on missing file
  ! grep -qiE 'echo.*verifier (payload|reasoning|score|sidecar body)' "$SNIPPET"
  ! grep -qiE 'cat.*\.score\.md' "$SNIPPET"
}

@test "snippet uses bare <tier> for --tier-override (not reviewer CSV grammar)" {
  [ -f "$SNIPPET" ]  # guard against vacuous pass on missing file
  # reviewer-fanout uses tag=tier CSV; verifier-fanout uses bare <tier>
  ! grep -qE 'tier-override.*tag=' "$SNIPPET"
  ! grep -qE 'tier-override.*[a-z]+=' "$SNIPPET"
}
