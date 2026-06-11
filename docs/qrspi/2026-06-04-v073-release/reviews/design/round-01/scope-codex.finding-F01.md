---
finding_id: R1-F01
severity: high
change_type: scope
referenced_files:
  - /Users/dfrysinger/code/qrspi-plus-v0.7.2/docs/qrspi/2026-06-04-v073-release/design.md:L13-L55
  - /Users/dfrysinger/code/qrspi-plus-v0.7.2/docs/qrspi/2026-06-04-v073-release/design.md:L196-L238
  - /Users/dfrysinger/code/qrspi-plus-v0.7.2/docs/qrspi/2026-06-04-v073-release/design.md:L319-L385
  - /Users/dfrysinger/code/qrspi-plus-v0.7.2/docs/qrspi/2026-06-04-v073-release/design.md:L425-L454
artifact: design
round: 1
reviewer: scope-codex
---

The artifact crosses Design DEFERS boundaries by prescribing file architecture and implementation-level mechanics instead of staying at outcome-altitude design. It repeatedly assigns exact ownership to concrete files/scripts (`scripts/*.sh`, specific `skills/*`, `agents/*`, `tests/*` locations), defines CLI signatures and command bodies, and includes multi-line executable shell behavior (`git status`, `git log`, `git diff "$(cat ...)"`, revert flow). Under Design DEFERS, file placement/module routing and executable shell beyond illustrative snippets belong to Structure/Plan/Implement.

Fix: keep the goals/CD decisions and invariants in design.md, but remove file-by-file placement and command-level procedure text; defer those to structure.md (placement/boundaries) and plan/implement artifacts (script/command mechanics and test implementation).
