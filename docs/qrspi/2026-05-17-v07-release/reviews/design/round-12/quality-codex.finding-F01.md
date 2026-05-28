---
finding_id: R12-F01
severity: medium
change_type: correctness
referenced_files: [/Users/dfrysinger/Library/CloudStorage/Dropbox/claude-workspace/agent-bravo/docs/qrspi/2026-05-17-v07-release/design.md:L30-L35, /Users/dfrysinger/Library/CloudStorage/Dropbox/claude-workspace/agent-bravo/docs/qrspi/2026-05-17-v07-release/research/summary.md:L10-L18]
artifact: design
round: 12
reviewer: quality-codex
---

G1’s per-agent layer is underspecified in a way that conflicts with the researched runtime surface. The design says agent files should add `model_role:` “so agent files name a role, not a concrete model,” but the research summary says today’s Claude dispatches resolve agent defaults from concrete `model:` frontmatter at agent activation, with only a few documented dispatch-time overrides. As written, downstream implementers could replace concrete agent defaults with role labels without also defining how Claude-side activations get a concrete model at runtime, which would leave part of the routing chain unresolved. Fix by stating explicitly whether `model_role:` is additive metadata alongside a required concrete `model:` fallback, or by defining the activation-time resolver that turns `model_role:` into a concrete `model:` before the agent starts.
