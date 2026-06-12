---
artifact: design
reviewer_tag: quality-codex
finding_id: quality-codex-F04
change_type: correctness
---

# G6 depends on a "recorded task-tip SHA set" research says does not exist

## Location

design.md L395-397, L404 (G6); research/summary.md L160-168.

## Finding

G6 says parent validation compares actual parents against "the recorded task-tip SHA list (the wave manifest / branch map records this at task-creation time)" and later claims this recording is existing behavior. Research says the Branch Map is symbolic only and resolved SHAs are never written back to the artifact.

## Expected fix

Revise G6 to explicitly design where/when expected task-tip SHAs are captured (likely at merge time from current task branch tips, not task-creation time) and add acceptance coverage for that capture path.
