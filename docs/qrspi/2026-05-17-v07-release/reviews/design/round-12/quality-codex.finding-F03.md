---
finding_id: R12-F03
severity: medium
change_type: correctness
referenced_files: [/Users/dfrysinger/Library/CloudStorage/Dropbox/claude-workspace/agent-bravo/docs/qrspi/2026-05-17-v07-release/design.md:L179-L186, /Users/dfrysinger/Library/CloudStorage/Dropbox/claude-workspace/agent-bravo/docs/qrspi/2026-05-17-v07-release/research/summary.md:L142-L151]
artifact: design
round: 12
reviewer: quality-codex
---

G4 treats “automatic” prompt caching for Claude Code Agent-tool dispatches as a settled property of the current system, but the cited research only establishes general provider/framework caching patterns, not that QRSPI’s actual Claude-side dispatch path already exposes or benefits from automatic caching at the system-prompt level. Because Mechanism A is justified on that assumption, downstream work could incorrectly scope the task as verification-only instead of implementation-plus-verification. Fix by softening this to an explicit hypothesis (“if Claude Code dispatches already cache stable prefixes, verify hit rates; otherwise add the needed mechanism”) or by citing a concrete QRSPI-specific source that proves the current dispatch path already has this behavior.
