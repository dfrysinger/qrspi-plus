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
      extends: options.projectTsconfig ?? join(process.cwd(), 'tsconfig.json'),
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
