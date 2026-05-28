---
round: 13
artifact: design
status: fixing
---

# Round 13 dispositions

## Findings inventory

- quality-claude: 1 finding (low=1, scope-class)
- scope-claude: 1 finding (medium=1)
- quality-codex: 3 findings (high=2, medium=1)
- scope-codex: 1 finding (medium=1)

Total: 6 findings → 5 distinct (G12 procedural drift double-flagged by both scope reviewers). All accept.

Convergence trend: 10 → 3 → 5 → 4 → 2 → 4 → 3 → 4 → 6 → 1 → 2 → 3 → 6. The 2 HIGH this round are refinement-class — quality-codex sharpened critiques of fixes I added (G1 precedence chain still had top-layer ambiguity; G10 binary-ref gate display was too thin). Not new drift; iteration tightening.

## Cross-reviewer match (G12 procedural drift)

- scope-claude R13-F01 + scope-codex R13-F01 flag the same G12 6-step numbered procedure (design.md:L594-L603). Fix once: replace the 6-step enumerated procedure with prose stating the architectural contract (staging before scratch-write; scratch-file removal after commit; worktree-local exclusion). Move the literal git command sequence to G12's recommended target — `skills/implementer-protocol/SKILL.md` — owned by Plan/Implement.

## R13-F01 quality-codex (high) — accept. G1 precedence top-layer tie-break unspecified

Round-12 fix added the 3-layer resolution chain (per-invocation override → role_map → concrete `model:`), but the top layer itself still names two sub-sources ("per-task `model:` field" AND "hardcoded dispatch-site override") without a tie-breaker. Current code has hardcoded `model: "sonnet"` dispatch overrides; without an explicit rule, implementation can silently preserve those and bypass task-specific routing.

**Fix:** In G1's model-resolution chain, expand layer 1 to two explicit sub-layers:
- 1a: Per-task `model:` field on the task spec (highest priority — task author's choice wins over orchestrator default).
- 1b: Hardcoded dispatch-site `model:` override in orchestrator code (only when 1a is absent).

Add the normalization note: existing hardcoded dispatch-site overrides remain valid as layer-1b defaults; once `tasks/task-NN.md` carries a `model:` field, it overrides them. Add a design-level test bullet: task with `model: opus` + hardcoded dispatch-site `model: sonnet` resolves to opus (1a wins); task without `model:` field + hardcoded dispatch-site `model: sonnet` resolves to sonnet (1b active).

## R13-F02 quality-codex (high) — accept. G10 binary reference display insufficient

G10's motivating failure case is wrong prototype PNGs passing visual review. Current G10 spec says the gate displays text inline and prints file paths for binaries. A path is not a visual review surface — the user cannot judge image correctness from a path.

**Fix:** In G10's recommendation, require binary reference artifacts to be presented for human inspection in a renderable form, not just by path. Mechanism (design-level contract; Plan/Implement own the wiring):
- Images (PNG/JPG/GIF/WebP/SVG): render inline using `SendUserFile` (already in toolset) OR equivalent attachment mechanism that surfaces the image in the user's UI.
- PDFs: surface via `SendUserFile` so the user can open inline.
- Other binaries (binary blobs Implement may emit later): require an explicit Plan-time decision per artifact type; default rejection if no rendering mechanism exists.

Add a design-level test bullet: G10 gate for a `reference_artifact: foo.png` produces a user-visible image attachment, not just a path string; absence of attachment is a Plan-level defect caught by reviewer.

## R13-F03 quality-codex (medium) — accept. G17 shellcheck cannot enforce bash 3.2 compat

G17 frames the version check as "shellcheck under bash 3.2 dialect rules" — but shellcheck does not provide a true bash-version compatibility mode that catches `mapfile`, associative arrays, `${var,,}`, etc. The current framing produces a CI surface that looks like a 3.2 gate while missing the syntax class the goal exists to block.

**Fix:** In G17, separate the two verification mechanisms:
- **Lint layer (shellcheck):** standard shell hygiene; not a version gate.
- **Version-compat layer:** a distinct mechanism. Two options Plan should choose between:
  - Option A: parser-only check — run `bash --posix -n` on macOS system bash (bash 3.2.57) to surface parse failures of bash-4+ constructs.
  - Option B: targeted grep ban-list — fail CI on patterns `\bmapfile\b`, `\bdeclare -A\b`, `\$\{[^}]*,,\}`, `\$\{[^}]*\^\^\}`, `\bcoproc\b`, `\bwait -n\b` (extensible).
- Plan picks one (or both) as the actual 3.2 gate; shellcheck remains a separate lint pass.

Add a design-level test bullet: file using `declare -A` is rejected by the 3.2 gate even if shellcheck passes; file using only POSIX constructs passes both layers.

## R13-F01 scope-claude + scope-codex (medium, double-flag) — accept. G12 procedural drift

The G12 "Commit sequence (defense in depth)" block enumerates a 6-step ordered procedure with literal git commands (`git status --porcelain`, `git add -A`, `git commit -F`, `git rev-parse HEAD`) and state-machine branching ("on empty → `BLOCKED` or `DONE_WITH_CONCERNS`"). Design OWNS the architectural decision (staging-before-scratch-write reorder, post-commit cleanup, worktree-local exclusion); DEFERS line-by-line logic to Plan/Implement.

**Fix:** Replace the 6-step enumerated procedure with a 1–2 paragraph prose description of the architectural contract:
- Architectural contract: staging runs BEFORE the scratch commit message file is written; the scratch file is removed after commit and before any subsequent staging cycle; the scratch file path is excluded via worktree-local `.git/info/exclude` to keep `git status` deterministic.
- The literal command sequence and per-step state-machine branching move to the G12-recommended edit target: `skills/implementer-protocol/SKILL.md` (Plan/Implement own).

## R13-F01 quality-claude (low, scope-class) — accept. G1 YAGNI on predicate keys

G1's "initial legal predicate keys" lists three: `citation_density_floor`, `input_volume_max`, `task_type`. Only `citation_density_floor` has a concrete v0.7 consumer (G5 research-specialist routing). The other two introduce vocabulary Plan must specify and Implement must implement with no current use case.

**Fix:** Trim the "initial legal predicate keys" list to `citation_density_floor` only. Replace `input_volume_max` and `task_type` with a forward-looking note: "Additional predicate keys may be added by future goals alongside the concrete dispatch site that requires them — the schema is extensible by design but the v0.7 vocabulary is `citation_density_floor`."

## Fix dispatch plan

Single fix subagent. 5 distinct accepts (G12 procedural drift counts as 1 fix consumed by both scope reviewers).

## Status

draft → fixing → re-review round 14.
