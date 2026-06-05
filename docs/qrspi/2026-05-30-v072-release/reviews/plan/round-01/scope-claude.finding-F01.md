---
finding_id: R1-F01
severity: medium
change_type: scope
referenced_files: [docs/qrspi/2026-05-30-v072-release/plan.md:L347, docs/qrspi/2026-05-30-v072-release/plan.md:L358-L360]
artifact: plan
round: 1
reviewer: scope-claude
---

Task 05 (G13 `change_type` enum drift hardening) carries a contradiction between **Target files** and **Scope: In** that this scope reviewer is asked to flag per the dispatch instructions ("Flag contradictions between Scope and Target files (e.g., Scope says 'create X' but Target files lists 'modify X' or vice versa).").

**Concrete contradiction:**

- Target files (line 347) lists `scripts/verifier-fan-in.sh (create)`.
- Scope: In (lines 358–360) describes "Add the canonical `change_type` enum (`style`, `clarity`, `correctness`, `scope`, `intent`) to the `scripts/verifier-fan-in.sh` header" and "Make `scripts/verifier-fan-in.sh` treat an out-of-enum `change_type:` as a contract violation: exit non-zero, write `.verifier-fan-in-audit.json` …" — i.e. extending/modifying behavior of an already-existing script.
- Dependencies (line 348) cite `Task 02`, and Task 02 (line 182) already lists `scripts/verifier-fan-in.sh (create)` as its Target file and is responsible for creating that script as the verifier-fan-in primitive.

By the time T05 executes (sequenced after T02 per the explicit dependency), `scripts/verifier-fan-in.sh` already exists. T05's Target-files marker must be `(modify)`, not `(create)`. The `(create)` marker also collides with T02's own canonical create-of-record, which would make two task specs claim creation of the same file path — exactly the kind of ownership ambiguity the per-task `(create)/(modify)` annotation exists to prevent.

**Why this is a scope finding rather than artifact-quality:**

The Plan reviewer dispatch contract handed to this scope reviewer explicitly carves out Scope-vs-Target-files contradictions as in-scope for me. The mis-marked annotation is a scope/boundary signal — it makes T05 appear to own the script's creation surface (a structural claim) when the OWNS/DEFERS-consistent reading of Scope: In is that T05 only owns an enum-hardening modification layered onto T02's already-created script. Left uncorrected, this would mis-route ownership of the file's create surface across two tasks.

**Suggested resolution:**

Change Target files line 347 from `scripts/verifier-fan-in.sh (create), …` to `scripts/verifier-fan-in.sh (modify), …`. No other Plan content needs to change — Scope: In, DoD, Dependencies, and Test expectations are already self-consistent against the modify reading.
