---
reviewer: security-claude
task: 19
round: 1
verdict: clean
---

# Security Review — Task 19, Round 1

No security findings.

## Scope examined

`scripts/_host-detect.sh`, `scripts/second-reviewer-available.sh`,
`scripts/_resolve-lib.sh` (new functions: `second_reviewer_vendor_known`,
`resolve_second_reviewer_vendor`), `skills/goals/SKILL.md`,
`skills/using-qrspi/SKILL.md`, `skills/reviewer-protocol/SKILL.md`,
`tests/unit/test-second-reviewer-available.bats`,
`tests/unit/test-dispatch-companion-availability.bats`,
`tests/unit/test-routing-matrix-application.bats`.

## Category results

### Injection (command / word-split / path-traversal / format-string)

- No `eval` anywhere in the changed files.
- Vendor override `$1` is stored in `_vendor` and consumed exclusively via
  quoted `[ "$_vendor" = "…" ]` comparisons, a case-WORD lookup (WORD is the
  matched string, not the pattern — glob characters in `$1` do not expand
  against `openai-codex|anthropic-claude`), and `printf '%s\n' "$_vendor"`.
  No injection surface.
- All `printf` diagnostics use `%s` specifiers for externally-derived strings;
  no format-string injection possible.
- `_SCRIPT_DIR` is derived via `cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd -P`
  — the canonical safe pattern. No user input flows into this path. Sourced
  files are `$_SCRIPT_DIR/_host-detect.sh` and `$_SCRIPT_DIR/_resolve-lib.sh`,
  both co-resident with the script, not user-supplied paths.

### Host-signal spoofing / privilege escalation

Any caller who can set `COPILOT_CLI=1` or any non-empty `CLAUDE_PROJECT_DIR`
can make `detect_host` return a recognised host identifier and thus make the
probe exit 0 ("second reviewer available"). The downstream impact is that the
SKILL prose asks the operator "do you want a second reviewer?" — the user still
makes an explicit `second_reviewer: true|false` choice and no dispatch is
forced. No credentials, capabilities, or trust boundaries are upgraded
automatically by a spoofed exit 0. The env-only signal design is intentional
(CD-1: no filesystem probes).

### Fail-closed audit

All failure paths audited; every unavailable path exits non-zero with zero
stdout dispatch-spec lines:

| Trigger | Exit | Stdout lines |
|---|---|---|
| Unknown host (no env signal) | 1 | 0 |
| `lookup_default_second_reviewer` → `none` | 1 | 0 |
| Unknown vendor override (`$1` not in allowlist) | 1 | 0 |
| `resolve_second_reviewer_vendor` with `none` default | 1 | 0 |
| `resolve_second_reviewer_vendor` same-vendor collision | 1 | 0 |
| Source failure (dependency unreachable) | 1 (via empty-`_host` → `none` chain) | 0 |

No fail-open path found. The SKILL prose "on a non-zero exit, write
`second_reviewer: false`" is intentional documented degradation, not a
silent-failure; the probe never exits 0 on any of the unavailable conditions
above.

### Data exposure

Diagnostic messages contain only canonical host identifiers
(`copilot-cli`, `claude-code`, `unknown`) and vendor names
(`openai-codex`, `anthropic-claude`, `none`). No credentials, file paths,
tokens, or PII flow through any code path.

### Cryptography / secrets

No cryptographic operations. No hardcoded secrets.

### Race conditions

Stateless read-only probes; no shared mutable state.

## Non-security observation (not filed as finding)

In `_resolve-lib.sh` `resolve_second_reviewer_vendor` (~line 93), when
`second_vendor = "none"` the diagnostic reads `vendor=none` (the internal
sentinel) rather than a label like `vendor=<none-configured>`. This is
cosmetically ambiguous but: the subsequent prose line "no default
second-reviewer vendor is configured for this host" is unambiguous; the
condition fails closed regardless; and the code-quality and silent-failure
reviewers have already flagged this wording. It is not a security concern.
