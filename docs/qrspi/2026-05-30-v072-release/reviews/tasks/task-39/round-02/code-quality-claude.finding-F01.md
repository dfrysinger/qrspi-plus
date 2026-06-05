---
finding_id: F01
severity: minor
category: yagni
files:
  - tools/build-plugin.mjs
---

# F01 — Dead `outRelFromRoot` block kept as a self-admitted speculative hook

`tools/build-plugin.mjs:504–515` computes `outRelFromRoot`, never reads it,
and is followed by `void outRelFromRoot;` with the comment:

> // outRelFromRoot is intentionally unused below — kept as a documented
> // observability hook should a future caller want to assert shape.

This is textbook YAGNI: a variable, a conditional, a `path.relative` call, a
`void` suppression, and a comment block — all preserved for a hypothetical
future caller that does not exist in the v0.7.2 surface and is not implied
by any item in `task-39.md` §Definition of done. The leading comment ("kept
for parity with prior versions, though manifest-driven copy never walks
outside the listed roots so an inside-root `build/` is naturally excluded")
also confirms that the manifest-driven posture introduced in this round
makes the value unnecessary for correctness.

The two surrounding guards — equality with `rootReal` and "rootReal under
outDirAbs" — are the load-bearing safety checks (lines 492–503). They run
before this block and stand on their own. Removing lines 504–515 leaves the
guards intact and the wipe step unchanged.

**Suggested remediation:** Delete lines 504–515 (the `let outRelFromRoot`
block, the `void` statement, and their comments). If a future caller ever
needs the value, `path.relative(rootReal, outDirAbs)` is a one-liner at the
call site — speculative pre-computation here adds maintenance surface
without buying anything today.

**Why minor:** No behavior or correctness impact. This is a maintainability
and YAGNI hygiene call: the author's own comment flags it as speculative,
which is the criterion the rule names ("Extension points for hypothetical
future use? Abstractions with only one implementation?" — here, zero
implementations).

This finding is independent of the deferred F02 (`canonicalUnderRoot`
DRY extraction) — different file region, different rule.
