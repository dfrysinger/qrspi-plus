---
reviewer: spec-claude
task: 1
round: 1
status: clean
model: claude-sonnet-4-5
timestamp: 2026-05-28T18:45:00Z
agent_id: t01-r1-spec-claude
---

# Spec review: CLEAN

All 12 normative test-expectation bullets from `tasks/task-01.md` are implemented
and verified. No scope violations, no extra features, no misinterpretations found.

## Verification summary

### Production code (`scripts/run-third-party-llm.sh`)

- `_control_char_check` helper added (diff lines 26-39). Uses
  `LC_ALL=C tr -d '\040-\176'` to delete all printable-ASCII bytes
  (space through tilde, octal \040-\176); DEL (\177) and all C0 bytes
  (0x00-0x1F) are outside that range and survive. `wc -c` counts the
  surviving bytes in the pipeline before command-substitution trailing-newline
  stripping can affect the result. Non-zero count calls `die` with the
  existing message format naming provider and header. No `grep -P` used.
- NUL raw-byte pre-flight added (diff lines 49-57): compares `wc -c` of
  raw `config.md` to `wc -c` after `tr -d '\000'`; any delta means NUL
  is present and triggers `die` before awk parsing (NUL is stripped by
  bash variable assignment so it cannot reach `HEADER_NAMES`/`HEADER_VALUES`
  through the normal path).
- Old `grep -qP '[\x00-\x1f\x7f]' 2>/dev/null` loop removed entirely
  (diff lines 67-73). Replaced with `_control_char_check "$_hname" "$_hval"`
  call per header.

### Tests (`tests/unit/test-run-third-party-llm.bats`)

All 12 test-expectation bullets from `tasks/task-01.md` have corresponding tests:

| Bullet | Coverage | Test name |
|--------|----------|-----------|
| 1 - C0 in VALUE | SOH, VT, ESC, US (representative; tr-range has no per-byte branch) | 4 tests |
| 2 - C0 in NAME | SOH, CR | 2 tests |
| 3 - DEL in VALUE | printf '\177' in value | 1 test |
| 4 - DEL in NAME | printf '\177' in name | 1 test |
| 5 - LF regression guard | function-extraction harness; wc-c-pipeline approach | 1 test |
| 6 - NUL causes exit not skip | raw NUL written to config.md; pre-flight catches it | 1 test |
| 7 - empty name/value no false positive | direct call with '' '' | 1 test |
| 8 - printable ASCII no false positive | direct call with safe printable string | 1 test |
| 9 - CR injection in VALUE | printf '\015' embedded in value | 1 test |
| 10 - CR injection in NAME | printf '\015' embedded in name | 1 test |
| 11 - no grep -P structural assertion | grep on extracted function body | 1 test |
| 12 - die message names provider + header | checks ctrl-test-prov and X-Named-Header | 1 test |

### On the spec-codex F01 finding ("pins each of the 33 control bytes")

The description prose says "pins each of the 33 control bytes as a die-path
trigger" but this phrase is NOT in the 12 normative test-expectation bullets.
The bullets state "every C0 control byte... causes the script to exit" as a
PROPERTY claim, not as an enumeration of 32 separate test cases. Because the
implementation uses a tr-range approach with no per-byte branching, the
universal property is verifiably established by representative sampling
(4 C0 values for value-side, 2 for name-side). All 12 normative bullets ARE
covered. I assess the implementation CLEAN on this point.

### Target files

Only the two files listed in the spec's Target files were modified:
`scripts/run-third-party-llm.sh` and
`tests/unit/test-run-third-party-llm.bats`. No auxiliary files added.

### TDD

Done report states GREEN phase with prewritten_red_tests signal. Test comments
mark the RED state: "RED: function is absent from current source (not yet
implemented)." Evidence is consistent with test-first dispatch.
