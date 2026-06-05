---
id: F03
reviewer: code-quality-claude
round: 2
severity: low
area: DRY / maintainability
file: scripts/detect-interaction-mode.sh
line: 103
---

# Duplicated platform-discriminator logic between override branch and host-detection block

## Location

`scripts/detect-interaction-mode.sh`:

- **Override branch**, lines 103–114 — discriminates `COPILOT_CLI` / `CLAUDE_PROJECT_DIR` / else to set `_override_platform`.
- **Host-detection block**, lines 131–165 — uses the same two discriminators (`COPILOT_CLI` / `CLAUDE_PROJECT_DIR` / else) as the outer if/elif/else structure.

The inline comment at line 108 documents this as intentional:

```bash
# Mirrors the host-detection discriminators below; intentionally bounded duplication.
```

## Concern

The comment is accurate and the intent is documented. However, the duplication is a
**real maintenance trap**: when a third platform is added (new `elif` branch), both
blocks must be updated in sync. A developer who adds a new `elif` to the
host-detection block and forgets to mirror it in the override branch will produce
inconsistent PLATFORM values — the override path would silently mis-report the
platform as `unknown` on the new host.

The script is currently at exactly 2 platforms so the synchronization cost is low,
but the pattern will only get harder to maintain as platforms are added.

## Tradeoff acknowledgement

The dispatch context notes this was a deliberate choice to avoid refactoring the
control flow. The comment makes the choice visible. At 2 platforms the cost is
indeed bounded. This finding is advisory rather than blocking.

## Simple fix

Extract a `_detect_platform_token` helper function (bash functions are 3.2 portable):

```bash
# Returns the platform token string for the active host environment.
_detect_platform_token() {
  if [[ "${COPILOT_CLI:-}" == "1" ]]; then
    printf 'copilot-cli'
  elif [[ -n "${CLAUDE_PROJECT_DIR:-}" ]]; then
    printf 'claude-code'
  else
    printf 'unknown'
  fi
}
```

Override branch becomes:

```bash
_override_platform="$(_detect_platform_token)"
```

Host-detection block retains its if/elif/else structure for the full output, but the
discriminator conditions can reference the same env-var tests (they already do — the
change just removes the silent duplicate). The host-detection block doesn't
trivially reduce to a function call because it emits different fields per branch, so
only the platform-token sub-decision is extracted.

This eliminates the synchronization requirement for all future platform additions.
