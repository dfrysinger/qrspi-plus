---
finding_id: R4-F02
severity: medium
change_type: correctness
referenced_files: [docs/qrspi/2026-05-17-v07-release/plan.md:L244-L248]
artifact: plan
round: 4
reviewer: quality-claude
---

T04's test expectations section (lines 244–248) does not assert that the codex-shim forwarder passes `--artifact-dir` to the universal dispatcher. The T04 description at line 242 explicitly includes it — "re-invokes `scripts/run-third-party-llm.sh --provider codex --model <id> --output-file <path>` (along with `--artifact-dir`)" — but the corresponding test expectation at line 245 reads only: "The forwarded invocation includes `--provider codex` and the model identifier originally passed to the shim, with no transport flag."

The gap matters because T03 marks `--artifact-dir` as a required flag (line 211: "Invocation missing any required flag (`--artifact-dir`, `--provider`, `--model`, `--output-file`) exits 1 and names the missing flag"). A T04 implementation that forwards `--provider`, `--model`, and `--output-file` but omits `--artifact-dir` would cause the dispatcher to exit 1 on every call — silently breaking all Codex dispatch sites. The test expectations as written would pass without detecting this regression (the expectation checks for `--provider codex` and the model identifier, but not `--artifact-dir`).

Fix: add a test expectation bullet to T04's list that explicitly states: "The forwarded invocation includes `--artifact-dir` with the artifact directory value resolved by the shim from its own caller context (so the dispatcher can read `config.md` from the correct artifact directory)."
