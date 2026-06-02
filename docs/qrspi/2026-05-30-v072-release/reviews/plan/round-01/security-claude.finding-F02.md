---
finding_id: R1-F02
reviewer_tag: security-claude
artifact: plan.md
round: 1
severity: medium
change_type: correctness
location: "Task 39 (G32 plugin build pipeline) — Scope (In) / Definition of done / Test expectations; compare against Task 21's symlink-canonicalization requirement"
---

## Issue

Task 39's `!cat` resolver in `tools/build-plugin.mjs` is required to fail
non-zero for "malformed `!cat` lines, missing targets, include cycles with
full cycle printed, absolute/path-traversal attempts, outside-root includes,
and any `${CLAUDE_SKILL_DIR}` occurrence in shipped files" (plan.md:2384, DoD
at 2406, tests at 2420). The phrase **"outside-root includes"** is not bound
to a canonicalization rule.

By contrast, Task 21 (the sister exfil-hardening task) explicitly requires
"`realpath` / `readlink -f` … rejects paths whose canonical target is not
under canonical `$REPO_ROOT/`" (plan.md:1311) and pins a symlink regression
"whose lexical path appears allowed but whose canonical target is outside
the repository" (plan.md:1337). Task 39 has no analogous clause.

## Why this is a security gap

A symlink committed under the source tree (e.g.
`skills/_shared/secret-include.md → ../../../etc/passwd`, or any in-repo
symlink whose target is outside the repo, or a symlink into a developer's
home directory on a CI runner) would, under a lexical-only "outside-root"
check, pass the resolver's outside-root gate (because the *literal* include
path is under-root) and have its target content inlined into a shipped
`build/skills/.../SKILL.md` file. That file is then committed into the repo,
distributed via `marketplace.json` pointing at `./build`, and loaded by
every host that installs the plugin.

This is a build-time exfil → distribution path:
- The resolver reads file contents and writes them into shipped artifacts.
- The shipped artifacts are committed and published.
- An adversarial PR (or a contributor accidentally `git add`ing a symlink
  pointing into their home directory) can leak local secrets or CI runner
  contents into a public plugin release through CI's reproducible-build
  diff gate, which will *pass* because the build is deterministic from the
  symlinked source.

The G32 release-acceptance criterion at plan.md:24 — "`${CLAUDE_SKILL_DIR}`
does not appear anywhere in the shipped tree" — does not catch this:
arbitrary inlined file contents are not flagged by any
`${CLAUDE_SKILL_DIR}`-name check.

## Required fix at plan level

Add to Task 39:

1. **Definition of done** — append: "The `!cat` resolver canonicalizes each
   include target with realpath/symlink-following and rejects any include
   whose canonical resolved target is outside canonical repo root, including
   the case where the literal include path is under-root but resolves
   outside-root via a symlink. Resolver rejects symlinks that escape
   `$REPO_ROOT/`, mirroring the boundary contract Task 21 establishes for
   `dispatch-agent.sh`."

2. **Test expectations** — append: a resolver failure fixture where an
   under-root include path is a symlink whose canonical target is outside
   the repo; assert non-zero exit with file:line and a diagnostic naming
   the symlink-escape condition, and assert the shipped `build/` tree is
   not produced.

3. **Cross-link note** — explicitly reference Task 21's
   `assert_path_under_repo_root` contract as the shared canonicalization
   pattern; both repo-boundary surfaces should use the same conceptual
   guard so the security model is uniform across runtime dispatch and
   build-time inclusion.

Without these, the build pipeline ships with a weaker boundary than the
runtime dispatcher and creates a new committed-into-`build/` exfil class
that did not exist before G32.
