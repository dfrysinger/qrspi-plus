---
finding_id: R2-F03
severity: high
change_type: correctness
referenced_files:
  - tests/unit/test-per-finding-file-emission.bats:119-137
  - skills/reviewer-protocol/third-party-emission.md:20-21
artifact: task-03
round: 2
reviewer: silent-failure-claude
---

# F03 — Wrong-channel rejection tested only by prose-grep; no behavioral test for splitter (high · correctness)

**Convergence:** Same as `silent-failure-codex.finding-F03.md` — doc-only loudness assertion, no executable test. Two independent reviewers caught it.

The test verifies the contract PROSE names the right strings (`<<<FINDING-BOUNDARY>>>`, `NO_FINDINGS`, `third-party-finding-splitter.sh`, `expected tag produced no output`). No test runs the splitter with malformed input and asserts output file count.

`third-party-emission.md:20-21`: "Anything that is neither boundary-prefixed nor the `NO_FINDINGS` sentinel is malformed and produces zero finding files for your tag." — never exercised behaviorally.

**Unverified splitter behaviors:** stray preamble before valid blocks, mixed output, chat-only without markers.

**Harness work — DEFERRED TO v0.7.3:** Add behavioral bats tests calling `third-party-finding-splitter.sh` with fixture inputs. Requires fixture-creation harness work that exceeds T03's prose-contract scope.
