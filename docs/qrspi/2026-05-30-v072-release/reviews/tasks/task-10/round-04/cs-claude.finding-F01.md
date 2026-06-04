---
finding_id: R4-F01
severity: low
change_type: style
referenced_files: [tests/acceptance/v07-phase1/test-phase1-acceptance.bats]
---

# AC1/AC2/AC3 duplicate unit-test prose pins

The three new acceptance-test blocks `[AC1]`, `[AC2]`, and `[AC3]` are pure grep-on-agent-file checks that are already exercised — more precisely — by the unit tests in `test-verified-file-shape.bats`. The unit tests cover the same agent file greps with narrower scope (awk-sliced context vs. whole-file search). The acceptance suite's comparative advantage is the behavioral tests in AC4 (fan-in script integration) and AC5 (YAML template parse + field shape), not static-doc pins. Removing AC1–AC3 from the acceptance file and pointing to the unit file eliminates the duplication without losing any coverage.
