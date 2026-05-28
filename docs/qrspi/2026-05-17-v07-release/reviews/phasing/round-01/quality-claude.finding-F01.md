---
finding_id: R1-F01
severity: medium
change_type: correctness
referenced_files:
  - docs/qrspi/2026-05-17-v07-release/phasing.md:L61
  - docs/qrspi/2026-05-17-v07-release/future-design.md:L39-L45
artifact: phasing
round: 1
reviewer: quality-claude
---

The Slice 3 replan-gate criterion for G17 asserts that a fixture script using `${!array[@]}` is "a bash-4+ construct not on Option B's ban-list" and that the bash32 CI job will reject it, thereby "demonstrating Option A' is the load-bearing gate." This claim is factually incorrect: indexed-array key expansion `${!array[@]}` has been valid in bash since version 3.0 and is therefore not a bash-4-only construct. A bash 3.2 runtime would not reject it.

The consequence is that the stated replan-gate criterion is uncheckable as written: if the fixture is run under the `bash:3.2` Docker image, it would pass rather than be rejected, so the gate cannot demonstrate the distinction between Option A' and Option B that the criterion claims.

`future-design.md` FD-02 (surfaced by quality-codex R18-F03) documents this same error at the design level and lists it as a future-design item to resolve before implementation. The phasing replan-gate criterion repeats the error independently, so it requires its own correction regardless of how FD-02 is resolved.

Proposed fix: replace `${!array[@]}` with a genuine bash-4-only construct that is also absent from Option B's ban-list. If the ban-list already covers all known bash-4-only constructs, the criterion should instead be rewritten to assert the contrapositive: "Option B's ban-list is the load-bearing list of forbidden constructs; the bash32 job serves as a backstop that validates the ban-list is current — any future bash-4 construct added to the ban-list will be execution-verified by the bash32 job." This reframing is accurate and still gives an observable criterion for the gate to check.
