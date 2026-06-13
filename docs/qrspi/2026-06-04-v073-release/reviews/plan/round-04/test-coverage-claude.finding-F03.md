---
finding_id: R4-F03
severity: medium
change_type: correctness
referenced_files: ["docs/qrspi/2026-06-04-v073-release/plan.md:L225-L227"]
artifact: plan
round: 4
reviewer: test-coverage-claude
---

T03's test expectations use a wildcard glob and a forward reference that leaves output filenames unspecified. Line 225: "one bats fixture per step asserts the expected files appear at `<artifact-dir>/reviews/<step>/round-NN.*`" — the `.*` wildcard is not a testable file path. A bats assertion requires an exact filename: `[ -f "$ARTIFACT_DIR/reviews/plan/round-01.diff" ]` cannot be written without knowing the extension. Line 226: "A `--step plan` fixture asserts the absorption-map is written to the expected path for the plan-spec reviewer to consume" — "the expected path" is never defined anywhere in T03, T16, or T17a; no test expectation names a concrete filename like `round-01-absorption-map.txt` or `round-01.absorption-map`. The one-sentence behavior claim in the overview table (line 27) also uses the glob `round-NN.*`. The test writer has to either invent the filename or read the implementation to discover it — both defeat the purpose of having plan-level test expectations. The test expectations should specify the exact output filenames for at least the diff case (e.g., `round-NN.diff`) and the absorption-map case.

