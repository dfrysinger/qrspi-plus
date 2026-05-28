---
finding_id: R6-F01
severity: high
change_type: correctness
referenced_files: [/Users/dfrysinger/Library/CloudStorage/Dropbox/claude-workspace/agent-bravo/docs/qrspi/2026-05-17-v07-release/structure.md:L265-L268, /Users/dfrysinger/Library/CloudStorage/Dropbox/claude-workspace/agent-bravo/docs/qrspi/2026-05-17-v07-release/design.md:L325-L343]
artifact: structure
round: 6
reviewer: quality-codex
---

Slice 7 misroutes the section-anchor index work by tying it to the cache-control failure path: `skills/structure/SKILL.md` is only asked to "Reserve a Section-Anchor Index placeholder pattern for Path-B follow-up" and says "Path-A keeps prefixes stable; no index needed." In the approved design, Path A/Path B only decide whether Claude Agent dispatch already has prompt caching or needs cache-control markers; Mechanism B, the section-anchor index for narrow Reads, is a separate accepted mechanism that Structure/Plan must shape independently of the cache-probe result. As written, a successful cache probe would skip the narrow-Read/index component entirely, contradicting the design's "Use two complementary mechanisms" decision. Fix the Slice 7 file map so Structure defines the section-anchor index/placeholder as the narrow-Read mechanism regardless of the cache probe outcome, while keeping cache-control marker work conditional on the spike result.
