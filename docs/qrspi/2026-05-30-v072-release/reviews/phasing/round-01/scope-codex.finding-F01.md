---
finding_id: R1-F01
severity: medium
change_type: correctness
referenced_files:
  - docs/qrspi/2026-05-30-v072-release/phasing.md:L72-L83
  - docs/qrspi/2026-05-30-v072-release/phasing.md:L131-L163
  - skills/phasing/owns-defers.md:L15-L18
artifact: phasing
round: 1
reviewer: scope-codex
---

`phasing.md` crosses the Phasing boundary by specifying deferred implementation/task-level content (explicit file paths/config keys and procedural test/task specs), e.g. `round-NN.diff`, `run-codex-review.sh`, `scripts/build-plugin.sh`, `~/.copilot/...`, and stepwise trap-testing instructions in the phase gate. Per OWNS/DEFERS, Phasing should stay at slice/phase grouping with replan gates, and defer file/module/task/implementation details to Structure/Plan/Implement. Fix by rewriting these sections to phase-level outcomes and acceptance criteria without naming concrete files/scripts or task-procedure details.
