---
finding_id: F01
severity: medium
change_type: correctness
artifact: structure
referenced_files:
  - /Users/dfrysinger/code/qrspi-plus-v0.7.2/docs/qrspi/2026-05-30-v072-release/structure.md
  - /Users/dfrysinger/code/qrspi-plus-v0.7.2/docs/qrspi/2026-05-30-v072-release/design.md
---

`structure.md`'s new `scripts/second-reviewer-available.sh` block defines the CLI as requiring `<vendor>` (`Usage: second-reviewer-available.sh <vendor>`) and the new test block exercises `bash scripts/second-reviewer-available.sh openai-codex`. That does not match design.md G27 D3/D2/acceptance, where the Skills invoke `bash scripts/second-reviewer-available.sh` with no argument and the script uses the D5 default-second-reviewer vendor for the detected host. The outline later says the vendor override is optional, but the concrete interface and tests make the no-arg path unpinned.

Update the interface to `[<vendor>]` and add/adjust test coverage so the no-argument invocation is the primary pinned acceptance path for Copilot CLI and Claude Code.

(Persisted by orchestrator from Codex chat-only return.)
