---
finding_id: R1-F01
reviewer_tag: silent-failure-claude
round: 1
task: 6
severity: medium
change_type: prose_contract
referenced_files:
  - agents/qrspi-finding-verifier.md
  - tests/unit/test-verifier-agent-file.bats
---

# F01 — "score: integer" claim in step 7 contradicts `VERIFY_FAILED` non-integer template; no G11 test covers the exception

## Location

`agents/qrspi-finding-verifier.md` line 66 (T06-introduced) + lines 58–64 (failure sidecar template, also T06-modified):

```
# line 66 (step 7, new T06 text):
"the canonical score used by the fan-in filter is the `score:` **integer** in the
sidecar frontmatter written in step 6"

# lines 58–64 (failure template, T06-modified to use frontmatter):
---
score: VERIFY_FAILED
reason: <one-sentence diagnosis>
---
```

`tests/unit/test-verifier-agent-file.bats` lines 72–78 (G11 integer test, T06-introduced):

```bash
echo "$body" | grep -qE 'score:.*int|score:.*0.*100|integer.*score:|frontmatter.*score:|score:.*frontmatter' \
  || { echo "verifier agent does not require score: integer 0-100 in sidecar frontmatter (G11)"; return 1; }
```

## Silent-failure risk

T06 rewrites step 7 to say the fan-in filter consumes **"the `score:` integer in the sidecar frontmatter."** The word "integer" is new — added by T06 — and implies the fan-in performs numeric parsing or comparison on `score:`. However, the failure-case sidecar (also present in the T06-modified step 6) emits `score: VERIFY_FAILED`, which is a non-integer string.

A fan-in implementer reading the agent file faithfully would produce code like:

```bash
score=$(yq '.score' "$sidecar_file")
if [ "$score" -ge "$threshold" ]; then ...   # bash: "integer expression expected" on VERIFY_FAILED
```

```python
score = yaml.safe_load(front)["score"]
if score >= threshold:   # Python: TypeError: '>=' not supported between str and int
```

Neither error is loud by default. Bash exits with code 2 (often swallowed by `||` guards); Python raises an uncaught exception if the caller doesn't wrap the comparison. In both cases the specific finding could be silently skipped, silently promoted, or silently misclassified.

The six new G11 bats tests do not catch this gap:

- `G11: sidecar frontmatter requires score: as integer 0-100` checks that the integer constraint is documented — but it passes by matching `score: <int 0..100>` in the *success* template. It does not verify that `VERIFY_FAILED` is documented as a valid, explicitly-named exception to the integer rule.
- No G11 test asserts that the agent file qualifies the step-7 "score: integer" claim with "unless VERIFY_FAILED."
- No G11 test asserts that the `reason:` field in the failure frontmatter is the diagnostic output path (success path puts reasoning in the body; failure path puts it in frontmatter — this asymmetry is also undocumented and untested).

A future edit that removes the `VERIFY_FAILED` block from the agent (making integers-only truly consistent) or that changes VERIFY_FAILED to `-1` (to satisfy integer parsing) would pass all G11 tests while breaking the fan-in's error-handling contract silently.

## Why this is T06's fault, not pre-existing

Pre-T06, step 7 said only:
> "Return exactly one line: `<reviewer_tag>.<finding_id>: <score>`"

The word **integer** applied to the canonical fan-in score field is T06-introduced (diff line +41). T06 also adds all six G11 bats tests. Together they create a stated integer-only constraint with no corresponding test for the VERIFY_FAILED exception — a gap that did not exist before this task.

## Fix

Option A — qualify the "integer" claim in step 7 and add a bats test:

In the agent file, change:

> "the canonical score used by the fan-in filter is the `score:` integer in the sidecar frontmatter"

to:

> "the canonical score used by the fan-in filter is the `score:` field in the sidecar frontmatter — an integer 0–100 on success, or the sentinel `VERIFY_FAILED` on failure"

Then add a bats test:

```bash
@test "G11: VERIFY_FAILED is documented as the non-integer failure sentinel for score:" {
  local body
  body=$(awk '/^---$/{n++; next} n>=2{print}' agents/qrspi-finding-verifier.md)
  echo "$body" | grep -qF 'VERIFY_FAILED' \
    || { echo "verifier agent does not document VERIFY_FAILED as failure sentinel"; return 1; }
  # Must appear in the sidecar template context, not just the chat-return format
  echo "$body" | grep -qE 'score:.*VERIFY_FAILED|VERIFY_FAILED.*sidecar|sidecar.*VERIFY_FAILED' \
    || { echo "VERIFY_FAILED not associated with sidecar score: field"; return 1; }
}
```

Option B — remove the `VERIFY_FAILED` sidecar path entirely and use integer sentinels (e.g., `score: -1`) so the "score: integer" claim becomes uniformly true. This requires coordinated changes to T02's fan-in script.
