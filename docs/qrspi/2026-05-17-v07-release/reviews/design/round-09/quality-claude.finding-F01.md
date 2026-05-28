---
finding_id: R9-F01
severity: medium
change_type: correctness
referenced_files: [docs/qrspi/2026-05-17-v07-release/design.md:L957-L968]
artifact: design
round: 9
reviewer: quality-claude
---

Decision 7 misclassifies the G12 BATS pin as a markdown-extraction consumer of G14's helper.

Decision 7 lists six v0.7 BATS pins that depend on G14's `tests/helpers/skill-markdown.bash` helper:

> - G8 owns-defers check.
> - G9 vocabulary check.
> - G11 reviewer-protocol quick-tier wording check.
> - G12 commit-procedure check.
> - G15 Replan boundary check.
> - G18 evergreen check.

But the G12 BATS pin described in the G12 section (lines 583, 596–599) is not a markdown section-extraction check. The G12 test "simulates an implementer commit cycle and asserts the resulting tree contains no `.qrspi-commit-msg.txt` blob and the worktree's `.git/info/exclude` carries the entry." It runs a git workflow and inspects working-tree/repo state — nothing in that surface needs the helper's H2/H3 section-extraction-with-awk machinery.

This matters for Phasing/Plan: G12 currently inherits a G14 sequencing dependency that does not actually exist. If Phasing orders G14 before G12 on the strength of Decision 7, that's harmless; but if a later Phasing review tries to parallelize G12 with G14 it may be blocked unnecessarily, and if a future replan re-derives dependencies from Decision 7 the false-positive coupling propagates.

G11's listing as a consumer is also worth a second look — the G11 quick-tier-wording check at line 548 reads as a single content-presence check that may or may not need section extraction depending on how it's implemented — but G11 has other markdown extraction surfaces (e.g. checking that `agents/qrspi-visual-fidelity-reviewer.md` consumes the new fields) so G11 plausibly is a helper consumer overall. G12 has no such other surface.

Suggested fix: remove G12 from Decision 7's helper-consumer enumeration (and from the parallel enumeration in G14's "Dependency note" at lines 660–661), leaving G8, G9, G11, G15, and G18 as the markdown-extraction consumers.
