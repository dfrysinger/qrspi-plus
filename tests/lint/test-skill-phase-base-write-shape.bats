#!/usr/bin/env bats
bats_require_minimum_version 1.5.0
#
# tests/lint/test-skill-phase-base-write-shape.bats
#
# Fix F01 (integration-round-01): pin the bare-SHA write SHAPE for
# `reviews/<phase>/phase-base.txt` in both skills/integrate/SKILL.md and
# skills/test/SKILL.md.
#
# Spec: docs/qrspi/2026-06-04-v073-release/fixes/integration-round-01/
#       fix-F01-phase-base-format.md
# Related finding: integration-claude.finding-F01.md
#
# The OBC script (scripts/orchestration-boundary-check.sh, T19) reads
# `reviews/<phase>/phase-base.txt` as a bare SHA (tr -d '[:space:]' then
# anchored against ^[0-9a-f]{7,64}$). OBC unit tests pin that contract at
# tests/unit/test-orchestration-boundary-check.bats:63-65, 230.
#
# Integration review round-01 caught the two SKILLs writing the file in
# key=value shape (`printf 'integration_base_sha=%s\n' ...`), which OBC
# rejects as `sha-format-invalid:` under `## Dispatch defects` — halting
# the Integrate and Test phases unconditionally. This lint locks the
# write-shape to bare SHA so future SKILL drift cannot reintroduce the
# format mismatch silently.
#
# Sibling lint `test-integrate-test-skill-phase-base-write.bats` (T24) pins
# that the SKILLs NAME the path; this F01 lint pins HOW they WRITE it.

setup() {
  REPO_ROOT="$(git -C "${BATS_TEST_DIRNAME}" rev-parse --show-toplevel)"
  export REPO_ROOT
  INTEGRATE_SKILL="${REPO_ROOT}/skills/integrate/SKILL.md"
  TEST_SKILL="${REPO_ROOT}/skills/test/SKILL.md"
  export INTEGRATE_SKILL TEST_SKILL
}

# Extract the printf line that writes phase-base.txt from a SKILL file.
# Strategy: find the printf-to-phase-base.txt block, where the printf and
# the redirect-to-path may sit on the same line OR on two consecutive lines
# joined by a backslash continuation.
extract_phase_base_printf_block() {
  local skill_path="$1"
  # awk: emit any line containing `printf ` AND mentioning phase-base.txt,
  # OR any printf line whose next non-blank line redirects to phase-base.txt.
  awk '
    /printf / && /phase-base\.txt/ { print; next }
    /printf / {
      buf = $0
      have = 1
      next
    }
    have && /phase-base\.txt/ {
      print buf
      print $0
      have = 0
      next
    }
    have && NF > 0 { have = 0 }
  ' "${skill_path}"
}

@test "skills/integrate/SKILL.md emits phase-base.txt as bare SHA (printf '%s\\n')" {
  [[ -r "${INTEGRATE_SKILL}" ]] || {
    echo "fixture-setup: integrate SKILL not readable at ${INTEGRATE_SKILL}" >&2
    return 1
  }

  local block
  block="$(extract_phase_base_printf_block "${INTEGRATE_SKILL}")"

  if [[ -z "${block}" ]]; then
    echo "extract failure: could not find a printf line near phase-base.txt in ${INTEGRATE_SKILL}" >&2
    return 1
  fi

  # The block must reference the phase-base.txt path target.
  if ! grep -qE 'reviews/integration/phase-base\.txt' <<<"${block}"; then
    echo "shape violation: extracted printf block does not target reviews/integration/phase-base.txt in ${INTEGRATE_SKILL}" >&2
    echo "extracted block:" >&2
    echo "${block}" >&2
    return 1
  fi

  # The printf template must be bare SHA — `printf '%s\n'`.
  if ! grep -qF "printf '%s\\n'" <<<"${block}"; then
    echo "shape violation: expected bare-SHA printf template printf '%s\\n' in ${INTEGRATE_SKILL} Phase Start write, to match the OBC bare-SHA contract (scripts/orchestration-boundary-check.sh + tests/unit/test-orchestration-boundary-check.bats)" >&2
    echo "extracted block:" >&2
    echo "${block}" >&2
    return 1
  fi

  # And must NOT carry the key=value prefix the OBC script rejects.
  if grep -qF "printf 'integration_base_sha=%s" <<<"${block}"; then
    echo "shape violation: ${INTEGRATE_SKILL} writes phase-base.txt in key=value form (printf 'integration_base_sha=%s...'), but the OBC contract requires a bare SHA — see fix-F01 spec" >&2
    echo "extracted block:" >&2
    echo "${block}" >&2
    return 1
  fi
}

@test "skills/test/SKILL.md emits phase-base.txt as bare SHA (printf '%s\\n')" {
  [[ -r "${TEST_SKILL}" ]] || {
    echo "fixture-setup: test SKILL not readable at ${TEST_SKILL}" >&2
    return 1
  }

  local block
  block="$(extract_phase_base_printf_block "${TEST_SKILL}")"

  if [[ -z "${block}" ]]; then
    echo "extract failure: could not find a printf line near phase-base.txt in ${TEST_SKILL}" >&2
    return 1
  fi

  if ! grep -qE 'reviews/test/phase-base\.txt' <<<"${block}"; then
    echo "shape violation: extracted printf block does not target reviews/test/phase-base.txt in ${TEST_SKILL}" >&2
    echo "extracted block:" >&2
    echo "${block}" >&2
    return 1
  fi

  if ! grep -qF "printf '%s\\n'" <<<"${block}"; then
    echo "shape violation: expected bare-SHA printf template printf '%s\\n' in ${TEST_SKILL} Process Step 1 write, to match the OBC bare-SHA contract (scripts/orchestration-boundary-check.sh + tests/unit/test-orchestration-boundary-check.bats)" >&2
    echo "extracted block:" >&2
    echo "${block}" >&2
    return 1
  fi

  if grep -qF "printf 'integration_base_sha=%s" <<<"${block}"; then
    echo "shape violation: ${TEST_SKILL} writes phase-base.txt in key=value form (printf 'integration_base_sha=%s...'), but the OBC contract requires a bare SHA — see fix-F01 spec" >&2
    echo "extracted block:" >&2
    echo "${block}" >&2
    return 1
  fi
}
