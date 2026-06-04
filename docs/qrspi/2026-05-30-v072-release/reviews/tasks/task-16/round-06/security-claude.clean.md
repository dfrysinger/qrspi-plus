---
reviewer: security-claude
task: 16
round: 6
verdict: clean
scope: fix-5 delta (R5-F03 tier allowlist — ERE/sed injection)
---

No security findings. The R5-F03 injection fix is verified complete.

Verification against the resolver (`scripts/_resolve-lib.sh`):

(a) `_validate_tier` runs BEFORE every dynamic `$tier` interpolation. The
    only value-driven grep/sed patterns are in `resolve_model` (grep line
    140, sed line 154), both gated by `_validate_tier "$tier"` at line 125.
    In `resolve_tier` the frontmatter/config reads (lines 75-76, 89-90) use
    STATIC patterns (`^tier:`, `^default_tier:`) — the tier value is
    extracted, never interpolated as a regex — and each layer validates
    before emit (lines 67, 79, 95).

(b) No unvalidated path reaches grep/sed. agent_tier (frontmatter) and
    default_tier (config) never flow into a dynamic pattern; resolve_model's
    line-125 guard is defense-in-depth even against an unvalidated direct
    caller.

(c) Allowlist is closed and case-sensitive: line 55 `case` matches exactly
    `extra-low|low|medium|high|extra-high` (no `nocasematch`).

(d) sed-delimiter risk eliminated: `/` is not in the allowlist and is
    rejected at line 125 before the sed at line 154.

(e) Config-row VALUE does not flow into any eval/execution. `value` is
    processed only via quoted `sed`/`tr` (`_normalize_tier_value`) and
    emitted via `printf '%s\n'` (line 166). No `eval`, no command
    substitution of config-derived strings anywhere in the lib.

Out of scope per dispatch: trusted_path enforcement (dispatch-site-owned),
4 known pre-existing bats failures.
