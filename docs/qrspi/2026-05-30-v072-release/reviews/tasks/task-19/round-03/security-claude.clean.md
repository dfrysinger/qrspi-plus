# security-claude — Round 03 Clean

reviewer: security-claude
round: 3
task: 19
verdict: CLEAN

## Summary

No exploitable vulnerabilities found. All seven security categories were
examined against the diff (new `_host-detect.sh`, new `second-reviewer-available.sh`,
and new `_resolve-lib.sh` functions) with specific focus on shell-injection /
unquoted-expansion / fail-open risks in host and vendor handling. The vendor
override (`$1`) is the primary untrusted surface; it is fully contained.

## Key invariants verified

### 1. No shell injection via the vendor override (`$1`)
`$1` flows only through:
- simple variable assignment (`_vendor="$1"`) — no word-splitting or glob risk
- bracket `[ ]` comparisons — no command execution
- `second_reviewer_vendor_known "$_vendor"` — a `case` statement with fixed literal
  patterns; shell `case` patterns are not ERE, the subject is not expanded as a
  pattern, and injection strings such as `openai-codex;cmd` or `openai-codex\n` fall
  to the `*) return 1` arm
- `printf '…%s…' "$_host" "$_vendor"` — value passed as a `%s` argument, never in
  the format string; no format-string injection possible

No `eval`, no command substitution of `$_vendor`, no `grep`/`sed` receiving
`$_vendor` as a pattern.

### 2. Fail-closed: unknown vendor override cannot produce exit 0
`second_reviewer_vendor_known` accepts exactly `openai-codex` or `anthropic-claude`.
Any other string — including crafted values — returns 1 and the probe exits 1.
Structurally impossible for an unrecognised vendor to reach the `printf '%s\n' "$_vendor"; exit 0` path.

### 3. Fail-closed: unknown-host + valid vendor override cannot produce exit 0
Guard at `second-reviewer-available.sh` line 54 evaluates `[ "$_default_vendor" = "none" ]`
unconditionally before the vendor check. Unknown/empty host → `lookup_default_second_reviewer`
returns `none` → first `||` clause fires → exit 1. A valid vendor override (`$1`)
cannot bypass the host guard.

### 4. Silent failure does not create a fail-open
`set -e` is absent, but if `detect_host` or `lookup_default_second_reviewer`
silently fail and produce empty output, `_default_vendor` becomes `""` (not `none`).
However `lookup_default_second_reviewer ""` hits the `*` case and returns `none`,
so `_default_vendor=none` → guard fires → exit 1. Fail-closed under degraded conditions.

### 5. No ERE injection in `_resolve-lib.sh::resolve_model`
`_validate_tier` validates `$tier` against an exact five-value allowlist
(`extra-low|low|medium|high|extra-high`) **before** interpolation into
`grep -E "^[[:space:]]+${tier}:[[:space:]]"` and the corresponding `sed -E` strip.
None of the allowed tier values contain ERE metacharacters.

### 6. `_SCRIPT_DIR` path construction is safe
`$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd -P)` produces a canonical
absolute path via `pwd -P`; the result is fully quoted in dot-source commands.
`BASH_SOURCE[0]` / `$0` are set by the invoking shell, not by command-line arguments.

### 7. Environment-variable host detection is by design
`COPILOT_CLI=1` and `CLAUDE_PROJECT_DIR=<non-empty>` are the canonical host signals;
an entity that can inject these into the process environment has full execution
context in that environment already. This is within the accepted trust model for
a shell probe run by the orchestrator.
