---
finding_id: R3-F03
severity: medium
change_type: correctness
referenced_files: [docs/qrspi/2026-06-04-v073-release/design.md]
artifact: design
round: 3
reviewer: quality-codex
---

Research grounding is referenced informally (e.g., “per Q1 research”, “Q4 established practice”) but not traced to concrete `research/q*.md` citations, which prevents citation verification and weakens decision traceability.  
Fix: for each major decision rationale that relies on research, add explicit `research/q*.md` citations so the claims are auditable against source findings.
