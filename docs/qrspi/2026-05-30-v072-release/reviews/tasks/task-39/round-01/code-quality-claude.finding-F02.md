---
finding_id: F02
severity: minor
category: dry
files:
  - tools/build-plugin.mjs
---

# F02 — Outside-root canonical-path guard duplicated three times

The "canonicalize via `fs.realpathSync`, then assert the result is `===
rootReal` or starts with `rootReal + sep`, else throw `BuildError(... resolves
outside repository ...)`" pattern is open-coded in three places:

1. `resolveTarget` (lines 125–143) — for `!cat` target relpaths.
2. `copyFilePreservingMode` (lines 207–222) — for non-`.md` source files.
3. `walk` inline `.md` preflight (lines 253–269) — for `.md` source files
   before resolver expansion.

All three blocks share the same shape: `try { canonical = fs.realpathSync(abs)
} catch (ENOENT) → "target not found"; else rethrow`, followed by the same
`canonical !== rootReal && !canonical.startsWith(rootReal + sep)` membership
check, followed by a `BuildError` whose message contains the audit phrase
`resolves outside repository (canonical: ...)`. The three error-message
prefixes differ slightly (`<rel>:<line>:` vs `<rel>:` vs `<rel>:`), which is
the only meaningful variation.

**Suggested remediation:** Extract a single helper, e.g.

```js
// Canonicalize `absPath` and assert it lies under `ctx.rootReal`. Throws a
// BuildError with the audit-friendly `resolves outside repository` phrase if
// the canonical path escapes root, or a `target not found` BuildError on
// ENOENT. `label` is the diagnostic prefix (e.g. `<rel>:<line>` or `<rel>`).
function canonicalUnderRoot(absPath, label, ctx) { ... }
```

and call it from all three sites. Benefits: the audit-phrase wording can never
drift between the three guards (today it's identical, but a future edit to one
won't propagate); the ENOENT-handling spelling is centralized; and the
symlink-escape regression test exercises one code path instead of three.

**Why minor:** Behavior is correct and the duplication is small (≈8 lines × 3).
The risk is drift, not bugs.
