---
finding_id: R1-F02
reviewer_tag: spec-claude
severity: low
change_type: clarity
referenced_files:
  - tests/acceptance/v07-phase1/test-phase1-acceptance.bats#L106-L199
---

# Acceptance test AC labels misaligned with spec AC1–AC5; spec AC2 + AC3 absent from acceptance suite

**Task spec (DoD) AC1–AC5:**
- AC1: defect_class field present + regex enforced in sidecar
- AC2: chars-cap (≤30) enforced
- AC3: unspecified fallback documented
- AC4: sub-threshold drop invariant
- AC5: optional observations H2 template documented

**What the acceptance file actually tests:**

| Test label | What it tests | Maps to spec |
|---|---|---|
| G28 AC1 | `grep -qF 'defect_class:'` in verifier (presence only, no regex) | partial spec AC1 |
| G28 AC2 | SKILL.md `MUST NOT … override` prose | spec AC4 topic |
| G28 AC3 | SKILL.md documents `## Sub-Threshold Observations` H2 with template | spec AC5 topic |
| G28 AC4 | `verifier-fan-in.sh` drops clarity-60 + correctness-65 fixtures | spec AC4 |
| G28 AC5 | YAML template in SKILL.md parses as valid YAML | spec AC5 sub-test |

Spec AC2 (chars-cap ≤30) and AC3 (unspecified fallback) appear only in `tests/unit/test-verified-file-shape.bats`. No acceptance test covers them.

Additionally, G28 AC1 is weaker than spec AC1 which requires "regex enforced in sidecar" — the acceptance test only `grep -qF 'defect_class:'` for token presence, not regex documentation.

**Impact:**
1. Acceptance suite has G28 AC2/AC3 slots occupied by AC4/AC5 content; spec AC2 and AC3 unrepresented in acceptance file.
2. Test labels do not correspond to spec AC numbers — misleading traceability.
3. Spec AC1's "regex enforced" requirement not asserted in acceptance suite.

Unit tests do provide correct coverage for chars-cap and unspecified-fallback, so no *behavioral* gap exists — but spec explicitly assigns AC2 and AC3 to the acceptance file.

**Fix:** Add two acceptance tests covering chars-cap (assert `≤30` appears near `defect_class`) and unspecified fallback (assert `defect_class: unspecified` in verifier). Relabel misaligned G28 AC2/AC3 tests to match what they test, restoring spec-AC traceability.
