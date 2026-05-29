---
reviewer: silent-failure-codex
task: 1
round: 2
finding: F01
severity: high
change_type: correctness
status: pending
model: gpt-5.3-codex
timestamp: 2026-05-28T18:55:00Z
agent_id: t01-r2-sf-codex
persistence_note: OpenAI-family transport returns chat-only; manually persisted by orchestrator. See GH issue #216.
referenced_files:
  - scripts/run-third-party-llm.sh
---

## NUL pre-flight can silently skip on count-evaluation errors

**Location:** `scripts/run-third-party-llm.sh:598-601`

**Issue type:** Missing error path / silent failure / fail-open

**Why it's silent:** `_raw_file_bytes` and `_raw_no_nul_bytes` are computed via pipelines (`wc -c < "$CONFIG_FILE"` and `tr -d '\000' < "$CONFIG_FILE" | wc -c`), but the pipeline exit status is never validated. If either value ends up empty or non-numeric (e.g. unexpected pipe failure, file race, fs error), the numeric test:

```bash
[ "$_raw_file_bytes" -ne "$_raw_no_nul_bytes" ]
```

returns exit 2 ("invalid integer expression"). Bash treats that as falsey for `if`-condition purposes, AND `set -e` is suppressed inside `if` conditionals by design. Result: the NUL pre-flight is bypassed and the script proceeds as if no NULs were present.

**Impact:** Header NUL pre-flight can be bypassed under command-failure conditions, with only a shell diagnostic on stderr and no explicit hard failure path. Fails open against an injection-class control byte. Low-probability trigger (pipelines on a local file rarely fail) but high-severity outcome (defeats the entire NUL detection branch).

**Suggested fix patterns (orchestrator notes for apply-fix):**

1. **Explicit empty-check before comparison:**
   ```bash
   if [[ -z "$_raw_file_bytes" || -z "$_raw_no_nul_bytes" || ! "$_raw_file_bytes" =~ ^[0-9]+$ || ! "$_raw_no_nul_bytes" =~ ^[0-9]+$ ]]; then
     die "header-validation: failed to compute byte counts for NUL pre-flight on config.md"
   fi
   ```

2. **`set -o pipefail` for the file** (broader blast radius — may surface other pipe-failure issues elsewhere).

3. **Switch to `wc -c "$CONFIG_FILE" | awk '{print $1}'`** (single command, no pipeline) and check command exit status.

Recommend (1): smallest blast radius, explicit fail-loud diagnostic, no side effects on other code paths.
