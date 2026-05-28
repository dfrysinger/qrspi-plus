---
finding_id: R2-F01
severity: high
change_type: added
artifact: plan
round: 2
reviewer: quality-claude
referenced_files:
  - docs/qrspi/2026-05-27-v071-hardening/plan.md
  - docs/qrspi/2026-05-27-v071-hardening/design.md
  - docs/qrspi/2026-05-27-v071-hardening/structure.md
---

# R2-F01: Task 7 test expectations introduce undefined term "codex-broker" and misattribute Copilot CLI transport

## Location

`plan.md` → Task 7, Test expectations, second and first new sub-expectations (diff lines 118–120):

```
- With `COPILOT_CLI=1` set, the acceptance test exercises a mocked Codex dispatch via `run-codex-review.sh` and asserts the dispatch returns a recognizable success signal (zero exit + non-empty stdout capture)
- With `COPILOT_CLI` unset and the Claude Code transport mocked, the dispatch surface routes through the `codex-broker` transport and again returns a recognizable success signal (zero exit + non-empty stdout capture)
```

## Observation

**Issue A — Undefined "codex-broker" term.** The second sub-expectation names "the `codex-broker` transport" as the routing target for the Claude Code path. This term does not appear in any companion artifact:

- `design.md` DKR7 names the Claude Code transport as "shell pipeline via `scripts/run-codex-review.sh`"
- `structure.md` Slice 6 names `scripts/run-codex-review.sh` as the transport file; no "codex-broker" component appears anywhere
- `goals.md` G6, `phasing.md` Slice 6, and the Phase 1 Acceptance Criteria all refer to the Claude Code transport as the shell-pipeline path without using the term "codex-broker"

The term is therefore a phantom component name that an implementer writing the acceptance test cannot resolve to any defined artifact or interface.

**Issue B — Copilot CLI path misdescribed as "via `run-codex-review.sh`".** The first sub-expectation says the Copilot CLI acceptance test "exercises a mocked Codex dispatch via `run-codex-review.sh`". Under Copilot CLI, design DKR7 specifies the dispatch transport as the native task tool with `agent_type: code-review` and `model: gpt-5.3-codex`, NOT the shell pipeline via `run-codex-review.sh`. While `run-codex-review.sh` is the entry point that hosts the `detect_host()` and `check_codex_available()` functions, describing the Copilot CLI dispatch as occurring "via `run-codex-review.sh`" conflates the test's entry point (calling the script to exercise dispatch routing) with the transport mechanism (task tool vs shell pipeline). A test-writer reading this expectation literally may mock `run-codex-review.sh`'s shell-pipeline path instead of asserting that the task-tool annotation is emitted for the Copilot CLI host.

## Why it matters

A test-writer implementing Task 7's acceptance tests will have no specification to determine what "codex-broker transport" refers to. The most likely failure modes are: (a) the term is silently misread as an alias for `run-codex-review.sh` (which would make both host paths test the same transport, defeating the per-host verification goal), or (b) the test-writer invents a component name that diverges from the implementation. Either produces an acceptance test that does not actually verify the dispatch-transport branching that DKR7 requires.

Combined with Issue B, an implementer following these expectations may write an acceptance test that verifies shell-pipeline success for BOTH host paths, leaving the Copilot CLI task-tool transport path entirely untested at the acceptance layer.

## Suggested resolution

Replace the two sub-expectations with transport-accurate language:

```
- With `COPILOT_CLI=1` set, calling `run-codex-review.sh` exercises the Copilot CLI dispatch path: the dispatch surface emits the task-tool transport annotation (`agent_type: code-review` / `model: gpt-5.3-codex`) and returns zero exit
- With `COPILOT_CLI` unset and the shell-pipeline transport mocked, calling `run-codex-review.sh` exercises the Claude Code dispatch path: the dispatch surface invokes the shell pipeline (`scripts/run-codex-review.sh` inner transport) and returns zero exit with non-empty stdout capture
```

Replace "codex-broker transport" with "the shell pipeline via `scripts/run-codex-review.sh`" to match design DKR7 and structure.md Slice 6 terminology.
