---
finding_id: R4-F04
severity: low
change_type: clarity
referenced_files: ["docs/qrspi/2026-06-04-v073-release/plan.md:L252"]
artifact: plan
round: 4
reviewer: test-coverage-claude
---

T04a's test expectation at line 252 reads: "The low-level `--diff-file <path>` mode remains functional against a fixture (regression guard for tests and non-standard callers)." "Remains functional" is not a testable assertion — a test harness cannot assert "functionalness." The expectation should specify the observable outcome: for example, "exits 0 and produces a dispatch manifest containing a non-empty `diff_file_path:` parameter" or "produces prompt output byte-identical to the pre-T04a low-level mode invocation." Without a concrete observable, the regression guard test is either vacuous (always passes) or relies on an implementer's interpretation that may not match what the reviewer checks. Every other expectation in T04a names a specific observable (byte-equality, parameter presence, stderr verbatim propagation).

