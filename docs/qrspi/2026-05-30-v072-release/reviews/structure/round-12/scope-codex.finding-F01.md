---
finding_id: F01
severity: medium
change_type: scope
artifact: structure
referenced_files:
  - /Users/dfrysinger/code/qrspi-plus-v0.7.2/docs/qrspi/2026-05-30-v072-release/structure.md
---

`scripts/_resolve-lib.sh`'s insertion-site note crosses into Design territory by declaring that the G27 D5 five-column matrix "supersedes the prior 4-column version" and instructing readers which design section is load-bearing. Structure can cite the lifted source and target insertion site, but deciding canonical supersession between design sections is an architecture/design-source decision, not a structure boundary.

**Location:** structure.md:1068-1072

**Fix:** Remove the supersession/design-reconciliation sentence from the Structure insertion-site note, or move that canonical-source decision back into `design.md`.

(Persisted by orchestrator from Codex chat-only return.)
