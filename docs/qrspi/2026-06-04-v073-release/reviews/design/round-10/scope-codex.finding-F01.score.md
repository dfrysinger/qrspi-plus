---
verifier_status: passed
score: 40
actual_model: unknown
defect_class: altitude-mismatch
---

Cite Check: confirmed. design.md L396 contains the cited path `<artifact-dir>/.wave-state/wave-N-expected-parents.json` (inside the G6 Solution step 2 capture procedure), and L404 contains "lands in the same dispatch-chain script as the validation". Both citations are accurate against the R09 additions.

Substance: The altitude concern is real — concrete file paths and script-placement decisions are conventionally Structure-owned in QRSPI. However, the design author already hedged the path with "e.g." (line 396: "writes the resolved SHA set to a runtime sidecar (e.g., `<artifact-dir>/.wave-state/wave-N-expected-parents.json`)"), presenting it as illustrative rather than authoritative. The "same dispatch-chain script as the validation" phrasing is functional (co-location requirement) rather than naming a specific script file. The expected fix the reviewer proposes is close to what the design already does, modulo dropping the parenthetical example path. A senior reviewer would treat this as a mild stylistic tightening rather than a load-bearing altitude violation. Real but minor.
