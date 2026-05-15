#!/usr/bin/env bats

# Structural pin for skills/implementer-protocol/SKILL.md.
#
# Asserts that the skill documents the on-disk report path contract and the
# five-line brief return surface introduced by the Subagent Contract Hardening
# slice of the v06-release.
#
# Checked invariants (one assertion per required string):
#   1. The literal disk path "reviews/tasks/task-NN/round-NN-implementer.md"
#      appears at least once in the skill file.
#   2. The literal substring "five-line brief" (case-insensitive) appears at
#      least once, confirming the contract name is present.
#   3-7. Each of the five brief-line key labels appears in the file:
#        "Status:", "Commit:", "Files:", "Tests:", "Report:"
#        One assertion per key; the failure message names the missing key.
#
# All paths are relative to the repository root. setup() resolves root by
# stepping two directories up from tests/unit/ (the standard BATS convention
# used by sibling tests in this directory).

bats_require_minimum_version 1.5.0

setup() {
  cd "$BATS_TEST_DIRNAME/../.."
  SKILL_FILE="skills/implementer-protocol/SKILL.md"
}

# ---------------------------------------------------------------------------
# Precondition: the skill file must exist.
# ---------------------------------------------------------------------------

@test "skills/implementer-protocol/SKILL.md exists on disk" {
  [ -f "$SKILL_FILE" ] \
    || { echo "MISSING FILE: $SKILL_FILE — implementer-protocol skill not found"; return 1; }
}

# ---------------------------------------------------------------------------
# 1. On-disk report path contract.
# ---------------------------------------------------------------------------

@test "SKILL.md documents the literal disk path reviews/tasks/task-NN/round-NN-implementer.md" {
  grep -qF "reviews/tasks/task-NN/round-NN-implementer.md" "$SKILL_FILE" \
    || { echo "MISSING: literal path 'reviews/tasks/task-NN/round-NN-implementer.md' not found in $SKILL_FILE"; return 1; }
}

# ---------------------------------------------------------------------------
# 2. Five-line brief contract name (case-insensitive).
# ---------------------------------------------------------------------------

@test "SKILL.md documents the contract name 'five-line brief' (case-insensitive)" {
  grep -qiF "five-line brief" "$SKILL_FILE" \
    || { echo "MISSING: substring 'five-line brief' (case-insensitive) not found in $SKILL_FILE"; return 1; }
}

# ---------------------------------------------------------------------------
# 3-7. Each of the five brief-line key labels.
#      One assertion per key so a failure names exactly which key is absent.
# ---------------------------------------------------------------------------

@test "SKILL.md documents the five-line brief key 'Status:'" {
  grep -qF "Status:" "$SKILL_FILE" \
    || { echo "MISSING KEY: 'Status:' not found in $SKILL_FILE"; return 1; }
}

@test "SKILL.md documents the five-line brief key 'Commit:'" {
  grep -qF "Commit:" "$SKILL_FILE" \
    || { echo "MISSING KEY: 'Commit:' not found in $SKILL_FILE"; return 1; }
}

@test "SKILL.md documents the five-line brief key 'Files:'" {
  grep -qF "Files:" "$SKILL_FILE" \
    || { echo "MISSING KEY: 'Files:' not found in $SKILL_FILE"; return 1; }
}

@test "SKILL.md documents the five-line brief key 'Tests:'" {
  grep -qF "Tests:" "$SKILL_FILE" \
    || { echo "MISSING KEY: 'Tests:' not found in $SKILL_FILE"; return 1; }
}

@test "SKILL.md documents the five-line brief key 'Report:'" {
  grep -qF "Report:" "$SKILL_FILE" \
    || { echo "MISSING KEY: 'Report:' not found in $SKILL_FILE"; return 1; }
}
