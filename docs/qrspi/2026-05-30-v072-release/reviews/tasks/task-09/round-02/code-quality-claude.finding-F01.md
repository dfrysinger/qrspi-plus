---
finding_id: F01
severity: low
change_type: style
referenced_files:
  - scripts/run-codex-review.sh
  - tests/acceptance/v07-phase1/test-phase1-acceptance.bats
actual_model: claude-opus-4-5
---

## ID Hygiene: QRSPI-internal task IDs in code comments and runtime error strings

The R1 diff introduces multiple QRSPI-internal IDs — `T09`, `T11`, `G3` — into two
prohibited surfaces: **code comments** and **runtime string literals** (test assertion
failure messages). Per the ID-hygiene rule, G/R/D/T/Q-prefixed numeric tokens are
forbidden in code comments, test section headings, and runtime strings regardless of
how scoped or explanatory the context is.

### Code comments in `scripts/run-codex-review.sh`

Lines 569–577 (the new comment block in `emit_dispatch_manifest_entry`):

```bash
  # T09 scope: record ONLY host/vendor/model — the resolved
  # ...
  # The downstream G3 task (T11) owns the wider provenance schema —
  # ...
  # and is explicitly out-of-scope per task-09.md line 32.
```

`T09`, `G3`, `T11` are all QRSPI task-tracking IDs embedded directly in a code comment.

### Code comments and runtime strings in `tests/acceptance/v07-phase1/test-phase1-acceptance.bats`

Multiple locations in the new diff section (around lines 1445–1488 and 1581–1594):

**Comments:**
```bash
  # host / vendor / model fields all present (T09 in-scope provenance triple)
  # ---- T09-scope narrowing -------------------------------------------
  # T09 owns ONLY host/vendor/model in the dispatch manifest entry. The
  # downstream G3 task owns subagent_type / agent / mode / status ...
  # T11/G3-scoped fields into the manifest before T11 lands.
  # T09 spec line 43 / DoD: keep behavior unchanged ...
```

**Runtime error strings (strict surface — all are `echo` arguments that become test
failure output visible to operators):**
```bash
  echo "manifest leaked T11/G3-scoped 'subagent_type' field — out of T09 scope"
  echo "manifest leaked T11/G3-scoped nested 'dispatch_spec' object — out of T09 scope"
  echo "manifest carries non-T09 'agent' field"
  echo "manifest carries non-T09 'mode' field"
  echo "manifest carries non-T09 'status' field"
  echo "verifier agent body references 'verified.md' — aggregate-header output target leaked into T09 scope"
  echo "verifier-fan-in.sh references 'verified.md' — aggregate-header output target leaked into T09 scope"
```

`T09`, `T11`, and `G3` all match `\b[GRDFTQ]-?[0-9]+[A-Za-z]?\b`. The runtime
strings are particularly load-bearing: when one of these assertions fails in CI, the
QRSPI-internal IDs become part of the operator-visible error output.

### Why this matters

The IDs in the script comment explain *why* certain fields were removed — that's a
legitimate WHY comment. But the comment text can convey the same rationale without
embedding run-specific tracking tokens:

```bash
  # T09 scope: record ONLY host/vendor/model
  →  # Scope-limited: record ONLY host/vendor/model
  
  # The downstream G3 task (T11) owns the wider provenance schema
  →  # The provenance-rename task owns the wider schema (see task-09.md line 32)
```

Similarly the test error strings can label what leaked without naming the owning task:
```bash
  echo "manifest leaked T11/G3-scoped 'subagent_type' field — out of T09 scope"
  →  echo "manifest contains 'subagent_type' — field is out of T09 scope (owned by the G3 provenance task)"
```

Wait — that still embeds the IDs. The fix is to drop the tracking tokens entirely and
rely on the prose to be self-explanatory:

```bash
  echo "manifest leaked scope-narrowed 'subagent_type' field; see task-09 Out-of-scope section"
```

No action is needed for the `task-09.md` file-path reference (`out-of-scope per
task-09.md line 32`) — a file path is not a QRSPI numeric token.
