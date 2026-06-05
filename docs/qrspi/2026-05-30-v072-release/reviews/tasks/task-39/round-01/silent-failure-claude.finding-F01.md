# F01 — `${CLAUDE_SKILL_DIR}` guard skips every non-`.md` shipped file

**Severity:** High
**Category:** Missing error path / silent fallback (DoD violation)
**File:** `tools/build-plugin.mjs`
**Lines:** 247–276 (the `entry.name.endsWith('.md')` branching in `walk.recurse`)

## What

`assertNoClaudeSkillDir(...)` only runs inside the `.md` arm of the walker.
The `else` branch (`copyFilePreservingMode`) — which handles every shipped
non-`.md` file: `scripts/*.sh`, `templates/*`, `LICENSE`, `README.md`'s
sibling assets, `.claude-plugin/*.json`, etc. — copies the file to `build/`
without ever scanning the bytes for the legacy token.

```js
if (entry.name.endsWith('.md')) {
  ...
  const expanded = expand(relForward, [], ctx);
  assertNoClaudeSkillDir(relForward, expanded);   // ← only path that scans
  fs.writeFileSync(dstAbs, expanded);
} else {
  copyFilePreservingMode(srcAbs, dstAbs, ctx, rel); // ← no token scan
}
```

## Why it matters

Task 39 §Definition of done is explicit:

> Fail non-zero with file:line plus reason for … any `${CLAUDE_SKILL_DIR}`
> occurrence in shipped files.
>
> shipped-file grep proves zero remaining `${CLAUDE_SKILL_DIR}` occurrences.

"Shipped files" is unqualified — it covers every artifact under `build/`,
not just Markdown. A leftover `${CLAUDE_SKILL_DIR}` in any of:

- `scripts/*.sh` runtime helpers (very plausible — these are *exactly*
  the files that historically referenced `${CLAUDE_SKILL_DIR}` because
  they're shell)
- `templates/*` (templated dispatch prompts may legacy-reference it)
- `.claude-plugin/plugin.json` or any other JSON metadata

…will silently land in `build/` and ship to consumers, defeating the
whole point of the v0.7.2 conversion. The contributor sees an exit-0
build, the CI diff gate sees no drift (because the legacy token survives
build-after-build identically), and the bug is invisible until a host
runtime tries to expand the now-undefined variable and produces wrong
content or a hard-to-attribute resolution failure.

This is also inconsistent with the resolver's own grammar story: `.md`
expansion is the *only* surface that has a chance to detect the token,
yet the token is a runtime-substitution artifact whose primary historical
home was shell scripts.

## Recommended fix

Run the token check on **every** file's bytes, regardless of extension,
inside `copyFilePreservingMode` (and keep the existing post-expansion
check on `.md` since the token can be introduced by an include). E.g.
read the file once into a buffer, scan for `${CLAUDE_SKILL_DIR}` (binary
files won't contain it; the cost is one `Buffer.indexOf` per file), then
write. Re-use `assertNoClaudeSkillDir` after computing a line number from
the byte offset. The diagnostic format `${rel}:${lineNo}: ...` already
matches the contract.

## Test gap

`tests/unit/test-build-gate.bats` and the acceptance fixtures need a
case that places `${CLAUDE_SKILL_DIR}` inside a non-`.md` shipped file
(e.g., a `scripts/sample.sh` fixture) and asserts the build fails
non-zero with the standard diagnostic. Without that case, this regression
is unobservable.
