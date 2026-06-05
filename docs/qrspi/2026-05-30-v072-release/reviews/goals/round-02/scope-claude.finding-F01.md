---
finding_id: R2-F01
artifact: goals
severity: medium
change_type: scope
referenced_files:
  - docs/qrspi/2026-05-30-v072-release/goals.md
round: 2
reviewer: scope-claude
---

## G17 "What we know so far" provides verbatim solution prose — Design-territory content

### Location
`goals.md` § G17 — Stale prose in implementer-protocol and test-writer, "What we know so far" block (lines ~488–493 of current file).

### Observation
The section provides word-for-word replacement text for three specific line ranges:

- `implementer-protocol/SKILL.md:241` — exact replacement parenthetical quoted in full
- `implementer-protocol/SKILL.md:174-181` — exact Composition bullet to add, quoted verbatim
- `agents/qrspi-test-writer.md:28` — exact rewrite sentence, quoted verbatim

All three are presented under "Candidates Design should weigh (issue body has concrete prose for all three):" — but the content is exact prose-to-substitute at specific line numbers, not a solution idea.

### Rule violated
`owns-defers.md` → **Goals DEFERS: Detailed solution definitions → Design.**

The OWNS rule allows "solution IDEAS… framed as candidates Design should weigh." Providing the exact replacement text for named file/line targets is a detailed solution definition — authoring that text is Design's job, not Goals'.

### Expected correction
Strip the verbatim prose from G17 and replace with the concept-level candidate: "reconcile the three stale prose surfaces to reflect that `.qrspi-commit-msg.txt` is now covered by a committed `.gitignore` in addition to the worktree-local `.git/info/exclude`." Design authors the exact wording.
