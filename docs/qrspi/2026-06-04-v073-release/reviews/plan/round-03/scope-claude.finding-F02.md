---
reviewer: scope-claude
artifact: plan.md
round: 3
finding_id: F02
severity: blocking
change_type: scope
location: plan.md § T03 (Create scripts/review-prep.sh …) — Description and Test Expectations
---

# F02 — T03 flips the design.md CD-2 silent-on-no-input contract to fail-loud-with-opt-in-flag

## What the artifact does (round-3 diff, plan.md T03)

T03's Description was substantially extended in round 3 with new contract surface that did not exist in round 2:

> "The default branch on 'artifact-dir not in a git repo' or 'git diff produced no output when a diff was expected' is fail-loud: the script exits non-zero with the named diagnostic `review-prep-no-diff-source:` (artifact-dir not a git working tree) or `review-prep-empty-diff:` (git diff returned no output for a step that requires one). The legitimate fixture-only 'silent empty output' shape is opt-in via an explicit `--allow-empty-no-diff` flag — without that flag, the production-default direction halts loud. … dispatch-agent (T04a) is the sole orchestrator-visible caller and never passes `--allow-empty-no-diff` for a real review round."

Three coordinated test expectations were added to lock the new direction:

> "Production-default invocation (no `--allow-empty-no-diff` flag): artifact-dir not in a git repo halts non-zero with the `review-prep-no-diff-source:` named diagnostic; a step that requires a diff but `git diff` produced no output halts non-zero with the `review-prep-empty-diff:` named diagnostic — neither condition silently degrades (silent-claude R2-F01 fail-loud direction)."
> "Fixture-only invocation with the explicit `--allow-empty-no-diff` flag: the legitimate non-git fixture case emits no files and exits 0 (preserves the test-fixture surface that R2-F01 carved out via opt-in)."

And T04a gained a paired-coverage expectation:

> "A production-default high-level invocation against an artifact-dir not in a git repo halts non-zero with review-prep's `review-prep-no-diff-source:` named diagnostic on stderr — dispatch-agent does NOT silently proceed with a missing diff path (silent-claude R2-F01 paired-coverage assertion with T03)."

## Why this is a scope finding

`docs/qrspi/2026-06-04-v073-release/design.md` CD-2 § Dependencies + edge cases (line 48, status: approved) explicitly mandates the opposite direction:

> "Edge case — `review-prep.sh` invocation when there is nothing to produce (e.g. an artifact-step that has no diff because the artifact is not in a git repo): **the script emits no files for that step and exits 0**. dispatch-agent omits the corresponding `*_path:` parameter from the dispatch prompt. **Same fail-loud-on-real-error / silent-on-no-input shape as the existing diff-emission contract in `using-qrspi/SKILL.md`.**"

Plan T03 is unilaterally:

1. Reversing the design-approved direction — flipping "silent-on-no-input + exits 0" to "fail-loud-with-named-diagnostic + non-zero exit" as the production default.
2. Introducing a new flag (`--allow-empty-no-diff`) to the script's interface contract to carve a fixture-only escape valve from the new default.
3. Defining two new contract-level named diagnostics (`review-prep-no-diff-source:`, `review-prep-empty-diff:`) the design.md edge-case prose does not name.
4. Adding a paired-coverage T04a assertion that locks dispatch-agent's high-level mode to the new direction.

Per `skills/plan/owns-defers.md`, **"Architecture decisions, key trade-offs, system diagrams" → `design.md` (locked upstream; Plan consumes, does not re-author)** and **"Function signatures, type definitions, parameter shapes" → `structure.md`** (the new `--allow-empty-no-diff` flag is a script interface contract). Both layers are crossed: Plan re-authors the design-level edge-case direction AND adds a structure-level flag surface.

## Plan-internal inconsistency with T01

T01's round-3 Author note correctly refused the symmetric move for silent-claude R01-F03:

> "Addressing it would require a design.md amendment changing CD-1 Acceptance bullet 2 from fail-soft to fail-loud; the approved design currently mandates the fail-soft direction… This plan honours the design contract and does not introduce a plan-side workaround. Re-opening the contract is a Design-phase decision, not a Plan-phase one."

The silent-claude R2-F01 → T03 situation is structurally identical to the silent-claude R01-F03 → T01 situation: a silent-reviewer finding asks for a direction reversal against a design-approved edge-case behavior; closing it requires a design.md amendment. T01 refused; T03 accepted and built the contract. The same reasoning that justifies T01's deferral applies to T03.

## Recommended remediation (Plan-layer)

Either:

(a) Drop T03's fail-loud direction additions: restore the round-2 description (silent-on-no-input + exit 0 per design.md CD-2); remove the `review-prep-no-diff-source:` / `review-prep-empty-diff:` diagnostics; remove the `--allow-empty-no-diff` flag; drop the matching T04a paired-coverage expectation; add a T03 Author note analogous to T01's, deferring silent-claude R2-F01 to a Design-phase re-open of CD-2's edge-case prose. OR

(b) Block T03 + T04a on a design.md amendment (BLOCKED status until CD-2's edge-case prose is updated and re-approved); once design.md owns the new direction, T03 and T04a's test expectations reference design.md as the authority and the new contract flows down through Structure (flag surface) and Implement (diagnostic literals).

The first option is the closer parallel to the T01 disposition and restores Plan-internal consistency: the round-3 boundary discipline T01's Author note set should apply uniformly across every silent-claude finding that asks Plan to re-open a design-approved direction.
