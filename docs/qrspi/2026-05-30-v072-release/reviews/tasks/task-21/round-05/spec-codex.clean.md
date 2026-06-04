---
reviewer: spec-codex
round: 5
status: clean
---
CLEAN — Verified against task-21.md spec line 19 + invariants:
- Fail-loud source guard at dispatch-agent.sh:78-80, dispatch-companion.sh:65-67
- assert_file_exists hoisted to dispatch-agent.sh:112-122; used at :593 (batch)
- G16 tokens removed from bats:1429-1449, sentinel:1553
- Path-family boundary checks intact at :965-997
- Companion audit covered at dispatch-companion.sh:45-57, :617-620
- Implementer-allowlist contract preserved in agents/qrspi-implementer.md:9-33
- Tests cover outside-path, symlink, readable companion, canonicalization fail-closed, structural checks (:1453-1631), batch (:1644-1788), source-guard regression (:1798-1830)
Advisory: includes scripts/lib/path-guard.sh beyond target list; small task-aligned shared helper, not scope creep.
