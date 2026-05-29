---
finding_id: R6-F02
severity: low
change_type: correctness
referenced_files: [scripts/run-codex-review.sh]
artifact: task-06/scripts/run-codex-review.sh
round: 6
reviewer: sec-claude
persistence_note: orchestrator-persisted (reviewer chat-only fallback)
subsumed_by: R6-F01 (realpath fix resolves this too)
---

**Title:** Symlink Bypass via Trusted Prefix

**Location:** Same `detect_host` prefix check.

`command -v` does NOT follow symlinks when returning a path. If `/opt/homebrew/bin/gh` is a symlink to `/tmp/attacker/gh`, `command -v gh` returns the symlink path which matches `/opt/*`.

**Attack (local user with Homebrew on Apple Silicon):**
```bash
# /opt/homebrew/bin is user-writable by design
ln -sf /tmp/evil/gh /opt/homebrew/bin/gh
COPILOT_CLI=1 PATH=/opt/homebrew/bin:/usr/bin:/bin detect_host
# command -v gh  →  "/opt/homebrew/bin/gh"
# [[ "/opt/homebrew/bin/gh" == /opt/* ]]  →  TRUE → "copilot-cli" forged
```

**Mitigation:** Subsumed by F01's `realpath` fix — symlinks resolve to actual target which fails prefix check. No separate fix needed; track that adding realpath to F01 closes both.
