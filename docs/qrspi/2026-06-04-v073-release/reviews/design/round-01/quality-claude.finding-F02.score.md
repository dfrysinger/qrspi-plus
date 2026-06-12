---
verifier_status: passed
score: 80
actual_model: unknown
defect_class: copy-paste-error
---
Verified: design.md line 562 in G9's acceptance section names the output artifact as `docs/qrspi/2026-06-04-v073-release/g8-footprint-report.md`. G8 (lines 458-494) is the version-centralization goal with no footprint report; G9 (the surrounding goal) is the footprint reduction goal. The `g8-` prefix is unambiguously a copy/paste error — an implementer following the acceptance bullet verbatim would create a misnamed artifact attributing G9's metric to G8. Cite Check passes: file exists, quoted string present at cited location, anchor (G9 acceptance) present. Real, actionable correctness defect; trivial single-token fix.
