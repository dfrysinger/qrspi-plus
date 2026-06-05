# F03 — Walker silently skips ENOENT on `statSync`, masking dangling symlinks and races

**Severity:** Medium
**Category:** Swallowed error / log-and-continue (without the log)
**File:** `tools/build-plugin.mjs`
**Lines:** 237–243

## What

```js
try {
  st = fs.statSync(srcAbs);
} catch (e) {
  if (e && e.code === 'ENOENT') continue; // dangling symlink
  throw e;
}
```

The `continue` swallows ENOENT with no diagnostic. The comment claims
"dangling symlink," but `statSync` returns ENOENT for at least three
distinct conditions:

1. The entry is a symlink whose target does not exist (the assumed case).
2. A concurrent process deleted the entry between `readdirSync` and
   `statSync` (TOCTOU race; legitimate but worth knowing).
3. The entry's path component contains a broken intermediate link
   (subtler symlink-escape variant).

In all three the file is silently dropped from `build/`. The build still
exits 0 and the CI diff gate sees no drift — it just sees a smaller
`build/`.

## Why it matters

Task 39's whole posture is fail-loud: missing `!cat` targets fail with
`target not found`, outside-root resolves fail with `resolves outside
repository`, etc. A dangling symlink at the *file* level is morally the
same kind of "this path does not name real bytes" condition and should
reach the operator with the same diagnostic vocabulary, not be silently
elided.

Concretely:

- A contributor moves a file but forgets to remove the dangling symlink
  → the file silently disappears from `build/` and they don't notice
  until a host can't find it.
- The symlink-escape regression fixture (task-39 §Test expectations)
  hinges on canonical-target diagnostics. A *broken* symlink-escape
  variant (target outside repo *and* doesn't exist) currently produces
  zero output and zero exit code — instead of the
  `resolves outside repository` audit phrase the task requires.

The combination of `force: true` on `rmSync` (F02) and this silent
`continue` means two of the three "things go missing" failure modes in
this script produce no diagnostic at all.

## Recommended fix

Use `fs.lstatSync` (no symlink follow) for the structural decision. If
`lstat` shows a symlink, `realpathSync` is the right next step — and any
ENOENT from `realpathSync` should map to the existing `BuildError`
phrasing:

```js
const lst = fs.lstatSync(srcAbs);   // succeeds even on dangling symlinks
if (lst.isSymbolicLink()) {
  // Force the realpath/canonical check; ENOENT here is a build failure,
  // not a silent skip.
  let canonical;
  try { canonical = fs.realpathSync(srcAbs); }
  catch (e) {
    if (e && e.code === 'ENOENT') {
      throw new BuildError(`${rel}: dangling symlink (target does not exist)`);
    }
    throw e;
  }
  // ... outside-root check, then stat the canonical path.
}
```

At minimum, write `build-plugin: skipping ${rel} (dangling symlink)` to
stderr instead of a bare `continue`, and consider making it fail-loud by
default with a `--allow-dangling-symlinks` opt-out (none of the current
test surface needs the silent-skip behavior).

## Test gap

No fixture covers a dangling symlink in the source tree. Add one that
asserts the build fails non-zero with a clear diagnostic when a tracked
symlink under `skills/` has no extant target.
