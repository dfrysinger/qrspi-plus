---
finding_id: R2-F03
reviewer_tag: security-claude
round: 2
task: 12
severity: medium
change_type: correctness
referenced_files:
  - scripts/round-prepare.sh
---

## F03 — Git option injection via unguarded `BASE_REF` / `REF` in `git rev-parse` and `git diff`

**File:** `scripts/round-prepare.sh` lines 109 and 331.

```bash
# line 109
TASK_BASE_SHA="$(git -C "${WORKTREE:-.}" rev-parse "$BASE_REF" 2>/dev/null || true)"
# line 331
git diff "$REF" > "$DIFF_TMP" 2>/dev/null || true
```

Neither call inserts a `--` sentinel. A value starting with `-` is interpreted as a flag.

**Attack — info disclosure:** `--base-ref "--show-toplevel"` causes `git rev-parse` to emit the repo root path; captured into `TASK_BASE_SHA`, propagates into PRIOR comparisons.

**Attack — arbitrary output path:** `--base-ref "--output=/etc/cron.d/backdoor"` makes `git diff` write the diff to attacker-controlled path, bypassing the atomic temp-file write.

**Fix:**
- Line 109: `git -C "${WORKTREE:-.}" rev-parse -- "$BASE_REF"`
- Line 331: allowlist-validate `REF` against `^[0-9a-zA-Z._/^~:-]+$` (git diff does NOT accept `--` before commit refs).
