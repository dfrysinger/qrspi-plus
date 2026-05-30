---
status: draft
question_ids: [14]
research_type: codebase
---

# Q14: Explicitness of per-task review section in `skills/implement/SKILL.md` for scope-tagger dispatch, `round-NN.diff` emission, `round-NN-commit.txt` anchor capture, and ref-selection (step 12)

## Summary

**TL;DR:** The per-task review section in `implement/SKILL.md` (primarily `## Per-Task Execution` and `### Per-Task Convergence Narrowing`) uses a hybrid model: it inlines the per-task-specific paths, bash commands, and fail-loud diagnostics, but explicitly defers the authoritative convergence-rule table and the full fail-loud diff-emission preconditions to `using-qrspi/SKILL.md § Standard Review Loop`. The section is not self-contained; a reader must have loaded the Standard Review Loop from `using-qrspi` to know the actual narrow/broaden decision rules.

**Key findings:**
- **`round-NN.diff` emission**: The orchestrator copy-paste bash command is inlined at `implement/SKILL.md:899–906`. However, the fail-loud precondition sequence (git ls-files check, mkdir-p, rm-f, quoted placeholders, exit-code check) is explicitly delegated to `using-qrspi/SKILL.md § Standard Review Loop step 1` by reference (`implement/SKILL.md:919`).
- **Scope-tagger dispatch (step 6)**: The `### Per-Task Convergence Narrowing` section (`implement/SKILL.md:1199–1207`) inlines the per-task parameter substitutions (`round_subdir`, `output_path`, `step`, `artifact_path/artifact_body = null`, `kept_findings`), but opens with "The dispatch shape mirrors using-qrspi step 6 (scope-tagger dispatch) with these per-task parameter substitutions" — the full dispatch shape lives only in `using-qrspi`.
- **`round-NN-commit.txt` anchor capture**: The most self-contained of the four. `implement/SKILL.md:1188` inlines the exact bash command (`git -C ".worktrees/{slug}/task-NN/" rev-parse HEAD > "<ABS_ARTIFACT_DIR>/reviews/tasks/task-NN/round-NN-commit.txt"`), the fail-loud diagnostic string, and the HEAD-advanced verification protocol (`implement/SKILL.md:1190–1197`). No cross-reference to `using-qrspi` for these details.
- **Ref-selection (step 12)**: `implement/SKILL.md:1209` inlines the per-task broaden default (`<ref>=<task-base-commit>` vs. the artifact-level `<base-branch>`), the anchor-assertion flow, backward-loop flag behavior, and rounds-1-and-2 always-broaden rule. However, the convergence-rule table itself (equal/proper-subset → narrow; superset/partial-overlap/disjoint → broaden; `<full>` in either set → broaden; either set empty → broaden) is not reproduced — it is referenced as "the convergence-rule table from using-qrspi step 12 (ref selection)". The I10 distinguishability diagnostic rule is similarly deferred.
- **Opening declaration**: `implement/SKILL.md:1186` explicitly states "Per-task review rounds reuse the convergence machinery from `using-qrspi/SKILL.md` § Standard Review Loop steps 6 / 11 / 12", establishing the cross-reference relationship as the design intent.
- **`scope_hint` wiring in reviewer dispatch**: `implement/SKILL.md:929` names `scope_hint` in the per-task reviewer dispatch template but conditions its inclusion on "using-qrspi step 12 (ref selection) narrowed for this round" — the triggering condition is defined only in the referenced skill.

**Surprises:** The `round-NN-commit.txt` anchor-capture prose (`implement/SKILL.md:1188–1197`) is substantially self-contained with inlined bash commands and detailed HEAD-advanced verification steps, while the other three elements all explicitly reference `using-qrspi`. This creates an asymmetry: the commit-anchor step can be understood from `implement/SKILL.md` alone, but the scope-tagger dispatch shape, the diff-emission preconditions, and the convergence-rule table cannot.

**Caveats:** The analysis is limited to the prose text of the two SKILL.md files as they exist on disk. Runtime agent behavior (whether agents actually load `using-qrspi/SKILL.md` transitively) was not investigated.

## Full findings

### Scope of investigation

The question asks about the `## Per-Task Execution` section of `skills/implement/SKILL.md` (1,562 lines) and its relationship to `skills/using-qrspi/SKILL.md` (1,260 lines), specifically the `## Standard Review Loop` section of the latter. The four sub-topics are: scope-tagger dispatch, `round-NN.diff` emission, `round-NN-commit.txt` anchor capture, and ref-selection (step 12).

---

### 1. `round-NN.diff` emission

**Inline content** (`implement/SKILL.md:899–906`, within `### Reviewer Dispatch Template`):

The orchestrator copy-paste section gives the exact bash command inline:

```sh
git -C ".worktrees/{slug}/task-NN/" diff "<ref>" \
  > "<ABS_ARTIFACT_DIR>/reviews/tasks/task-NN/round-NN.diff"
```

with the note: "`<ref>` resolution is documented in § Pre-dispatch diff-file emission above."

**Cross-reference to `using-qrspi`** (`implement/SKILL.md:919`, § `Pre-dispatch diff-file emission`):

The more complete prose paragraph states the orchestrator "follows the fail-loud diff-emission contract in `using-qrspi/SKILL.md` § Standard Review Loop step 1 (preconditions: artifact tracked in git via the worktree's `git -C` clause, mkdir-p, rm-f, quoted placeholders, exit-code check)."

The five-step precondition sequence from `using-qrspi/SKILL.md:680–687` (git ls-files check, mkdir-p with stderr capture, rm -f leaf overwrite, git diff with quoted placeholders, exit-code check) is **not** reproduced inline in `implement/SKILL.md`; it is delegated by reference.

**Conclusion**: diff emission is **partially inlined** (command) + **referenced** (preconditions).

---

### 2. Scope-tagger dispatch (step 6)

**Opening cross-reference** (`implement/SKILL.md:1186`):

> "Per-task review rounds reuse the convergence machinery from `using-qrspi/SKILL.md` § Standard Review Loop steps 6 / 11 / 12 (scope-tagger dispatch / per-round commit / ref selection). The contract is identical to the artifact-level flow; only paths and the default `<ref>` differ."

**Inline per-task parameter substitutions** (`implement/SKILL.md:1199–1207`, `### Per-Task Convergence Narrowing` → **Step 6**):

The section inlines five per-task-specific substitutions:
- `round_subdir`: `<ABS_ARTIFACT_DIR>/reviews/tasks/task-NN/round-NN/`
- `output_path`: `<ABS_ARTIFACT_DIR>/reviews/tasks/task-NN/round-NN-scope-set.txt`
- `step`: `implement-per-task`
- `artifact_path` / `artifact_body`: both literal `null` (multi-file → file-path tags)
- `kept_findings`: newline-separated absolute paths to `*.finding-*.md` files from the round

It also repeats the structural-validation guard ("a malformed scope-set file present-on-disk routes through the verifier-round failure menu") and a `full-artifact > 0` diagnostic sentence.

**Not inlined**: The full `qrspi-scope-tagger` dispatch shape, the tagger's input/output schema, and the scope-set structural validation rule set live in `using-qrspi/SKILL.md:923–994`. `implement/SKILL.md` says "The dispatch shape mirrors using-qrspi step 6 (scope-tagger dispatch) with these per-task parameter substitutions" — acknowledging the delta-only nature of the inline content.

**`scope_hint` wiring in reviewer dispatch template** (`implement/SKILL.md:929`):

The per-task Claude reviewer dispatch template names the parameter but conditions its inclusion on "`using-qrspi` step 12 (ref selection) narrowed for this round" — the triggering condition and the wrapping format are defined only in `using-qrspi`.

**Conclusion**: scope-tagger dispatch is **delta-inlined** (per-task substitutions) + **referenced** (full dispatch shape).

---

### 3. `round-NN-commit.txt` anchor capture

**Inline content** (`implement/SKILL.md:1188–1197`, `### Per-Task Convergence Narrowing`):

This is the most self-contained of the four topics. The section provides:

- The exact bash command:
  ```
  git -C ".worktrees/{slug}/task-NN/" rev-parse HEAD > "<ABS_ARTIFACT_DIR>/reviews/tasks/task-NN/round-NN-commit.txt"
  ```
- The one-line 40-char SHA + trailing newline format
- The rationale (step 12's narrow decision reads this file before setting `<ref>=HEAD~1`)
- Fail-loud behavior with the diagnostic string: `"Per-round commit anchor capture failed for task NN round NN: <stderr>"`
- Two-part HEAD-advanced verification:
  1. **Reported-SHA reconciliation** — compare `commit_sha:` field from implementer's DONE report against `git rev-parse HEAD`
  2. **Round-base distinctness** — compare HEAD against the round's base SHA (from `round-(NN-1)-commit.txt` for rounds ≥ 2)

The verification protocol at `implement/SKILL.md:1190–1197` includes both checks, abort messages, and recovery path language, all inline.

**Cross-reference to `using-qrspi`**: None for the capture/verification step itself. The section references `using-qrspi` only in the opening sentence (`implement/SKILL.md:1186`) establishing that the convergence machinery overall derives from `using-qrspi` steps 6/11/12.

The analogous `using-qrspi/SKILL.md:995` states "Capture the per-round commit SHA (per-round commit anchor for step 12)… into `reviews/{step}/round-NN-commit.txt`" — but `implement/SKILL.md` does not forward-reference or defer to this passage; it re-states the equivalent rules inline with per-task paths substituted.

**Conclusion**: `round-NN-commit.txt` anchor capture is **primarily inlined**.

---

### 4. Ref-selection (step 12)

**Inline per-task content** (`implement/SKILL.md:1209–1213`):

The `### Per-Task Convergence Narrowing` → **Step 12** paragraph inlines:
- The path substitutions: comparing `reviews/tasks/task-NN/round-NN-scope-set.txt` against `reviews/tasks/task-NN/round-(NN-1)-scope-set.txt`
- The per-task broaden default: `<ref>=<task-base-commit>` (not `<base-branch>` — the critical per-task distinction)
- The narrow decision: `<ref>=HEAD~1`, contingent on an anchor assertion
- The anchor assertion: read SHA from `reviews/tasks/task-NN/round-(NN-1)-commit.txt`, run `git -C ".worktrees/{slug}/task-NN/" rev-parse HEAD~1`, compare; if they differ, fall through to broaden with a named diagnostic
- Rounds 1 and 2 always-broaden rule
- Missing-scope-set / `scope_tagger_enabled=false` short-circuit
- Backward-loop flag behavior (consume-once, reset to `<task-base-commit>`)
- `$SCOPE_HINT` population logic

**Cross-reference to `using-qrspi`**: The convergence-rule table is explicitly referenced but not reproduced: "compare… using the convergence-rule table from using-qrspi step 12 (ref selection) (equal/proper-subset → narrow; superset/partial/disjoint → broaden; either set empty → broaden; `<full>` ∈ either set → broaden)". This parenthetical quotes the table's outcomes, but the full table definition with its intermediate cases and tie-breaking rules lives only in `using-qrspi/SKILL.md:1001–1040`.

The I10 distinguishability rule (missing-scope-set diagnostics distinguishing cause) is deferred: "apply the I10 distinguishability rule from using-qrspi step 12 (ref selection) substituting the per-task paths."

**Reviewer dispatch template references step 12** (`implement/SKILL.md:929`): The `scope_hint` parameter in the per-task reviewer dispatch is conditionally included "ONLY when using-qrspi step 12 (ref selection) narrowed for this round" — the decision is managed by step 12, not by anything local to the dispatch template.

**Conclusion**: ref-selection (step 12) is **heavily inlined** for per-task specifics, but **references** `using-qrspi` for the canonical convergence-rule table and the I10 diagnostic rule.

---

### Overall structure: inline vs. reference

| Sub-topic | Inlined in `implement/SKILL.md` | Delegated to `using-qrspi` |
|-----------|--------------------------------|---------------------------|
| `round-NN.diff` emission | Bash command (`implement/SKILL.md:899–906`), brief per-task recap (`implement/SKILL.md:919`) | Fail-loud precondition sequence (5 steps), `using-qrspi:680–687` |
| Scope-tagger dispatch (step 6) | 5 per-task parameter substitutions (`implement/SKILL.md:1199–1207`); structural-validation guard summary | Full dispatch shape, schema, validation rule set (`using-qrspi:923–994`) |
| `round-NN-commit.txt` anchor capture | Full bash command, format, rationale, fail-loud diagnostic, HEAD-advanced verification (both checks) (`implement/SKILL.md:1188–1197`) | None (most self-contained of the four) |
| Ref-selection (step 12) | Per-task paths, broaden default, anchor assertion, rounds-1-2 rule, backward-loop flag, `$SCOPE_HINT` population (`implement/SKILL.md:1209–1213`) | Convergence-rule table, I10 distinguishability rule (`using-qrspi:1001–1040`) |

**The section's own opening statement** (`implement/SKILL.md:1186`) makes the design intent explicit: "Per-task review rounds reuse the convergence machinery from `using-qrspi/SKILL.md` § Standard Review Loop steps 6 / 11 / 12." This signals that the per-task section is a **delta specification** layered on top of the Standard Review Loop, not a standalone description. A reader who has not loaded `using-qrspi/SKILL.md` would know the bash commands and per-task paths but would lack the convergence-rule table (the core decision logic of step 12) and the complete fail-loud diff-emission preconditions.
