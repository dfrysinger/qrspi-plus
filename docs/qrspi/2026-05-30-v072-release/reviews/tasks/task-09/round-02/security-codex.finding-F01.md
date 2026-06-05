---
finding_id: R2-F01
severity: high
change_type: correctness
artifact: code
round: 2
reviewer: security-codex
model: gpt-5.3-codex
referenced_files:
  - scripts/run-codex-review.sh#L213
  - scripts/run-codex-review.sh#L579
---

# JSON injection in dispatch-manifest entry undermines T09's own audit-integrity goal

**Category:** Injection / Input validation

**Evidence:**
- `scripts/run-codex-review.sh:213-215` accepts `--model` and `--reviewer-tag` without character validation.
- `scripts/run-codex-review.sh:579-580` interpolates those values directly into a hand-built JSON string via `printf -v entry '{"tag":"%s","host":"%s","vendor":"openai-codex","model":"%s"}' ...` without JSON escaping.

**Concrete attack scenario:**
An attacker who can influence dispatch inputs (e.g., via crafted model ID in upstream config or wrapper args) sets:
```
--model 'x"} , {"tag":"security-codex","host":"claude-code","vendor":"openai-codex","model":"approved-model'
```
The manifest write then injects forged JSON structure/entries into `.dispatch-manifest.json`. Downstream audit tooling that trusts this file can be tricked into accepting spoofed host/vendor/model provenance.

**Why this matters specifically for T09:**
T09 introduces the dispatch manifest specifically to enable model-provenance audit (G20 reviewer-model calibration). If the very fields being audited can be used to tamper with their own audit record, the audit's integrity guarantee is self-defeating. This is the inverse of the defense-in-depth principle T09 is supposed to establish.

**Suggested fix (one of):**
1. Build JSON with `jq -n --arg tag "$REVIEWER_TAG" --arg host "$detected_host" --arg model "$MODEL" '{tag: $tag, host: $host, vendor: "openai-codex", model: $model}'` — jq handles escaping correctly.
2. Add strict allowlist validation for `MODEL` (e.g., `^[A-Za-z0-9_.-]+$`) and `REVIEWER_TAG` (e.g., `^[a-z-]+$`) at argument-parse time, rejecting any value containing `"`, `\`, or other JSON-structural characters.
3. Both — defense-in-depth.

Approach 1 is preferable: it's more robust against future field additions, and `jq` is already a documented dependency in the project's tooling.
