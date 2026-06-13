---
verifier_status: passed
score: 0
actual_model: unknown
reason: "HALLUCINATED: docs/qrspi/2026-06-04-v073-release/parallelization.md has 317 lines, cited L410-L459 out of range"
defect_class: fabricated-citation
---

The finding cites lines L410-L459 of parallelization.md, but the file is only 317 lines long. The cited range is entirely out of bounds, so the citation is hallucinated. Halting per Cite Check.
