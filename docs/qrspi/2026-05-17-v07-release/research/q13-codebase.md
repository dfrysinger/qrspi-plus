---
status: draft
question_ids: [13,14,21]
research_type: codebase
---

# Q13, Q14, Q21: Parallelize worktree checks, Branch Map vocabulary, and artifact shape

## Summary

**TL;DR:** `skills/parallelize/SKILL.md` contains an explicit advisory Worktree-Aware Setup Validation step that checks project-root lint/typecheck/test config exclusions for `.worktrees/**` and framework build directories before scheduling parallel task branches. The canonical Branch Map `Base` vocabulary in the Parallelize skill is space-separated symbolic text (`feature branch tip`, `task-NN tip`, `stage-after-W{N}`, `task-00 tip`), but `agents/qrspi-parallelize-reviewer.md` currently states a different hyphenated/older vocabulary (`feature-branch-tip`, `stage-{N}`, `task-NN-tip`). The Worked Example presents `parallelization.md` as frontmatter plus Execution Mode, Dependency Analysis, Execution Order, Branch Map, Stage Commits, and Mermaid sections; the only fixture under `tests/fixtures/` is a deliberate out-of-scope seed with a malformed Branch Map including concrete commits.

**Key findings:**
- Parallelize owns symbolic planning artifacts and defers concrete branch/worktree creation, baseline tests, runtime `task-00`, and commit hashes to Implement.
- Worktree-aware validation checks eslint, tsconfig, vitest/jest, and recursive framework build-dir ignores from the project root; missing exclusions are advisory and get surfaced in `parallelization.md` plus a notification line.
- Canonical Parallelize `Base` values are `feature branch tip`, `task-NN tip`, `stage-after-W{N}`, and `task-00 tip`.
- The quality reviewer’s symbolic-base check does not match the canonical vocabulary in `skills/parallelize/SKILL.md`.
- `skills/reviewer-protocol/SKILL.md` does not define Branch Map vocabulary; it defines cross-cutting reviewer mechanics, schema, dispatch contracts, and untrusted-data rules.
- Reviewer linting of artifact shape is split between quality checks in `qrspi-parallelize-reviewer.md` and scope/boundary checks in `qrspi-parallelize-scope-reviewer.md`.

**Surprises:** The Parallelize skill’s canonical Branch Map vocabulary is space-separated, while the parallelize quality reviewer names hyphenated and older-looking forms (`feature-branch-tip`, `stage-{N}`, `task-NN-tip`) and omits `task-00 tip`.

**Caveats:** Investigation covered the files named in the questions plus `agents/qrspi-parallelize-scope-reviewer.md`, the visible `tests/fixtures/` fixture set, and grep searches under `tests/`. It did not inspect every non-fixture test implementation in full.

## Full findings

### Query Planning

Planned searches:
- Read `skills/parallelize/SKILL.md` for process steps, Branch Model, Worked Example, artifact requirements, and red flags.
- Read `skills/parallelize/owns-defers.md` for ownership boundaries around worktrees, branches, commits, and baseline tests.
- Read `agents/qrspi-parallelize-reviewer.md` and `skills/reviewer-protocol/SKILL.md` for reviewer-side Branch Map vocabulary and linting behavior.
- Check `agents/qrspi-parallelize-scope-reviewer.md` because Q13 asks about downstream responsibility partitioning and Q21 asks how reviewer templates lint shape.
- Search `tests/fixtures/` for `parallelization.md`, Branch Map, Wave, and symbolic-base examples.

### Q13: Worktree-related pre-flight checks and responsibility partitioning

`skills/parallelize/SKILL.md` defines Parallelize as a plan-time artifact producer and Implement as the runtime owner of branch/worktree execution. The Overview says Parallelize writes `parallelization.md`, gets approval, and hands off to Implement, “which is the runtime owner of branch creation, worktrees, baseline tests, and the per-task orchestration loop” (`skills/parallelize/SKILL.md:14`). It also states Parallelize “never creates branches, never runs baseline tests, never dispatches per-task subagents” and that resolving symbolic bases to real commits happens in Implement (`skills/parallelize/SKILL.md:16`).

The process step sequence includes a dedicated `### Worktree-Aware Setup Validation` section after the artifact writing/presentation steps (`skills/parallelize/SKILL.md:106`). The mandated validation is worktree-related and runs before scheduling parallel task branches:
- Validate from the project root, “not in a worktree” (`skills/parallelize/SKILL.md:110`).
- Check eslint config sources (`eslint.config.js`, `.eslintrc*`, or `package.json` `eslintConfig`) for `.worktrees/**` and framework build-dir ignores such as `.next/**`, `dist/**`, or `build/**` (`skills/parallelize/SKILL.md:112`).
- Check `tsconfig.json` `exclude` for `.worktrees/**` or equivalent; if path aliases point at the project root, confirm aliases do not re-include worktree paths (`skills/parallelize/SKILL.md:113`).
- Check vitest/jest config `exclude` or `testPathIgnorePatterns` for `.worktrees/**` (`skills/parallelize/SKILL.md:114`).
- Verify recursive framework build-directory globs under worktrees, e.g. `.next/**` rather than only `.next/` (`skills/parallelize/SKILL.md:115`).

The reason for the validation is stated as project-level lint/test invocations walking sibling worktrees’ build outputs when excludes are missing, causing large volumes of noise on minified code (`skills/parallelize/SKILL.md:108`). The validation is advisory rather than blocking: “A missing exclusion does not halt parallelization” (`skills/parallelize/SKILL.md:117`). Findings are surfaced as remediation suggestions in `parallelization.md` and as a human-reviewer notification line (`skills/parallelize/SKILL.md:117-L119`). The skill also states the implementer running Parallelize does not auto-apply patches (`skills/parallelize/SKILL.md:121`).

`skills/parallelize/owns-defers.md` partitions responsibility as follows:
- Parallelize owns the dependency graph, file-overlap analysis, Wave membership and bases, Wave dependency graph, symbolic Branch Map, Stage Commits table when needed, Mermaid dependency graph, and Execution Mode decision (`skills/parallelize/owns-defers.md:5-L9`).
- Parallelize defers concrete commit hashes, branch creation, worktree creation, baseline tests, and runtime-injected `task-00` to Implement; Parallelize records only symbolic bases (`skills/parallelize/owns-defers.md:17`).
- Parallelize also defers per-task implementation logic to Implement (`skills/parallelize/owns-defers.md:14`) and runtime-only review configuration to Implement (`skills/parallelize/owns-defers.md:18`).

The main skill repeats the same partition at additional points:
- Implement creates per-task worktrees under `.worktrees/<project>/task-NN/` (`skills/parallelize/SKILL.md:108`).
- Implement persists runtime baseline-fix injection by appending `task-00` and adding `## Runtime Adjustments`; Parallelize does not anticipate it (`skills/parallelize/SKILL.md:77`).
- The Terminal State says Implement begins worktrees, baseline tests, and per-task subagent dispatch after the approved parallelization plan (`skills/parallelize/SKILL.md:268-L270`).

### Q14: Canonical Branch Map vocabulary in Parallelize, reviewer, and reviewer protocol

The canonical Branch Map vocabulary in `skills/parallelize/SKILL.md` is defined in the Branch Model under “Symbolic base vocabulary” (`skills/parallelize/SKILL.md:79`). The only allowed `Base` values are:
- `feature branch tip` (`skills/parallelize/SKILL.md:80`)
- `task-NN tip` (`skills/parallelize/SKILL.md:81`)
- `stage-after-W{N}` (`skills/parallelize/SKILL.md:82`)
- `task-00 tip` (`skills/parallelize/SKILL.md:83`)

The Artifact section repeats that the Branch Map table has columns `Task / Branch / Base` and that the `Base` column uses only the symbolic vocabulary from the Branch Model: `feature branch tip`, `task-NN tip`, `stage-after-W{N}`, `task-00 tip` (`skills/parallelize/SKILL.md:127-L130`). The Red Flags section also treats any `Base` entry outside the four symbolic values as a stop condition (`skills/parallelize/SKILL.md:287-L295`). The final Iron Laws restate the same four values (`skills/parallelize/SKILL.md:374-L380`).

The Worked Example uses the same canonical vocabulary:
- Dependency Analysis Wave annotations include `base: feature branch tip`, `base: stage-after-W1`, and `base: task-01 tip` (`skills/parallelize/SKILL.md:325-L328`).
- Execution Order says Wave 1 has `shared base = feature branch tip`, Wave 2 forks from `stage-after-W1`, and Wave 3 forks directly from `task-01`’s tip (`skills/parallelize/SKILL.md:332-L334`).
- Branch Map rows use `feature branch tip`, `stage-after-W1`, and `task-01 tip` (`skills/parallelize/SKILL.md:338-L343`).

`agents/qrspi-parallelize-reviewer.md` defines or assumes a different symbolic-base vocabulary in its quality checks: it says Branch Map `Base` values must use `feature-branch-tip`, `stage-{N}`, and `task-NN-tip`, and forbids literal commit SHAs (`agents/qrspi-parallelize-reviewer.md:28-L30`). That reviewer vocabulary differs from the Parallelize skill in at least these ways:
- It uses hyphenated `feature-branch-tip` rather than `feature branch tip`.
- It uses `stage-{N}` rather than `stage-after-W{N}`.
- It uses `task-NN-tip` rather than `task-NN tip`.
- It does not include `task-00 tip`.

The same reviewer also assumes Branch Map presence and consistency with Dependency Analysis (`agents/qrspi-parallelize-reviewer.md:32-L34`), but no other Branch Map vocabulary is defined there.

`skills/reviewer-protocol/SKILL.md` does not define Branch Map vocabulary. Its relevant content is cross-cutting review protocol: expected reviewer tags for `parallelize` (`skills/reviewer-protocol/SKILL.md:19-L32`), dispatch parameter names and wrappers (`skills/reviewer-protocol/SKILL.md:38-L49`), finding schema (`skills/reviewer-protocol/SKILL.md:53-L62`), classifier (`skills/reviewer-protocol/SKILL.md:63-L114`), untrusted-data handling (`skills/reviewer-protocol/SKILL.md:125-L164`), and per-finding disk-write contract (`skills/reviewer-protocol/SKILL.md:208-L260`). No Branch Map `Base` values appear in the protocol file.

### Q21: Current `parallelization.md` presentation shape and reviewer linting

`skills/parallelize/SKILL.md` defines required `parallelization.md` sections in its Artifact section:
- Execution Mode: sequential/parallel/hybrid with one-sentence rationale (`skills/parallelize/SKILL.md:127`)
- Dependency Analysis: table with `Task / Dependencies / Files / Wave` (`skills/parallelize/SKILL.md:128`)
- Branch Map: table with `Task / Branch / Base` and canonical symbolic `Base` vocabulary (`skills/parallelize/SKILL.md:129`)
- Stage Commits: only when multi-parent dependencies exist, with `Stage branch / Composition / Created before` (`skills/parallelize/SKILL.md:130`)
- Execution Order: narrative describing Wave dependency graph, concurrency, and downstream gates (`skills/parallelize/SKILL.md:131`)
- Mermaid dependency graph inline in the file (`skills/parallelize/SKILL.md:132`)

The Worked Example presentation shape is:
1. YAML frontmatter with `status: draft` (`skills/parallelize/SKILL.md:310-L313`)
2. `# Parallelization Plan` (`skills/parallelize/SKILL.md:315`)
3. `## Execution Mode: Hybrid` plus rationale (`skills/parallelize/SKILL.md:317-L319`)
4. `## Dependency Analysis` table with columns `Task`, `Dependencies`, `Files`, `Wave` (`skills/parallelize/SKILL.md:321-L328`)
5. `## Execution Order` narrative with Wave descriptions and stage-commit timing (`skills/parallelize/SKILL.md:330-L334`)
6. `## Branch Map` table with columns `Task`, `Branch`, `Base` (`skills/parallelize/SKILL.md:336-L343`)
7. `## Stage Commits` table with columns `Stage branch`, `Composition`, `Created before` (`skills/parallelize/SKILL.md:345-L349`)

The Worked Example includes `stage-after-W1` in both the Branch Map and Stage Commits table (`skills/parallelize/SKILL.md:342-L349`). The Worked Example snippet shown in the file ends after Stage Commits; the required Mermaid section is specified elsewhere in the Artifact section (`skills/parallelize/SKILL.md:132`) and in Process Step 8 (`skills/parallelize/SKILL.md:103`), but the visible “Worked Example — Good” block does not include a Mermaid dependency graph before the closing fence at line 350.

Under `tests/fixtures/`, the only parallelization-specific fixture found is `tests/fixtures/seeded-out-of-scope-parallelize.md`. Its shape is deliberately invalid/out-of-scope:
- Frontmatter and `# Parallelization: Out-of-Scope Seed (parallelization.md)` (`tests/fixtures/seeded-out-of-scope-parallelize.md:1-L5`)
- `## Execution Mode` with “Parallel” (`tests/fixtures/seeded-out-of-scope-parallelize.md:9-L11`)
- `## Dependency Analysis` table with columns `Task / Depends on / Files`, not the canonical `Task / Dependencies / Files / Wave` (`tests/fixtures/seeded-out-of-scope-parallelize.md:13-L18`)
- `## Branch Map` table with columns `Task / Branch / Base / Concrete Commit`, including concrete commits and noncanonical bases (`main`, `T1-tip`) (`tests/fixtures/seeded-out-of-scope-parallelize.md:20-L27`)
- Additional sections intentionally violating DEFERS boundaries: Task Specs, Architecture Decisions, Phasing, and Implementation Logic (`tests/fixtures/seeded-out-of-scope-parallelize.md:29-L49`)
- `## Mermaid Dependency Graph` (`tests/fixtures/seeded-out-of-scope-parallelize.md:51-L56`)
- No `## Execution Order` section is present in this fixture.

Reviewer linting is split across quality and scope templates.

The quality reviewer lints artifact shape and consistency through these checks:
- Intra-Wave file overlap must be absent; overlap is high severity (`agents/qrspi-parallelize-reviewer.md:28`).
- Branch Map `Base` values must use the reviewer-stated symbolic vocabulary and contain no literal commit SHAs (`agents/qrspi-parallelize-reviewer.md:29`).
- Hybrid multi-parent dependencies require a planned stage commit (`agents/qrspi-parallelize-reviewer.md:30`).
- Execution Order narrative must respect Dependency Analysis dependencies (`agents/qrspi-parallelize-reviewer.md:31`).
- Required sections are Branch Map, Dependency Analysis (pairwise), Mermaid dependency graph, and Execution Order narrative (`agents/qrspi-parallelize-reviewer.md:32`).
- Dependency Analysis and Branch Map must be consistent in task ordering and base assignments (`agents/qrspi-parallelize-reviewer.md:33`).
- Completeness check requires every current-phase task from the plan to appear as a Mermaid node, Branch Map row, and pairwise file-overlap analysis participant; missing tasks or missing task pairs are high-severity correctness findings (`agents/qrspi-parallelize-reviewer.md:34`).

The scope reviewer lints boundary shape rather than dependency correctness:
- It reads `skills/parallelize/owns-defers.md` as the authoritative scope rule (`agents/qrspi-parallelize-scope-reviewer.md:13-L15`).
- It applies boundary-drift detection, OWNS coverage, and lexical drift scans for branch creation commands, concrete commit SHAs, or test-execution instructions in a parallelization doc (`agents/qrspi-parallelize-scope-reviewer.md:21-L25`).
- It takes no companion artifacts and evaluates only against OWNS/DEFERS (`agents/qrspi-parallelize-scope-reviewer.md:17-L19`).

The cross-cutting reviewer protocol does not lint the Branch Map shape directly. It enforces reviewer output mechanics, including the expected reviewer matrix for `parallelize` (`quality-claude`, `scope-claude`, plus Codex equivalents when enabled) (`skills/reviewer-protocol/SKILL.md:23-L32`), line-range citations in findings (`skills/reviewer-protocol/SKILL.md:51`), five-field finding schema (`skills/reviewer-protocol/SKILL.md:53-L62`), and one-finding-per-file emission (`skills/reviewer-protocol/SKILL.md:208-L260`).
