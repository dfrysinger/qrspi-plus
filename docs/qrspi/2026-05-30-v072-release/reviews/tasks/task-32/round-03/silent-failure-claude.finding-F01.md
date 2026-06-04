# F01 — Synthesis subagents omit incremental draft; compaction durability silently broken

**Severity:** critical
**Category:** Missing input / silent contract violation
**Files:** `skills/design/SKILL.md:330-335`, `skills/goals/SKILL.md:219-221`

Both skills now declare on-disk draft as the single source of truth across compaction. The resume procedure correctly reads the draft on resume. But the end-of-phase synthesis subagent's input list does NOT include the incremental draft — only conversation summary + supporting artifacts. After a mid-phase /compact + resume, the synthesis subagent sees only post-compaction conversation (G16+) and silently drops pre-compaction decisions (G1-G15). No error, no diagnostic.

**Required fix:** Add the existing incremental draft as a required synthesis subagent input AND a synthesis instruction to MERGE the draft with new conversation content rather than re-synthesize.
