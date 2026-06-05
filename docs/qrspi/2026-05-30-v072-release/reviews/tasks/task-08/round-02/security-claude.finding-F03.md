---
finding_id: R2-F03
severity: low
change_type: clarity
artifact: code
round: 2
reviewer: security-claude
model: claude-sonnet-4.6
referenced_files:
  - tests/acceptance/v07-phase1/test-phase1-acceptance.bats#L1086-L1087
---

# `printf` format-string latent risk in `_t8_write_finding_pair`

**Problem:** Current call is safe (`$body` is a `%s` argument, not in the format-string position). Latent risk: if the helper is ever refactored to interpolate `body` into the format string rather than as an argument, `%s`/`%d`/`%n` in `body` text would consume or corrupt subsequent printf arguments, producing silently wrong fixture YAML.

**Currently all TC4–TC8 body strings are safe** (no `%` characters). This is a low-severity latent risk, not an immediate exploit.

**Fix (advisory):** Add a brief comment near the printf call noting that `$body` must remain in argument position, never in the format string.
