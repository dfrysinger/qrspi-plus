---
finding_id: R15-F01
severity: medium
change_type: correctness
referenced_files: [docs/qrspi/2026-05-17-v07-release/design.md:L844-L848, docs/qrspi/2026-05-17-v07-release/design.md:L1098-L1100]
artifact: design
round: 15
reviewer: quality-codex
---

The design creates an internal contradiction around G18's CI test dependency surface. In G18's dependency notes and Decision 7, it says the evergreen-markdown BATS pin depends on G14's markdown-section helper, but the G18 proposal itself describes a repo-wide regex-style scan over evergreen markdown files, not a section-bounded extraction test. That matters because it changes sequencing and phasing: treating G14 as a hard upstream dependency can force unnecessary ordering for a test that, as currently specified, does not need section extraction at all. Fix: either revise G18 so the planned test actually consumes the helper in a load-bearing way, or drop the stated G14 dependency from G18/Decision 7 and keep only the real dependency on G17's CI surface.
