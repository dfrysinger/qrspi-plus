#!/usr/bin/env bats

@test "verifier agent file exists" {
  [ -f agents/qrspi-finding-verifier.md ]
}

@test "frontmatter does NOT declare a top-level model: key (per T9 hardening, G9)" {
  awk '/^---$/{n++; next} n==1{print}' agents/qrspi-finding-verifier.md \
    | grep -qE '^model:' \
    && { echo "qrspi-finding-verifier frontmatter unexpectedly carries 'model:' key (per T9, agent files must not pin model)"; return 1; } || true
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

@test "sidecar path construction rule is documented (.md -> .score.md)" {
  # Require one of the three derivation-rule forms; do NOT accept loose alternatives
  # like <reviewer-tag>.*finding-F.*\.score\.md that match the path example without
  # proving the .md → .score.md derivation rule is present.
  awk '/^---$/{n++; next} n>=2{print}' agents/qrspi-finding-verifier.md \
    | grep -qE '\.md.*->.*\.score\.md|\.md.*→.*\.score\.md|replacing.*\.md.*\.score\.md' \
    || { echo "verifier agent does not document the .md -> .score.md derivation rule"; return 1; }
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
  echo "$body" | grep -qiE 'altitude mismatch' \
    || { echo "missing 'altitude mismatch' entry"; return 1; }
  echo "$body" | grep -qF 'feedback/' \
    || { echo "missing 'feedback/' entry"; return 1; }
  # "X is missing" where X is in the artifact
  echo "$body" | grep -qiE "is missing|missing.*where" \
    || { echo "missing 'X is missing' entry"; return 1; }
}

# ── sidecar-extension lock tests ──────────────────────────────────────────────

@test "sidecar-extension lock: .score.yml is absent from verifier agent body" {
  local body
  body=$(awk '/^---$/{n++; next} n>=2{print}' agents/qrspi-finding-verifier.md)
  echo "$body" | grep -qF '.score.yml' \
    && { echo "verifier agent body still references .score.yml — must be removed"; return 1; } || true
}

@test "sidecar-extension lock: canonical path uses .score.md extension" {
  # The agent must document the locked path shape: <reviewer-tag>.finding-F<NN>.score.md
  awk '/^---$/{n++; next} n>=2{print}' agents/qrspi-finding-verifier.md \
    | grep -qE 'finding-F[0-9N].*\.score\.md|\.score\.md.*finding-F' \
    || { echo "verifier agent does not document the canonical .score.md sidecar path"; return 1; }
}

@test "sidecar contract: frontmatter requires score: integer 0-100" {
  local body
  body=$(awk '/^---$/{n++; next} n>=2{print}' agents/qrspi-finding-verifier.md)
  # Must document that score: is an integer in 0..100 in the sidecar frontmatter;
  # require both the type signal and the range signal.
  echo "$body" | grep -qiE 'score.*integer.*0.*100|score.*int.*0.*100|score:.*<int.*0.{0,3}100>' \
    || { echo "verifier agent does not require score: integer 0-100 in sidecar frontmatter"; return 1; }
}

@test "sidecar contract: chat-side score labeled non-load-bearing telemetry" {
  local body
  body=$(awk '/^---$/{n++; next} n>=2{print}' agents/qrspi-finding-verifier.md)
  echo "$body" | grep -qiE 'non-load-bearing|not load.bearing|telemetry' \
    || { echo "verifier agent does not label chat-side score as non-load-bearing telemetry"; return 1; }
}

@test "sidecar contract: disk sidecar is canonical fan-in input" {
  local body
  body=$(awk '/^---$/{n++; next} n>=2{print}' agents/qrspi-finding-verifier.md)
  # Require a phrase that directly ties "load-bearing", "fan-in", and "input" together
  # to avoid matching any unrelated use of the word "canonical".
  echo "$body" | grep -qF "load-bearing fan-in input" \
    || { echo "verifier agent missing canonical disk-sidecar-as-fan-in-input contract phrase"; return 1; }
}

@test "sidecar-extension lock: wrong-extension references rejected (not fallback)" {
  local body
  body=$(awk '/^---$/{n++; next} n>=2{print}' agents/qrspi-finding-verifier.md)
  # The agent must state that the .score.md extension is locked / only allowed extension
  # (no fallback to .yml or other variants)
  echo "$body" | grep -qiE '\.score\.md.*locked|locked.*\.score\.md|only.*\.score\.md|\.score\.md.*only|no.*\.yml.*alternative|extension.*locked' \
    || { echo "verifier agent does not document that .score.md extension is locked with no fallback"; return 1; }
}

# ── orchestrator-ID hygiene ────────────────────────────────────────────────────

@test "orchestrator ID G11 is absent from verifier agent body" {
  # Internal orchestrator IDs must not appear in production agent files (they are
  # meaningless to the subagent at runtime and bloat every verifier dispatch).
  local body
  body=$(awk '/^---$/{n++; next} n>=2{print}' agents/qrspi-finding-verifier.md)
  echo "$body" | grep -qE '\bG11\b' \
    && { echo "verifier agent body still carries orchestrator ID 'G11' — remove it"; return 1; } || true
}

# ── verifier_status two-field contract (replaces VERIFY_FAILED score encoding) ─

@test "sidecar contract: success path includes verifier_status: passed field" {
  # Success sidecar must declare verifier_status: passed so fan-in can branch on
  # status before performing numeric comparison on score.
  awk '/^---$/{n++; next} n>=2{print}' agents/qrspi-finding-verifier.md \
    | grep -qF 'verifier_status: passed' \
    || { echo "verifier agent missing 'verifier_status: passed' in success sidecar template"; return 1; }
}

@test "sidecar contract: failure path includes verifier_status: failed field" {
  # Failure sidecar must declare verifier_status: failed (not re-use score: with a
  # non-integer string, which creates type confusion for fan-in consumers).
  awk '/^---$/{n++; next} n>=2{print}' agents/qrspi-finding-verifier.md \
    | grep -qF 'verifier_status: failed' \
    || { echo "verifier agent missing 'verifier_status: failed' in failure sidecar template"; return 1; }
}

@test "sidecar contract: failure path uses failure_reason field (not reason)" {
  # Failure sidecar must use failure_reason: for its diagnosis field so the schema
  # is unambiguous — success path has no failure_reason key.
  awk '/^---$/{n++; next} n>=2{print}' agents/qrspi-finding-verifier.md \
    | grep -qF 'failure_reason:' \
    || { echo "verifier agent missing 'failure_reason:' key in failure sidecar template"; return 1; }
}

@test "sidecar contract: score: VERIFY_FAILED encoding is absent (forbidden old form)" {
  # The old 'score: VERIFY_FAILED' encoding mixed non-integer string into a field
  # documented as integer 0-100, causing type confusion in fan-in consumers.
  # This encoding is permanently forbidden; failure state is expressed via verifier_status.
  awk '/^---$/{n++; next} n>=2{print}' agents/qrspi-finding-verifier.md \
    | grep -qF 'score: VERIFY_FAILED' \
    && { echo "verifier agent still uses forbidden 'score: VERIFY_FAILED' encoding — replace with verifier_status: failed"; return 1; } || true
}
