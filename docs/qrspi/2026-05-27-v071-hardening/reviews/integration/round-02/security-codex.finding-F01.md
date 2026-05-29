---
finding_id: R2-F02
severity: medium
change_type: security
referenced_files: [agents/qrspi-test-writer.md, skills/implementer-protocol/SKILL.md]
artifact: integration
round: 2
reviewer: security-codex
---

## Added skills:[implementer-protocol] preload introduces conflicting wider directives

**Surface:** `agents/qrspi-test-writer.md:6`, `skills/implementer-protocol/SKILL.md:240`, `:248-249`

The round-01 fix added `skills: [implementer-protocol]` to test-writer frontmatter to close R1-F04 (preload symmetry with implementer). The preload pulls in two directives that contradict the test-writer's HARD CONSTRAINT block (lines 13-31):

1. **`git -C <worktree> add -A`** at `implementer-protocol/SKILL.md:240` (Commit Before Reporting procedure step 3)
   - vs. test-writer line 22: "`git add <test-file-paths>` (only); never `git add -A`"
   - Risk: LLM could stage non-test files (production code, secrets, scratch artifacts) into the RED commit.

2. **Write `reviews/tasks/task-NN/round-NN-implementer.md`** at `implementer-protocol/SKILL.md:248-249` (On-disk full report)
   - vs. test-writer line 17: "writes only files under `tests/` or with test-suffix conventions"
   - Risk: LLM could write outside its file-modification scope.

Both conflicts are prompt-layer only (the tool layer doesn't enforce path containment), so an LLM that follows the preloaded protocol blindly would broaden the test-writer's intended surface.

**Why integration-emergent:** R1-F04 reviewer recommended the preload without checking whether the skill body's directives matched the test-writer's HARD CONSTRAINT envelope. The fix-task-01 spec implemented exactly what was asked; the conflict is in the original finding's incomplete scope analysis.

**Suggested fix (one of):**

A. **Revert preload, inline restatement.** Remove `skills: [implementer-protocol]` from frontmatter; instead expand line 76 of test-writer body to inline the specific bits of implementer-protocol scratch-file pattern that apply (write/commit/rm sequence + "stage only your authored files" restated for test-writer's scope). This is the least-invasive fix and removes the conflict entirely.

B. **Keep preload, add explicit supersedes block.** Add a one-paragraph block in test-writer body immediately after the HARD CONSTRAINT block: "The HARD CONSTRAINT block above supersedes any wider directives in preloaded skills. In particular: ignore `git add -A` in implementer-protocol; ignore the `reviews/tasks/...` write directive; use only `git add <test-file-paths>` and write only under `output_dir`."

Option A is preferred — fewer prompt directives is generally better than more, and the test-writer never actually needed the full implementer-protocol body (only the scratch-file pattern's three lines).

**Process gap surfaced (worth filing):** the R1-F04 reviewer (integration-claude) suggested a preload without checking the preloaded skill's directives against the consumer agent's narrower scope envelope. This is a reviewer-side scope check that should be part of any "add `skills:` preload" recommendation.
