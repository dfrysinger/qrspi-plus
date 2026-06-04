---
finding_id: R2-F04
reviewer_tag: sf-claude
severity: medium
change_type: correctness
referenced_files:
  - agents/qrspi-finding-verifier.md
  - tests/unit/test-verified-file-shape.bats#L194-L203
---

# Verifier procedure has no on-error branch: early-step failure leaves no sidecar written

**Procedure (steps 1–7) is purely sequential** with no explicit error-handling instruction:

> 1. Read finding_file_path
> 2. Read artifact_path + diff_file_path
> 3. For each referenced_files entry, Read it
> 3.5. Cite Check
> 4. If any upstream_paths cited, Read it
> 5. Score
> 5.5. Defect-class tag
> 6. Write sidecar_path
> 7. Return telemetry

Failure-sidecar template at L114–L122 describes shape to write on "unable to evaluate", but **no step says** "on error from steps 1–5, fall through to step 6 with `verifier_status: failed`."

**What happens when verifier crashes before step 6:**
- Step 2 fails (artifact file missing/unreadable) → agent likely returns error, stops. No sidecar.
- Step 3.5 triggers tool error mid-read → agent may halt. No sidecar.
- Rate-limit during step 3 → agent retries or stops. No sidecar.

When no sidecar is written, `scripts/verifier-fan-in.sh` falls back to **keep-all** (per SKILL.md L984: "sidecar absent … → favor surfacing"). The finding is kept, routing continues. Silent failure: crash event produces no `defect_class: verifier-crash` record, failure rates are silently underreported in any future sidecar-based observability query.

**Test (L194–L203) only checks documentation:** verifies template *documents* `defect_class:`. Cannot verify that LLM verifier *writes* failure sidecar when step 2 or 3 crashes. Test passes even when agent never reaches step 6.

**Fix:** Add explicit on-error instruction before step 1:

> **On any unrecoverable error at steps 1–5** (tool failure, file missing, rate-limit, parse error): stop the normal path and go directly to step 6 using the "On failure" sidecar template, populating `defect_class:` with the best-fit failure class (e.g. `tool-error`, `file-missing`, `verifier-crash`) and `failure_reason:` with a one-sentence diagnosis. Never return without writing a sidecar.
