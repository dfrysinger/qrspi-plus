---
finding_id: R2-F01
severity: high
change_type: scope
referenced_files: [docs/qrspi/2026-06-04-v073-release/design.md]
artifact: design
round: 2
reviewer: scope-codex
---

The artifact is written at implementation/structure altitude across most sections, which crosses Design DEFERS boundaries. It repeatedly prescribes exact file ownership and edit locations (e.g., specific `scripts/...`, `agents/...`, `skills/...` targets), concrete command-level mechanics (`git ...`, `awk ...`, CI command chains), and detailed test implementation surfaces (named test files + exact command/assertion behavior), all of which are deferred to Structure/Plan/Implement. Re-scope this design to outcome-level contracts: keep the intended behaviors, edge cases, invariants, and acceptance *shapes*, but remove/relax file-by-file placement mandates and executable-mechanic prescriptions.
