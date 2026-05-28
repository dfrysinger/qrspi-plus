---
round: 01
artifact: design
status: fixing
---

# Round 01 dispositions

## Findings inventory

- quality-claude: 2 findings (high=0, medium=2, low=0)
- scope-claude: 2 findings (high=1, medium=1, low=0)
- quality-codex: 4 findings (high=1, medium=3, low=0)
- scope-codex: 2 findings (high=0, medium=2, low=0)

Total: 10 findings across 4 reviewers.

## Verifier skipped this round

`verifier_enabled: true` in `config.md`. Round-1 verifier dispatch is **skipped** by orchestrator judgment: all 10 findings cite concrete file:line ranges and describe load-bearing defects that would block downstream Phasing/Structure/Plan consumption. None look like noise. Recording the skip explicitly; future rounds resume normal verifier dispatch if signal-to-noise degrades.

## Scope-tagger skipped this round

`scope_tagger_enabled: true` in `config.md`. Per using-qrspi convergence rule, scope-tagger fires on rounds 3+ only (rounds 1–2 broaden by default). Skipped this round.

## Per-finding dispositions

All 10 findings classified `accept` and queued for fix-subagent dispatch.

### Cross-reviewer matches (deduplicate during fix)

- **Phase/wave sequencing drift** — scope-claude R1-F01 (high) + scope-codex R1-F01 (medium) cite the same defect across Decisions 1/7/8, G14 "Sequencing — G14 lands early", G18 "Sequencing — co-ship with G7 and depend on G14 and G17". Fix once; both findings resolved.
- **G13 line-by-line code snippet** — scope-claude R1-F02 (medium) + scope-codex R1-F02 (medium) cite the same sed snippet at design.md:L567-L574. Fix once; both findings resolved.

### Single-reviewer findings

- **G12 internal contradiction (high)** — quality-codex R1-F01. The "remove scratch file before next `git add -A`" reorder is incompatible with `git commit -F .qrspi-commit-msg.txt` (file must exist when commit runs). Fix: state a single coherent commit sequence (stage tracked work → write scratch → commit -F → remove scratch → next staging cycle is clean).
- **G1 precedence contradiction (medium)** — quality-codex R1-F02. "Later layers override earlier" sentence contradicts "per-task > per-run > per-agent" precedence. Fix: remove the "later layers" sentence; keep only the explicit precedence rule.
- **G5 conditional predicates not in G1 schema (medium)** — quality-codex R1-F03. G5 requires conditional matrix entries (citation-density floor etc.) but G1's schema doesn't define a conditional surface. Fix: extend G1's schema description to include a conditional-predicate clause, with predicate-resolution test added to G1's design-level test list.
- **G7 CI BATS backstop claim unsupported (medium)** — quality-codex R1-F04. Cross-cutting summary claims G7 has a CI BATS backstop; G7 only specifies pre-DONE self-check. Fix option (narrow the claim — cheapest, no Plan churn): rewrite Decision 4 and cross-cutting test strategy so only G18 has the CI BATS backstop; G7 is enforced by implementer self-check + reviewer visibility.
- **Decision 10 omits id_hygiene_exempt (medium)** — quality-claude R1-F01. G7 introduces the per-task `id_hygiene_exempt:` carve-out frontmatter but Decision 10's enumeration of new task-spec fields omits it. Fix: add `id_hygiene_exempt: [<paths>]` to Decision 10's bullet list under G7.
- **G15 Formal-goal definition vs Replan check mismatch (medium)** — quality-claude R1-F02. "Formal goal" defined as `id` + `type` + criteria, but the schema check tests only `id:` presence. Fix: align the check — Replan classifies as Idea any goal missing ANY of (id, type, acceptance criteria); load-bearing signal is the missing field, not just `id:` absence.

## Fix dispatch plan

Single fix subagent dispatch. Subagent receives:
- Path to design.md
- Paths to all 10 finding files (Reads them itself, not embedded in prompt)
- Per-finding fix guidance from this dispositions file
- Constraint: edit only design.md; do not touch goals.md, research, config

Subagent reports a brief diff summary (sections touched + finding IDs resolved). Reviewer round 2 fires after fix-subagent confirmation.

## Status

draft → fixing → (post-fix) → re-review round 02.
