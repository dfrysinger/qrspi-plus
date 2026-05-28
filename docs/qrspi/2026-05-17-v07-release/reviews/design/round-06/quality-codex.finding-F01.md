---
finding_id: R6-F01
severity: medium
change_type: correctness
referenced_files: [docs/qrspi/2026-05-17-v07-release/design.md:L764-L766, docs/qrspi/2026-05-17-v07-release/goals.md:L13-L15]
artifact: design
round: 6
reviewer: quality-codex
---

The design's G17 CI decision explicitly limits CI to the Ubuntu default Bash and defers older Bash coverage to a future user-repo concern, but the approved goals make bash 3.2+ portability a release constraint for this repo's shell-side scripts. That contradiction can mislead Plan/Implement into shipping `run-third-party-llm.sh`, helper scripts, or protocol shell snippets that pass CI while using Bash 4/5-only syntax.

Fix: revise the G17 recommendation and test strategy so qrspi-plus itself has a concrete bash 3.2 compatibility guard where applicable, such as a macOS/Bash 3.2 lane, a targeted compatibility test for changed shell scripts, or an explicit design justification for any script surface that is not required to support bash 3.2.
