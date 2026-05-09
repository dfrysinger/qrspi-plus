# Integration Drift Mitigations Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add four harness-level checks to QRSPI to catch the 11 drift classes that surfaced during the keeplii-simplified Phase 1 integrate phase. After this plan lands, future QRSPI runs catch SWC build failures, missing global stylesheet imports, sibling-task type drift, worktree-aware lint noise, and several flavors of "vitest green ≠ runtime works" before integrate.

**Architecture:** Four conceptual items split across seven tasks. Items 1 and 4 are skill-prose edits + small bats tests. Items 2 and 3 add Node scripts under `scripts/` plus skill conventions plus bats end-to-end tests against the scripts. The whole branch lands as one PR; tasks commit independently for traceability.

**Tech Stack:** Markdown (skill files, agent files), bash (existing scripts/), Node 18+ ESM (.mjs scripts — no new package.json deps), bats (tests). No new framework deps; `node` is already a runtime requirement of any project QRSPI supports.

**Spec:** [`docs/integration-drift-mitigations.md`](../../integration-drift-mitigations.md) (in this same worktree).

**Source drifts (with `integration-notes.md` anchor):** task-08/10/11 Server-Actions export rule (Item 1), task-03 globals.css missing (Item 2), task-08/11 magic-link redirect/PKCE (Item 2 + future Item 5), task-04/09 unwired nav (Item 2), task-29 vs 30/32 SweepError shape (Item 3), task-16 requireAuth collision (Item 3), task-01 worktree lint noise (Item 4), task-04/14/16 tsc-probe race (Item 4).

---

## Implementer notes — read before starting

**Plan-only design latitude.** Three places have intentional design latitude: the smoke-spec YAML keys (Task 4), the notification file format (Task 6), and the sibling-impact symbol-diff output shape (Task 7). The plan specifies the contract those decisions must satisfy; the implementer chooses the surface form. If a chosen form disagrees with this plan's example, prefer the plan's example unless escalating with rationale.

**No new package.json.** qrspi-plus is a markdown-and-bash plugin with no Node package. The two new scripts (`run-smoke-checks.mjs`, `sibling-impact.mjs`) must run with `node` directly using only the standard library. No dependencies. No `package.json`. Tests invoke them via `node scripts/<name>.mjs` from bats.

**bats convention.** Existing tests under `tests/unit/test-*.bats` use bats-core with `setup_file` / `setup` / `teardown` hooks and `bats_test_dirname` for fixture resolution. New bats files follow the same shape. Skill-content tests grep against `skills/**/SKILL.md`; script tests invoke the script in a tempdir with fixture inputs.

**Skill section discovery.** Section locations in `skills/*/SKILL.md` files shift between PRs. When a step says "add to the verification step in implement/SKILL.md", the implementer should `grep -n "^##\|^###" skills/implement/SKILL.md` first to locate the actual section, not rely on line numbers that may have drifted.

**TDD for the Node scripts.** Tasks 5 and 7 are TDD: bats test first (RED), script next (GREEN), refactor. Tasks 1, 2, 3, 4, 6 are mostly prose edits — write the bats grep assertion first, fail it, then make the edit, pass it. Same TDD shape, just trivially short.

**Atomicity.** Each task is one commit. No squash. Tasks are sequential — Task N's tests assume Task N's code is in place but no further. The PR-tip is what gates merge.

---

## File Structure

| File | Shape | Item | Task |
|---|---|---|---|
| `skills/plan/SKILL.md` | Modify — add `build_command` field doc; add `dev_command` field doc; reference `smoke-spec.md` | 1, 2 | 1, 4 |
| `skills/plan/smoke-spec.md` | Create — convention doc for `smoke_checks:` blocks | 2 | 4 |
| `skills/implement/SKILL.md` | Modify — extend Process Steps verification + per-task TDD section | 1, 2, 3 | 1, 4, 6 |
| `skills/implementer-protocol/SKILL.md` | Modify — add "all green = done" rule; add notifications start-of-task step | 1, 3 | 1, 6 |
| `skills/implementer-protocol/notifications.md` | Create — notifications protocol doc | 3 | 6 |
| `skills/parallelize/SKILL.md` | Modify — add setup-validation step | 4 | 2 |
| `skills/_shared/tsc-probe-helper.md` | Create — convention doc for the helper | 4 | 3 |
| `templates/tsc-probe.ts` | Create — vendor-in TS template | 4 | 3 |
| `scripts/run-smoke-checks.mjs` | Create — Node ESM script | 2 | 5 |
| `scripts/sibling-impact.mjs` | Create — Node ESM script | 3 | 7 |
| `tests/unit/test-build-gate.bats` | Create | 1 | 1 |
| `tests/unit/test-worktree-aware-defaults.bats` | Create | 4 | 2 |
| `tests/unit/test-tsc-probe-helper.bats` | Create | 4 | 3 |
| `tests/unit/test-smoke-spec-convention.bats` | Create | 2 | 4 |
| `tests/unit/test-run-smoke-checks.bats` | Create | 2 | 5 |
| `tests/unit/test-sibling-notification-protocol.bats` | Create | 3 | 6 |
| `tests/unit/test-sibling-impact.bats` | Create | 3 | 7 |

`templates/` does not currently exist at the repo root; Task 3 creates it.

---

## Task 1: Build-gate convention (Item 1)

**Files:**
- Modify: `skills/plan/SKILL.md` — add `build_command` field doc to the project-environment section
- Modify: `skills/implement/SKILL.md` — extend the per-task verification step
- Modify: `skills/implementer-protocol/SKILL.md` — add the "all green" rule
- Create: `tests/unit/test-build-gate.bats`

**Contracts to satisfy:**

1. The Plan skill declares that every plan MUST include a `build_command` field. Allowed values: a non-empty string (the command to run, e.g., `pnpm build`, `cargo build --release`, `tsc -p .`), or the literal string `none` if the project has no build step. If `none`, a one-line rationale is required adjacent to the field.
2. The Implement skill's per-task verification step runs the project's `build_command` after tests pass and before declaring the task DONE. A non-zero exit fails the task with build output captured in the implementer report.
3. The Implementer Protocol's "done" signal is: tests green AND build green AND typecheck green AND lint green. Any one failing fails the task. (Typecheck/lint are added if not already there.)

- [ ] **Step 1: Read context**

Run: `grep -n "^##\|^###" skills/plan/SKILL.md skills/implement/SKILL.md skills/implementer-protocol/SKILL.md`

Identify:
- The section in `plan/SKILL.md` that lists project-environment fields (look near "Plan Document Structure", "Phase-Scoped Content", or similar). If no explicit project-environment section exists, add the field documentation under a new `### Project Environment Fields` subsection inside Plan Document Structure.
- The section in `implement/SKILL.md` that describes per-task verification (look at `### TDD Process (inside the implementer subagent)` and `### Implementer Status Reporting`). The build pass goes after the test-running step.
- The section in `implementer-protocol/SKILL.md` near `## Self-Review (shared)` or `## Report Format` for the all-green rule.

- [ ] **Step 2: Write the failing bats test**

Create `tests/unit/test-build-gate.bats`:

```bash
#!/usr/bin/env bats

setup_file() {
  REPO_ROOT="$(cd "$(dirname "${BATS_TEST_FILENAME}")/../.." && pwd -P)"
  export REPO_ROOT
}

@test "plan/SKILL.md documents the build_command field" {
  run grep -F 'build_command' "$REPO_ROOT/skills/plan/SKILL.md"
  [ "$status" -eq 0 ]
}

@test "plan/SKILL.md allows 'none' as a build_command sentinel" {
  run grep -F "'none'" "$REPO_ROOT/skills/plan/SKILL.md"
  [ "$status" -eq 0 ]
}

@test "implement/SKILL.md runs build after tests in per-task verification" {
  run grep -E -i 'build.*after.*test|run.*build_command|run the (project|plan).*build' "$REPO_ROOT/skills/implement/SKILL.md"
  [ "$status" -eq 0 ]
}

@test "implement/SKILL.md fails the task when build exits non-zero" {
  run grep -E -i 'non-zero.*exit.*fail|fail.*task.*build|build.*fail.*task' "$REPO_ROOT/skills/implement/SKILL.md"
  [ "$status" -eq 0 ]
}

@test "implementer-protocol/SKILL.md states all-green rule" {
  run grep -E -i 'tests green AND build green|all four checks|tests.*build.*typecheck.*lint' "$REPO_ROOT/skills/implementer-protocol/SKILL.md"
  [ "$status" -eq 0 ]
}
```

- [ ] **Step 3: Run the test, verify all assertions FAIL**

Run: `bats tests/unit/test-build-gate.bats`

Expected: 5 failures. The grep patterns don't match yet because nothing has been added.

- [ ] **Step 4: Edit `skills/plan/SKILL.md`**

Locate the Plan Document Structure section (around line 177). Add a project-environment subsection that documents the `build_command` field. The added prose must say in substance:

> ### Project Environment Fields
>
> Every plan declares the commands the implementer gate uses to verify a task:
>
> - `build_command` — the command that produces the project's build artifact, run after tests pass during per-task verification. Examples: `pnpm build` (Next.js, Vite), `cargo build --release`, `go build ./...`, `tsc -p .` (lib-only). Set to the literal string `'none'` only for pure-script projects with no build step; include a one-line rationale next to the field when set to `'none'`.
> - `dev_command` — *(reserved for the smoke-check gate added by a sibling task; see [`smoke-spec.md`](smoke-spec.md))*. Plans that opt into smoke checks declare this; plans that don't may omit it.
>
> The implementer reads these from the plan and runs them at the per-task gate (see `skills/implement/SKILL.md`).

The exact heading text and surrounding placement are at the implementer's discretion; the four bullets above (build_command, none-with-rationale, dev_command forward-reference, gate-reading rule) must all appear.

- [ ] **Step 5: Edit `skills/implement/SKILL.md`**

Locate the TDD Process subsection inside Per-Task Execution (around line 326) and the Implementer Status Reporting subsection (around line 339). Add — either as a new step inside TDD Process or as a new subsection between them — content that says in substance:

> ### Build Verification (per task)
>
> After tests pass, run the project's `build_command` (declared in the plan's project-environment fields). If `build_command` is `'none'`, skip this step.
>
> A non-zero exit fails the task. The build's stdout+stderr is captured in the implementer's report. The implementer does NOT modify the build configuration to make it pass — surface the failure for review like any other test failure. If the failure is a spec contradiction (e.g., the spec says "export this constant" but the framework forbids it), report BLOCKED with the spec-contradiction reason.

- [ ] **Step 6: Edit `skills/implementer-protocol/SKILL.md`**

Locate `## Self-Review (shared)` (around line 97) or `## Report Format` (around line 120). Add — either at the end of Self-Review's Completeness checklist or as a brief section before Report Format — content that says in substance:

> ### Done Signal
>
> "Done" requires all four to be green:
> 1. Tests pass (suite the plan declared, no skips, no flake-retries)
> 2. Build passes (`build_command` from the plan; skipped only if the plan declares `'none'`)
> 3. Typecheck passes (when the project has one — TypeScript, mypy, etc.)
> 4. Lint passes (when the project has one)
>
> Any one failing fails the task. Status DONE means all four green; DONE_WITH_CONCERNS means all four green but with explicit doubts; BLOCKED means a check failed in a way the implementer cannot resolve.

- [ ] **Step 7: Run the bats test, verify all assertions PASS**

Run: `bats tests/unit/test-build-gate.bats`

Expected: 5 passes.

- [ ] **Step 8: Commit**

Run:
```bash
git -C /private/tmp/qrspi-drift add skills/plan/SKILL.md skills/implement/SKILL.md skills/implementer-protocol/SKILL.md tests/unit/test-build-gate.bats
git -C /private/tmp/qrspi-drift commit -m "feat(implement): add build-gate verification per task"
```

---

## Task 2: Worktree-aware parallelize defaults (Item 4a)

**Files:**
- Modify: `skills/parallelize/SKILL.md` — add a setup-validation step
- Create: `tests/unit/test-worktree-aware-defaults.bats`

**Contracts to satisfy:**

1. Before scheduling parallel task branches, the parallelize skill checks the project's lint/typecheck/test configs for `.worktrees/**` and framework-build-dir (e.g., `.next/`) exclusions.
2. If a check fails, the skill emits a remediation patch suggestion (added to `parallelization.md` or surfaced to the human in the review round) and a notification to the planner. The skill does NOT block parallelization on a missing exclusion — the worktree-noise problem is recoverable; halting the pipeline is overkill.
3. The skill prose names at minimum: `eslint` ignore, `tsconfig` exclude, `vitest` / `jest` test exclude. Other framework configs (Cargo target/, Go vendor/, etc.) can be added later; Phase 1 covers the JS/TS flavors that hit keeplii.

- [ ] **Step 1: Read context**

Run: `grep -n "^##\|^###" skills/parallelize/SKILL.md`

Identify the Process Steps section (around line 90) and the Artifact section (around line 106). The setup-validation step goes inside Process Steps; the artifact may grow a new subsection if the validation surfaces findings the human needs to see.

- [ ] **Step 2: Write the failing bats test**

Create `tests/unit/test-worktree-aware-defaults.bats`:

```bash
#!/usr/bin/env bats

setup_file() {
  REPO_ROOT="$(cd "$(dirname "${BATS_TEST_FILENAME}")/../.." && pwd -P)"
  export REPO_ROOT
}

@test "parallelize/SKILL.md mentions a worktree-aware setup-validation step" {
  run grep -E -i 'setup.validation|worktree.aware|\.worktrees' "$REPO_ROOT/skills/parallelize/SKILL.md"
  [ "$status" -eq 0 ]
}

@test "parallelize/SKILL.md names the four config kinds checked" {
  run grep -F 'eslint' "$REPO_ROOT/skills/parallelize/SKILL.md"
  [ "$status" -eq 0 ]
  run grep -F 'tsconfig' "$REPO_ROOT/skills/parallelize/SKILL.md"
  [ "$status" -eq 0 ]
  run grep -E 'vitest|jest' "$REPO_ROOT/skills/parallelize/SKILL.md"
  [ "$status" -eq 0 ]
}

@test "parallelize/SKILL.md states validation is non-blocking (advisory)" {
  run grep -E -i 'does not block|not.*blocking|advisory|non.blocking' "$REPO_ROOT/skills/parallelize/SKILL.md"
  [ "$status" -eq 0 ]
}

@test "parallelize/SKILL.md mentions framework build dir like .next" {
  run grep -F '.next' "$REPO_ROOT/skills/parallelize/SKILL.md"
  [ "$status" -eq 0 ]
}
```

- [ ] **Step 3: Run, verify FAIL**

Run: `bats tests/unit/test-worktree-aware-defaults.bats`. Expected: 4 failures.

- [ ] **Step 4: Edit `skills/parallelize/SKILL.md`**

Add a new `### Worktree-Aware Setup Validation` subsection inside Process Steps (around line 90). The added prose must say in substance:

> ### Worktree-Aware Setup Validation
>
> Before scheduling parallel task branches, validate that the project's lint/typecheck/test configurations exclude the worktree-tree pattern QRSPI uses. The Implement skill creates per-task worktrees under `.worktrees/<project>/task-NN/`, each of which may contain its own framework build directory (e.g., `.next/` for Next.js, `dist/` for Vite, `build/` for many bundlers). Without explicit exclusions, project-level lint/test invocations walk into sibling worktrees' build outputs, producing thousands of noise findings on minified code.
>
> Validate in this order, on the project root (not in a worktree):
>
> 1. **eslint** — config (eslint.config.js, .eslintrc*, package.json `eslintConfig`) ignores `.worktrees/**` AND the framework build directory (`.next/**`, `dist/**`, `build/**`).
> 2. **tsconfig** — `tsconfig.json` `exclude` array contains `.worktrees/**` (or equivalent). If the project uses path aliases pointed at the project root, also confirm aliases don't accidentally re-include worktree paths.
> 3. **vitest / jest** — test config's `exclude` (or `testPathIgnorePatterns`) contains `.worktrees/**`.
> 4. **framework build dir under worktrees** — verify recursive globs (e.g., `.next/**` not just `.next/`) so deep worktree subtrees are covered.
>
> **This validation is advisory, not blocking.** A missing exclusion does not halt parallelization. Surface findings as remediation suggestions in the parallelize artifact (`parallelization.md`) and as a notification line for the human reviewer:
>
> > Worktree-aware setup validation: missing `.worktrees/**` exclusion in `eslint.config.js`. Recommended patch: add `'.worktrees/**'` to the `ignores:` array. (The worktree-noise problem manifests as inflated lint-error counts during integrate; it does not affect correctness of the per-task gates.)
>
> The implementer running parallelize does NOT auto-apply patches. Patches are advisory-only at this gate.

- [ ] **Step 5: Run bats, verify PASS**

Run: `bats tests/unit/test-worktree-aware-defaults.bats`. Expected: 4 passes.

- [ ] **Step 6: Commit**

```bash
git -C /private/tmp/qrspi-drift add skills/parallelize/SKILL.md tests/unit/test-worktree-aware-defaults.bats
git -C /private/tmp/qrspi-drift commit -m "feat(parallelize): add worktree-aware setup validation"
```

---

## Task 3: Self-isolating tsc-probe helper (Item 4b)

**Files:**
- Create: `skills/_shared/tsc-probe-helper.md` — convention doc
- Create: `templates/tsc-probe.ts` — vendor-in template
- Create: `tests/unit/test-tsc-probe-helper.bats`

**Contracts to satisfy:**

1. The convention doc deprecates the project-tsconfig-glob tsc-probe pattern (used by keeplii task-04, task-14, task-16) and points implementers at the helper template.
2. The helper template, when copied into a project as `tests/_qrspi-helpers/tsc-probe.ts`, exposes a function `tscProbe({ source, expectError }: { source: string; expectError?: RegExp | string })` that:
   - Writes the source to a temp file with a UUID-suffixed name (e.g., `__qrspi_probe_${uuid}.ts`) under a temp directory the helper creates.
   - Writes a one-off `tsconfig.probe-${uuid}.json` next to the probe whose `include` array contains ONLY the probe file and whose `compilerOptions` extends or duplicates the project's settings.
   - Runs `tsc -p tsconfig.probe-${uuid}.json` (NOT the project tsconfig).
   - Returns `{ exitCode: number; stdout: string; stderr: string }`.
   - Cleans up both the probe file and the probe tsconfig in a `finally` block, even on error.
3. The helper uses only Node 18+ stdlib + TypeScript installed via the project's own dev deps. No new package.json deps. The helper itself is plain TypeScript and is loaded by the project's existing test runner.

- [ ] **Step 1: Write the failing bats test**

Create `tests/unit/test-tsc-probe-helper.bats`:

```bash
#!/usr/bin/env bats

setup_file() {
  REPO_ROOT="$(cd "$(dirname "${BATS_TEST_FILENAME}")/../.." && pwd -P)"
  export REPO_ROOT
}

@test "_shared/tsc-probe-helper.md exists" {
  [ -f "$REPO_ROOT/skills/_shared/tsc-probe-helper.md" ]
}

@test "tsc-probe-helper convention doc deprecates project-tsconfig-glob pattern" {
  run grep -E -i 'deprecat|do not use.*project tsconfig|racy' "$REPO_ROOT/skills/_shared/tsc-probe-helper.md"
  [ "$status" -eq 0 ]
}

@test "tsc-probe-helper convention doc names UUID-based filename pattern" {
  run grep -E -i 'uuid|unique|suffix' "$REPO_ROOT/skills/_shared/tsc-probe-helper.md"
  [ "$status" -eq 0 ]
}

@test "tsc-probe-helper convention doc points at templates/tsc-probe.ts" {
  run grep -F 'templates/tsc-probe.ts' "$REPO_ROOT/skills/_shared/tsc-probe-helper.md"
  [ "$status" -eq 0 ]
}

@test "templates/tsc-probe.ts exists" {
  [ -f "$REPO_ROOT/templates/tsc-probe.ts" ]
}

@test "templates/tsc-probe.ts exports tscProbe function" {
  run grep -E 'export.*function tscProbe|export.*tscProbe' "$REPO_ROOT/templates/tsc-probe.ts"
  [ "$status" -eq 0 ]
}

@test "templates/tsc-probe.ts writes a probe-specific tsconfig with only the probe file in include" {
  run grep -F 'tsconfig.probe-' "$REPO_ROOT/templates/tsc-probe.ts"
  [ "$status" -eq 0 ]
  run grep -F 'include' "$REPO_ROOT/templates/tsc-probe.ts"
  [ "$status" -eq 0 ]
}

@test "templates/tsc-probe.ts cleans up in finally" {
  run grep -E 'finally|unlinkSync' "$REPO_ROOT/templates/tsc-probe.ts"
  [ "$status" -eq 0 ]
}
```

- [ ] **Step 2: Run, verify FAIL**

Run: `bats tests/unit/test-tsc-probe-helper.bats`. Expected: 8 failures (no files exist yet).

- [ ] **Step 3: Create `skills/_shared/tsc-probe-helper.md`**

Content (verbatim):

```markdown
---
name: tsc-probe-helper
description: Self-isolating tsc-probe pattern for type-level fixture tests. Replaces the project-tsconfig-glob pattern that races across parallel worktrees.
---

# Self-isolating tsc-probe helper

Tasks that need to verify "this fixture should fail to type-check" historically
write the probe into the project tree, run `tsc --project tsconfig.json`, and
expect tsc to fail with errors from the probe. This pattern is **racy across
parallel QRSPI worktrees**: each task's probe file appears in the project
tsconfig's glob, and parallel `tsc` invocations cross over each other (one
test's tsc invocation sees another test's mid-flight probe → first test's
"compiles cleanly" assertion fails on the second test's intentional errors).

The pattern from keeplii task-04, task-14, task-16 — using the project
tsconfig — is **deprecated**. Tasks using the tsc-probe pattern MUST use the
helper template at `templates/tsc-probe.ts`, vendored into the project's
`tests/_qrspi-helpers/tsc-probe.ts` on first use.

## Why the helper is safe

- **UUID-suffixed probe filenames**: parallel tests cannot collide on disk.
- **One-off probe tsconfig**: the probe file is the ONLY entry in `include`,
  so tsc never picks up sibling worktrees' probes.
- **Cleanup in `finally`**: probe file + probe tsconfig are removed even on
  test failure or early exit.

## When to use

Any test of the shape "this TypeScript should fail to compile because of
[bug X]". The fixture you'd otherwise inline as a `// @ts-expect-error`
comment.

## When NOT to use

- Run-time correctness tests (use vitest / jest directly).
- Tests where the fixture is meant to compile (use a static fixture in
  `tests/fixtures/` and let the project tsc cover it normally).

## Vendoring the template

On first use in a project, copy `templates/tsc-probe.ts` (from this plugin)
into `tests/_qrspi-helpers/tsc-probe.ts`. The QRSPI parallelize skill's
setup-validation step (see `skills/parallelize/SKILL.md`) flags missing
helpers; the implementer running the affected task vendors the helper as
part of the same commit.

## Usage

```ts
import { tscProbe } from '../_qrspi-helpers/tsc-probe';

it('rejects branded type assigned to bare string', async () => {
  const result = await tscProbe({
    source: `
      import type { UserId } from '../../src/types';
      const id: UserId = 'plain-string'; // expected to fail
    `,
    expectError: /Type 'string' is not assignable/,
  });
  expect(result.exitCode).not.toBe(0);
  expect(result.stderr + result.stdout).toMatch(/Type 'string' is not assignable/);
});
```
```

- [ ] **Step 4: Create `templates/tsc-probe.ts`**

Create the directory with `mkdir -p templates` (if not present) and write the helper. Content:

```typescript
// QRSPI tsc-probe helper.
//
// Vendored into projects as `tests/_qrspi-helpers/tsc-probe.ts`. See
// `skills/_shared/tsc-probe-helper.md` for rationale.
//
// Why this exists: running `tsc -p <project tsconfig>` across parallel QRSPI
// worktrees is racy — each test's probe file lands in the project glob, and
// concurrent tsc invocations interfere. This helper writes a one-off
// tsconfig that includes ONLY the probe file, runs tsc against it, and
// cleans up in `finally`.

import { execFileSync } from 'node:child_process';
import { mkdtempSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { randomUUID } from 'node:crypto';

export interface TscProbeOptions {
  /** TypeScript source to type-check. */
  source: string;
  /** Optional pattern the tsc output must contain. */
  expectError?: RegExp | string;
  /**
   * Optional path to the project's tsconfig.json. The probe tsconfig
   * extends this so it inherits compilerOptions (strict mode, paths, etc.).
   * Defaults to `tsconfig.json` in the current working directory.
   */
  projectTsconfig?: string;
}

export interface TscProbeResult {
  exitCode: number;
  stdout: string;
  stderr: string;
}

export function tscProbe(options: TscProbeOptions): TscProbeResult {
  const uuid = randomUUID();
  const dir = mkdtempSync(join(tmpdir(), `qrspi-tsc-probe-${uuid}-`));
  const probeFile = join(dir, `__qrspi_probe_${uuid}.ts`);
  const probeTsconfig = join(dir, `tsconfig.probe-${uuid}.json`);

  try {
    writeFileSync(probeFile, options.source, 'utf8');

    const tsconfigBody = {
      extends: options.projectTsconfig ?? '../tsconfig.json',
      compilerOptions: {
        noEmit: true,
        skipLibCheck: true,
      },
      include: [probeFile],
    };
    writeFileSync(probeTsconfig, JSON.stringify(tsconfigBody, null, 2), 'utf8');

    let stdout = '';
    let stderr = '';
    let exitCode = 0;
    try {
      stdout = execFileSync('tsc', ['-p', probeTsconfig], {
        encoding: 'utf8',
        stdio: ['ignore', 'pipe', 'pipe'],
      });
    } catch (err) {
      const e = err as { status?: number; stdout?: Buffer | string; stderr?: Buffer | string };
      exitCode = e.status ?? 1;
      stdout = (e.stdout?.toString() ?? '');
      stderr = (e.stderr?.toString() ?? '');
    }

    if (options.expectError) {
      const combined = stdout + stderr;
      const ok =
        options.expectError instanceof RegExp
          ? options.expectError.test(combined)
          : combined.includes(options.expectError);
      if (!ok) {
        throw new Error(
          `tscProbe: expected error pattern not found.\nExpected: ${String(options.expectError)}\nGot:\n${combined}`,
        );
      }
    }

    return { exitCode, stdout, stderr };
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
}
```

- [ ] **Step 5: Run bats, verify PASS**

Run: `bats tests/unit/test-tsc-probe-helper.bats`. Expected: 8 passes.

- [ ] **Step 6: Commit**

```bash
git -C /private/tmp/qrspi-drift add skills/_shared/tsc-probe-helper.md templates/tsc-probe.ts tests/unit/test-tsc-probe-helper.bats
git -C /private/tmp/qrspi-drift commit -m "feat(_shared): add self-isolating tsc-probe helper template"
```

---

## Task 4: Smoke-spec convention (Item 2a)

**Files:**
- Create: `skills/plan/smoke-spec.md`
- Modify: `skills/plan/SKILL.md` — extend test-expectations section + add `dev_command` field
- Modify: `skills/implement/SKILL.md` — add smoke-check verification step
- Create: `tests/unit/test-smoke-spec-convention.bats`

**Design latitude:** the exact YAML keys are at the implementer's discretion as long as the contract below is met.

**Contracts to satisfy:**

1. The convention doc defines a `smoke_checks:` block as a list of entries, each with at minimum: `path`, `auth` (one of `none` / `signed-in` / `admin`), `expect_status`. Optional fields: `expect_body_contains` (array), `expect_body_not_contains` (array), `expect_location` (for 30x), `expect_link_href_pattern` (regex string for stylesheet `<link>` checks).
2. The Plan skill states that any task adding/modifying a route, page, layout, or user-facing component MUST include a `smoke_checks:` block. Tasks touching only internal libraries MAY omit it.
3. The Plan skill declares the `dev_command` field (forward-referenced from Task 1) — the command the implementer runs to start the dev server before smoke checks.
4. The Implement skill says the implementer runs declared smoke checks via the helper script (`scripts/run-smoke-checks.mjs`, added in Task 5) after build passes. A smoke-check failure fails the task.

- [ ] **Step 1: Write the failing bats test**

Create `tests/unit/test-smoke-spec-convention.bats`:

```bash
#!/usr/bin/env bats

setup_file() {
  REPO_ROOT="$(cd "$(dirname "${BATS_TEST_FILENAME}")/../.." && pwd -P)"
  export REPO_ROOT
}

@test "smoke-spec.md exists" {
  [ -f "$REPO_ROOT/skills/plan/smoke-spec.md" ]
}

@test "smoke-spec.md documents the smoke_checks: block name" {
  run grep -F 'smoke_checks:' "$REPO_ROOT/skills/plan/smoke-spec.md"
  [ "$status" -eq 0 ]
}

@test "smoke-spec.md documents required fields path, auth, expect_status" {
  run grep -F 'path' "$REPO_ROOT/skills/plan/smoke-spec.md"
  [ "$status" -eq 0 ]
  run grep -F 'auth' "$REPO_ROOT/skills/plan/smoke-spec.md"
  [ "$status" -eq 0 ]
  run grep -F 'expect_status' "$REPO_ROOT/skills/plan/smoke-spec.md"
  [ "$status" -eq 0 ]
}

@test "smoke-spec.md documents auth values none, signed-in, admin" {
  run grep -F 'none' "$REPO_ROOT/skills/plan/smoke-spec.md"
  [ "$status" -eq 0 ]
  run grep -F 'signed-in' "$REPO_ROOT/skills/plan/smoke-spec.md"
  [ "$status" -eq 0 ]
  run grep -F 'admin' "$REPO_ROOT/skills/plan/smoke-spec.md"
  [ "$status" -eq 0 ]
}

@test "smoke-spec.md documents optional fields including expect_body_contains and expect_link_href_pattern" {
  run grep -F 'expect_body_contains' "$REPO_ROOT/skills/plan/smoke-spec.md"
  [ "$status" -eq 0 ]
  run grep -F 'expect_link_href_pattern' "$REPO_ROOT/skills/plan/smoke-spec.md"
  [ "$status" -eq 0 ]
}

@test "plan/SKILL.md requires smoke_checks for route/page/layout/component tasks" {
  run grep -E -i 'smoke_checks.*(route|page|layout|component)|(route|page|layout|component).*smoke_checks' "$REPO_ROOT/skills/plan/SKILL.md"
  [ "$status" -eq 0 ]
}

@test "plan/SKILL.md declares the dev_command field" {
  run grep -F 'dev_command' "$REPO_ROOT/skills/plan/SKILL.md"
  [ "$status" -eq 0 ]
}

@test "implement/SKILL.md runs smoke checks after build" {
  run grep -E -i 'smoke.check.*after.*build|smoke_checks|run-smoke-checks' "$REPO_ROOT/skills/implement/SKILL.md"
  [ "$status" -eq 0 ]
}
```

- [ ] **Step 2: Run, verify FAIL**

Run: `bats tests/unit/test-smoke-spec-convention.bats`. Expected: 8 failures.

- [ ] **Step 3: Create `skills/plan/smoke-spec.md`**

Content:

```markdown
---
name: smoke-spec
description: Convention for the smoke_checks block in plan task specs. Smoke checks are fetch-based runtime assertions the implementer runs after build passes.
---

# Smoke check spec

A `smoke_checks:` block in a task spec lists fetch-based runtime assertions
the implementer runs after the build passes. Smoke checks catch the
"vitest green ≠ runtime works" drift class — missing globals.css imports,
broken redirects, unwired routes, runtime React errors that surface at
first request.

## Block format

```yaml
smoke_checks:
  - path: /signin
    auth: none
    expect_status: 200
    expect_body_contains:
      - "Sign in"
    expect_link_href_pattern: "globals\\.css"
  - path: /home
    auth: signed-in
    expect_status: 200
    expect_body_not_contains:
      - "Welcome to Home"  # placeholder copy that should have been replaced
  - path: /api/auth/callback?code=stub
    auth: none
    expect_status: 302
    expect_location: "/onboarding"
```

## Required fields

- `path` — URL path to fetch (relative to the dev server's origin).
- `auth` — one of `none`, `signed-in`, `admin`. The implementer scaffolds a
  session cookie based on this value before issuing the fetch.
- `expect_status` — integer HTTP status the response must match exactly.

## Optional fields

- `expect_body_contains` — array of strings; each must appear in the
  response body.
- `expect_body_not_contains` — array of strings; none may appear.
- `expect_location` — string for 30x responses; the `Location` header must
  match exactly.
- `expect_link_href_pattern` — regex (as a string); at least one
  `<link rel="stylesheet" href="...">` `href` must match. Used to verify
  global stylesheets are reachable.

## Auth scaffolding

The Plan declares the project's auth-scaffolding recipe in a sibling field
(e.g., `smoke_auth: { cookie_name: "sb-access-token", signing: "..." }`).
The first project to use smoke checks pays the recipe-authoring cost; the
implementer refers to that field when running checks against the dev
server.

## When to include smoke checks

- **Required** for any task adding or modifying a route, page, layout, or
  user-facing component.
- **Optional** for tasks touching only internal libraries (no route or
  component surface).

## Helper script

The implementer runs smoke checks via `scripts/run-smoke-checks.mjs` (in
this plugin). The script:
1. Reads the task spec's `smoke_checks:` block.
2. Starts the dev server using `dev_command` from the plan.
3. Waits for the port to listen (default 3000; configurable).
4. Issues each fetch and asserts the contract.
5. Stops the dev server.
6. Exits non-zero on any failure.

The implementer does NOT modify smoke checks to make them pass — they are
authored by the Plan skill, not the implementer.
```

- [ ] **Step 4: Edit `skills/plan/SKILL.md`**

Two edits:

(a) In the project-environment fields section added in Task 1, replace the `dev_command` placeholder with full prose:

> - `dev_command` — the command that starts the dev server, used by the smoke-check gate. Required when any task in the plan declares a `smoke_checks:` block; optional otherwise. Examples: `pnpm dev`, `cargo run`, `python manage.py runserver`. Plans that opt into smoke checks also declare `smoke_auth:` per [`smoke-spec.md`](smoke-spec.md).

(b) Locate the test-expectations / task-spec authoring section (around the Task Specs section, line 202). Add a sentence:

> Any task adding or modifying a route, page, layout, or user-facing component MUST include a `smoke_checks:` block per the smoke-spec convention ([`smoke-spec.md`](smoke-spec.md)). Tasks that only modify internal libraries (no route or component surface) MAY omit it.

- [ ] **Step 5: Edit `skills/implement/SKILL.md`**

After the build-verification step added in Task 1 (Per-Task Execution / Build Verification), add a new subsection:

> ### Smoke-Check Verification (per task)
>
> If the task spec includes a `smoke_checks:` block, the implementer runs
> them via `scripts/run-smoke-checks.mjs` after the build passes:
>
> 1. Start the dev server using the plan's `dev_command` in the worktree.
> 2. Wait for the configured port to listen (default 30 s timeout).
> 3. Invoke `node scripts/run-smoke-checks.mjs --task-spec tasks/task-NN.md`
>    from the worktree root.
> 4. Stop the dev server (the helper script handles this on its own clean
>    exit; the implementer ensures it on a crash via a cleanup hook).
> 5. A smoke-check failure fails the task. The implementer fixes the
>    underlying code; the implementer does NOT modify the smoke spec to
>    make it pass.
>
> Tasks without a `smoke_checks:` block skip this step.

- [ ] **Step 6: Run bats, verify PASS**

Run: `bats tests/unit/test-smoke-spec-convention.bats`. Expected: 8 passes.

- [ ] **Step 7: Commit**

```bash
git -C /private/tmp/qrspi-drift add skills/plan/smoke-spec.md skills/plan/SKILL.md skills/implement/SKILL.md tests/unit/test-smoke-spec-convention.bats
git -C /private/tmp/qrspi-drift commit -m "feat(plan): add smoke_checks convention for runtime gate"
```

---

## Task 5: run-smoke-checks.mjs script (Item 2b)

**Files:**
- Create: `scripts/run-smoke-checks.mjs`
- Create: `tests/unit/test-run-smoke-checks.bats`

**Contracts to satisfy:**

1. Script signature: `node scripts/run-smoke-checks.mjs --task-spec <path-to-task-md> [--port <number>] [--base-url <url>]`. Default base-url is `http://localhost:3000`.
2. Reads the `smoke_checks:` YAML block from the task spec (between fenced ` ```yaml` and ` ``` ` block, OR a top-level YAML frontmatter section — the implementer chooses but documents the choice).
3. For each entry, issues a fetch, asserts `expect_status`, and applies optional assertions. Returns exit code 0 on all-pass, 1 on any-fail. Prints a per-check pass/fail line and an overall summary.
4. The script does NOT start or stop the dev server. The implementer (per the Implement skill's Smoke-Check Verification step) handles dev-server lifecycle. The script assumes the server is already listening at `--base-url`.
5. Auth scaffolding: for `auth: none`, no cookies. For `auth: signed-in` / `auth: admin`, the script reads `smoke_auth:` from the task spec (or a sibling `smoke-auth.json` file the plan provides) and attaches the named cookie to each request. If `auth: signed-in` is declared but no `smoke_auth:` is found, fail loudly with a clear message — no fallback.
6. Pure Node 18+ stdlib. No npm deps.

- [ ] **Step 1: Write the failing bats test**

Create `tests/unit/test-run-smoke-checks.bats`:

```bash
#!/usr/bin/env bats

setup_file() {
  REPO_ROOT="$(cd "$(dirname "${BATS_TEST_FILENAME}")/../.." && pwd -P)"
  export REPO_ROOT
  TMP_DIR="$(mktemp -d)"
  export TMP_DIR

  # Start a tiny Node test server in the background to fixture against.
  cat > "$TMP_DIR/server.mjs" <<'EOF'
import { createServer } from 'node:http';
const server = createServer((req, res) => {
  if (req.url === '/ok') {
    res.writeHead(200, { 'content-type': 'text/html' });
    res.end('<html><head><link rel="stylesheet" href="/globals.css"/></head><body>Hello World</body></html>');
  } else if (req.url === '/redirect') {
    res.writeHead(302, { 'location': '/ok' });
    res.end();
  } else if (req.url === '/protected') {
    const cookie = req.headers.cookie ?? '';
    if (cookie.includes('test-session=valid')) {
      res.writeHead(200, { 'content-type': 'text/plain' });
      res.end('admin area');
    } else {
      res.writeHead(401, { 'content-type': 'text/plain' });
      res.end('unauthorized');
    }
  } else {
    res.writeHead(404);
    res.end();
  }
});
server.listen(0, () => {
  console.log(server.address().port);
});
EOF

  # Boot it and capture the port.
  node "$TMP_DIR/server.mjs" > "$TMP_DIR/port.txt" &
  SERVER_PID=$!
  export SERVER_PID
  # Wait briefly for port output.
  for i in 1 2 3 4 5 6 7 8 9 10; do
    if [ -s "$TMP_DIR/port.txt" ]; then break; fi
    sleep 0.1
  done
  PORT="$(cat "$TMP_DIR/port.txt")"
  export PORT
  export BASE_URL="http://localhost:$PORT"
}

teardown_file() {
  if [ -n "${SERVER_PID:-}" ]; then
    kill "$SERVER_PID" 2>/dev/null || true
  fi
  rm -rf "$TMP_DIR"
}

@test "exits 0 when all smoke checks pass" {
  cat > "$TMP_DIR/task.md" <<EOF
# Task: example

\`\`\`yaml
smoke_checks:
  - path: /ok
    auth: none
    expect_status: 200
    expect_body_contains:
      - "Hello World"
    expect_link_href_pattern: "globals\\\\.css"
\`\`\`
EOF
  run node "$REPO_ROOT/scripts/run-smoke-checks.mjs" --task-spec "$TMP_DIR/task.md" --base-url "$BASE_URL"
  [ "$status" -eq 0 ]
}

@test "exits 1 when a status assertion fails" {
  cat > "$TMP_DIR/task.md" <<EOF
\`\`\`yaml
smoke_checks:
  - path: /ok
    auth: none
    expect_status: 500
\`\`\`
EOF
  run node "$REPO_ROOT/scripts/run-smoke-checks.mjs" --task-spec "$TMP_DIR/task.md" --base-url "$BASE_URL"
  [ "$status" -eq 1 ]
}

@test "exits 1 when expect_body_contains is missing from response" {
  cat > "$TMP_DIR/task.md" <<EOF
\`\`\`yaml
smoke_checks:
  - path: /ok
    auth: none
    expect_status: 200
    expect_body_contains:
      - "Goodbye"
\`\`\`
EOF
  run node "$REPO_ROOT/scripts/run-smoke-checks.mjs" --task-spec "$TMP_DIR/task.md" --base-url "$BASE_URL"
  [ "$status" -eq 1 ]
}

@test "follows expect_location on a 302" {
  cat > "$TMP_DIR/task.md" <<EOF
\`\`\`yaml
smoke_checks:
  - path: /redirect
    auth: none
    expect_status: 302
    expect_location: /ok
\`\`\`
EOF
  run node "$REPO_ROOT/scripts/run-smoke-checks.mjs" --task-spec "$TMP_DIR/task.md" --base-url "$BASE_URL"
  [ "$status" -eq 0 ]
}

@test "uses smoke_auth cookie for auth: signed-in" {
  cat > "$TMP_DIR/task.md" <<EOF
\`\`\`yaml
smoke_auth:
  cookie_name: test-session
  cookie_value: valid
smoke_checks:
  - path: /protected
    auth: signed-in
    expect_status: 200
    expect_body_contains:
      - "admin area"
\`\`\`
EOF
  run node "$REPO_ROOT/scripts/run-smoke-checks.mjs" --task-spec "$TMP_DIR/task.md" --base-url "$BASE_URL"
  [ "$status" -eq 0 ]
}

@test "fails loudly when auth: signed-in is declared but smoke_auth is missing" {
  cat > "$TMP_DIR/task.md" <<EOF
\`\`\`yaml
smoke_checks:
  - path: /protected
    auth: signed-in
    expect_status: 200
\`\`\`
EOF
  run node "$REPO_ROOT/scripts/run-smoke-checks.mjs" --task-spec "$TMP_DIR/task.md" --base-url "$BASE_URL"
  [ "$status" -eq 1 ]
  [[ "$output" =~ smoke_auth ]]
}

@test "exits 1 when no smoke_checks block found" {
  cat > "$TMP_DIR/task.md" <<EOF
# A task with no smoke checks.
EOF
  run node "$REPO_ROOT/scripts/run-smoke-checks.mjs" --task-spec "$TMP_DIR/task.md" --base-url "$BASE_URL"
  [ "$status" -eq 1 ]
  [[ "$output" =~ "no smoke_checks" ]]
}
```

- [ ] **Step 2: Run, verify FAIL**

Run: `bats tests/unit/test-run-smoke-checks.bats`. Expected: all 7 tests fail (script does not exist).

- [ ] **Step 3: Implement `scripts/run-smoke-checks.mjs`**

Pure-stdlib Node ESM. The implementation must:

- Parse `--task-spec`, `--base-url`, `--port` flags. (`--port` overrides the port portion of `--base-url`.)
- Read the task-spec file, extract the first ` ```yaml ... ``` ` fenced block whose body contains `smoke_checks:`.
- Parse YAML using a minimal hand-rolled parser scoped to the subset above (top-level keys, lists of objects, scalar values, double-quoted strings, integers). Do NOT pull in a YAML lib. The supported subset is: top-level keys (`smoke_checks:`, `smoke_auth:`); under `smoke_checks:`, a list of mapping entries; under each mapping, scalar fields; under `expect_body_contains:` / `expect_body_not_contains:`, lists of scalars. If the YAML structure violates this subset, exit 1 with a parse-error message naming the line.
- For each smoke-check entry: issue a fetch with `redirect: 'manual'` so 30x are observable. Apply `expect_status` exactly. Apply optional assertions per the convention.
- For `auth: signed-in` / `auth: admin`: read `smoke_auth:` from the same YAML block and attach `Cookie: <cookie_name>=<cookie_value>` to the request. If absent, exit 1 with the literal string `smoke_auth required for auth: signed-in but not declared in task spec`.
- For `expect_link_href_pattern`: parse the response body with a regex like `/<link[^>]+rel=["']stylesheet["'][^>]+href=["']([^"']+)["']/gi`, collect hrefs, and pass if any matches the pattern. Pattern is interpreted as a JavaScript RegExp source string.
- Print one line per check: `[PASS] /path` or `[FAIL] /path: <reason>`. Print a summary line: `N passed, M failed of K`.
- Exit 0 if all pass, 1 otherwise. Exit 1 with `no smoke_checks found in <path>` if no block.
- No npm deps, no top-level await on optional modules. Use `node:http`, `node:fs`, `node:url`, `node:process`.

- [ ] **Step 4: Run bats, verify all PASS**

Run: `bats tests/unit/test-run-smoke-checks.bats`. Expected: 7 passes.

If any test reports timeout or hang, check the test fixture's server didn't get the port assignment race. The 1-second port-wait loop in `setup_file` should cover it; if not, increase the loop count.

- [ ] **Step 5: Commit**

```bash
git -C /private/tmp/qrspi-drift add scripts/run-smoke-checks.mjs tests/unit/test-run-smoke-checks.bats
git -C /private/tmp/qrspi-drift commit -m "feat(scripts): add run-smoke-checks.mjs runtime gate helper"
```

---

## Task 6: Sibling-notification protocol (Item 3a)

**Files:**
- Create: `skills/implementer-protocol/notifications.md`
- Modify: `skills/implementer-protocol/SKILL.md` — link in the new file
- Modify: `skills/implement/SKILL.md` — add shared-base impact analysis step
- Create: `tests/unit/test-sibling-notification-protocol.bats`

**Design latitude:** the notification file format is at the implementer's discretion as long as the contract is met. The example below uses Markdown frontmatter; a YAML or JSON shape is also acceptable.

**Contracts to satisfy:**

1. Notifications live under `tasks/task-NN/notifications/<timestamp>-from-task-<source>.md` (one file per notification).
2. Each notification names: source task, target file, target symbol (if applicable), the change shape (signature diff, rename, removal, etc.), and a short suggested action.
3. The implementer-protocol's at-task-start checklist now includes "list `tasks/task-NN/notifications/`; if non-empty, surface each in spec-context". Each notification must be marked "addressed" (with a one-line reason) or "n/a" (with a one-line reason) before task completion. Unaddressed notifications block DONE.
4. The Implement skill's per-task verification step adds "shared-base impact analysis" after a fix-cycle: run `scripts/sibling-impact.mjs` (added in Task 7), write notification entries to affected siblings.

- [ ] **Step 1: Write the failing bats test**

Create `tests/unit/test-sibling-notification-protocol.bats`:

```bash
#!/usr/bin/env bats

setup_file() {
  REPO_ROOT="$(cd "$(dirname "${BATS_TEST_FILENAME}")/../.." && pwd -P)"
  export REPO_ROOT
}

@test "implementer-protocol/notifications.md exists" {
  [ -f "$REPO_ROOT/skills/implementer-protocol/notifications.md" ]
}

@test "notifications.md describes path tasks/task-NN/notifications/" {
  run grep -F 'tasks/task-' "$REPO_ROOT/skills/implementer-protocol/notifications.md"
  [ "$status" -eq 0 ]
  run grep -F 'notifications/' "$REPO_ROOT/skills/implementer-protocol/notifications.md"
  [ "$status" -eq 0 ]
}

@test "notifications.md requires source task and changed file" {
  run grep -E -i 'source.*task|from.task' "$REPO_ROOT/skills/implementer-protocol/notifications.md"
  [ "$status" -eq 0 ]
  run grep -E -i 'changed file|target file|file' "$REPO_ROOT/skills/implementer-protocol/notifications.md"
  [ "$status" -eq 0 ]
}

@test "notifications.md describes addressed/n-a marking" {
  run grep -E -i 'addressed|n/a|not applicable' "$REPO_ROOT/skills/implementer-protocol/notifications.md"
  [ "$status" -eq 0 ]
}

@test "implementer-protocol/SKILL.md links to notifications.md" {
  run grep -F 'notifications.md' "$REPO_ROOT/skills/implementer-protocol/SKILL.md"
  [ "$status" -eq 0 ]
}

@test "implementer-protocol/SKILL.md has at-task-start step listing notifications/" {
  run grep -E -i 'notifications/|notifications directory|task start.*notifications' "$REPO_ROOT/skills/implementer-protocol/SKILL.md"
  [ "$status" -eq 0 ]
}

@test "implement/SKILL.md adds shared-base impact analysis step" {
  run grep -E -i 'shared.base impact|sibling.impact|sibling notification' "$REPO_ROOT/skills/implement/SKILL.md"
  [ "$status" -eq 0 ]
}

@test "implement/SKILL.md references scripts/sibling-impact" {
  run grep -F 'sibling-impact' "$REPO_ROOT/skills/implement/SKILL.md"
  [ "$status" -eq 0 ]
}
```

- [ ] **Step 2: Run, verify FAIL**

Run: `bats tests/unit/test-sibling-notification-protocol.bats`. Expected: 8 failures.

- [ ] **Step 3: Create `skills/implementer-protocol/notifications.md`**

Content:

```markdown
---
name: notifications
description: Sibling-notification protocol — how cross-task contract changes surface to dependent tasks
---

# Sibling notifications

Tasks running in parallel QRSPI worktrees can drift apart when one task's
fix-cycle changes a contract another task depends on. The keeplii-simplified
SweepError-shape drift (task-29 vs task-30/task-32) and the requireAuth
collision (task-08 vs task-16) are canonical examples: the surface only
appeared at integrate.

This protocol surfaces those drifts at the source: when task-N's fix-cycle
modifies a file outside its own scope, the implementer skill computes a
notification for each sibling task whose spec or code references the
changed symbol and writes it to that sibling's notifications directory.

## Notification location

`tasks/task-MM/notifications/<timestamp>-from-task-<NN>.md`

Where `MM` is the affected sibling's task number, `NN` is the source task,
and `<timestamp>` is ISO 8601 (e.g., `2026-05-09T18-04-22Z` — colons
replaced with hyphens for filesystem safety).

## Notification content

Each notification names:

- `source_task` — the task whose change triggered this notification
- `source_commit` — the SHA of the commit that introduced the change
- `target_file` — the file whose contract changed
- `target_symbol` — the affected exported symbol, when applicable
- `change_shape` — one of `signature_change`, `rename`, `removal`, `behavior_change`
- `before` / `after` — minimal diff fragment showing the contract delta
- `suggested_action` — one short sentence — refit, rename, no-op-with-rationale

Example:

```markdown
---
source_task: 29
source_commit: 011a770
target_file: src/lib/jobs/types.ts
target_symbol: SweepError
change_shape: signature_change
suggested_action: refit emit sites to discriminated-union shape
---

## Before

```ts
export type SweepError = { targetId: string; message: string };
```

## After

```ts
export type SweepError =
  | { kind: 'target'; targetId: string; message: string }
  | { kind: 'sweep'; message: string };
```

The `targetId: '__sweep__'` sentinel is replaced by the `kind: 'sweep'` arm.
Sibling tasks emitting `SweepError` must update emit sites; sibling tests
reading `error.targetId` must narrow to the `kind: 'target'` arm.
```

## At-task-start protocol

At the start of any task run, list `tasks/task-NN/notifications/`. If
non-empty:

1. Surface each notification in the implementer's spec-context block.
2. Treat each as a checklist item that must be either:
   - **addressed** — with a one-line reason describing what was changed in
     this task to refit the contract, OR
   - **n/a** — with a one-line reason describing why this task is not
     affected (e.g., "this task no longer imports the changed symbol").

Unaddressed notifications block DONE. The implementer cannot mark a task
DONE while any notification is in pending state. If a notification cannot
be resolved within the task's scope (e.g., the refit requires a separate
plan), report DONE_WITH_CONCERNS and explicitly name the deferred
notification.

## Source-side: writing notifications

The Implement skill's per-task verification step runs the shared-base
impact analyzer (`scripts/sibling-impact.mjs`) after a fix-cycle modifies
files outside the task's own scope. The analyzer emits notifications for
each affected sibling task. The implementer running the source task does
NOT need to author notifications by hand — the analyzer does it.

Notifications are advisory: a future planner pass or sibling implementer
can mark them n/a if they're false positives. False positives are
preferable to silent drift.
```

- [ ] **Step 4: Edit `skills/implementer-protocol/SKILL.md`**

Add a new section `## Notifications (At Task Start)` near the top of the file (after `## Dispatch Parameters` is a good spot). Content (in substance):

> ## Notifications (At Task Start)
>
> Before beginning work on a task, list `tasks/task-NN/notifications/`. If the directory is non-empty, surface each notification in your spec-context block and resolve each one (addressed or n/a) before reporting DONE. See [`notifications.md`](notifications.md) for the full protocol.

- [ ] **Step 5: Edit `skills/implement/SKILL.md`**

Add a new `### Shared-Base Impact Analysis (Per Task, Post-Fix)` subsection after the build-verification step:

> ### Shared-Base Impact Analysis (Per Task, Post-Fix)
>
> After a fix-cycle modifies any file outside `tasks/task-NN/`, run the shared-base impact analyzer:
>
> `node scripts/sibling-impact.mjs --task-id NN --commit <fix-commit-sha> --base <base-branch>`
>
> The analyzer:
> 1. Diffs the fix-commit against the base branch.
> 2. For each modified file outside `tasks/task-NN/`, computes the set of sibling task branches that import or reference the changed symbols.
> 3. Writes notification entries to `tasks/task-MM/notifications/` for each affected sibling per the [notifications protocol](../implementer-protocol/notifications.md).
>
> The analyzer is advisory: false positives can be marked n/a by the sibling implementer. Skipping the analyzer is permitted only if the fix touched no files outside `tasks/task-NN/`.

- [ ] **Step 6: Run bats, verify PASS**

Run: `bats tests/unit/test-sibling-notification-protocol.bats`. Expected: 8 passes.

- [ ] **Step 7: Commit**

```bash
git -C /private/tmp/qrspi-drift add skills/implementer-protocol/notifications.md skills/implementer-protocol/SKILL.md skills/implement/SKILL.md tests/unit/test-sibling-notification-protocol.bats
git -C /private/tmp/qrspi-drift commit -m "feat(implementer-protocol): add sibling-notification protocol"
```

---

## Task 7: sibling-impact.mjs script (Item 3b)

**Files:**
- Create: `scripts/sibling-impact.mjs`
- Create: `tests/unit/test-sibling-impact.bats`

**Contracts to satisfy:**

1. Script signature: `node scripts/sibling-impact.mjs --task-id <NN> --commit <SHA> --base <branch> [--tasks-dir <path>]`. Default `--tasks-dir` is `tasks/`.
2. Reads the diff introduced by `<commit>` via `git diff --name-only <commit>^..<commit>`. The `--base` flag is the fallback used only when `<commit>` has no parent (root commit). This matches the real-world semantic: the analyzer reports what *this* fix-cycle changed, not what diverges from base across multiple commits.
3. For each modified file outside `tasks/task-<NN>/`, finds candidate sibling tasks: every directory under `tasks/` matching `task-<MM>` for `MM != NN`. A candidate is "affected" if any file under its directory contains a literal substring match for the **full changed file path**. (Phase 1 uses full-path substring matching only — basename matching produces false positives for generic names like `index.ts`. Symbol-aware diff is deferred to a future iteration.)
4. For each affected sibling, writes a notification file at `tasks/task-MM/notifications/<timestamp>-from-task-<NN>.md` per the notifications protocol. The notification names: source_task, source_commit, target_file, change_shape (`file_changed` for Phase 1 — symbol-shape detection deferred), and a generic suggested_action stub.
5. Prints one line per notification written: `Wrote tasks/task-MM/notifications/...`. Exits 0 if any notifications were written, 0 if no affected siblings, 1 only on a hard error (git unavailable, --task-id missing, etc.).
6. Pure Node 18+ stdlib. Uses `node:child_process` to invoke `git`.

- [ ] **Step 1: Write the failing bats test**

Create `tests/unit/test-sibling-impact.bats`:

```bash
#!/usr/bin/env bats

setup_file() {
  REPO_ROOT="$(cd "$(dirname "${BATS_TEST_FILENAME}")/../.." && pwd -P)"
  export REPO_ROOT
}

setup() {
  # Each test runs in its own throwaway git repo with a tasks/ tree.
  TMP_DIR="$(mktemp -d)"
  cd "$TMP_DIR"
  git init -q
  git config user.email t@t.test
  git config user.name t
  git checkout -q -b base

  mkdir -p src/lib tasks/task-01 tasks/task-02 tasks/task-03
  echo 'export type X = { a: number };' > src/lib/types.ts
  echo "Task 01 — modifies src/lib/types.ts" > tasks/task-01/spec.md
  echo "Task 02 — references src/lib/types.ts" > tasks/task-02/spec.md
  echo "Task 03 — does not touch types.ts" > tasks/task-03/spec.md

  git add .
  git commit -q -m "base"

  # Task 01 modifies the shared type.
  git checkout -q -b task-01
  echo 'export type X = { kind: "a"; a: number } | { kind: "b" };' > src/lib/types.ts
  git add .
  git commit -q -m "task-01: change X"
  TASK_01_SHA="$(git rev-parse HEAD)"

  export TMP_DIR TASK_01_SHA
}

teardown() {
  cd /
  rm -rf "$TMP_DIR"
}

@test "writes a notification for sibling task that references the changed file" {
  run node "$REPO_ROOT/scripts/sibling-impact.mjs" --task-id 01 --commit "$TASK_01_SHA" --base base --tasks-dir "$TMP_DIR/tasks"
  [ "$status" -eq 0 ]

  # task-02 references types.ts → notification expected.
  run bash -c "ls $TMP_DIR/tasks/task-02/notifications/*.md 2>/dev/null | wc -l"
  [ "$status" -eq 0 ]
  [ "$output" -ge 1 ]

  # task-03 does not reference types.ts → no notification.
  [ ! -d "$TMP_DIR/tasks/task-03/notifications" ] || \
    [ "$(ls $TMP_DIR/tasks/task-03/notifications | wc -l)" -eq 0 ]

  # task-01 (the source) does not get a self-notification.
  [ ! -d "$TMP_DIR/tasks/task-01/notifications" ] || \
    [ "$(ls $TMP_DIR/tasks/task-01/notifications | wc -l)" -eq 0 ]
}

@test "notification names source task and changed file" {
  run node "$REPO_ROOT/scripts/sibling-impact.mjs" --task-id 01 --commit "$TASK_01_SHA" --base base --tasks-dir "$TMP_DIR/tasks"
  [ "$status" -eq 0 ]

  notif="$(ls $TMP_DIR/tasks/task-02/notifications/*.md | head -1)"
  run grep -F 'source_task: 01' "$notif"
  [ "$status" -eq 0 ]
  run grep -F 'src/lib/types.ts' "$notif"
  [ "$status" -eq 0 ]
}

@test "exits 0 when no siblings reference the changed file" {
  # Make a change in a file no sibling references.
  cd "$TMP_DIR"
  git checkout -q task-01
  echo 'orphan' > src/lib/orphan-no-refs.ts
  git add .
  git commit -q -m "orphan add"
  ORPHAN_SHA="$(git rev-parse HEAD)"

  run node "$REPO_ROOT/scripts/sibling-impact.mjs" --task-id 01 --commit "$ORPHAN_SHA" --base base --tasks-dir "$TMP_DIR/tasks"
  [ "$status" -eq 0 ]
}

@test "exits 1 when --task-id is missing" {
  run node "$REPO_ROOT/scripts/sibling-impact.mjs" --commit "$TASK_01_SHA" --base base --tasks-dir "$TMP_DIR/tasks"
  [ "$status" -eq 1 ]
  [[ "$output" =~ "task-id" ]]
}

@test "exits 1 when --commit is missing" {
  run node "$REPO_ROOT/scripts/sibling-impact.mjs" --task-id 01 --base base --tasks-dir "$TMP_DIR/tasks"
  [ "$status" -eq 1 ]
  [[ "$output" =~ "commit" ]]
}

@test "skips changes inside the source task's own directory" {
  cd "$TMP_DIR"
  git checkout -q task-01
  echo 'self change' >> tasks/task-01/spec.md
  git add .
  git commit -q -m "task-01 self change"
  SELF_SHA="$(git rev-parse HEAD)"

  run node "$REPO_ROOT/scripts/sibling-impact.mjs" --task-id 01 --commit "$SELF_SHA" --base base --tasks-dir "$TMP_DIR/tasks"
  [ "$status" -eq 0 ]

  # No sibling notifications.
  [ ! -d "$TMP_DIR/tasks/task-02/notifications" ] || \
    [ "$(ls $TMP_DIR/tasks/task-02/notifications | wc -l)" -eq 0 ]
}
```

- [ ] **Step 2: Run, verify FAIL**

Run: `bats tests/unit/test-sibling-impact.bats`. Expected: 6 failures (script does not exist).

- [ ] **Step 3: Implement `scripts/sibling-impact.mjs`**

Pure-stdlib Node ESM. The implementation must:

- Parse `--task-id`, `--commit`, `--base`, `--tasks-dir` flags. Required: `--task-id`, `--commit`. Default `--base` is `main`. Default `--tasks-dir` is `tasks/`.
- Run `git diff --name-only <commit>^..<commit>` to get the files this commit introduced. If the commit has no parent (root commit), fall back to `git diff --name-only <base> <commit>`. Cwd is the project root (the `tasks-dir`'s parent if absolute, else `process.cwd()`).
- Filter to changes outside `tasks/task-<task-id>/`.
- For each remaining changed file, scan sibling task directories under `tasks-dir`:
  - Walk each `tasks/task-<MM>/` directory recursively (depth-first, files only).
  - For each text file under that directory, check whether the file's contents include the full changed-file path as a literal substring. (Basename-only matching is intentionally NOT applied — it produces false positives for generic names like `index.ts`.)
  - If yes, mark task-MM as affected.
- For each (sibling-task, changed-file) pair, write a notification file:
  - Path: `<tasks-dir>/task-<MM>/notifications/<ISO-timestamp-with-hyphens>-from-task-<NN>.md`
  - Content: frontmatter block per the notifications protocol example, plus a "## Suggested action" body section with a generic "Review the diff at <commit-sha> and refit, or mark n/a." stub. Do NOT attempt to detect signature shapes in Phase 1.
- Print one line per notification: `Wrote <path>`.
- Exit 0 on success (whether or not any notifications were written). Exit 1 only on hard errors (missing flags, git unavailable, tasks-dir not a directory).

- [ ] **Step 4: Run bats, verify all PASS**

Run: `bats tests/unit/test-sibling-impact.bats`. Expected: 6 passes.

- [ ] **Step 5: Commit**

```bash
git -C /private/tmp/qrspi-drift add scripts/sibling-impact.mjs tests/unit/test-sibling-impact.bats
git -C /private/tmp/qrspi-drift commit -m "feat(scripts): add sibling-impact.mjs cross-task drift detector"
```

---

## End-of-plan: full bats run

After all 7 tasks land, run the full unit test suite to confirm no regressions in pre-existing tests:

```bash
bats tests/unit
```

Expected: all existing tests still pass, plus the 7 new test files (with their assertion counts) pass too. If any pre-existing test now fails, the plan triggered an unexpected interaction — escalate.

## Self-review checklist (controller, before merge)

- [ ] Each task is atomic — produces a single commit, with bats green at the commit boundary
- [ ] No task references content authored by a later task
- [ ] All four items from the spec doc have at least one task per item:
  - Item 1 → Task 1
  - Item 2 → Tasks 4, 5
  - Item 3 → Tasks 6, 7
  - Item 4 → Tasks 2, 3
- [ ] No `package.json` or new npm dep was introduced
- [ ] All `node` scripts run on Node 18+ stdlib only
- [ ] All bats tests use `setup_file` / `setup` / `teardown` per existing convention

## Execution Handoff

Use **superpowers:subagent-driven-development**. Each task dispatches a fresh subagent with the full task text + scene-setting context. Two-stage review per task: spec-reviewer first, code-quality-reviewer second. Tasks are sequential (no parallel implementer dispatches per SDD red-flag). Worktree is `/private/tmp/qrspi-drift`; branch is `feat/integration-drift-mitigations`.
