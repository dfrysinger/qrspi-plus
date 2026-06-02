---
reviewer: security-claude
round: 2
artifact: plan.md
severity: medium
change_type: correctness
finding_id: F01
task: T39
goal: G32
---

# F01 — T39 symlink canonicalization covers only `!cat` targets; tree-copy phase still follows checked-in symlinks out of repo

## Where

- `plan.md` Task 39 (G32 plugin build pipeline), **Definition of done** line 2420 and **Test expectations** line 2435 (the round-01 symlink-escape clauses).
- Adjacent T39 lines 2389, 2392, 2409 (tree-copy / runtime-include-list behavior).

## What the plan requires

The round-01 hardening (DoD bullet 2420 + Test bullet 2435) says:

> `tools/build-plugin.mjs` canonicalizes **every `!cat` target path** with `fs.realpathSync` (or equivalent) BEFORE reading the target's bytes, and fails non-zero with a `resolves outside repository` diagnostic when the canonical path is not lexically prefixed by the canonical `$REPO_ROOT/`.

> **Symlink-escape regression**: a fixture commits a **`!cat`-targeted file** that is itself a symlink whose canonical target is outside `$REPO_ROOT` …

Both clauses scope the canonicalization to the `!cat` *resolver* (the directive-expansion code path). The build script also performs a **separate** tree-copy operation per DoD line 2409 and Scope-In bullets at lines 2389/2392:

> `node tools/build-plugin.mjs` creates a reproducible `build/` tree … using `.claude-plugin/plugin.json` component paths plus the fixed runtime include list: **`scripts/`, `templates/`, `LICENSE`, `README.md`, optional `AGENTS.md`/`CLAUDE.md`, and `.claude-plugin/`**.

> Copy runtime plugin content and defensive shared snippets into `build/`, while omitting dev-only paths …

This is a distinct code path from the `!cat` resolver. The plan never requires that the **copy** phase canonicalize each source path under `$REPO_ROOT/` before reading bytes into `build/`.

## Risk (fail-open / exfil class)

This leaves the same symlink-escape exfil surface open via the tree-copy path that round-01 just closed for `!cat`:

1. A checked-in symlink at e.g. `scripts/foo.sh → /etc/passwd`, `templates/x.md → ../../../private-key`, or `skills/_shared/foo.md → /var/log/secret` is followed by Node's standard file-copy primitives (`fs.copyFileSync` and `fs.cpSync` follow source symlinks by default; only the rarely-used `verbatimSymlinks: true` option preserves them).
2. The build script copies that source path into the corresponding `build/...` location, **inlining the referent's bytes** into a shipped artifact.
3. The shipped plugin (`build/` is committed and `marketplace.json` points install at `./build` per DoD 2416) carries the exfiltrated content.

The threat model is identical to the `!cat` symlink-escape class round-01 patched: a single malicious commit (or a compromised developer machine that creates the symlink before staging) escalates into shipped exfil content, with the build pipeline as the only effective guardrail. PR review can miss a symlink stat (`git diff` shows the symlink target as a text line but reviewers may not recognize the escape). The shipped `${CLAUDE_SKILL_DIR}` grep (DoD 2414) does **not** catch this — leaked secrets don't contain that token.

The same defensive primitive (`realpath` / `fs.realpathSync` + canonical-prefix check + `resolves outside repository` diagnostic) already named in the round-01 clause is the correct fix; the round-01 clause just needs to bind it to the broader file-read surface, not only the `!cat` resolver.

## What's missing (concrete clauses to add to T39)

1. **DoD addition** — pair with line 2420:
   > `tools/build-plugin.mjs` canonicalizes every source path it reads or copies into `build/` (runtime include list members `scripts/`, `templates/`, `LICENSE`, `README.md`, `AGENTS.md`/`CLAUDE.md`, `.claude-plugin/`, and the `skills/` source tree — every regular file enumerated by recursive directory walks, not only `!cat` targets) with `fs.realpathSync` (or equivalent) BEFORE reading the file's bytes, and fails non-zero with a `resolves outside repository` diagnostic when the canonical path is not lexically prefixed by the canonical `$REPO_ROOT/`. The copy operation uses `fs.lstatSync` + `fs.realpathSync` instead of symlink-following copies so that source symlinks whose canonical targets lie outside `$REPO_ROOT/` cannot inline out-of-repo bytes into the shipped tree.

2. **Test-expectations addition** — pair with line 2435:
   > **Tree-copy symlink-escape regression**: a fixture commits a regular file *under one of the copied runtime paths* (e.g. `scripts/<name>.sh`, `templates/<name>.md`, or `skills/_shared/<name>.md`) that is itself a symlink whose canonical target is outside `$REPO_ROOT/` (e.g. `/etc/passwd` or `/tmp/secret-fixture`); the build fails non-zero before any byte of the symlink's referent enters the `build/` tree, with a stderr diagnostic containing `resolves outside repository`. Distinct regression from the `!cat`-target symlink fixture in line 2435; both fixtures must pass for the build to be considered hardened.

## Why this matters at plan level

An implementer building exactly what the plan currently says will (correctly) harden the `!cat` resolver path and leave the tree-copy path open, because the DoD literally scopes canonicalization to `!cat` targets ("canonicalizes every `!cat` target path"). Without the additions above, the residual symlink-escape exfil channel ships with v0.7.2, and the round-01 patch reads as a complete fix when it is in fact only half of the surface. Adding the clauses now keeps the symlink-canonicalization story coherent (one defensive primitive applied uniformly to every source path the build pipeline reads).
