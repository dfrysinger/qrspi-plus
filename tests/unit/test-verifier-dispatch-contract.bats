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
                'Write.*round-NN-dispositions\.md' \
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
# (or normalize, in the trailing-newline case). One is pinned above; the
# remaining four below pin the previously untested schema-guard branches.
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
