---
round: 06
artifact: design
status: fixing
---

# Round 06 dispositions

## Findings inventory

- quality-claude: 1 finding (medium=1)
- scope-claude: 0 findings (clean sentinel — 5th consecutive scope-clean round)
- quality-codex: 1 finding (medium=1)
- scope-codex: 2 findings (medium=2)

Total: 4 findings.

## Per-finding dispositions

### R6-F01 quality-claude (medium) — accept

G11's "What research found" says "No UI-specific tag exists" but research summary explicitly documents existing `visual_fidelity_check.wireframe_refs` + `ui_producing` boolean AND existing `agents/qrspi-visual-fidelity-reviewer.md`. The new `ui: true` field overlaps with `ui_producing` without reconciliation; the "before authoring the v0.7 reviewer agent" wording implies a new file when one already exists.

**Fix:** In G11's "What research found" subsection, replace the incorrect claim with the accurate research finding. Acknowledge:
- `visual_fidelity_check.wireframe_refs` + `ui_producing` boolean exist in the current Plan task-spec template.
- `agents/qrspi-visual-fidelity-reviewer.md` already exists in qrspi-plus's `agents/` directory.

In G11's Recommendation, reconcile explicitly:
- The new `ui: true` field **replaces** `visual_fidelity_check.ui_producing` (single source of truth at the task-spec frontmatter level, not nested inside a `visual_fidelity_check` sub-block).
- `visual_fidelity_check.wireframe_refs` remains as a nested field under `ui: true` tasks. Migration: a pre-existing `visual_fidelity_check.ui_producing: true` task gets `ui: true` at the frontmatter level; the nested `ui_producing` field is dropped.
- The v0.7 visual-fidelity reviewer work **refines** the existing `agents/qrspi-visual-fidelity-reviewer.md` agent (not a new file). Specifically, refine it to consume the new `ui: true` + `lift_source:` task-spec fields and the new wave-aware brief.

Add a design-level test bullet under G11:
- Existing-agent-refinement test: the `agents/qrspi-visual-fidelity-reviewer.md` file is edited in place by the v0.7 reviewer task, not duplicated.

### R6-F01 quality-codex (medium) — accept

G17 limits CI to Ubuntu's default Bash (5.x) but `goals.md` constraint (around lines 13-15) mandates bash 3.2+ portability for shell-side scripts. Plan/Implement would ship `run-third-party-llm.sh` and helpers passing CI while using bash-4/5-only syntax.

**Fix:** Add a bash-3.2 compatibility lane to G17. Update the "Three jobs" enumeration to four jobs:

4. **`shellcheck-bash32`** (or whatever name fits the existing naming convention) — runs shellcheck with `--shell=bash` and explicit bash 3.2 dialect checks against `scripts/**/*.sh`, `hooks/**/*.sh`, and `tests/helpers/**.bash`.

OR alternatively, extend the existing `shellcheck` job with a bash 3.2 dialect pass. Either form is fine — the design must commit to a bash 3.2 verification mechanism running in CI.

Update Decision 9 / Decision 4 if they reference G17's job count.

Add a design-level test bullet:
- Bash-3.2-compatibility test: shell-side scripts (`scripts/**/*.sh`, `hooks/**/*.sh`, `tests/helpers/**.bash`) pass shellcheck under bash 3.2 dialect rules; bash-4/5-only syntax (associative arrays, `[[`-only constructs, etc.) fails the check.

### R6-F01 scope-codex (medium) — reject

scope-codex flags G12's 6-step procedure as "implementer-protocol command sequence" with literal `git status --porcelain`, `git add -A` etc. as "procedural implementation detail".

scope-claude has explicitly cleared this same content in rounds 2, 3, 4, 5, and 6 (5 consecutive clears), reasoning: "the step ordering IS the load-bearing design decision... each step names a protocol-contract action at one-line granularity with no control flow, error handling, or implementation detail. The explicit git commands function as protocol-boundary names — `git commit -F` is itself part of the design decision (preserving the file-based commit convention per the user's Bash rule)."

The disagreement is a judgment-call between two reviewers reading the same OWNS/DEFERS rule. scope-claude's reading is correct: G12's six steps are protocol-contract actions, not implementation procedure. The literal git commands serve as canonical surface names (like file paths name contract surfaces), not procedure scripts. The round-1 reorder rationale specifically depends on knowing WHICH actions are in WHICH order; abstracting the action names would defeat the design decision.

**Disposition: reject.** Recording the rejection rationale here; no fix needed.

### R6-F02 scope-codex (medium) — partial accept

G17 specifies `.github/workflows/ci.yml` (exact path), job names `bats-unit` / `bats-acceptance` / `shellcheck`, and the `gh run list --branch <branch> --limit 1` query. Exact file path and the specific token strings used as job-IDs ARE Plan/Implement territory. The job count (3, or 4 after R6-F01 quality-codex fix), the three (now four) verification surfaces (BATS unit, BATS acceptance, shellcheck, bash3.2 compat), the trigger pattern, the concurrency control, the gh-CLI consumability — those are Design-level architecture.

**Fix (partial):** Keep the architecture and rationale; drop the implementation-specific tokens.

- Replace ".github/workflows/ci.yml" with "the qrspi-plus CI workflow file (per GitHub Actions conventions, under `.github/workflows/`; exact filename owned by Implement)".
- Replace exact job-name tokens (`bats-unit`, `bats-acceptance`, `shellcheck`) with behavioral descriptions: "a job that runs the unit BATS suite", "a job that runs the acceptance BATS suite", "a job that runs shellcheck against the shell-script surface". Plan picks the actual identifiers.
- Replace `gh run list --branch <branch> --limit 1 ... conclusion: success` with: "Integrate's CI gate consumes the workflow run status via the GitHub Actions API (e.g., the `gh` CLI); the canonical signal is success of all jobs on the head commit of the integrate branch. Exact query shape owned by Implement."
- Replace `concurrency: { group: ci-${{ github.ref }}, cancel-in-progress: true }` literal with: "concurrency control by `github.ref` with cancel-in-progress; exact YAML syntax owned by Implement."
- BATS pin filename was already removed in round 3 (this finding is about other implementation-specific tokens still in G17).

## Fix dispatch plan

Single fix subagent. 3 accept, 1 reject (G12 commands).

## Status

draft → fixing → (post-fix) → re-review round 07.

## Convergence note

Round trend: 10 → 3 → 5 → 4 → 2 unique → 4 (3 accept after dedup). Scope-claude has been clean 5 consecutive rounds. quality-codex/quality-claude are doing deeper passes each round. If round 7 surfaces only minor / judgment-call findings, will recommend the user accept and close.
