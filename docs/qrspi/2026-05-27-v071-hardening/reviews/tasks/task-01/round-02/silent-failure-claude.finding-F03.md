---
reviewer: silent-failure-claude
task: 1
round: 2
finding: F03
severity: low
change_type: correctness
status: pending
model: claude-sonnet-4.6
persistence_note: Claude returned findings inline. Orchestrator manually persisted.
referenced_files:
  - scripts/run-third-party-llm.sh
---

## NUL pre-flight die message says "in header configuration" but scans the entire config.md file body

**Location:** `scripts/run-third-party-llm.sh`, line 601

The scan `wc -c < "$CONFIG_MD"` reads **every byte** of the file — the YAML frontmatter AND all document body content (prose, headings, diagrams below the second `---`). Any NUL byte anywhere in the file triggers the die path saying **"in header configuration"**.

**Category:** Inappropriate Error Transformation. An accurate detection event (NUL present) paired with a misleading location claim. An operator inadvertently adding a binary attachment in the document body would waste diagnostic time auditing the `providers:` block.

**Note on scope overlap with round-01 spec-gpt55 F01:** spec-gpt55 F01 flagged that the NUL die message doesn't name the offending header (architecturally impossible for file-scope scan). This finding is orthogonal: the message's *section attribution* ("header configuration") is broader than what the file-scope scan can actually localize.

**Suggested fix:** Change the die message to accurately reflect the file-scope nature:
```bash
die "header-validation: config.md for provider '$PROVIDER' contains NUL bytes (raw byte scan of entire file); NUL in header values is rejected because bash strips NUL at variable assignment"
```
