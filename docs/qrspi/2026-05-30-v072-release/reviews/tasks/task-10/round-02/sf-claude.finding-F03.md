---
finding_id: R2-F03
reviewer_tag: sf-claude
severity: low
change_type: correctness
referenced_files:
  - agents/qrspi-finding-verifier.md#L96,L119
---

# `unspecified` unconditionally valid for failure sidecars collapses crash-type cluster signal

**L119 (failure-sidecar template):** `defect_class: <kebab-case tag …; literal 'unspecified' is also valid when failure produced no defect signal>`

**L96 (required-on-every-sidecar prose):** "failure sidecars whose evaluation never produced a defect signal — emit literal `defect_class: unspecified` rather than omitting the field"

**Silent failure:** "failure produced no defect signal" is true for every verifier crash — crashed evaluator, tool time-out, file-read error, rate-limit failure. Protocol permits `defect_class: unspecified` for all failure sidecars, making `verifier-crash` and `infrastructure-failure` advisory examples agents can safely ignore.

Future cluster-analysis tooling sees:

| verifier_status | defect_class  | What it could mean |
|---|---|---|
| `failed` | `unspecified` | "crash before step 2" |
| `failed` | `unspecified` | "evaluated but no classifiable defect" |
| `failed` | `unspecified` | "rate-limited mid-evaluation" |

All three produce identical structured records. Only `failure_reason` prose distinguishes; not machine-parseable for clustering without NLP. Cluster analysis silently biases any "what fraction of failures are infra vs evaluation" query.

**Fix:** Tighten failure-sidecar template guidance: `unspecified` should be reserved for cases where evaluator reached a verdict but found no classifiable defect class. For failure sidecars, require best-effort classification from `verifier-crash`, `infrastructure-failure`, `tool-error`, or similar; `unspecified` should only be valid on failure path when verifier genuinely cannot determine even the failure category.
