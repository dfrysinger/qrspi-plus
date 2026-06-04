---
finding_id: R2-F01
severity: high
change_type: correctness
artifact: code
round: 2
reviewer: security-claude
model: claude-sonnet-4.6
referenced_files:
  - scripts/run-codex-review.sh#L213
  - scripts/run-codex-review.sh#L579
---

# JSON injection in `.dispatch-manifest.json` via unvalidated `--reviewer-tag` / `--model`

**Convergent with security-codex F01.**

**Location:** `scripts/run-codex-review.sh:579-580` (R1 diff hunk, `emit_dispatch_manifest_entry`):

```bash
printf -v entry '{"tag":"%s","host":"%s","vendor":"openai-codex","model":"%s"}' \
  "$REVIEWER_TAG" "$detected_host" "$MODEL"
```

The R1 fix retained `$REVIEWER_TAG` and `$MODEL` as bare `%s` interpolations inside a hand-built JSON string. Neither variable is sanitised or format-validated. The comment at line 565 asserts "values are controlled (no embedded quotes from untrusted input)" — but this is a documentation claim, not an enforced invariant. The sibling `--companion NAME` (line 232) and `--field NAME` (line 252) arguments ARE gated by `^[A-Za-z_][A-Za-z0-9_]*$` pattern checks; `--reviewer-tag` and `--model` are not.

**Concrete attack:**
```bash
bash scripts/run-codex-review.sh \
  --reviewer-tag 'evil","host":"attacker-host' \
  --model 'gpt-4' \
  ...
```
produces:
```json
{"tag":"evil","host":"attacker-host","host":"claude-code","vendor":"openai-codex","model":"gpt-4"}
```

Effects: (a) duplicate-key shadowing makes host field parser-dependent; (b) crafted `--model` allows audit-trail forgery, defeating the model-provenance audit T09 was specifically designed to establish.

**Fix:** Add format-validation guards for `--reviewer-tag` and `--model` consistent with the existing `--companion NAME` pattern. Suggested patterns:
- `--reviewer-tag`: `^[a-z][a-z0-9_-]*$`
- `--model`: `^[A-Za-z0-9][A-Za-z0-9._-]*$`

Reject on mismatch with a clear diagnostic. Alternatively (preferred), build JSON via `jq -n --arg tag "$REVIEWER_TAG" --arg host "$detected_host" --arg model "$MODEL" '{tag:$tag, host:$host, vendor:"openai-codex", model:$model}'` — jq handles escaping correctly and is robust against future field additions.

**Note on simulate helper:** `_t9_simulate_verifier_sidecar_write` was specifically reviewed for injection risk per scope hint. The awk-extracted `actual_model` flows into `printf '...%s...' "$actual_model"` which bash treats verbatim (no format-specifier interpretation in `%s` arguments). Command substitution strips newlines; awk reads single YAML line. **Simulate-helper surface is clean.**
