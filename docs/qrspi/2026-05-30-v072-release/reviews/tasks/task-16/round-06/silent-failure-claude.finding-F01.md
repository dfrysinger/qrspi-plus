---
finding_id: R6-F01
severity: medium
change_type: correctness
referenced_files: [scripts/_resolve-lib.sh]
---
`resolve_model` silently emits an EMPTY value with exit 0 when a tier row's value
normalizes to the empty string — a residual silent-success path in a fail-loud
hardening task.

scripts/_resolve-lib.sh:140-167. The row grep `^[[:space:]]+${tier}:[[:space:]]`
(line 140) matches any row that has at least one whitespace char after the
`${tier}:` key, so a whitespace-only value matches and `row` is non-empty,
bypassing the unconfigured-tier HALT at lines 143-147. The sed at line 154
(`s/^[[:space:]]+${tier}:[[:space:]]+//`) then strips the key AND all trailing
whitespace, leaving `value=""`; `_normalize_tier_value ""` returns `""` (line 155).
The none-check at line 159 (`[ "$value" = "none" ]`) is false for the empty
string, so control falls through to the success emit at lines 166-167:
`printf '%s\n' "$value"; return 0` — emitting a BLANK line and exit 0.

Reproduce: a malformed/half-migrated row such as `  medium:   ` (key with
trailing whitespace and no value) or a comment-spaced blank row yields
`resolve_model medium` → stdout empty, exit 0. The caller parsing `{ vendor:,
model: }` out of an empty string receives a "success" with no vendor/model and
has no signal that the config row was blank. This is exactly the silent-failure
class (Category 2 — empty return instead of propagating an error) that this G7b/#204
task exists to close: malformed config should HALT loudly, not resolve to an
empty model with exit 0.

The F01 normalize-once fix (lines 153-167) correctly closes the inline-comment
none-defeat and the duplicate emit path — none-check and emit share one normalized
value with no fall-through, and the round-05 regression test (test-config-model-routing.bats:430,
asserts `status -ne 0` + `*HALT*`) genuinely covers the comment case. The
CONFIG-missing F02 halt (lines 131-135) is a distinct, non-re-maskable loud halt.
This empty-value gap is the one remaining hole: there is no `[ -z "$value" ]`
guard between the none-check and the emit, and no behavioral test exercises a
whitespace-only / blank tier value (the suite tests absent rows at line 451 and
clean rows at line 441, but never a present-but-empty value).

Fix: after normalization (line 155), add an empty-value guard that HALTs with a
distinct malformed-row diagnostic naming the tier, e.g.
`if [ -z "$value" ]; then printf '[routing] HALT: tier "%s" has an empty/malformed
model_routing value...\n' "$tier" >&2; return 1; fi`, before the none-check at
line 159. Add a behavioral test pinning that a blank-value row exits non-zero.
