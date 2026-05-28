---
finding_id: R1-F09
severity: low
change_type: correctness
referenced_files: [docs/qrspi/2026-05-17-v07-release/plan.md:L1028-L1039]
artifact: plan
round: 1
reviewer: silent-failure-claude
---

T35's `scripts/g4-section-anchor-refresh.sh` test expectations include: "A source artifact containing two H2 headings with identical text causes the script to exit non-zero with a loud diagnostic naming the offending artifact, the duplicate heading text, and the line numbers of the collision, without writing a partial or corrupt index." This correctly specifies the duplicate-heading fail-loud behavior.

However, T35's test expectations do not specify what happens when the manifest file itself is malformed or absent. The script "reads `scripts/g4-section-anchor-manifest.json` from T34" — but there is no test expectation asserting what the script does when:
- The manifest file does not exist (e.g., path drift between T34 and T35)
- The manifest JSON is malformed (parse error)
- A manifest entry points to a source artifact that does not exist

If the manifest is absent or malformed, the script may silently skip all index regeneration (producing exit 0 with no updated indexes) or may fail with an opaque parse-error message that does not identify the manifest as the source of the problem. The downstream T36 tests that read the regenerated indexes would then fail with confusing "index does not reflect the source" errors rather than a clear "manifest was missing or malformed."

The fix is to add test expectations in T35: "Running the script when `scripts/g4-section-anchor-manifest.json` is absent exits non-zero with a loud diagnostic naming the missing manifest file. Running the script with a malformed manifest JSON exits non-zero with a loud diagnostic naming the manifest file and the parse error. Running the script with a manifest entry whose source path does not exist exits non-zero with a loud diagnostic naming the missing source." These three cases close the silent-failure surface on manifest resolution.
