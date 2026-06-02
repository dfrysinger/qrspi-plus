---
status: approved
task: 36
phase: 1
pipeline: full
goal_ids: [G17]
task_type: lightweight
model: sonnet
---

# Task 36: G17 implementer-protocol and test-writer stale-prose cleanup

- **Target files:** modify `skills/implementer-protocol/SKILL.md`; modify `agents/qrspi-test-writer.md`
- **Dependencies:** none
- **LOC estimate:** ~70

**Overview**

Reconcile three stale commit-hygiene prose surfaces after v0.7.1 Wave 1 T2 added `.qrspi-commit-msg.txt` to qrspi-plus's committed root `.gitignore`, preserving runtime behavior and invariant structure. This is documentation-only drift cleanup: the task applies the locked replacement edits and removes false or incomplete pre-T2 claims without expanding scope. (Why: see goals.md ### G17. Approach: see design.md ## G17.)

**Scope**

- **In:**
  - Replace the Invariant 3 rationale sentence in `skills/implementer-protocol/SKILL.md` with the locked design wording that preserves deterministic-status framing while clarifying downstream target repositories do not inherit qrspi-plus's committed `.gitignore` entry.
  - Replace the Commit-Before-Reporting step 4 parenthetical in `skills/implementer-protocol/SKILL.md` with `(keeps the scratch file out of the next round's diff)`.
  - Delete the redundant worktree-local-exclude sentence from the commit ownership bullet in `agents/qrspi-test-writer.md`, leaving the commit / `rm .qrspi-commit-msg.txt` workflow intact.
  - Preserve existing runtime behavior, existing invariant structure, and the existing commit-hygiene invariant tests.

- **Out:**
  - No sibling G17 task owns additional work; G17 does not fan out to other task specs.
  - Adding a new invariant, making the committed `.gitignore` a peer of Invariants 1/2/3, or rewriting Composition — explicitly out of scope.
  - Editing correct target-repo-scoped `.qrspi-commit-msg.txt` mentions in `skills/implement/SKILL.md` — design.md ## G17 says these remain accurate.
  - Changing `agents/qrspi-test-writer.md` L23 / L24 / L77-80 operational references or adding new tests — design.md ## G17 marks these as load-bearing / already covered.

**Definition of done**

- `skills/implementer-protocol/SKILL.md` contains the locked replacement Invariant 3 rationale sentence from design.md ## G17 deliverable 1.
- `skills/implementer-protocol/SKILL.md` contains the locked replacement Commit-Before-Reporting step 4 parenthetical `(keeps the scratch file out of the next round's diff)`.
- `agents/qrspi-test-writer.md` no longer carries the redundant sentence `The worktree-local .git/info/exclude already lists .qrspi-commit-msg.txt.` in the commit ownership bullet, while the commit / removal workflow remains present.
- The stale or false phrases `not gitignored`, `committed .gitignore is not polluted`, and single-layer exclude framing are removed from the edited surfaces.
- No new invariant, Composition rewrite, unrelated target-file edit, runtime behavior change, or test change is introduced.
- The edited prose follows R1-R7 + cross-cutting principles from `skills/_shared/prompt-design-rules.md` (resolved from the installed plugin path per host convention), especially concise wording and positive-substitute framing.

**Test expectations**

- Grep/diff audit of `skills/implementer-protocol/SKILL.md` confirms the two locked replacement edits match design.md ## G17 deliverables 1 and 2.
- Grep/diff audit of `agents/qrspi-test-writer.md` confirms the design.md ## G17 deliverable 3 deletion is applied and the commit / `rm .qrspi-commit-msg.txt` workflow remains.
- Grep audit of the edited surfaces confirms stale prose is absent: `not gitignored`, the old `committed .gitignore is not polluted` rationale, and the redundant single-layer worktree-local exclude sentence.
- Review audit confirms no new invariant, no Composition rewrite, no unrelated `skills/implement/SKILL.md` edits, and no test changes.
- Apply R1-R7 + cross-cutting principles from `skills/_shared/prompt-design-rules.md` (resolved from the installed plugin path per host convention); specifically verify concise shortened wording, positive-substitute current-contract wording, no dialogue-leakage, and no issue-history bloat.

**References**

- goals.md ### G17 — problem framing for stale prose after `.qrspi-commit-msg.txt` entered qrspi-plus's committed root `.gitignore`.
- design.md ## G17 — locked replacement prose, explicit non-goals, and no-new-tests rationale.
- structure.md ### `skills/implementer-protocol/SKILL.md` — per-file block for the two implementer-protocol replacement edits.
- structure.md ### `agents/qrspi-test-writer.md` — per-file block for the test-writer commit ownership sentence deletion.
