---
verifier_status: passed
score: 80
actual_model: unknown
defect_class: contract-inconsistency
---

Cite Check: design.md line 13 explicitly states `scripts/upstream-paths.sh` "accepts `--step <step>`"; line 21 states "Keeps the script context-free." Line 246 introduces a Plan-step branch that reads `pipeline:` from `<artifact-dir>/config.md`, and line 250 references the orchestrator passing `--artifact-dir` — a flag CD-1 never declares. Acceptance lines 263-265 say "against a fixture artifact-dir" without specifying how artifact-dir reaches the script. All quoted/anchored content present at cited locations.

This is a real, substantive contract inconsistency between two adjacent Cross-Goal / Goal blocks that share a hard sequencing dependency (G4 hard-depends on CD-1 per line 257). Implementers cannot derive the script's CLI signature without picking between the two stated contracts, and the "context-free" framing in CD-1 is directly contradicted by G4's internal config.md read. Worth fixing before plan/implementation. Not a 90+ because the fix is mechanical (add `--artifact-dir` to CD-1's signature + soften "context-free") and a reasonable reader can infer the intended resolution from line 250.
