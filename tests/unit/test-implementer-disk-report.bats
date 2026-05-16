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
  cd "$BATS_TEST_DIRNAME/../.." || return 1
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
#
#      Greps are scoped to the code-block template in SKILL.md rather than
#      the full file. "Status:", "Commit:", "Files:", "Tests:", and "Report:"
#      are common English words that appear throughout the file in unrelated
#      prose; an unanchored full-file grep would pass vacuously even if the
#      actual five-line brief template were removed.
#
#      Extraction strategy: awk scans for the "five-line brief only" sentinel
#      line (which immediately precedes the template code block), then captures
#      lines inside the next fenced code block (``` ... ```). The result is
#      written to ${BATS_TEST_TMPDIR}/brief_section.txt and each key-label
#      assertion greps against that scoped region.
# ---------------------------------------------------------------------------

# Helper: extract the five-line brief template block from SKILL.md.
# Called once per test; BATS_TEST_TMPDIR is per-test isolated scratch space.
#
# Awk rules (no dead code):
#   1. Set found=1 on the sentinel line and skip it.
#   2. Once found, treat the first ``` as the opening fence (set in_block=1);
#      treat the second ``` as the closing fence and `exit` immediately. This
#      bounds extraction to exactly the one code block following the sentinel,
#      preventing later code blocks in SKILL.md (which is "designed to grow")
#      from leaking key labels into a vacuous-pass.
#   3. Otherwise, print body lines while inside the block.
#
# Empty-extract guard: if the sentinel is missing (e.g., SKILL.md is
# restructured and the phrase drifts), the awk produces an empty file. The
# guard emits an actionable diagnostic naming the missing sentinel rather
# than letting the five key-label tests fail with misleading MISSING KEY
# messages.
_extract_brief_section() {
  awk '/five-line brief only/ { found = 1; next }
       found && /^```/ { if (in_block) exit; in_block = 1; next }
       found && in_block { print }' \
    "$SKILL_FILE" > "${BATS_TEST_TMPDIR}/brief_section.txt"
  if [ ! -s "${BATS_TEST_TMPDIR}/brief_section.txt" ]; then
    echo "EXTRACTION ERROR: sentinel 'five-line brief only' not found in SKILL.md" >&2
    return 1
  fi
}

@test "SKILL.md documents the five-line brief key 'Status:' in the template block" {
  _extract_brief_section
  grep -qF "Status:" "${BATS_TEST_TMPDIR}/brief_section.txt" \
    || { echo "MISSING KEY: 'Status:' not found in the five-line brief template block of $SKILL_FILE"; return 1; }
}

@test "SKILL.md documents the five-line brief key 'Commit:' in the template block" {
  _extract_brief_section
  grep -qF "Commit:" "${BATS_TEST_TMPDIR}/brief_section.txt" \
    || { echo "MISSING KEY: 'Commit:' not found in the five-line brief template block of $SKILL_FILE"; return 1; }
}

@test "SKILL.md documents the five-line brief key 'Files:' in the template block" {
  _extract_brief_section
  grep -qF "Files:" "${BATS_TEST_TMPDIR}/brief_section.txt" \
    || { echo "MISSING KEY: 'Files:' not found in the five-line brief template block of $SKILL_FILE"; return 1; }
}

@test "SKILL.md documents the five-line brief key 'Tests:' in the template block" {
  _extract_brief_section
  grep -qF "Tests:" "${BATS_TEST_TMPDIR}/brief_section.txt" \
    || { echo "MISSING KEY: 'Tests:' not found in the five-line brief template block of $SKILL_FILE"; return 1; }
}

@test "SKILL.md documents the five-line brief key 'Report:' in the template block" {
  _extract_brief_section
  grep -qF "Report:" "${BATS_TEST_TMPDIR}/brief_section.txt" \
    || { echo "MISSING KEY: 'Report:' not found in the five-line brief template block of $SKILL_FILE"; return 1; }
}
