---
finding_id: R2-F01
severity: medium
change_type: clarity
referenced_files: [docs/qrspi/2026-05-17-v07-release/phasing.md:L75, docs/qrspi/2026-05-17-v07-release/future-design.md:L39-L46]
artifact: phasing
round: 2
reviewer: quality-claude
---

The Slice 3 replan-gate criterion at phasing.md line 75 contains the parenthetical "(Full resolution context lives in future-design FD-02.)" This makes the criterion not fully self-contained: a reader checking the replan gate cannot determine what "re-validates the ban-list is current by execution test against new bash-4 constructs as authors add them" means in practice without consulting the future-design file.

The reference to FD-02 is load-bearing: FD-02 in `future-design.md` (lines 39–46) documents that the design-level test fixture used to demonstrate the Option A vs Option B distinction was incorrect — the chosen example construct `${!array[@]}` is valid in bash 3.2+, not actually bash-4-only. FD-02 recommends rewriting the criterion to assert the contrapositive ("Option B's ban-list is the load-bearing list of forbidden constructs; Option A is a backstop that re-validates the ban-list is current by execution test against a future bash-4 construct authors add to the ban-list"). Since FD-02 was deferred, the current criterion in phasing.md reflects the pre-correction wording and forwards the reader to a future artifact to understand what the criterion is actually asserting.

Replan-gate criteria must be "checkable without ambiguity" per the phasing quality check. A criterion that off-loads its "full resolution context" to a deferred future-design entry does not meet that bar on its own.

Resolution: replace the parenthetical with an inline, self-contained statement of what the criterion asserts. The FD-02 rewrite is the right direction — something like: "Option B's ban-list is the load-bearing list of forbidden constructs that prevents bash-4 constructs from entering the project; the bash-3.2 runtime job is a backstop whose job is to catch any bash-4 construct that a future author adds to the ban-list, thereby confirming the ban-list stays current. Both the ban-list and the runtime backstop are verifiable in CI output." The future-design reference can then be dropped from the replan-gate criterion because the criterion is self-contained.
