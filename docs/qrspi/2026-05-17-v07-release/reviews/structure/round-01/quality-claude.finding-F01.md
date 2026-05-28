---
finding_id: R1-F01
severity: medium
change_type: correctness
referenced_files: [docs/qrspi/2026-05-17-v07-release/structure.md:L477-L481]
artifact: structure
round: 1
reviewer: quality-claude
---

The architectural diagram's G14 helper arrows carry a label that inverts the dependency direction and misidentifies which entities source the helper. The arrows in question read:

```
SkillMdHelper -.sourced by.-> ParallelizeOwns
SkillMdHelper -.sourced by.-> ParallelizeSkill
SkillMdHelper -.sourced by.-> ReplanSkill
SkillMdHelper -.sourced by.-> ReviewerProtocolQuick
SkillMdHelper -.sourced by.-> TestWriter
```

Arrow direction in Mermaid `A --> B` means "A points to B." Combined with the label "sourced by," a downstream agent reads this as "`SkillMdHelper` is sourced by `ParallelizeOwns`," i.e., `skills/parallelize/owns-defers.md` pulls in `tests/helpers/skill-markdown.bash`. That is wrong: Markdown skill files do not source BATS bash libraries.

The design (§G14, Decision 7) is clear: `skill-markdown.bash` is a BATS helper sourced by BATS test files, not by skill or agent markdown files. The canonical G14 dependent set is the BATS test pins for G8, G9, G11, and G15. None of `skills/parallelize/owns-defers.md`, `skills/parallelize/SKILL.md`, `skills/replan/SKILL.md`, `skills/reviewer-protocol/SKILL.md`, or `agents/qrspi-test-writer.md` source the bash helper — their respective BATS test files do.

Additionally, `TestWriter` in the diagram refers to `agents/qrspi-test-writer.md` (the agent file), which does not consume `skill-markdown.bash` at all. The design (§G14 Dependency note) explicitly excludes G6 from the G14 helper's canonical consumer set; only the BATS test for the test-writer dual-mode contract (`tests/unit/test-test-writer-dual-mode.bats`) uses the helper.

A Plan or Implement agent reading this diagram will misunderstand the runtime dependency: it may believe skill files import a bash library, or create spurious task dependencies trying to make skill files "source" the helper.

Fix: reverse the arrow direction and update the label. Each dependency arrow should read `<BatsTestFile> -.uses.-> SkillMdHelper` with the arrow pointing FROM the BATS test file TO the helper, OR remove these arrows from the diagram entirely since the file map already records which BATS tests use `skill-markdown.bash` in the Responsibility column. If kept, the five arrows should reference the BATS test files (e.g., `test-parallelize-owns-defers.bats`, `test-parallelize-vocab.bats`, `test-replan-boundary-with-goals.bats`, `test-quick-tier-wording.bats`, `test-test-writer-dual-mode.bats`), not the skill or agent files.
