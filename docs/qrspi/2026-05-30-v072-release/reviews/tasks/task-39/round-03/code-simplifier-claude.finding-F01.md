# F01: Triplicated canonical-path / outside-root check

**Severity:** low (code-simplifier; semantics-preserving)
**File:** `tools/build-plugin.mjs`
**Lines:** 145–177, 264–284, 341–361

## Pattern

Three separate sites perform the same six-step check sequence on a
source-side absolute path:

1. `fs.realpathSync(srcAbs)` → canonical
2. `catch (e)` — if `e.code === 'ENOENT'` throw `BuildError("…: target not found…")`, else rethrow
3. Compare `canonical !== ctx.rootReal && !canonical.startsWith(ctx.rootReal + path.sep)`
4. If outside, throw `BuildError("…: resolves outside repository (canonical: …)")`
5. Return / use `canonical`

The three sites are:

- `resolveTarget` (lines 145–177) — used by `!cat` directive resolution
- `copyFilePreservingMode` (lines 264–284) — used by non-`.md` shipped files
- The `.md` pre-flight inside `recurseDir` (lines 341–361) — added (per
  the task spec) to catch `SKILL.md` symlinked outside `$REPO_ROOT`

The diagnostic phrasing differs slightly across the three (different
`<file>:<line>:` prefixes) but the canonical-prefix check and the
"audit-friendly diagnostic phrase" `resolves outside repository` are
identical across all three. The task spec explicitly requires this
phrase to appear at every canonicalization surface (so duplicating it
is correct, but the duplication is exactly what motivates extraction).

## Suggested simplification

Extract a single helper that returns the canonical path and throws
`BuildError` with a caller-supplied label prefix. Roughly:

```js
function canonicalizeUnderRoot(srcAbs, label, ctx) {
  let canonical;
  try {
    canonical = fs.realpathSync(srcAbs);
  } catch (e) {
    if (e && e.code === 'ENOENT') {
      throw new BuildError(`${label}: target not found`);
    }
    throw e;
  }
  if (
    canonical !== ctx.rootReal &&
    !canonical.startsWith(ctx.rootReal + path.sep)
  ) {
    throw new BuildError(
      `${label}: resolves outside repository (canonical: ${canonical})`,
    );
  }
  return canonical;
}
```

Then the three call sites collapse to one line each, with `label`
constructed by the caller (e.g. `${sourceRel}:${lineNo}: ${target}` for
`resolveTarget`, `rel` for the directory walk, etc.).

## Why this is semantics-preserving

- `realpathSync` is unchanged.
- ENOENT mapping to `BuildError("…: target not found…")` is unchanged.
- The outside-root predicate is byte-identical across all three sites
  today, so factoring keeps it byte-identical.
- The diagnostic strings end with the same `resolves outside repository
  (canonical: …)` suffix today; if the caller passes the existing
  prefix as `label`, stderr output is unchanged.
- `resolveTarget` currently composes its prefix as `${sourceRel}:${lineNo}: ${target}`
  while `copyFilePreservingMode` uses `${relPath}` and the `.md`
  pre-flight uses `${rel}`; these are caller-specific and stay
  caller-controlled in the suggested shape.

## Scope note

This is a clarity/de-duplication suggestion, not a defect. The current
code works and the task spec explicitly mandates the diagnostic phrase
at every surface — extracting a helper makes "every surface uses the
mandated phrase" a one-line invariant instead of a three-site grep.
