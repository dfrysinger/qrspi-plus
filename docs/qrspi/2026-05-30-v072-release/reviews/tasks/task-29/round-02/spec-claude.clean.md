---
reviewer: spec-claude
task: 29
round: 2
status: clean
---

# Spec Reviewer — Task 29 Round 2 — Clean

R1 F01 demanded two structural assertions in
`tests/lint/test-design-altitude-boundary-include.bats`:

1. **Adjacency check** between the introducer prose and the `!cat`
   directive in `agents/qrspi-design-scope-reviewer.md`.
2. **No-residual-body check** in `skills/design/owns-defers.md`
   confirming the previous inline OWNS/DEFERS body has not been
   reintroduced alongside the `!cat` include.

Both assertions are now present and correctly scoped:

- Adjacency check: lines 136–155 of the bats file extract the line
  numbers of the literal introducer prose and the literal `!cat`
  directive via `grep -nF … | head -n1 | cut -d: -f1`, then enforce
  `(( directive_line != introducer_line + 1 ))` with a diagnostic
  naming the file, both observed line numbers, and the required
  invariant. Verified against the agent file: the introducer prose
  sits on the line immediately preceding the `!cat` directive
  (diff lines 9–10 of `agents/qrspi-design-scope-reviewer.md`), so
  the check passes for the current artifact and would fail on drift.

- No-residual-body check: lines 157–180 of the bats file enumerate
  six inline-body patterns (`^### Design OWNS`, `^### Design DEFERS`,
  `^Design OWNS:`, `^Design DEFERS:`, `\*\*Design OWNS:\*\*`,
  `\*\*Design DEFERS:\*\*`) and fail with a file-and-pattern-naming
  diagnostic if any match. The patterns are grepped against the
  consumer source (not the expanded include), correctly avoiding
  false positives from headings inside the shared snippet, and the
  test docstring calls out this distinction explicitly.

Other spec items spot-checked and confirmed:

- All four target files touched, no out-of-scope edits in the diff.
- `skills/_shared/design-altitude-boundary.md` carries one contiguous
  `### What Design OWNS` block followed by one contiguous
  `### What Design DEFERS` block, with the OWNS allowances and
  DEFERS exclusions named in the task spec (detailed solutions,
  edge cases, flows, prompt-writing specifics, acceptance examples,
  per-solution diagrams, naming/rename inventory, phasing labels in
  OWNS; implementation bodies, full test code, executable shell,
  file architecture, unified architecture/test strategy, task
  carving in DEFERS).
- `skills/design/owns-defers.md` retains its surrounding structure
  (intro paragraph, phasing pointer, change_type sentence) and
  replaces the inline body with the literal `!cat` directive.
- `agents/qrspi-design-scope-reviewer.md` carries the exact
  introducer prose on the line immediately after the Step 1 Read
  citation, followed by the literal `!cat` directive on the next
  line.
- Two bats tests at lines 118–134 already enforce literal-directive
  presence in both consumers with file-and-directive-naming
  diagnostics, satisfying the DoD bullet for removal-fails-lint.

No spec-completeness, scope, interpretation, test-coverage, extra-
features, or target-files-deviation findings.
