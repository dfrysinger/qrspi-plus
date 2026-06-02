---
reviewer: test-coverage-claude
round: 3
artifact: plan.md
task: T11
severity: high
change_type: correctness
---

# F01 — T11 dispatch-manifest provenance: no test expectations for missing-field fail-loud or malformed-field schema-strict paths

## What

T11 was fully rewritten in round-02/03 (formerly [G29], now [G3]) to land the
five `dispatch_spec` provenance fields (`subagent_type`, `host`, `vendor`,
`model`, `prompt_file`) on the pre-rename `scripts/run-codex-review.sh`. The
Test Expectations block (plan.md task 11, lines under "**Test expectations**")
contains four bullets:

1. First-party dispatch → inspect `.dispatch-manifest.json` for `dispatch_spec`
   object containing all five fields.
2. Third-party/background dispatch → inspect for `host`/`vendor`/`model` plus
   job metadata.
3. Repeated invocations against the same round dir → manifest remains
   well-formed JSON with all expected entries.
4. Acceptance coverage → orchestrator-facing payload remains a prompt-file
   reference.

What is **missing**:

- **(b) Fail-loud path when a field is missing.** No test expectation
  describes what the dispatcher does when one of `subagent_type`, `host`,
  `vendor`, `model`, or `prompt_file` cannot be resolved (no host signal,
  unresolved tier→vendor lookup, missing prompt-file path). The DoD says
  manifest writes must be "atomic and append-safe" with "no entries... lost
  or malformed", but a manifest entry that contains five empty-string fields
  is well-formed JSON and would satisfy bullets #1 and #3 vacuously.

- **(c) Schema-strict path when a field is malformed.** No test expectation
  describes the behavior when a passed value is the wrong shape — e.g., a
  non-string `subagent_type`, a `vendor` that is not in the resolver's
  vendor enum, a `prompt_file` that is not an absolute path, a `host` value
  the matrix does not recognize. The current expectations would pass even
  if every value were stringified and written verbatim with no validation.

## Why this matters

The round-03 dispatch prompt for this reviewer explicitly named these two
paths as required coverage: "verify Test Expectations cover (a) all 5
dispatch_spec provenance fields populated correctly, (b) the fail-loud path
when a field is missing, (c) the schema-strict path when a field is
malformed."

If the test author writes only the four listed expectations, the resulting
acceptance test will accept an implementation that silently writes empty or
junk values into `dispatch_spec` — defeating the auditability property the
task exists to deliver. The Phase 1 Acceptance Criterion #2 reference to
"dispatch on misrouted `model_routing` entries" assumes a fail-loud manifest
write, but no test pins that behavior at T11's level.

## Recommended fix

Add two test expectations to T11:

- **Missing-field fail-loud:** "Exercise a first-party dispatch with the
  `prompt_file` argument (or `subagent_type`, or any of the other four
  fields) deliberately omitted/empty; verify the dispatch script exits
  non-zero before writing a manifest entry, and verify stderr contains a
  diagnostic naming the missing field." (Or, if the locked design is that
  the script writes `unknown` / a sentinel value, pin that sentinel
  literally — the silent-empty-string outcome must be made impossible.)

- **Malformed-field schema-strict:** "Exercise a dispatch with a `vendor`
  value outside the resolver's vendor enum and a non-absolute `prompt_file`
  path; verify each case exits non-zero with a diagnostic naming the
  rejected field and value." If T11's design intentionally accepts opaque
  strings (no schema validation), add a positive expectation pinning that
  decision so the Test author does not invent rejection behavior the
  implementation does not provide.

Also tighten bullet #1 to assert each of the five fields is non-empty (not
just present as a JSON key), so an all-empty-strings implementation cannot
pass vacuously.
