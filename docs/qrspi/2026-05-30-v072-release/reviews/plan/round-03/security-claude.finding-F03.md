---
finding_id: F03
reviewer: security-claude
round: 3
artifact: plan.md
change_type: correctness
severity: medium
task_refs: [T39]
---

# F03 — T39 `!cat` resolver can inline dev-only / unshipped content into shipped build files; strip-list invariant is not pinned

## Summary

Task 39's build pipeline strips dev-only directories (`docs/`, `tools/`,
`tests/`) from the shipped `build/` tree (DoD line 2242:
"excludes dev-only `build/docs/`, `build/tools/`, and `build/tests/`"). The
`!cat` resolver enforces two path-shape invariants for include targets:

1. Strict whole-line bare-relative grammar (DoD line 2244).
2. Canonical-target-under-`$REPO_ROOT/` symlink-escape rejection (DoD line 2252).

Neither invariant prevents a SHIPPED runtime file (say
`skills/foo/SKILL.md`) from carrying `!cat tests/secret.md` or
`!cat docs/internal-only-design-notes.md`. Both are inside `$REPO_ROOT`, both
have valid bare-relative paths, neither symlink-escapes. The resolver would
happily inline that content into the shipped `build/skills/foo/SKILL.md`, even
though `tests/` and `docs/` themselves never appear in the build tree.

This breaks the dev-only/runtime separation that DoD line 2242 commits to:
"excludes dev-only `build/docs/`, `build/tools/`, and `build/tests/`." The
file-tree level strip-list is bypassable at the **content level** by any
`!cat` directive in a shipped file. The Test Expectations (lines 2256–2267) do
not include a fixture exercising this case.

## Concrete leakage scenarios this enables

1. **Unintentional content leak.** Test fixtures, internal-only docs,
   maintainer-only notes, and any other file deliberately excluded from the
   shipped plugin can be silently embedded into the user-facing skill prose
   via an authoring oversight (`!cat tests/fixtures/sample-prompts/...md`).
   The build succeeds, the diff-gate passes (because `build/` is regenerated
   consistently), and the leak ships.

2. **Future-secret leak.** If `tools/` ever contains a developer
   credential file, generated key material, or vendor-bundled config that the
   strip-list is the only protection against, a single shipped file with
   `!cat tools/<file>` would inline it. Today there's no rule preventing it
   from being added.

3. **Surface for future supply-chain attacks.** A malicious PR can
   add `!cat tests/secret-payload.md` to a shipped SKILL.md as a one-line
   change. Reviewers checking the SKILL.md diff see only a tiny include
   directive; the actual embedded payload lives in `tests/`, which most
   reviewers will treat as not-shipped. The build does what it's told. The
   adversary's payload reaches every end user via the marketplace `./build`
   tarball.

## Why the existing T39 guards don't catch this

- **Outside-root check** (DoD line 2245): `tests/` IS inside the repo root.
  The guard fires only for `/etc/passwd`-shaped targets.
- **Symlink-escape check** (DoD line 2252): `tests/secret.md` is not a
  symlink; it's a regular file inside the repo. The realpath guard passes.
- **Strip-list** (DoD line 2242): operates on whole-tree copy/exclude, not on
  resolver-time `!cat` resolution. By the time `!cat` runs, the resolver
  already has bytes from the unshipped path in memory and writes them into a
  shipped file.

## Recommended remediation (do not require any specific wording)

Add to T39 a **build-set membership invariant** on the resolver:

- A `!cat` target's canonical path MUST be lexically inside one of the
  runtime-include directories (the same allow-list that already drives the
  copy step), not just inside `$REPO_ROOT`. Targets in `docs/`, `tools/`,
  `tests/`, or any path otherwise excluded from `build/` fail non-zero with a
  diagnostic naming the violating include and the unshipped directory.

Add the matching test expectation:

- A fixture commits a shipped runtime file containing
  `!cat tests/fixtures/sample.md` (and the same against `docs/`, `tools/`).
  The build fails non-zero with a diagnostic identifying the dev-only target.
  Without this fixture, the strip-list invariant the DoD claims is not
  actually enforced at content level.

## Files / sections to update

- `plan.md` Task 39 → **Scope: In** (lines 2220–2231) or **Definition of done**
  (around line 2244) — add the build-set membership invariant.
- `plan.md` Task 39 → **Test expectations** (lines 2256–2267) — add a
  dev-only-inline fixture alongside the existing symlink-escape and
  path-traversal fixtures.
