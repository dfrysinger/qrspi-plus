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
