---
reviewer: test-coverage-claude
round: 3
artifact: plan.md
task: T20
severity: medium
change_type: correctness
---

# F02 — T20 dispatch-script rename: no test expectation verifies T11's `dispatch_spec` provenance survives the rename

## What

T20 (G3 dispatch-script rename collapse) lists T11 in its dep chain (so the
new round-03 T11 framing is upstream). T20 hard-renames
`scripts/run-codex-review.sh` → `scripts/dispatch-agent.sh` and renames the
matching test file `tests/unit/test-run-codex-review.bats` →
`tests/unit/test-dispatch-agent.bats`. T11 added the
`dispatch_spec.{subagent_type, host, vendor, model, prompt_file}` provenance
write-side to the pre-rename script.

T20's Test Expectations bullet on dispatch-agent unit coverage says:

> Dispatch-agent unit coverage verifies renamed entry-point invocation,
> first-party spec-line parsing, `.dispatch-manifest.json` entries,
> `PROMPT_FILE=<absolute-path>` emission, and no dependency on
> `run-codex-review.sh`.

The phrase ".dispatch-manifest.json entries" is generic. It does not pin that
the T11 `dispatch_spec` object — with all five named provenance fields — is
still written by the renamed `dispatch-agent.sh`. The Test author for T20
could satisfy this expectation with an assertion that the manifest contains
at least one entry of any shape, even if the rename refactor accidentally
dropped the `dispatch_spec` writer (e.g., by editing the wrong helper
function during the rename diff).

No other T20 bullet covers provenance survival either. The third-party
companion/splitter bullets cover the new dispatch chain but not the
manifest-write shape inherited from T11.

## Why this matters

Round-02 surgery deliberately re-pointed T20's dep list to include T11
specifically so the rename would happen after the provenance edits land. The
correctness story is: T11 writes the provenance into the pre-rename script,
then T20 renames the script and the consumer skills, and the provenance must
still flow through to the manifest under the new script name. Without a
T20-level test expectation pinning the dispatch_spec object survives the
rename, the round-03 dispatch prompt's order-of-operations concern ("verify
Test Expectations exercise the order-of-operations correctly under the new
T11 framing") is not met.

The T11 acceptance tests originally written against
`scripts/run-codex-review.sh` would either need to be updated by T20 to
target the renamed script — in which case T20 owns the update and should
have a test expectation that those provenance assertions are retargeted and
still pass — or they would silently break/skip.

## Recommended fix

Add one explicit T20 test expectation:

> After rename, `tests/unit/test-dispatch-agent.bats` (renamed from
> `test-run-codex-review.bats`) contains all of T11's `dispatch_spec`
> provenance assertions retargeted to `scripts/dispatch-agent.sh`: the
> first-party manifest entry written by the renamed script carries a
> `dispatch_spec` object with non-empty `subagent_type`, `host`, `vendor`,
> `model`, and `prompt_file` fields, and the third-party manifest entry
> carries `host`/`vendor`/`model` plus job metadata.

Optionally pair with: "Acceptance suite from T11 runs green against the
renamed `dispatch-agent.sh` without any unmigrated references to
`run-codex-review.sh`."
