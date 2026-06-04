# F01 — Stale leftovers from the R8 marker-array / function-relocation refactor in `dispatch-agent.sh`

**Severity:** low (cleanliness)

**Files:**
- `scripts/dispatch-agent.sh` lines ~1026 and ~928–929

## What

The R8 fixes (commit 514a6cd) introduced the `FORBIDDEN_MARKERS` array and moved `assert_file_exists` above the batch block. Both changes left small but genuine dead artifacts behind:

### 1. `MARKER_LITERAL` is now dead code

`scripts/dispatch-agent.sh:1026`:

```bash
MARKER_LITERAL="<<<AGENT-BODY-END>>>"
FORBIDDEN_MARKERS=(
  "<<<AGENT-BODY-END>>>"
  "<<<UNTRUSTED-SCOPE-HINT-START"
  ...
)
```

After the R8 conversion, both `reject_if_contains_marker_file` and `reject_if_contains_marker_value` iterate `FORBIDDEN_MARKERS`. `MARKER_LITERAL` is set and never read anywhere else in the file (a grep across `dispatch-agent.sh` confirms only the assignment site). It is dead code that invites future readers to wonder which is canonical, and risks future drift (one variable updated, the other not) if a sixth marker is added.

**Fix:** delete the `MARKER_LITERAL=...` line. The array is the single source of truth.

### 2. Tombstone-only comment block where `assert_file_exists` used to live

`scripts/dispatch-agent.sh:928–929`:

```bash
# assert_file_exists is defined earlier in this script (above the batch block)
# so it is available in both batched-mode and single-mode code paths.

AGENT_FILE_ABS="$(resolve_path "$AGENT_FILE")"
```

This is a pure relocation tombstone. The comment doesn't orient the reader (the next line is unrelated business logic) and doesn't explain WHY — it only points at the new location, which any reader can find with grep. It adds noise to a code section a future reader will have to skim.

**Fix:** delete the two-line comment. The orientation comment that lives next to the actual function definition (above the batch block) is sufficient.

## Why it matters

Both items are individually trivial, but together they're the kind of tombstone residue that accumulates when a refactor is rushed under round pressure. They make `dispatch-agent.sh` (already a long file) slightly harder to read, and the dead `MARKER_LITERAL` could mislead a reader into adding a sixth marker only to that one variable.

Neither blocks correctness — production behavior is identical with or without these cleanups. Flagged as low-severity cleanliness so the implementer can decide whether to fold the trim into a wrap-up commit or carry it forward.

## Out of scope (per dispatch deferrals)

Not flagging:
- bats refactor / TMP_DIR tmp-dir-under-repo workaround (cq-codex R7 F01 deferred)
- `QRSPI_REPO_ROOT` override mechanism (deferred)
- T04/T09 R2 token strip (R7 closed)
- exit-code 13→1 (R7 closed)
- FORBIDDEN_MARKERS array and inline batch job-id WARN (R7 closed via R8 fixes)

Flagged here because the residue from those R8 fixes is itself a fresh artifact of round 8 and was not part of the closed R7 items.
