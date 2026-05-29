---
finding_id: R4-F02
severity: low
change_type: correctness
referenced_files: [scripts/run-codex-review.sh]
artifact: task-06/scripts/run-codex-review.sh
round: 4
reviewer: sec-claude
persistence_note: orchestrator-persisted (reviewer chat-only fallback)
normalized_change_type: original was "residual", normalized to "correctness" per closed enum
---

**Location:** `scripts/run-codex-review.sh:131–136`

**Title:** sec.F02 HOME validation does not enforce absolute path; `relative/HOME` bypasses the check

```bash
case "${HOME:-}" in
  *..* | "" | *$'\n'*)
    echo "check_codex_available: unsafe HOME value — must be an absolute path without '..' components" >&2
    return 1
    ;;
esac
```

The diagnostic message reads *"must be an absolute path without '..' components"* but the pattern only rejects: `..` anywhere, empty string, newlines. It does **not** check that `HOME` starts with `/`.

A value like `HOME=relative-dir` passes all three case arms. The subsequent glob then expands to `relative-dir/.claude/plugins/cache/.../codex/*/scripts/codex-companion.mjs` — a **relative path** resolved from the process's CWD.

**Current impact:** `check_codex_available`'s return value only guards a warning message (lines 573–577) — it does not block dispatch. Practical impact is suppression of a diagnostic stderr line. No code path changes, no privilege escalation.

**Fix:** Add `if [[ "${HOME}" != /* ]]; then ... return 1; fi` after the case guard.
