---
finding_id: R6-F01
severity: medium
change_type: correctness
referenced_files: [scripts/run-codex-review.sh]
artifact: task-06/scripts/run-codex-review.sh
round: 6
reviewer: sec-claude
persistence_note: orchestrator-persisted (reviewer chat-only fallback, second occurrence in this task)
---

**Title:** Path Normalization Bypass in `detect_host` Prefix Check — NEW REGRESSION from R5

**Location:** `scripts/run-codex-review.sh` — `detect_host` function, R5 diff lines 27–30

```bash
_gh_path="$(command -v gh 2>/dev/null)"
if [[ "${COPILOT_CLI:-}" == "1" ]] && \
   [[ -n "$_gh_path" ]] && \
   [[ "$_gh_path" == /usr/* || "$_gh_path" == /opt/* || "$_gh_path" == /Applications/* ]]; then
```

**Root cause:** `command -v` resolves PATH entries **without normalizing `..` segments** — it returns the constructed path (`$PATH_ENTRY/$cmd`), not the real path. The bash `[[ ]]` glob match `"$_gh_path" == /usr/*` is a string prefix test; it does not normalize dots.

**Attack:**
```bash
mkdir -p /tmp/fakebins
printf '#!/bin/sh\nexit 0\n' > /tmp/fakebins/gh; chmod +x /tmp/fakebins/gh

COPILOT_CLI=1 PATH=/usr/../tmp/fakebins:/usr/bin:/bin detect_host
# command -v gh  →  "/usr/../tmp/fakebins/gh"
# [[ "/usr/../tmp/fakebins/gh" == /usr/* ]]  →  TRUE
# emits "copilot-cli" ← forged
```

Same bypass with `/opt/../tmp/...`, `/Applications/../tmp/...`.

**Why R5 partially worked:** Straight `PATH=/tmp/fakebins:...` is correctly rejected (returns `/tmp/fakebins/gh`, no whitelist match). The `..`-normalization vector is the regression.

**Required fix:** Normalize via `realpath` (or `readlink -f`) before prefix check:
```bash
_gh_path="$(command -v gh 2>/dev/null)"
if [[ -n "$_gh_path" ]]; then
  _gh_path="$(realpath "$_gh_path" 2>/dev/null || printf '%s' "$_gh_path")"
fi
```

`realpath` resolves both symlinks and `..` segments, so `/usr/../tmp/fakebins/gh` → `/tmp/fakebins/gh` → fails all prefix checks correctly.

**Missing test:** add a bats case using `PATH=/usr/../tmp/fakebins:/usr/bin:/bin` with COPILOT_CLI=1; assert `detect_host` returns `claude-code`.
