---
finding_id: R3-F03
reviewer_tag: code-quality-claude
round: 3
task: 12
severity: low
change_type: clarity
referenced_files:
  - scripts/round-prepare.sh
---

# F03 — Bare `sys.argv[1]` expression statement reads as dead code / silent no-op

## Location

`scripts/round-prepare.sh:338` (inside non-git workspace Python heredoc)

## Observation

```python
python3 - "$SIDECAR_TMP" <<'PYEOF'
import json, sys
sys.argv[1]          # ← this line
out = { ... }
open(sys.argv[1], "w").write(...)
PYEOF
```

`sys.argv[1]` as a bare expression evaluates and immediately discards the value. In Python this is effectively a no-op — unless the intent is to raise `IndexError` early if the argument is absent, but that intent is undocumented and the behavior differs from how a reader would interpret a discarded expression. A future maintainer is likely to delete it as dead code (breaking the early-fail guard, if that was the intent) or leave it without understanding it.

## Suggestion

Make the intent explicit:

```python
# Fail early if SIDECAR_TMP argument is missing.
out_path = sys.argv[1]
```

Then use `out_path` in the `open()` call below.
