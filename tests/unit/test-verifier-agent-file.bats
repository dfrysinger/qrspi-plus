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
  awk '/^---$/{n++; next} n>=2{print}' agents/qrspi-finding-verifier.md \
    | grep -qE '\.md.*->.*\.score\.md|\.md.*→.*\.score\.md|replacing.*\.md.*\.score\.md|<reviewer-tag>.*finding-F.*\.score\.md|sidecar_path.*\.score\.md'
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

# ── G11 sidecar-extension lock tests ──────────────────────────────────────────

@test "G11: .score.yml is absent from verifier agent body (no .yml alternative allowed)" {
  local body
  body=$(awk '/^---$/{n++; next} n>=2{print}' agents/qrspi-finding-verifier.md)
  echo "$body" | grep -qF '.score.yml' \
    && { echo "verifier agent body still references .score.yml — must be removed (G11)"; return 1; } || true
}

@test "G11: sidecar path uses exactly .score.md extension in the canonical path" {
  # The agent must document the locked path shape: <reviewer-tag>.finding-F<NN>.score.md
  awk '/^---$/{n++; next} n>=2{print}' agents/qrspi-finding-verifier.md \
    | grep -qE 'finding-F[0-9N].*\.score\.md|\.score\.md.*finding-F' \
    || { echo "verifier agent does not document the canonical .score.md sidecar path (G11)"; return 1; }
}

@test "G11: sidecar frontmatter requires score: as integer 0-100" {
  local body
  body=$(awk '/^---$/{n++; next} n>=2{print}' agents/qrspi-finding-verifier.md)
  # Must document that score: is an integer in 0..100 in the sidecar frontmatter
  echo "$body" | grep -qE 'score:.*int|score:.*0.*100|integer.*score:|frontmatter.*score:|score:.*frontmatter' \
    || { echo "verifier agent does not require score: integer 0-100 in sidecar frontmatter (G11)"; return 1; }
}

@test "G11: chat-side score output is labeled non-load-bearing telemetry" {
  local body
  body=$(awk '/^---$/{n++; next} n>=2{print}' agents/qrspi-finding-verifier.md)
  echo "$body" | grep -qiE 'non-load-bearing|not load.bearing|telemetry' \
    || { echo "verifier agent does not label chat-side score as non-load-bearing telemetry (G11)"; return 1; }
}

@test "G11: disk sidecar is the canonical fan-in input (not chat output)" {
  local body
  body=$(awk '/^---$/{n++; next} n>=2{print}' agents/qrspi-finding-verifier.md)
  echo "$body" | grep -qiE 'canonical|disk.*sidecar|sidecar.*canonical|fan.in.*sidecar|sidecar.*fan.in' \
    || { echo "verifier agent does not identify disk sidecar as canonical fan-in input (G11)"; return 1; }
}

@test "G11: wrong-extension sidecar references are rejected (not accepted as fallback)" {
  local body
  body=$(awk '/^---$/{n++; next} n>=2{print}' agents/qrspi-finding-verifier.md)
  # The agent must state that the .score.md extension is locked / only allowed extension
  # (no fallback to .yml or other variants)
  echo "$body" | grep -qiE '\.score\.md.*locked|locked.*\.score\.md|only.*\.score\.md|\.score\.md.*only|no.*\.yml.*alternative|extension.*locked' \
    || { echo "verifier agent does not document that .score.md extension is locked with no fallback (G11)"; return 1; }
}
