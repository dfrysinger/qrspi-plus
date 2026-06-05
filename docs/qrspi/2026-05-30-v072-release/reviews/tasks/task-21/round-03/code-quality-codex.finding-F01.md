---
finding_id: F01
reviewer: code-quality-codex
severity: medium
change_type: correctness
referenced_files: [scripts/lib/path-guard.sh:3, scripts/dispatch-agent.sh:74, scripts/dispatch-agent.sh:575, scripts/dispatch-agent.sh:631, scripts/dispatch-companion.sh:45, scripts/dispatch-companion.sh:610, tests/unit/test-dispatch-agent.bats:24, tests/unit/test-dispatch-agent.bats:1413]
---
**G16 ID hygiene violations in production/test code.** Internal QRSPI IDs (G16) leak into comments and test names outside docs/qrspi/. Strip G16 references from code/test surfaces; replace with descriptive prose ("path-traversal guard").
