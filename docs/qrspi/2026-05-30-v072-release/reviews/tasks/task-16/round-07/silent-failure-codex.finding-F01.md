---
finding_id: R7-F01
reviewer_tag: silent-failure-codex
severity: medium
change_type: correctness
referenced_files: [scripts/_resolve-lib.sh]
---

# R7-F01 — `-r`-only guard lets a readable directory (non-regular path) pass the file gate

**Reviewer:** silent-failure-codex (gpt-5.3-codex), T16 round-07 correctness fan-out
**Severity:** Medium
**Change type:** correctness (regression introduced by the fix-6 `-f`→`-r` change)

## Finding

Fix-6 replaced `[ -f X ]` with `[ -r X ]` at three guard sites (L85 agent-file,
L99 resolve_tier CONFIG_MD, L142 resolve_model CONFIG_MD negated-halt). `[ -r X ]`
is true for ANY readable path, including a **directory** or other non-regular file.
When CONFIG_MD (or an agent_file) resolves to a readable directory:

- **resolve_model (L142):** the negated halt `[ ! -r dir ]` is FALSE (a dir is
  readable), so the loud "CONFIG_MD is unset or not a readable file" HALT does NOT
  fire. Control falls through to `grep ... "$CONFIG_MD" 2>/dev/null` (L151), which
  fails on a directory with stderr suppressed → empty `row` → the code mis-halts
  via `_halt_unconfigured_tier` with a **misleading "unconfigured tier"
  diagnostic**, sending an operator down the wrong repair path.
- **resolve_tier (L99):** a readable directory passes the guard, grep fails
  silently, `default_tier` is empty → control reaches the Layer-4 medium fallback
  (warn + exit 0) attributing the cause incorrectly.

This is the same fail-loud-on-malformed-config class the task exists to close
(F01): a non-regular config path should HALT loudly with a truthful diagnostic,
not be reinterpreted as an unconfigured tier or a default-tier-absent Layer-4
degrade.

## Recommended fix (additive)

Require a **regular file AND readable** at all three sites:
- L85:  `[ -n "$agent_file" ] && [ -f "$agent_file" ] && [ -r "$agent_file" ]`
- L99:  `[ -n "${CONFIG_MD:-}" ] && [ -f "${CONFIG_MD:-}" ] && [ -r "${CONFIG_MD:-}" ]`
- L142: `[ -z "${CONFIG_MD:-}" ] || [ ! -f "${CONFIG_MD:-}" ] || [ ! -r "${CONFIG_MD:-}" ]`

The existing L143 diagnostic ("CONFIG_MD is unset or not a readable file") already
covers the directory case wording. Add a regression test: CONFIG_MD pointed at a
readable directory → resolve_model HALTs (exit 1) with the "not a readable file"
diagnostic, not "unconfigured tier".

## Cross-reviewer note

sf-claude, sec-claude, sec-codex all assessed the same directory case and judged
it non-regressive (resolve_model still halts; resolve_tier falls to the documented
Layer-4 medium path). This finding is the diagnostic-accuracy / regular-file-guarantee
refinement, not a silent-success regression. Synthesis: `-f && -r` satisfies BOTH
this finding AND the round-06 truthful-diagnostic finding.
