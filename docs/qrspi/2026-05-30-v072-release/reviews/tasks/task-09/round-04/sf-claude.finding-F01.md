---
finding_id: R4-F01
reviewer_tag: sf-claude
round: 4
severity: medium
change_type: correctness
referenced_files: [scripts/run-codex-review.sh]
---

# sf-claude F01: Manifest file-I/O operations unchecked in set +e context

**Status of prior sf-claude/sf-codex F01 (R3 round):** CONFIRMED CLOSED. R3 jq guard at lines 619-626 is correct (full assignment guarded, `$?` propagation accurate, hard abort before write). AC12 PATH-shim test is sound.

## New finding

**Location:** scripts/run-codex-review.sh:628-640

Script runs with `set +e` (line 50). None of the four I/O ops are guarded:

| Operation | Failure mode | Silent consequence |
|---|---|---|
| `mkdir -p "$round_dir"` (628) | Permissions, quota | Subsequent writes fail silently; no manifest |
| `sed ... > "$tmp"` (635) | Read permission; sed missing | `$tmp` empty/absent; append produces fragment; mv lands corrupt file |
| `printf ... > "$tmp"` (638) | Disk-full, tmpfs quota | `$tmp` absent/partial; mv overwrites valid manifest with corruption |
| `mv "$tmp" "$manifest"` (640) | Permissions, cross-device | Function returns 0; script proceeds; no manifest update; no error raised |

## Why this matters for T09

T09's central goal is "every dispatch auditably recorded" — the manifest is the audit artifact. When mv or mkdir silently fails, dispatch proceeds, dispatcher exits 0, CI receives green, operator has no indication.

Same failure class as the R3-closed jq finding (command-sub failure under `set +e`); R3 closed jq path but file-I/O path is structurally equivalent.

## Suggested fix (defer to v0.7.3)

Apply same `||` pattern used for jq guard. See sf-codex R4-F01 for symmetric finding.

## CONVERGENT WITH sf-codex R4-F01 — both reviewers independently. Strong signal.

## Disposition (orchestrator)

R4 = 4th review pass. R3 was final fix-cycle in 3-round budget. Per QRSPI skill ("if unresolved after 3, flag and move on"), this routes to **accept-with-issues at task batch gate** and v0.7.3 backlog under "fail-loud filesystem writes in audit emission."
