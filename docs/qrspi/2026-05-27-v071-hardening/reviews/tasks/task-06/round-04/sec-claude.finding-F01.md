---
finding_id: R4-F01
severity: low
change_type: correctness
referenced_files: [scripts/run-codex-review.sh]
artifact: task-06/scripts/run-codex-review.sh
round: 4
reviewer: sec-claude
persistence_note: orchestrator-persisted (reviewer chat-only fallback)
normalized_change_type: original was "residual", normalized to "correctness" per closed enum
---

**Location:** `scripts/run-codex-review.sh:108`

**Title:** `command -v gh` trusts attacker-controlled PATH; sec.F01 fix is bypassable via PATH injection

```bash
detect_host() {
  if [[ "${COPILOT_CLI:-}" == "1" ]] && command -v gh >/dev/null 2>&1; then
    echo "copilot-cli"
```

`command -v gh` is the bash built-in `command` with `-v` — it performs a PATH-table lookup, not a hard-coded binary check. An attacker who can set `COPILOT_CLI=1` can equally set `PATH=/attacker/bin:$PATH` and place an executable named `gh` there (`exit 0`). Both conditions then evaluate true and `detect_host` emits `copilot-cli` regardless of whether the real GitHub CLI exists.

**Attack scenario:**
```bash
export COPILOT_CLI=1
mkdir -p /tmp/fakebins && printf '#!/bin/sh\nexit 0\n' > /tmp/fakebins/gh && chmod +x /tmp/fakebins/gh
export PATH=/tmp/fakebins:$PATH
# detect_host now emits "copilot-cli" unconditionally
```

**Current impact:** At 2a24254 both dispatch branches (lines 585–592) are identical — only the stderr marker differs. So today this is a misleading-log issue, not an exploitable privilege gap. Latent forward risk if branches ever diverge.

**Fix:** Use absolute path or validate `command -v gh` result is under `/usr` or `/opt`.
