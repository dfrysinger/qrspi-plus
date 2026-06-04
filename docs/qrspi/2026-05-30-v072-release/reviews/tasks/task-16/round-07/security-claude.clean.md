# Security Review — task-16, round-07 (CONVERGENCE, fix-cycle 6)

**Reviewer:** security-claude
**Artifact:** scripts/_resolve-lib.sh
**Scope:** fix-6 incremental delta only (`git diff fe25f09 HEAD`)
**Verdict:** CLEAN — no new security regression in the delta.

## Delta surfaces assessed

The fix-6 delta added: (1) an empty-value HALT in `resolve_model`, (2) a
`_halt_unconfigured_tier` helper deduplicating the two `none`/absent-row halts,
and (3) `-f`→`-r` test changes for `agent_file` / `CONFIG_MD`.

### (a) Empty-value guard + helper interpolation — SAFE
`$tier` and `$value` flow only into `printf` calls as trailing **arguments**
(`%s`), never into a grep ERE, sed expression, or `eval`. The only grep/sed
sites that interpolate `${tier}` (lines 151, 164) are unchanged from fix-5 and
remain strictly downstream of `_validate_tier "$tier"` (line 136). `$value` is
never interpolated into any pattern — it is compared and printed only.

### (b) `_halt_unconfigured_tier` printf — FORMAT-STRING SAFE
Both printf calls (lines 56–57) use literal constant format strings with `$1`
as a trailing argument. A tier value containing `%n`/`%s` cannot reach the
format-string slot. No `eval`, no command substitution of the tier value. Both
call sites (155, 181) are downstream of the line-136 allowlist, so the argument
is always one of the five legal tiers anyway.

### (c) `-f`→`-r` change — NO NEW TOCTOU / PATH SURFACE
Paths (`agent_file`, `CONFIG_MD`) are operator/dispatch-site-owned config paths,
not attacker-controlled across a trust boundary. A lost check-then-grep race or
a directory passing the more-permissive `-r` test yields an empty grep result
(stderr suppressed) that falls through to the existing safe HALT paths. No
path-traversal or privilege escalation introduced.

## Out of scope (per dispatch)
- `trusted_path:` short-circuit — dispatch-site-owned, deferred.
- 4 known pre-existing bats failures — not this task.
- fix-5 allowlist (`_validate_tier`) — unchanged; verified CLEAN round-06.
