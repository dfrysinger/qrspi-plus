---
finding_id: R3-F01
severity: medium
change_type: correctness
artifact: design
round: 3
reviewer: quality-claude
referenced_files:
  - docs/qrspi/2026-05-30-v072-release/design.md:L440-L450
  - docs/qrspi/2026-05-30-v072-release/design.md:L545
  - docs/qrspi/2026-05-30-v072-release/design.md:L578
  - docs/qrspi/2026-05-30-v072-release/design.md:L596-L598
---

## CD-4 references `orchestrator_fixes[]` audit field with no defined location, writer, or schema slot

**Location:** `design.md` CD-4 § H.3 (L545), § H.5 (L578), § H.6 (L596–598); contradicted by Component E (L440–450).

**Problem.** The CD-4 halt-response protocol introduces `orchestrator_fixes[]` as the audit-log structure that records every silent rescue event. Three sites mention it as load-bearing:

- H.3 (L545): "All rescue events (every tier) are logged to `orchestrator_fixes[]` with `{finding_id, cause, tier, original_value, fixed_value, fix_method, citation?}`. Round-summary prose at round end surfaces per-tier counts so persistent reviewer/verifier regression stays visible."
- H.5 (L578): "Audit visibility of underlying reviewer drift is preserved via `orchestrator_fixes[]` and the round-summary per-tier breakdown."
- H.6 acceptance (L596, L598): fixture tests are required to verify "is logged to `orchestrator_fixes[]`" and "tests fail if interpretive rescue is recorded without a citation."

Component E (L440–450) is the only place in CD-4 that locks an audit-file schema. Its `.verifier-fan-in-audit.json` shape is `{scored, kept, dropped, halts, thresholds}` — no `orchestrator_fixes` slot, no extension hook, and the writer is `scripts/verifier-fan-in.sh` (which never sees the rescue events because rescue happens between fan-in invocations).

The "Round-summary prose" referenced in H.3 has the same gap: no CD-4 component or other goal block names a file, a writer, or a consumer for it.

**Impact.** Plan and Implement cannot author the H.6 fixtures (or the writer/reader paths in the rescue tiers) without inventing the storage location. Three forks are equally compatible with the prose:

1. Extend `.verifier-fan-in-audit.json` with an `orchestrator_fixes` array — but the fan-in script does not own the rescue flow, and the file is written before any rescue runs.
2. Create a separate audit artifact (e.g., `<round-dir>/.orchestrator-fixes.json` or extend `.round-complete.json`) — but no goal block names it.
3. Append to dispositions prose — but H.3 says "logged to `orchestrator_fixes[]`" with a typed schema, which reads as JSON, not prose.

Each fork has different acceptance-test, lint, and reviewer-protocol implications. The current design leaves the choice to whoever authors Plan first, which is exactly the under-spec pattern Sub-Rule C (L890–919) was added to prevent.

**Suggested fix.** Lock one of:

- **(a)** Extend Component E's JSON schema with an `orchestrator_fixes: []` array (typed per H.3's structure) AND specify that an orchestrator-side write occurs *after* the verifier-fan-in script has produced the initial file — i.e., the JSON is co-owned (fan-in script writes the kept-set fields; orchestrator post-augments the rescue fields). Name the merge semantics (read-modify-write with atomic mv? append-only key?) explicitly.
- **(b)** Define a new file (e.g., `<round-dir>/.orchestrator-fixes.json`) with its own component letter, lock the schema, name the writer (orchestrator rescue tiers) and consumer (round-summary prose surface), and update H.3 / H.5 / H.6 to point at it.

Also lock the "round-summary prose" surface — name the file (likely `.round-complete.json` or `round-NN-dispositions.md`), name the writer (orchestrator, after rescue completes), and name the consumer (user-facing chat output at round end). Without that surface, H.3's "per-tier counts surfaced at round end" is unverifiable.
