---
finding_id: R4-F02
reviewer_tag: silent-failure-claude
round: 4
task: 12
severity: low
change_type: correctness
referenced_files:
  - scripts/round-prepare.sh
---

# F02 — KEPT pre-existing: non-git workspace sidecar path uses bare `mv` without error check

## Location

`scripts/round-prepare.sh`, non-git workspace branch, ~ line 350:

```bash
python3 - "$SIDECAR_TMP" <<'PYEOF'
...
PYEOF
mv "$SIDECAR_TMP" "$SIDECAR"          # ← bare mv; no `if !` guard
echo "round-prepare: non-git workspace; no diff produced." >&2
exit 2
```

## What goes wrong

If `python3` fails (disk full, write-permission denied on `OUTPUT_DIR`, unexpected exception), `SIDECAR_TMP` is never created (or is partially written). `mv "$SIDECAR_TMP" "$SIDECAR"` then fails — but since `set -e` is not active (`set -u` only), bash continues to the `echo` line and `exit 2`.

The caller receives:
- Exit code `2` — documented meaning: "non-git workspace; sidecar written without diff/scope_hint"
- `echo` line: "round-prepare: non-git workspace; no diff produced." — which echoes even on failure, making it appear normal
- No `.round-prepare.json` on disk (or a zero-byte partial file)

Any downstream consumer that reads `.round-prepare.json` to get `diff_file`/`scope_hint` silently gets a FileNotFoundError (or JSON parse error). The round appears to have completed when the sidecar was never written.

## Context — pre-existing, not introduced by R3

The main sidecar path (lines ~406–410) already uses the correct guarded pattern that was added in a prior round:

```bash
if ! mv "$SIDECAR_TMP" "$SIDECAR"; then
  rm -f "$SIDECAR_TMP"
  echo "round-prepare: failed to write $SIDECAR" >&2
  exit 1
fi
```

R3 applied the `makedirs` exception-surface fix but did not extend the guarded-`mv` pattern to the non-git branch. Since this is the final review pass for the task, flagging for closure as accepted-with-issues.

## Severity rationale

Low: only triggers on disk/permission failure in the non-git branch, which is itself rare in normal QRSPI operation (the artifact directory is typically inside a git tree). The `echo` masquerade makes it harder to detect than a loud failure. The main-path already has the correct pattern, so the fix is a one-line change.

## Suggested remediation (informational — budget exhausted, accepted-with-issues)

Replace the bare `mv` with the same guarded pattern already used on the main path:

```bash
if ! mv "$SIDECAR_TMP" "$SIDECAR"; then
  rm -f "$SIDECAR_TMP"
  echo "round-prepare: failed to write non-git sidecar at $SIDECAR (disk full / permissions?)" >&2
  exit 1
fi
```
