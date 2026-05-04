#!/usr/bin/env bats
bats_require_minimum_version 1.5.0

# Task 14 — Replan minor-path archive-and-populate sequence
#
# These are content-assertion (prompt-content invariant) tests against
# skills/replan/SKILL.md, asserting that the SKILL prose documents the
# correct minor-path procedure: archive four artifacts, read roadmap,
# populate next-phase drafts from future-* artifacts, mark drafts, and
# invoke Goals.
#
# All assertions extract a target heading's section text first (until the
# next `^## ` heading) and then assert on the extracted slice — never on
# the whole file — so a string appearing under a different heading cannot
# vacuously satisfy a different section's check.

setup() {
  REPLAN_FILE="$BATS_TEST_DIRNAME/../../skills/replan/SKILL.md"
  OWNS_FILE="$BATS_TEST_DIRNAME/../../skills/replan/owns-defers.md"
  SCOPE_REVIEWER_TEMPLATE="$BATS_TEST_DIRNAME/../../skills/_shared/templates/scope-reviewer.md"
  export REPLAN_FILE OWNS_FILE SCOPE_REVIEWER_TEMPLATE
}

# extract_section <file> <heading-line>
# Prints the section starting at the given exact heading (e.g. "## Replan OWNS / Replan DEFERS")
# up to but NOT including the next "^## " heading. Heading line itself is included.
extract_section() {
  local file="$1"
  local heading="$2"
  awk -v h="$heading" '
    $0 == h { in_section = 1; print; next }
    in_section && /^## / { in_section = 0 }
    in_section { print }
  ' "$file"
}

# extract_subsection <file> <h2-heading> <h3-heading>
# Extracts an H3 sub-block from inside an H2 section. Used to scope
# OWNS/DEFERS sub-list assertions to their own block.
extract_subsection() {
  local file="$1"
  local h2="$2"
  local h3="$3"
  extract_section "$file" "$h2" \
    | awk -v h="$h3" '
        $0 == h { in_b = 1; print; next }
        in_b && /^### / { exit }
        in_b && /^## / { exit }
        in_b { print }
      '
}

# extract_h3_direct <file> <h3-heading>
# Extracts an H3 sub-block directly from a file (no H2 wrapper required).
# Used for owns-defers.md files which start at H3 level.
extract_h3_direct() {
  local file="$1"
  local h3="$2"
  awk -v h="$h3" '
    $0 == h { in_b = 1; print; next }
    in_b && /^### / { exit }
    in_b && /^## / { exit }
    in_b { print }
  ' "$file"
}

# ── File existence and OWNS/DEFERS heading ──────────────────────────────────

@test "skills/replan/SKILL.md exists" {
  [ -f "$REPLAN_FILE" ]
}

@test "## Replan OWNS / Replan DEFERS heading is present" {
  run grep -c "^## Replan OWNS / Replan DEFERS$" "$REPLAN_FILE"
  [ "$status" -eq 0 ]
  [ "$output" = "1" ]
}

@test "OWNS/DEFERS section uses H3 subheadings ### Replan OWNS and ### Replan DEFERS (family-shape)" {
  grep -qE "^### Replan OWNS$" "$OWNS_FILE"
  grep -qE "^### Replan DEFERS$" "$OWNS_FILE"
}

# ── OWNS list contents (scoped to ### Replan OWNS sub-block) ────────────────

@test "### Replan OWNS lists archive of four synthesizing artifacts" {
  local block
  block="$(extract_h3_direct "$OWNS_FILE" "### Replan OWNS")"
  [ -n "$block" ]
  echo "$block" | grep -qi "archive"
  echo "$block" | grep -q "goals.md"
  echo "$block" | grep -q "questions.md"
  echo "$block" | grep -q "research/summary.md"
  echo "$block" | grep -q "design.md"
}

@test "### Replan OWNS lists populate-from-future-* and mark-as-draft and invoke-Goals" {
  local block
  block="$(extract_h3_direct "$OWNS_FILE" "### Replan OWNS")"
  echo "$block" | grep -qi "future-goals.md"
  echo "$block" | grep -qi "future-questions.md"
  echo "$block" | grep -qi "future-research-summary.md"
  echo "$block" | grep -qi "future-design.md"
  echo "$block" | grep -qi "status: draft"
  echo "$block" | grep -qE "qrspi:goals|invoke .*Goals"
}

# ── DEFERS list contents (scoped to ### Replan DEFERS sub-block) ────────────

@test "### Replan DEFERS lists phasing decisions to Phasing" {
  local block
  block="$(extract_h3_direct "$OWNS_FILE" "### Replan DEFERS")"
  [ -n "$block" ]
  echo "$block" | grep -qi "Phasing"
  # Co-occurrence: a single line/bullet must reference a phasing-decision
  # concept AND the Phasing destination — otherwise unrelated mentions
  # could vacuously pass.
  echo "$block" | grep -iE "slice|phase boundar|replan-gate|Iron Law" | grep -q "Phasing"
}

@test "### Replan DEFERS lists roadmap authoring to Phasing" {
  local block
  block="$(extract_h3_direct "$OWNS_FILE" "### Replan DEFERS")"
  echo "$block" | grep -qi "roadmap"
  echo "$block" | grep -i "roadmap" | grep -q "Phasing"
}

# ── Five-step archive-and-populate sequence ─────────────────────────────────

@test "Archive-and-Populate Sequence section is present" {
  run grep -c "^### Archive-and-Populate Sequence" "$REPLAN_FILE"
  [ "$status" -eq 0 ]
  [ "$output" = "1" ]
}

@test "Archive-and-Populate Sequence enumerates all five steps in order" {
  # Extract the H3 sub-block scoped to the Phase Snapshot's parent H2 section
  # (Human Gate — Minor Changes), then look at the H3 block specifically.
  local block
  block="$(awk '
    /^### Archive-and-Populate Sequence/ { in_b = 1; print; next }
    in_b && /^## / { exit }
    in_b && /^### / && !/^### Archive-and-Populate Sequence/ { exit }
    in_b { print }
  ' "$REPLAN_FILE")"
  [ -n "$block" ]
  # Five numbered steps must be present in order.
  echo "$block" | grep -qE "^1\. \*\*Archive\*\*"
  echo "$block" | grep -qE "^2\. \*\*Read roadmap\*\*"
  echo "$block" | grep -qE "^3\. \*\*Extract from future-\* artifacts\*\*"
  echo "$block" | grep -qE "^4\. \*\*Write next-phase drafts\*\*"
  echo "$block" | grep -qE "^5\. \*\*Invoke Goals\*\*"
}

@test "Archive step uses runtime path docs/qrspi/{slug}/phases/phase-NN/ (NOT qrspi-plus/phases/)" {
  local block
  block="$(awk '
    /^### Archive-and-Populate Sequence/ { in_b = 1; print; next }
    in_b && /^## / { exit }
    in_b && /^### / && !/^### Archive-and-Populate Sequence/ { exit }
    in_b { print }
  ' "$REPLAN_FILE")"
  echo "$block" | grep -q "docs/qrspi/{slug}/phases/phase-NN/"
  ! echo "$block" | grep -q "qrspi-plus/phases/"
}

@test "Step 4 marks all four next-phase drafts with status: draft" {
  local block
  block="$(awk '
    /^### Archive-and-Populate Sequence/ { in_b = 1; print; next }
    in_b && /^## / { exit }
    in_b && /^### / && !/^### Archive-and-Populate Sequence/ { exit }
    in_b { print }
  ' "$REPLAN_FILE")"
  # Step 4 must mention status: draft for the populated drafts.
  echo "$block" | grep -qE "status: ?draft"
}

@test "Step 5 invokes qrspi:goals (unchanged invocation target)" {
  local block
  block="$(awk '
    /^### Archive-and-Populate Sequence/ { in_b = 1; print; next }
    in_b && /^## / { exit }
    in_b && /^### / && !/^### Archive-and-Populate Sequence/ { exit }
    in_b { print }
  ' "$REPLAN_FILE")"
  echo "$block" | grep -q "qrspi:goals"
}

# ── Future-research naming normalization ────────────────────────────────────

@test "no future-research/ directory references remain in SKILL.md" {
  ! grep -q "future-research/" "$REPLAN_FILE"
}

@test "future-research-summary.md appears at least once in the minor-path region" {
  # The minor-path region spans Human Gate — Minor Changes through the end of
  # Archive-and-Populate Sequence. Assert the canonical single-file name lives
  # somewhere in that region.
  local minor_region
  minor_region="$(awk '
    /^## Human Gate — Minor Changes/ { in_b = 1 }
    in_b && /^## Human Gate — Major Changes/ { exit }
    in_b { print }
  ' "$REPLAN_FILE")"
  echo "$minor_region" | grep -q "future-research-summary.md"
}

# ── Fail-closed ABORT clauses (silent-failure-hunter HIGHs) ─────────────────

# Helper for these tests: extract the Archive-and-Populate Sequence block.
extract_archive_block() {
  awk '
    /^### Archive-and-Populate Sequence/ { in_b = 1; print; next }
    in_b && /^## / { exit }
    in_b && /^### / && !/^### Archive-and-Populate Sequence/ { exit }
    in_b { print }
  ' "$REPLAN_FILE"
}

# Helper: extract one numbered step's prose (steps 1..5) from the archive block.
# Each step starts with "^N. \*\*..." and ends at the next numbered step or end-of-block.
extract_step() {
  local n="$1"
  extract_archive_block | awk -v n="$n" '
    BEGIN { pat = "^" n "\\. \\*\\*" }
    $0 ~ pat { in_s = 1; print; next }
    in_s && /^[0-9]+\. \*\*/ { exit }
    in_s { print }
  '
}

@test "Step 1 (Archive) contains an ABORT fail-closed clause" {
  local step
  step="$(extract_step 1)"
  [ -n "$step" ]
  echo "$step" | grep -q "ABORT"
}

@test "Step 1 (Archive) fails on directory creation OR missing source files" {
  local step
  step="$(extract_step 1)"
  # Must mention destination/directory creation failure modes
  echo "$step" | grep -iE "permission|ENOSPC|cannot be created|directory"
  # Must mention source-file missing/unreadable
  echo "$step" | grep -iE "missing|unreadable"
  # Must explicitly forbid partial archive
  echo "$step" | grep -iE "partial|partially"
}

@test "Step 2 (Read roadmap) contains an ABORT fail-closed clause" {
  local step
  step="$(extract_step 2)"
  [ -n "$step" ]
  echo "$step" | grep -q "ABORT"
}

@test "Step 2 (Read roadmap) fails on missing roadmap.md or no next-phase entries" {
  local step
  step="$(extract_step 2)"
  echo "$step" | grep -iE "roadmap.md.*missing|missing.*roadmap"
  echo "$step" | grep -iE "no next-phase entries|final phase|empty next-phase"
}

@test "Step 3 (Extract) contains an ABORT fail-closed clause" {
  local step
  step="$(extract_step 3)"
  [ -n "$step" ]
  echo "$step" | grep -q "ABORT"
}

@test "Step 3 (Extract) fails on missing future-* file when expected" {
  local step
  step="$(extract_step 3)"
  echo "$step" | grep -iE "future-.*missing|missing.*future-"
  echo "$step" | grep -iE "expected|expect"
  # And explicitly forbids silently writing empty drafts
  echo "$step" | grep -iE "empty draft|silently"
}

@test "Step 4 (Write drafts) contains an ABORT fail-closed clause" {
  local step
  step="$(extract_step 4)"
  [ -n "$step" ]
  echo "$step" | grep -q "ABORT"
}

@test "Step 4 (Write drafts) mentions atomicity (all-or-nothing)" {
  local step
  step="$(extract_step 4)"
  echo "$step" | grep -iE "atomic|atomicity"
  echo "$step" | grep -iE "roll back|rollback|all-or-nothing|all four"
}

@test "Step 5 (Invoke Goals) contains an ABORT fail-closed clause" {
  local step
  step="$(extract_step 5)"
  [ -n "$step" ]
  echo "$step" | grep -q "ABORT"
}

@test "Step 5 (Invoke Goals) requires pre-invocation draft existence and non-emptiness check" {
  local step
  step="$(extract_step 5)"
  echo "$step" | grep -iE "status: ?draft"
  echo "$step" | grep -iE "≥1 entry|at least 1 entry|non-empty|empty.*malformed|malformed"
  echo "$step" | grep -iE "before invoking|before invocation"
}

# ── Scope-reviewer dispatch in Review Round ─────────────────────────────────

@test "Review Round dispatches scope-reviewer with {ARTIFACT_TYPE}=replan" {
  local section
  section="$(extract_section "$REPLAN_FILE" "## Review Round")"
  [ -n "$section" ]
  echo "$section" | grep -qi "scope-reviewer"
  echo "$section" | grep -q "{ARTIFACT_TYPE}=replan"
}

@test "Review Round scope-reviewer dispatch references OWNS/DEFERS as locked rule set" {
  local section
  section="$(extract_section "$REPLAN_FILE" "## Review Round")"
  # Co-occurrence: scope-reviewer line must reference OWNS / DEFERS
  echo "$section" | grep -i "scope-reviewer" | grep -qE "OWNS|DEFERS|Replan OWNS"
}

@test "Review Round scope-reviewer dispatch is fail-closed on malformed OWNS/DEFERS" {
  local section
  section="$(extract_section "$REPLAN_FILE" "## Review Round")"
  # Must mention fail-closed semantic + the H3 procedure reference from the template
  echo "$section" | grep -iE "fail-closed|fails-closed|fails closed"
  echo "$section" | grep -iE "malformed|unparseable"
}

@test "Review Round scope-reviewer dispatch runs in parallel with the Claude reviewer" {
  local section
  section="$(extract_section "$REPLAN_FILE" "## Review Round")"
  echo "$section" | grep -i "scope-reviewer" | grep -qiE "parallel|in parallel"
}

# ── Scope-reviewer template allowed-values list includes `replan` ───────────

@test "scope-reviewer template ## Parameters allowed-values list includes replan" {
  # The scope-reviewer template fails-closed if dispatched with an
  # {ARTIFACT_TYPE} value not in its allowed list. Replan dispatches with
  # {ARTIFACT_TYPE}=replan, so the template must list `replan` as one of
  # the allowed values under its `## Parameters` section. This guards
  # against the silent-failure mode where the template would fail-closed
  # before running checks against the Replan-proposed changes.
  [ -f "$SCOPE_REVIEWER_TEMPLATE" ]
  local section
  section="$(awk '
    /^## Parameters/ { in_b = 1; print; next }
    in_b && /^## / { exit }
    in_b { print }
  ' "$SCOPE_REVIEWER_TEMPLATE")"
  [ -n "$section" ]
  # Allowed-values list must contain a bullet for `replan`.
  echo "$section" | grep -qE "^[[:space:]]*-[[:space:]]+\`replan\`$"
}

# ── Task 34: Artifact Gating includes phasing.md (R1 Claude-I2) ─────────────

@test "Artifact Gating section lists phasing.md as a required input with status: approved" {
  # R1 Claude-I2: Replan's required-inputs section was missing phasing.md.
  # phasing.md is the source of truth for slice decomposition + phase
  # boundaries (M54 ownership boundary); Replan READS it to honor those
  # decisions. Must appear in the Artifact Gating required-inputs list.
  local section
  section="$(extract_section "$REPLAN_FILE" "## Artifact Gating")"
  [ -n "$section" ]
  # phasing.md must appear in the section, paired with `status: approved`
  # on the same bullet (mirrors the goals.md/design.md/plan.md rows).
  echo "$section" | grep -F "phasing.md" | grep -q "status: approved"
}

# ── Task 34: codex_reviews uses Config Validation Procedure (R2 I-N5) ──────

@test "Artifact Gating does NOT contain the silent codex_reviews default fallback" {
  # R2 I-N5: prior text said "If config.md doesn't exist, default to
  # codex_reviews: false" — this is the silent default forbidden by
  # using-qrspi's "No silent defaults" contract. Must be removed.
  local section
  section="$(extract_section "$REPLAN_FILE" "## Artifact Gating")"
  [ -n "$section" ]
  ! echo "$section" | grep -qiE "default to .*codex_reviews|codex_reviews.* false.*default|If .*config.md.*doesn't exist.*codex_reviews"
}

@test "Artifact Gating invokes the Config Validation Procedure for codex_reviews" {
  # Replacement for the silent default: invoke the Config Validation
  # Procedure (per using-qrspi:411). Mirrors the pattern used by
  # Integrate/Test ("Apply the Config Validation Procedure in
  # using-qrspi/SKILL.md. {Skill} validates {fields}.").
  local section
  section="$(extract_section "$REPLAN_FILE" "## Artifact Gating")"
  [ -n "$section" ]
  echo "$section" | grep -q "Config Validation Procedure"
  echo "$section" | grep -qE "using-qrspi/SKILL.md|using-qrspi"
  # Must name codex_reviews as a field Replan validates.
  echo "$section" | grep -i "Replan" | grep -q "codex_reviews"
}

# ── Task 40: Step 2 reads roadmap from snapshot path, not deleted live path ─

@test "Step 2 (Read roadmap) reads from snapshot path, not the deleted live path" {
  # Round-3 integration M-1 / cross-cutting F-1: artifact_promote_next_phase
  # (hooks/lib/artifact.sh) deletes roadmap.md during phase-promote, BEFORE
  # the archive-and-populate sequence's step 2 runs. The fail-closed clause
  # ("If roadmap.md is missing OR has no next-phase entries … ABORT") would
  # fire deterministically every minor-path run if step 2 read from the live
  # path. artifact_snapshot_phase copies roadmap.md into
  # phases/phase-{completed_NN}/roadmap.md prior to promote, so step 2 must
  # read from that snapshot path.
  local step
  step="$(extract_step 2)"
  [ -n "$step" ]
  # Step 2 must reference the snapshot path under phases/phase-NN/.
  echo "$step" | grep -qE "phases/phase-(\{completed_NN\}|NN)/roadmap.md"
  # Step 2 must NOT instruct opening the bare live `roadmap.md` (the deleted
  # path). Permit references that are clearly part of the snapshot path
  # (i.e. preceded by `phases/phase-…/`) — those will not match the negative
  # pattern below because we strip them out first.
  local stripped
  stripped="$(echo "$step" | sed -E 's#phases/phase-[^/[:space:]`]*/roadmap.md##g')"
  ! echo "$stripped" | grep -qE "open[[:space:]]+\`?roadmap.md\`?"
}

@test "Step 2 (Read roadmap) attributes the snapshot to artifact_snapshot_phase" {
  # The snapshot path exists because artifact_snapshot_phase ran in the
  # Phase Snapshot section just above. Step 2's prose should make the
  # snapshot provenance explicit so a future reader can trace WHY the read
  # path is the snapshot copy (avoids drift if someone later edits the
  # snapshot helper without updating Replan).
  local step
  step="$(extract_step 2)"
  [ -n "$step" ]
  echo "$step" | grep -qiE "snapshot|artifact_snapshot_phase"
}
