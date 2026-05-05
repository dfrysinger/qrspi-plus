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

@test "NO_FINDINGS without trailing newline (11-byte form) also writes a clean marker" {
  scripts/codex-finding-splitter.sh \
    tests/fixtures/issue-109/codex-stdout/no-findings-no-newline.txt \
    "$ROUND_DIR" \
    "$TAG"
  [ -f "$ROUND_DIR/${TAG}.clean.md" ]
  ! ls "$ROUND_DIR"/${TAG}.finding-*.md 2>/dev/null
}

@test "malformed input writes nothing and exits non-zero with stderr diagnostic" {
  run --separate-stderr scripts/codex-finding-splitter.sh \
    tests/fixtures/issue-109/codex-stdout/malformed.txt \
    "$ROUND_DIR" \
    "$TAG"
  [ "$status" -ne 0 ]
  echo "$stderr" | grep -qiE 'malformed|FINDING-BOUNDARY|NO_FINDINGS'
  ! ls "$ROUND_DIR"/${TAG}.finding-*.md 2>/dev/null
  ! ls "$ROUND_DIR"/${TAG}.clean.md 2>/dev/null
}

@test "empty input writes nothing and exits non-zero with stderr diagnostic" {
  run --separate-stderr scripts/codex-finding-splitter.sh \
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
