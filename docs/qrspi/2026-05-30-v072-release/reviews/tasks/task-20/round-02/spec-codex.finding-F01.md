---
finding_id: R2-F01
severity: high
change_type: correctness
referenced_files:
  - scripts/dispatch-agent.sh
  - scripts/dispatch-companion.sh
---
Batched third-party dispatch calls an unsupported CLI shape — launch cannot succeed end-to-end.

`dispatch-agent.sh:705-710` invokes `dispatch-companion.sh launch --vendor ...` (with the literal token `launch` as $1). `dispatch-companion.sh` does NOT implement a `launch` subcommand: it detects launch mode by scanning `"$@"` for the `--vendor` flag (L562-565), then enters a `while [ "$#" -gt 0 ]` flag-parser whose default branch is `*) die "launch: unrecognised flag: $1"` (L580). The first arg `launch` matches no flag and aborts immediately with `"launch: unrecognised flag: launch"`.

Result: in batched (`--agents`) mode, every third-party reviewer's launch returns non-zero, the per-tag non-fatal branch (L711-714) records `status=failed`, and the manifest never carries any pending entries with real job_ids — exactly the round-1 F01 condition the fix was supposed to close, just shifted from "no launch attempt" to "launch attempt fails immediately." `await-round.sh` therefore has nothing to drain and the third-party finding-splitter pipeline never runs.

Violates DoD bullet 3 (`tasks/task-20.md:43,55,59`) and the batched-mode third-party launch contract.

**Fix path (one of):**
(a) Drop the `launch` token from the batched invocation in dispatch-agent.sh — match the actual flag-based shape: `dispatch-companion.sh --vendor "$_vendor" --model "$_model" --prompt-file "$_prompt_file" --round-dir "$BATCH_OUTPUT_DIR" --tag "$_tag"`.
(b) Or add an explicit `launch` subcommand at the top of dispatch-companion.sh that shifts the token off and falls through to the existing flag parser.

(a) is the smaller diff and matches the convention the new positive tests already use.
