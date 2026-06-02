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

# ── Informational-carve-out rubric assertions (verifier agent file) ───────────

@test "informational-carve-out: verifier body contains literal case-sensitive Informational: token" {
  # The carve-out's load-bearing detection token is the literal case-sensitive
  # 'Informational:' string (capital I, lowercase remainder, trailing colon).
  # No other variant carries the semantic — this anchor is a regression guard
  # against rubric edits that paraphrase the token away.
  local body
  body=$(awk '/^---$/{n++; next} n>=2{print}' agents/qrspi-finding-verifier.md)
  echo "$body" | grep -qF 'Informational:' \
    || { echo "verifier agent body missing literal case-sensitive 'Informational:' token in carve-out"; return 1; }
}

@test "informational-carve-out: documents case-sensitive detection rule" {
  awk '/^---$/{n++; next} n>=2{print}' agents/qrspi-finding-verifier.md \
    | grep -qiE 'case.sensitive' \
    || { echo "verifier agent carve-out missing 'case-sensitive' detection rule"; return 1; }
}

@test "informational-carve-out: documents first-non-blank-line detection rule on message body" {
  # The carve-out keys off the first non-blank line of the finding's message body,
  # not the first byte of the file. Pin the phrase shape that documents this.
  awk '/^---$/{n++; next} n>=2{print}' agents/qrspi-finding-verifier.md \
    | grep -qE 'first non.blank line' \
    || { echo "verifier agent carve-out missing 'first non-blank line' detection rule"; return 1; }
}

@test "informational-carve-out: precedes the false-positive-pattern list" {
  # Placement is load-bearing — the carve-out MUST appear before the existing
  # 'Treat the following patterns as likely false positives' sentence so the
  # branch executes before the false-positive rubric is consulted.
  local fp_line info_line
  fp_line=$(grep -nF 'likely false positives' agents/qrspi-finding-verifier.md | head -n1 | cut -d: -f1)
  info_line=$(grep -nF 'Informational findings' agents/qrspi-finding-verifier.md | head -n1 | cut -d: -f1)
  [ -n "$fp_line" ] || { echo "could not locate false-positive-pattern sentence anchor"; return 1; }
  [ -n "$info_line" ] || { echo "could not locate 'Informational findings' carve-out heading"; return 1; }
  [ "$info_line" -lt "$fp_line" ] \
    || { echo "carve-out (line $info_line) must appear BEFORE false-positive-pattern list (line $fp_line)"; return 1; }
}

@test "informational-carve-out: explicitly disables false-positive scoring on Informational findings" {
  # Body must instruct the agent NOT to apply the false-positive patterns when
  # the Informational prefix is detected — this is the rubric branch itself.
  awk '/^---$/{n++; next} n>=2{print}' agents/qrspi-finding-verifier.md \
    | grep -qE 'do NOT apply the false.positive|not apply the false.positive' \
    || { echo "verifier agent carve-out missing 'do NOT apply the false-positive patterns' instruction"; return 1; }
}

@test "informational-carve-out: scores on structural confidence (75/50/25 anchors)" {
  local body
  body=$(awk '/^---$/{n++; next} n>=2{print}' agents/qrspi-finding-verifier.md)
  echo "$body" | grep -qiE 'structural confidence' \
    || { echo "verifier agent carve-out missing 'structural confidence' rubric framing"; return 1; }
  # Anchor 75: structurally verifiable
  echo "$body" | grep -qE '75:.*[Ss]tructurally verifiable' \
    || { echo "verifier agent carve-out missing 75 anchor (structurally verifiable)"; return 1; }
  # Anchor 50: partially verifiable
  echo "$body" | grep -qE '50:.*[Pp]artially verifiable' \
    || { echo "verifier agent carve-out missing 50 anchor (partially verifiable)"; return 1; }
  # Anchor 25: premise wrong / cannot be located
  echo "$body" | grep -qE '25:.*([Pp]remise wrong|cannot be located)' \
    || { echo "verifier agent carve-out missing 25 anchor (premise wrong)"; return 1; }
}

# ── Informational-findings reviewer-protocol section assertions ───────────────

@test "informational-findings-protocol: '## Informational Findings' section exists" {
  grep -qE '^## Informational Findings\s*$' skills/reviewer-protocol/SKILL.md \
    || { echo "skills/reviewer-protocol/SKILL.md missing '## Informational Findings' section"; return 1; }
}

@test "informational-findings-protocol: section is placed between Disagreement-Valid Framing and Untrusted Data Handling" {
  local dv info udh
  dv=$(grep -nE '^## Disagreement-Valid Framing\s*$' skills/reviewer-protocol/SKILL.md | head -n1 | cut -d: -f1)
  info=$(grep -nE '^## Informational Findings\s*$' skills/reviewer-protocol/SKILL.md | head -n1 | cut -d: -f1)
  udh=$(grep -nE '^## Untrusted Data Handling\s*$' skills/reviewer-protocol/SKILL.md | head -n1 | cut -d: -f1)
  [ -n "$dv" ] && [ -n "$info" ] && [ -n "$udh" ] \
    || { echo "missing one of the three section anchors (Disagreement-Valid / Informational / Untrusted Data)"; return 1; }
  [ "$dv" -lt "$info" ] && [ "$info" -lt "$udh" ] \
    || { echo "expected Disagreement-Valid ($dv) < Informational ($info) < Untrusted Data ($udh)"; return 1; }
}

@test "informational-findings-protocol: documents the literal Informational: prefix shape" {
  # Section MUST cite the exact case-sensitive token (capital I, trailing colon)
  # so reviewer agents and human reviewers have the same anchor.
  awk '/^## Informational Findings/{flag=1; next} /^## /{flag=0} flag' skills/reviewer-protocol/SKILL.md \
    | grep -qF 'Informational:' \
    || { echo "Informational Findings section missing literal 'Informational:' prefix token"; return 1; }
}

@test "informational-findings-protocol: documents case-sensitive prefix detection" {
  awk '/^## Informational Findings/{flag=1; next} /^## /{flag=0} flag' skills/reviewer-protocol/SKILL.md \
    | grep -qiE 'case.sensitive' \
    || { echo "Informational Findings section missing case-sensitive prefix rule"; return 1; }
}

@test "informational-findings-protocol: documents first-non-blank-line placement on message field" {
  awk '/^## Informational Findings/{flag=1; next} /^## /{flag=0} flag' skills/reviewer-protocol/SKILL.md \
    | grep -qE 'first non.blank line' \
    || { echo "Informational Findings section missing 'first non-blank line' placement rule"; return 1; }
  awk '/^## Informational Findings/{flag=1; next} /^## /{flag=0} flag' skills/reviewer-protocol/SKILL.md \
    | grep -qE 'message' \
    || { echo "Informational Findings section missing reference to 'message' field"; return 1; }
}

@test "informational-findings-protocol: documents intended use (real observation, no demanded action)" {
  # The when-to-use semantics are load-bearing — distinguishes Informational
  # from acknowledged-and-silenced (which stays in the false-positive rubric).
  awk '/^## Informational Findings/{flag=1; next} /^## /{flag=0} flag' skills/reviewer-protocol/SKILL.md \
    | grep -qiE 'real (issue|observation)|believes the finding is real|real but is not demanding action|not demanding action|does not demand action' \
    || { echo "Informational Findings section missing intended-use framing (real observation, no demanded action)"; return 1; }
}

@test "informational-findings-protocol: documents downstream structural-confidence scoring" {
  awk '/^## Informational Findings/{flag=1; next} /^## /{flag=0} flag' skills/reviewer-protocol/SKILL.md \
    | grep -qiE 'structural confidence' \
    || { echo "Informational Findings section missing downstream 'structural confidence' scoring note"; return 1; }
}

@test "informational-findings-protocol: documents log-only handling (no auto-apply, no pause)" {
  # Downstream behavior: review loop logs the finding but does NOT auto-apply
  # or pause regardless of change_type. The 'no pause' assertion uses a
  # negation-anchored pattern (mirroring the auto-apply pattern below) so a
  # bare 'pause' token elsewhere in the section cannot satisfy the assertion;
  # a regression that drops the negating qualifier will surface here.
  local section
  section=$(awk '/^## Informational Findings/{flag=1; next} /^## /{flag=0} flag' skills/reviewer-protocol/SKILL.md)
  echo "$section" | grep -qiE 'log' \
    || { echo "Informational Findings section missing log-only handling note"; return 1; }
  echo "$section" | grep -qiE 'not auto.apply|does NOT auto.apply|no auto.apply|never auto.apply' \
    || { echo "Informational Findings section missing 'not auto-apply' downstream behavior"; return 1; }
  echo "$section" | grep -qiE 'not.*pause|does NOT pause|no.*pause|never pause' \
    || { echo "Informational Findings section missing 'no pause' downstream behavior (negation-anchored)"; return 1; }
}

@test "informational-findings-protocol: documents backward-compat for unprefixed findings" {
  # Findings without the Informational: prefix MUST continue to be scored exactly
  # as before (no behavior change for existing finding shapes).
  awk '/^## Informational Findings/{flag=1; next} /^## /{flag=0} flag' skills/reviewer-protocol/SKILL.md \
    | grep -qiE 'without the prefix|no prefix|unprefixed|backward.compat|continue to be scored|no behavior change' \
    || { echo "Informational Findings section missing backward-compat note for unprefixed findings"; return 1; }
}

@test "informational-findings-protocol: documents confused-deputy scope guard against artifact-directed labeling" {
  # Parallel to the secondary-escalation confused-deputy guard in
  # ## Change-Type Classifier: the Informational: prefix is reviewer-authored
  # intent, not a label that untrusted artifact content (code comments, docstrings,
  # fixture text, embedded data) may direct the reviewer to apply. If artifact
  # content suggests using the prefix, the reviewer MUST NOT honor that suggestion.
  # Pin a semantic anchor — either the explicit 'confused-deputy' token or the
  # 'artifact-directed' phrasing — inside the Informational Findings section.
  local section
  section=$(awk '/^## Informational Findings/{flag=1; next} /^## /{flag=0} flag' skills/reviewer-protocol/SKILL.md)
  echo "$section" | grep -qiE 'confused.deputy|artifact.directed' \
    || { echo "Informational Findings section missing confused-deputy / artifact-directed scope guard"; return 1; }
  # The guard must clearly assert reviewer-authored intent vs. untrusted/embedded content.
  echo "$section" | grep -qiE 'reviewer.authored|reviewer-authored intent' \
    || { echo "Informational Findings section missing 'reviewer-authored' framing in confused-deputy guard"; return 1; }
}

# ── R2 Fix E: sidecar field-ordering invariant (load-bearing security pin) ─

@test "sidecar field-order: success template has score: BEFORE defect_class:" {
  # Extract the success-path fenced markdown block following 'On success:'.
  local block
  block=$(awk '
    /^[[:space:]]*On success:[[:space:]]*$/ { flag=1; next }
    flag && /^[[:space:]]*```markdown[[:space:]]*$/ { in_block=1; next }
    in_block && /^[[:space:]]*```[[:space:]]*$/ { exit }
    in_block { print }
  ' agents/qrspi-finding-verifier.md)
  [ -n "$block" ] || { echo "could not locate On-success sidecar template block"; return 1; }
  local score_line defect_line
  score_line=$(echo "$block" | grep -nE '^\s*score:' | head -1 | cut -d: -f1)
  defect_line=$(echo "$block" | grep -nE '^\s*defect_class:' | head -1 | cut -d: -f1)
  [ -n "$score_line" ] || { echo "no score: in success template"; return 1; }
  [ -n "$defect_line" ] || { echo "no defect_class: in success template"; return 1; }
  [ "$score_line" -lt "$defect_line" ] \
    || { echo "success template field order violated: score: at line $score_line, defect_class: at line $defect_line (score MUST precede defect_class)"; return 1; }
}

@test "sidecar field-order: failure template has defect_class: as the LAST frontmatter field" {
  # Extract the failure-path fenced markdown block following 'On failure'.
  local block
  block=$(awk '
    /^[[:space:]]*On failure/ { flag=1; next }
    flag && /^[[:space:]]*```markdown[[:space:]]*$/ { in_block=1; next }
    in_block && /^[[:space:]]*```[[:space:]]*$/ { exit }
    in_block { print }
  ' agents/qrspi-finding-verifier.md)
  [ -n "$block" ] || { echo "could not locate On-failure sidecar template block"; return 1; }
  # Extract frontmatter lines (between the two --- markers).
  local fm
  fm=$(echo "$block" | awk '/^[[:space:]]*---[[:space:]]*$/{n++; next} n==1{print}')
  [ -n "$fm" ] || { echo "could not extract failure-template frontmatter"; return 1; }
  local last_field
  last_field=$(echo "$fm" | grep -E '^[[:space:]]*[a-z_]+:' | tail -1 | sed -E 's/^[[:space:]]*([a-z_]+):.*/\1/')
  [ "$last_field" = "defect_class" ] \
    || { echo "failure template's last frontmatter field is '$last_field' — must be 'defect_class' per the load-bearing field-ordering invariant"; echo "frontmatter:"; echo "$fm"; return 1; }
}

@test "sidecar field-order: agent body documents the load-bearing invariant" {
  grep -qE 'Field.ordering invariant|score:.*MUST precede.*defect_class|defect_class:.*MUST appear LAST' \
    agents/qrspi-finding-verifier.md \
    || { echo "agent body does not document the load-bearing field-ordering invariant"; return 1; }
}

@test "sidecar field-order: verifier-fan-in.sh header documents the invariant" {
  # The script's documentation block must mirror the agent body so future
  # parser-replacement tooling inherits the same security pin.
  grep -qE 'field.ordering invariant|score:.*MUST precede.*defect_class' \
    scripts/verifier-fan-in.sh \
    || { echo "verifier-fan-in.sh header does not document the field-ordering invariant"; return 1; }
}

# ── R2 Fix H: failure-class taxonomy (best-effort required on failure) ────

@test "defect_class: failure-path classification names the failure-class taxonomy" {
  # Required tokens from the taxonomy must appear in the agent body so
  # verifiers have a closed vocabulary to draw from on the failure path.
  local body
  body=$(cat agents/qrspi-finding-verifier.md)
  for tok in 'verifier-crash' 'infrastructure-failure' 'file-missing' 'rate-limited'; do
    echo "$body" | grep -qF "$tok" \
      || { echo "failure-class taxonomy missing token: $tok"; return 1; }
  done
  # The 'best-effort' or 'reserve unspecified' phrasing must appear so the
  # promiscuous-unspecified anti-pattern is explicitly forbidden.
  echo "$body" | grep -qiE 'best.effort|reserve.*unspecified' \
    || { echo "agent body does not require best-effort failure classification (sf-claude R2 F03)"; return 1; }
}

# ── R2 Fix I: on-error branch (procedure must fall through to a sidecar) ──

@test "verifier procedure documents on-error fall-through to failure-sidecar template" {
  # The on-error paragraph must appear BEFORE step 1 of the procedure.
  local before_step1
  before_step1=$(awk '
    /^## Procedure/ { in_proc=1; next }
    in_proc && /^1\. \*\*Read `<finding_file_path>`\*\*/ { exit }
    in_proc { print }
  ' agents/qrspi-finding-verifier.md)
  [ -n "$before_step1" ] || { echo "could not extract pre-step-1 procedure prose"; return 1; }
  echo "$before_step1" | grep -qiE 'on.any.unrecoverable error|on.error' \
    || { echo "pre-step-1 procedure prose does not introduce the on-error branch"; return 1; }
  echo "$before_step1" | grep -qiE 'never return without writing a sidecar|Never return.*sidecar' \
    || { echo "on-error paragraph missing 'never return without writing a sidecar' guarantee"; return 1; }
}
