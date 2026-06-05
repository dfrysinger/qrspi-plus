# F02 — `--out` resolving to repo root silently `rm -rf`'s the entire repo

**Severity:** High (catastrophic data loss; partial-state / silent
destructive failure)
**Category:** Partial state on failure / missing precondition guard
**File:** `tools/build-plugin.mjs`
**Lines:** 292–309 (`outDirAbs` resolution and unconditional `rmSync`)

## What

```js
const outDirAbs = path.resolve(
  rootReal,
  args.out || path.join(rootReal, 'build'),
);
...
let outRelFromRoot = null;
if (outDirAbs === rootReal || outDirAbs.startsWith(rootReal + path.sep)) {
  outRelFromRoot = path.relative(rootReal, outDirAbs);
  if (outRelFromRoot === '') outRelFromRoot = null;       // ← swallows the
                                                          //    "out is root"
                                                          //    case
}

if (fs.existsSync(outDirAbs)) {
  fs.rmSync(outDirAbs, { recursive: true, force: true }); // ← wipes root
}
fs.mkdirSync(outDirAbs, { recursive: true });
```

Three invocations all resolve `outDirAbs` to `rootReal`:

1. `node tools/build-plugin.mjs --out .`
2. `node tools/build-plugin.mjs --out "$PWD"` (when run from repo root)
3. `node tools/build-plugin.mjs --out ''` (empty value still passes the
   `args.out || ...` truthiness check; correct — but `--out` with the
   value as the literal repo root path hits this too)

When that happens the script (a) blanks `outRelFromRoot` to `null` so the
walker has no signal to skip the output dir, and (b) executes
`fs.rmSync(rootReal, { recursive: true, force: true })`. The user's
working tree, including `.git`, is destroyed before any walk happens.
There is no diagnostic, no confirmation, no dry-run mode, and `force:
true` actively suppresses errors that might otherwise abort it.

## Why it matters

This is the textbook §6 partial-state silent failure: a single typo
(`--out .` instead of `--out ./build`) wipes the contributor's repo
including uncommitted work and the `.git` history. The CI workflow runs
without `--out` so CI itself is safe, but the script is documented as a
local rebuild tool in CONTRIBUTING.md (per task-39 scope), so
contributors *will* invoke it manually.

## Recommended fix

Before the wipe, fail loud on any of:

- `outDirAbs === rootReal`
- `outDirAbs` is a parent of `rootReal` (`rootReal.startsWith(outDirAbs +
  path.sep)`)
- `outDirAbs` resolves to `/`, `process.env.HOME`, or any path with no
  parent directory

```js
if (outDirAbs === rootReal ||
    outDirAbs === path.parse(outDirAbs).root ||
    rootReal === outDirAbs ||
    rootReal.startsWith(outDirAbs + path.sep)) {
  process.stderr.write(
    `build-plugin: refusing to wipe --out (${outDirAbs}) — ` +
    `must be a strict subdirectory of --root (${rootReal})\n`,
  );
  process.exit(2);
}
```

Also drop `force: true` from `rmSync` so EACCES / EBUSY surface instead
of being silently ignored.

## Test gap

No unit test exercises `--out` pointing at the repo root. Add one that
invokes the script in a sandbox and asserts (a) non-zero exit, (b) the
sandbox repo's tracked files still exist post-invocation.
