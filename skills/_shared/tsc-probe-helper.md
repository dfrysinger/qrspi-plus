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

The legacy pattern — running probes through the project tsconfig — is
**deprecated**. Tasks using the tsc-probe pattern MUST use the helper
template at `templates/tsc-probe.ts`, vendored into the project's
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
