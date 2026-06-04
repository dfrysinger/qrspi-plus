# T10 R1 spec-gate fan-in

**Status:** SPEC-GATE FAILED → dispatching R1 fix cycle (round budget: 1 of 3 used after fix)

## Findings (3 total)

### CONVERGENT HIGH (must fix)

**R1-F01 (spec-claude + spec-codex):** `defect_class:` documented as Optional above-threshold contradicts spec "REQUIRED on every sidecar." `agents/qrspi-finding-verifier.md:96` weakens unconditional spec REQUIRED to conditional required-only-for-low-scores. Failure-sidecar template also omits the field. Internal contradiction: same sentence says "missing field is a schema violation" while also saying "Optional but permitted when score is at-or-above threshold."

**Fix:** Change step 5.5 prose to "Required on every sidecar. When the finding does not fit any meaningful defect category — including at-or-above-threshold findings — emit literal `defect_class: unspecified` rather than omitting the field." Also add `defect_class:` to the failure-sidecar template at line 114-120. Add unit test pinning failure-sidecar template carries `defect_class:`.

### Novel — Codex F02 MED (should fix)

**R1-F02 spec-codex:** Sub-Threshold Observations YAML template field-name drift. Spec says `summary`, `finding_paths[]`, `defect_class`, `score`, `threshold`. Implementation uses `observation_summary` and adds undocumented `contributing_findings` structure. Acceptance regex permissive (allows either `observation_summary` or `summary`).

**Fix:** Rename `observation_summary` → `summary` in the H2 template. Decision needed on `contributing_findings` substructure: either (a) remove it (strict spec match), or (b) document the substructure as spec-extension (defer to user). Tighten acceptance regex to assert exact spec field shape.

### Novel — Claude F02 LOW/ADVISORY (should fix)

**R1-F02 spec-claude:** Acceptance test labels G28 AC1-AC5 don't match spec AC1-AC5. Spec AC2 (chars-cap) and AC3 (unspecified fallback) live only in unit tests, not acceptance suite. Spec explicitly partitions tests between suites.

**Fix:** Add 2 acceptance tests for spec AC2 (chars-cap ≤30 near `defect_class`) and spec AC3 (`defect_class: unspecified` in verifier). Relabel G28 AC2/AC3 to match what they actually test. Tighten G28 AC1 to assert regex documentation, not just `defect_class:` token presence.

## Round 1 dispositions

- R1-F01: KEEP (CONVERGENT HIGH — fix mandatory)
- R1-F02 codex: KEEP (clarity, spec drift, simple rename)
- R1-F02 claude: KEEP (test traceability, +2 ACs, simple relabel)

Decision needed: `contributing_findings` substructure — strict spec match (remove) or document as extension (keep). Default: REMOVE for strict spec compliance.

## HEAD before fix: e616b7de
