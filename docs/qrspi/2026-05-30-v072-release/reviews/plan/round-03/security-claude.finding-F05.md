---
finding_id: F05
reviewer: security-claude
round: 3
artifact: plan.md
change_type: clarity
severity: low
task_refs: [T19]
---

# F05 — T19 `second-reviewer-available.sh` vendor override accepts unvalidated CLI input

## Summary

Task 19 creates `scripts/second-reviewer-available.sh` with "no-arg default-vendor
lookup, optional diagnostic vendor override" (line 1115). The override is
explicitly bounded ("does not read `model_routing:` or enforce primary/second
vendor distinctness" — line 1142) and unavailable paths fail loud with one
`[second-reviewer-unavailable]` diagnostic. So far so good.

What's not pinned: any input-validation contract on the override string itself.
The probe consumes the value, looks it up in the shared matrix in
`_resolve-lib.sh`, and either succeeds, exits non-zero with `unknown vendor`, or
exits non-zero with `unavailable vendor`. The Test Expectations
(lines 1140–1147) cover known-vendor success, unknown-vendor failure, and
matrix shared-source enforcement — but no fixture covers what happens when
the override is hostile-formatted (path traversal, shell metacharacters,
embedded newlines, control bytes, very long strings).

## Concrete concerns

1. **The override value will appear in error messages.** Line 1132 requires
   the diagnostic to "name... the detected host plus requested/default
   vendor." If the vendor string contains control bytes or terminal escape
   sequences, the diagnostic written to stderr can corrupt terminal state for
   the operator or hide adjacent diagnostic lines. The plan does not pin a
   sanitization rule for diagnostic interpolation.

2. **`_resolve-lib.sh` lookup contract is opaque to T19.** If
   `_resolve-lib.sh`'s vendor-lookup helpers use the value as part of a
   filesystem path, an array index, or a `case` glob pattern, an override
   like `'*'` or `'../codex'` may match unintended entries or escape the
   intended lookup table. T19's tests assert "shared-source tests fail if
   the probe carries a parallel hardcoded host table" (line 1143), but no
   test asserts the matrix lookup treats the override as opaque-data rather
   than as a pattern/path.

3. **Override is mentioned as "diagnostic" only, but exit code is
   load-bearing.** Callers that script around this probe (the Goals SKILL
   migration the same task lands, line 1117) will likely use exit code to
   decide whether to set `second_reviewer: false`. If a hostile or malformed
   override can swing the exit code in an unintended direction (e.g., a value
   that happens to match a wildcard and return 0 when no real second reviewer
   exists), Goals proceeds with `second_reviewer: true` against a vendor
   that isn't actually available. Tests don't include this case.

## Why this matters at plan level

This is **low severity** because the probe is intended to be operator-invoked
or invoked from another script under operator control, not from network input.
The attack surface is shallow. But the plan is otherwise careful about
fail-loud invariants in this area, and the lack of any input-shape rule on the
override stands out as an inconsistent gap that a future change could widen
(e.g., if the probe ever gets called from a SKILL that interpolates a
user-typed value).

## Recommended remediation (do not require any specific wording)

Add to T19 Test Expectations one of:

- A bounded-charset fixture asserting that override values matching the
  documented vendor-token shape (e.g., lowercase alphanumeric + hyphen) are
  accepted, and anything else (path components, metacharacters, control bytes)
  is rejected pre-lookup with the same `[second-reviewer-unavailable]`
  diagnostic — or with a distinct `[second-reviewer-invalid]` diagnostic so
  callers can distinguish "no matching vendor" from "you passed garbage."

- A "matrix-lookup is opaque-data" fixture passing `*`, `?`, `../`, and similar
  shell-glob / path-shape values and asserting the lookup neither matches a
  real vendor by coincidence nor escapes the intended lookup table.

Either remediation is small (probably <10 lines of test fixture) and prevents
a class of latent regressions as the probe acquires more callers.

## Files / sections to update

- `plan.md` Task 19 → **Definition of done** (lines 1129–1136) — add an
  override-shape constraint.
- `plan.md` Task 19 → **Test expectations** (lines 1140–1147) — add a
  malformed-override fixture.
