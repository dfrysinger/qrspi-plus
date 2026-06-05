---
finding_id: R1-F01
reviewer_tag: spec-claude
severity: high
change_type: correctness
referenced_files:
  - agents/qrspi-finding-verifier.md#L96
---

# defect_class documented as optional above-threshold contradicts spec "REQUIRED on every sidecar"

**Task spec (DoD item 1):**
> "Field is REQUIRED on every sidecar (zero-byte / missing / unrecognized value → orchestrator-side HARD-GATE failure already covered by existing schema-validation logic)."

The spec is explicit and unconditional — the field must appear on every sidecar regardless of score.

**Implementation (`agents/qrspi-finding-verifier.md:96`):**
> "**Required when score is sub-threshold** (`clarity` < 80 or `correctness` < 70) so the data is usable for future cluster analysis. **Optional but permitted when score is at-or-above threshold** (informational only)."

This directly weakens the spec's unconditional REQUIRED to a conditional required-only-for-low-scores. The same sentence then says "A missing field is a schema violation" — internally contradictory: if omitting the field above-threshold is "permitted," calling absence a "schema violation" is incoherent.

The sidecar success-case template (L108) shows the field, and the unit test passes, but that only confirms the example contains the field — it does not enforce that the verifier *must always emit* it. The step 5.5 prose is the verifier agent's authoritative instruction and tells it to optionally skip the field above threshold.

**Impact:** Any above-threshold sidecar produced in practice may arrive at `scripts/verifier-fan-in.sh` without a `defect_class:` field. The instrumentation goal (cluster analysis) is undermined for the majority of kept findings.

**Fix:** Change the step 5.5 sentence to: "**Required on every sidecar.** When the finding does not fit any meaningful defect category — including at-or-above-threshold findings — emit literal `defect_class: unspecified` rather than omitting the field." The `unspecified` fallback already exists for exactly this case; the optionality caveat should be removed.
