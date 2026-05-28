---
finding_id: R18-F01
severity: high
change_type: correctness
referenced_files: [/Users/dfrysinger/Library/CloudStorage/Dropbox/claude-workspace/agent-bravo/docs/qrspi/2026-05-17-v07-release/design.md:L102-L111, /Users/dfrysinger/Library/CloudStorage/Dropbox/claude-workspace/agent-bravo/docs/qrspi/2026-05-17-v07-release/design.md:L133-L139]
artifact: design
round: 18
reviewer: quality-codex
---

G2 defines a single `run-third-party-llm.sh` interface whose `--output-file` contract is said to apply uniformly across both transports, but the Codex transport is simultaneously defined to return only a `jobId` for a separate `await`. Those two contracts are incompatible: an async `codex-broker` launch cannot both "return the jobId for separate await" and satisfy the smoke/fail-loud tests that expect a completed response to land in `--output-file` on exit 0. Downstream Implement/Plan work will not know whether success for the Codex transport means "job launched" or "response written," and the test strategy currently asserts both. Fix by choosing one universal contract explicitly: either `run-third-party-llm.sh` is launch-only for async transports (with a separate await surface and transport-specific smoke tests), or it always blocks until `--output-file` is populated and hides launch/await internally.
