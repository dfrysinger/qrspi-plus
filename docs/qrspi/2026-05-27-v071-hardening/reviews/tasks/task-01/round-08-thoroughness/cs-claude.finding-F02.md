---
finding: F02
reviewer: cs-claude
round: 8
task: 1
severity: suggestion
change_type: style
file: scripts/run-third-party-llm.sh
lines: 614-619
persistence_note: orchestrator-persisted (reviewer chat-only fallback)
advisory: true
---

# F02 — Duplicated case-guard pattern in NUL pre-flight

Two adjacent `case` blocks with identical patterns AND identical die messages:
```bash
case "$_raw_file_bytes" in
  ''|*[!0-9]*) die "header-validation: failed to compute byte counts for NUL pre-flight on config.md for provider '$PROVIDER'" ;;
esac
case "$_raw_no_nul_bytes" in
  ''|*[!0-9]*) die "header-validation: failed to compute byte counts for NUL pre-flight on config.md for provider '$PROVIDER'" ;;
esac
```

Die message doesn't distinguish which count failed, so no diagnostic loss from deduplicating.

## Suggested alternative
```bash
for _nul_count in "$_raw_file_bytes" "$_raw_no_nul_bytes"; do
  case "$_nul_count" in
    ''|*[!0-9]*) die "header-validation: failed to compute byte counts for NUL pre-flight on config.md for provider '$PROVIDER'" ;;
  esac
done
unset _nul_count
```

**Disposition:** ADVISORY (cs findings are non-blocking per SKILL).
