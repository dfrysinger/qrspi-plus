#!/usr/bin/env bats

@test "verifier_enabled field is documented under Fields that affect pipeline behavior" {
  awk '
    /^### Fields that affect pipeline behavior/ { in_section=1; next }
    /^### / { in_section=0 }
    in_section { print }
  ' skills/using-qrspi/SKILL.md \
    | grep -qE '^\s*-\s+\*\*`verifier_enabled`\*\*' \
    || { echo "verifier_enabled not documented under Fields that affect pipeline behavior"; return 1; }
}

@test "verifier_enabled default is true" {
  awk '/verifier_enabled/{print; getline; print; getline; print}' skills/using-qrspi/SKILL.md \
    | grep -qE 'default\s*`true`'
}

@test "persistence semantics documented (durable across /compact + resume)" {
  grep -A5 -B0 'verifier_enabled' skills/using-qrspi/SKILL.md \
    | grep -qE 'durable across.*compact|persists across|resume.*re-entry'
}

@test "runtime-backfill carve-out documented in Exceptions" {
  awk '
    /^### Exceptions/ { in_section=1; next }
    /^### / && in_section { in_section=0 }
    in_section { print }
  ' skills/using-qrspi/SKILL.md \
    | grep -qE 'verifier_enabled.*runtime backfill|runtime backfill.*verifier_enabled' \
    || { echo "runtime-backfill carve-out not in ### Exceptions section"; return 1; }
}

@test "round-scoped skip does NOT mutate config.md" {
  grep -A6 -B0 'verifier_enabled' skills/using-qrspi/SKILL.md \
    | grep -qE 'does NOT mutate.*config\.md|round only|CURRENT round only'
}

@test "Apply-fix protocol body reads verifier_enabled from config.md" {
  local protocol
  protocol=$(awk '
    /\*\*Apply-fix protocol\.\*\*/ { in_block=1 }
    in_block && /\*\*Diff handling between rounds/ { exit }
    in_block { print }
  ' skills/using-qrspi/SKILL.md)
  echo "$protocol" | grep -qF 'verifier_enabled' \
    || { echo "Apply-fix protocol does not reference verifier_enabled"; return 1; }
}

@test "runtime-backfill code is present in Apply-fix protocol" {
  local protocol
  protocol=$(awk '
    /\*\*Apply-fix protocol\.\*\*/ { in_block=1 }
    in_block && /\*\*Diff handling between rounds/ { exit }
    in_block { print }
  ' skills/using-qrspi/SKILL.md)
  echo "$protocol" | grep -qE 'verifier_enabled missing from config\.md|backfilling default'
}

@test "fresh-run config init writes verifier_enabled: true to config.md" {
  # Spec §1: "Fresh run directories start with verifier_enabled: true (set by
  # the using-qrspi run-init code at run creation)." Shape-agnostic check —
  # the run-init prose lists at least the legacy fields (codex_reviews, route)
  # and must now also include verifier_enabled: true somewhere in the same
  # SKILL.md file. The three field names appear together nowhere else in
  # using-qrspi/SKILL.md (codex_reviews / route / verifier_enabled), so a
  # whole-file presence triple is sufficient and shape-independent.
  grep -qE '^[[:space:]]*[-*][[:space:]]*`?codex_reviews`?:|codex_reviews:[[:space:]]+(true|false)' skills/using-qrspi/SKILL.md \
    || { echo "codex_reviews not present in using-qrspi/SKILL.md"; return 1; }
  grep -qE '^[[:space:]]*[-*][[:space:]]*`?route`?:|route:[[:space:]]+' skills/using-qrspi/SKILL.md \
    || { echo "route not present in using-qrspi/SKILL.md"; return 1; }
  # The new field must appear with a literal `true` default in a run-init
  # context — the simplest shape-agnostic check is "verifier_enabled: true"
  # appearing somewhere in the file (the schema doc + the run-init template
  # both contain it; if either is missing, this fails).
  grep -qE 'verifier_enabled:[[:space:]]*true' skills/using-qrspi/SKILL.md \
    || { echo "verifier_enabled: true not present in using-qrspi/SKILL.md (run-init template missing the field)"; return 1; }
  # Stronger shape: the run-init template region typically appears in a
  # fenced code block. Assert at least one ```yaml/```bash/```markdown fenced
  # block contains both `route:` and `verifier_enabled:` together — that's the
  # template-shape signal.
  awk '
    /^```/ { in_fence = !in_fence; if (!in_fence) { if (has_route && has_ve) { print "TEMPLATE_FENCE_OK"; exit }; has_route=0; has_ve=0 } }
    in_fence && /^[[:space:]]*route:/ { has_route=1 }
    in_fence && /^[[:space:]]*verifier_enabled:[[:space:]]*true/ { has_ve=1 }
  ' skills/using-qrspi/SKILL.md | grep -q '^TEMPLATE_FENCE_OK$' \
    || { echo "no fenced code block in using-qrspi/SKILL.md contains both 'route:' and 'verifier_enabled: true' (the run-init template fence)"; return 1; }
}
