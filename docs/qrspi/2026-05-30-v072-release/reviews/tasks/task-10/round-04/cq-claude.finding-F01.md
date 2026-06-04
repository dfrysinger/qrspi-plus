---
finding_id: R4-F01
severity: medium
change_type: style
referenced_files: [tests/unit/test-verified-file-shape.bats, tests/acceptance/v07-phase1/test-phase1-acceptance.bats]
---

# ID Hygiene: QRSPI-internal goal/design IDs in test code comments

**Locations:**
- `tests/unit/test-verified-file-shape.bats:144` — `# Defect-class rubric pins (G28 D1).`
- `tests/acceptance/v07-phase1/test-phase1-acceptance.bats:1957` — `# G28 — Convergent-evidence exception: verifier instrumentation + dispositions`

Both tokens `G28` (goal ID) and `D1` (design ID) match the QRSPI-internal pattern `\b[GRDFTQ]-?[0-9]+[A-Za-z]?\b`. They appear in bash `#` comments inside test files, which the ID-hygiene rule forbids (code comments outside `docs/qrspi/`).

Convergent with cq-codex.finding-F01 (same locations + tokens).

**Recommended remediation (backlog):**
- `# Defect-class rubric pins (G28 D1).` → `# Defect-class rubric pins — verifier sidecar instrumentation.`
- `# G28 — Convergent-evidence exception: ...` → `# Convergent-evidence exception: ...`
