---
finding_id: R4-F02
severity: low
change_type: correctness
referenced_files: [scripts/run-codex-review.sh]
artifact: task-06/scripts/run-codex-review.sh
round: 4
reviewer: sf-claude
persistence_note: orchestrator-persisted (reviewer chat-only fallback)
normalized_change_type: original was "introduced-by-fix", normalized to "correctness" per closed enum
---

**Title:** sec.F03 normalization coerces unexpected codex_reviews values to "false" without any diagnostic

**Location:** `scripts/run-codex-review.sh:566-569`

```bash
case "$_codex_reviews" in
  true|false) ;;
  *) _codex_reviews="false" ;;   # ← silent coercion, no stderr diagnostic
esac
```

The security intent is correct: never echo an untrusted raw value. However the `*)` branch resets `_codex_reviews` to `"false"` with **no operator warning**.

A legitimate misconfiguration — `codex_reviews: True`, `codex_reviews: yes`, `codex_reviews: 1` — is silently treated as "Codex not configured." The mismatch diagnostic at lines 573–576 then does not fire (checks `== "true"` which never matches), so the operator receives **no signal** that their configuration was discarded.

**Confusion surface:** An operator who writes `codex_reviews: True` (YAML-style boolean) sees Codex reviews silently disabled. No log line, no warning, no mismatch message.

**Fix:** Emit a no-value diagnostic before coercing, avoiding injection of raw string:
```bash
case "$_codex_reviews" in
  true|false) ;;
  *)
    echo "warning: codex_reviews field in config.md has an unrecognised value; treating as 'false'" >&2
    _codex_reviews="false"
    ;;
esac
```
