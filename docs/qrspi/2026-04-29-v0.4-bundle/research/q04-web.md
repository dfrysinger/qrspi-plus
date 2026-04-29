---
status: draft
question_ids: [4]
research_type: web
---

# Q4: Git ref hierarchies — rules and conventions

## Summary

**TL;DR:** Git stores refs as a hierarchical namespace backed by a filesystem layout (loose refs as files under `.git/refs/`) plus an optional `packed-refs` flat file. Because loose refs are real files, a ref that is a path prefix of another ref cannot coexist with it (e.g., `foo` and `foo/bar`), and `git check-ref-format` enforces a list of refname syntactic rules. Conventions for grouping related branches use `/`-separated prefixes such as `feature/...`, `release/...`, `hotfix/...`, and `users/<name>/...`.

**Key findings:**
- Refs live under `$GIT_DIR/refs/` with subdirectories such as `refs/heads/`, `refs/tags/`, `refs/remotes/<remote>/`, `refs/notes/`, and `refs/stash`; the loose-ref backend stores each ref as a single file whose path mirrors the refname (git-scm.com/docs/gitrepository-layout).
- `git check-ref-format` defines the syntactic rules for refnames: components separated by `/`, no component may begin with `.` or end with `.lock`, no `..`, no ASCII control chars / space / `~ ^ : ? * [ \`, no consecutive `/`, no leading or trailing `/`, no trailing `.`, and no `@{` (git-scm.com/docs/git-check-ref-format).
- Because loose refs are filesystem entries, a refname that is a strict path prefix of an existing refname (a "D/F conflict") cannot exist simultaneously: creating `foo/bar` while `foo` exists, or vice versa, is rejected (git-scm.com/docs/git-check-ref-format, Pro Git §10.3 "Git References").
- `git pack-refs` collapses loose refs into a single `packed-refs` file; the on-disk hierarchy then exists logically (via the textual refnames) rather than as actual directories, but the same naming rules and D/F conflict constraints still apply at the refname level (git-scm.com/docs/git-pack-refs, git-scm.com/docs/gitrepository-layout).
- The remote-tracking namespace `refs/remotes/<remote>/<branch>` is itself an example of conventional nesting: `git clone` and the default fetch refspec `+refs/heads/*:refs/remotes/origin/*` map remote heads under a per-remote prefix (git-scm.com/docs/git-fetch, git-scm.com/book/en/v2/Git-Internals-The-Refspec).
- Common community/workflow idioms place related branches under shared prefixes: Git Flow uses `feature/`, `release/`, `hotfix/`, `support/`, plus long-lived `develop` and `master`/`main` (nvie.com/posts/a-successful-git-branching-model, danielkummer.github.io/git-flow-cheatsheet); GitHub Flow uses topic branches off `main` without mandated prefixes (docs.github.com/en/get-started/using-github/github-flow); per-user namespaces like `users/<name>/<topic>` and `wip/...` are described as conventions (git-scm.com Pro Git, ref-discussion in `git config` docs for `receive.denyDeletes` etc.).
- `git for-each-ref` and `git branch --list 'feature/*'` rely on these prefixes for filtering, and `gitnamespaces(7)` describes a separate mechanism (`GIT_NAMESPACE` / `refs/namespaces/<name>/`) that virtualizes ref hierarchies for hosting multiple logical repos in one physical repo (git-scm.com/docs/gitnamespaces).

**Surprises:** The D/F conflict is enforced at the refname/storage layer, so it persists even after `git pack-refs` removes the actual directories — `foo` and `foo/bar` still cannot coexist.

**Caveats:** Exact error wording and edge cases (case-insensitive filesystems on macOS/Windows, reflog interactions, ref-storage backends like reftable) vary across Git versions; the rules cited here come from current `git-scm.com` docs and may differ in older releases or alternative backends.

## Full findings

### Ref hierarchy rules in git

**Storage layout.** `gitrepository-layout(5)` documents that refs live under `$GIT_DIR/refs/`, with conventional subdirectories `refs/heads/` (local branches), `refs/tags/` (tags), and `refs/remotes/<remote>/` (remote-tracking branches); other tools use `refs/notes/`, `refs/stash`, `refs/replace/`, etc. Each loose ref is a file whose pathname under `$GIT_DIR` is exactly the refname, and whose contents are either a 40-hex SHA-1 or a `ref: <target>` symref line (https://git-scm.com/docs/gitrepository-layout).

**Packed refs.** `git pack-refs` writes a single `packed-refs` file at `$GIT_DIR/packed-refs` containing one ref per line, replacing many small loose-ref files. The man page states: "Traditionally, tips of branches and tags … were stored one file per ref. … This command packs many of the refs … into a single file" (https://git-scm.com/docs/git-pack-refs). Loose refs still take precedence over packed entries with the same name when both exist.

**Refname syntactic rules.** `git check-ref-format` enumerates the constraints (https://git-scm.com/docs/git-check-ref-format):

1. Refnames can include slash `/` for hierarchical grouping, but no slash-separated component can begin with `.` or end with `.lock`.
2. They must contain at least one `/` (this enforces a category like `heads/`, `tags/`) — except for the top-level names `HEAD`, `FETCH_HEAD`, `ORIG_HEAD`, `MERGE_HEAD`, `CHERRY_PICK_HEAD`.
3. They cannot have two consecutive dots `..`.
4. They cannot contain ASCII control characters (i.e., bytes whose values are lower than `\040`, or `\177` DEL), space, tilde `~`, caret `^`, colon `:`.
5. They cannot have `?`, `*`, or `[`.
6. They cannot begin or end with a slash `/` or contain multiple consecutive slashes.
7. They cannot end with a dot `.`.
8. They cannot contain the sequence `@{`.
9. They cannot be the single character `@`.
10. They cannot contain a backslash `\`.

**Directory/file (D/F) conflict.** Because loose refs are filesystem files, two refs cannot coexist where one's name is a path prefix of the other. The Pro Git book's "Git References" section explains the loose layout and notes that you cannot have both `refs/heads/foo` and `refs/heads/foo/bar` because the first occupies the path that the second would need as a directory (https://git-scm.com/book/en/v2/Git-Internals-Git-References). Git rejects such creations with errors like `cannot lock ref 'refs/heads/foo/bar': 'refs/heads/foo' exists; cannot create 'refs/heads/foo/bar'`. The constraint is preserved even after `git pack-refs` because Git treats the packed namespace as if loose refs could be reconstructed; see the discussion in the `git update-ref` and `check-ref-format` documentation (https://git-scm.com/docs/git-update-ref, https://git-scm.com/docs/git-check-ref-format).

**Resolution and overrides.** `gitrevisions(7)` describes the lookup order for an unqualified name `<refname>`: `$GIT_DIR/<refname>`, `refs/<refname>`, `refs/tags/<refname>`, `refs/heads/<refname>`, `refs/remotes/<refname>`, `refs/remotes/<refname>/HEAD` (https://git-scm.com/docs/gitrevisions). This is why fully-qualifying refs as `refs/heads/...` avoids ambiguity when a tag and branch share a name.

**Reftable / alternate backends.** `git config` documents `extensions.refStorage` and Git 2.45+ introduces the reftable backend, which stores refs in a binary table rather than per-file; the same refname syntactic rules and D/F conflict semantics still apply at the logical refname level (https://git-scm.com/docs/git-config, https://git-scm.com/docs/reftable).

### Conventions for nesting refs under shared prefixes

**Built-in namespacing.**
- `refs/heads/<branch>` — local branches.
- `refs/tags/<tag>` — tags.
- `refs/remotes/<remote>/<branch>` — remote-tracking branches; produced by the default fetch refspec `+refs/heads/*:refs/remotes/origin/*` (https://git-scm.com/book/en/v2/Git-Internals-The-Refspec, https://git-scm.com/docs/git-fetch).
- `refs/notes/<name>` — `git notes` (https://git-scm.com/docs/git-notes).
- `refs/stash` — `git stash` (https://git-scm.com/docs/git-stash).
- `refs/replace/<sha1>` — `git replace` (https://git-scm.com/docs/git-replace).
- `refs/namespaces/<name>/refs/...` — `gitnamespaces(7)` virtual namespaces for hosting multiple logical repos in one physical repo, controlled by `GIT_NAMESPACE` (https://git-scm.com/docs/gitnamespaces).

**Workflow conventions for branches.**
- Git Flow (Vincent Driessen) uses `feature/<name>`, `release/<version>`, `hotfix/<version>`, `support/<version>`, plus long-lived `develop` and `master`/`main` (https://nvie.com/posts/a-successful-git-branching-model/, https://danielkummer.github.io/git-flow-cheatsheet/).
- GitHub Flow uses short-lived topic branches off `main` and does not mandate prefixes; many teams nonetheless adopt `feature/`, `fix/`, `chore/` (https://docs.github.com/en/get-started/using-github/github-flow).
- Per-user namespaces such as `users/<username>/<topic>` or `personal/<username>/<topic>` are conventions used by, e.g., the Linux kernel, the Git project itself (`pu`/`next`/`seen` at the top level plus per-contributor branches on hosting forks), and many corporate monorepos. They are described in mailing-list and Pro Git sidebars but are not enforced by Git itself (https://git-scm.com/book/en/v2/Distributed-Git-Maintaining-a-Project).
- Dependabot and similar bots create branches under prefixes like `dependabot/<ecosystem>/<package>-<version>` (https://docs.github.com/en/code-security/dependabot/working-with-dependabot/dependabot-options-reference).
- Stacked-PR tooling (Graphite, Sapling, `git-branchless`) uses prefixes like `<user>/<feature>/01-base`, `<user>/<feature>/02-step` to keep stacks grouped (https://graphite.dev/docs).

**Filtering and refspec idioms.**
- `git branch --list 'feature/*'`, `git for-each-ref refs/heads/feature/*`, and refspec wildcards like `refs/heads/feature/*:refs/remotes/origin/feature/*` exploit the prefix structure (https://git-scm.com/docs/git-branch, https://git-scm.com/docs/git-for-each-ref, https://git-scm.com/docs/git-fetch).
- `receive.denyDeletes`, `receive.denyNonFastForwards`, and update-hook patterns commonly key on prefixes such as `refs/heads/release/*` to apply stricter policy to release branches (https://git-scm.com/docs/git-config, https://git-scm.com/docs/githooks).

**Practical implication of D/F conflict on conventions.** Because `feature/login` and `feature` cannot coexist as branches, conventions universally use the prefix as a non-leaf only — i.e., never name a branch the same as a category prefix you also intend to subdivide. Stack Overflow discussions ("cannot lock ref … exists; cannot create") repeatedly cite this as the cause of unexpected branch-creation failures (https://stackoverflow.com/questions/22630404/git-branch-cannot-create-branch-with-the-same-name-as-existing-directory).

## Sources

- https://git-scm.com/docs/gitrepository-layout
- https://git-scm.com/docs/git-check-ref-format
- https://git-scm.com/docs/git-pack-refs
- https://git-scm.com/docs/git-update-ref
- https://git-scm.com/docs/gitrevisions
- https://git-scm.com/docs/git-fetch
- https://git-scm.com/docs/git-branch
- https://git-scm.com/docs/git-for-each-ref
- https://git-scm.com/docs/git-config
- https://git-scm.com/docs/githooks
- https://git-scm.com/docs/gitnamespaces
- https://git-scm.com/docs/git-notes
- https://git-scm.com/docs/git-stash
- https://git-scm.com/docs/git-replace
- https://git-scm.com/docs/reftable
- https://git-scm.com/book/en/v2/Git-Internals-Git-References
- https://git-scm.com/book/en/v2/Git-Internals-The-Refspec
- https://git-scm.com/book/en/v2/Distributed-Git-Maintaining-a-Project
- https://nvie.com/posts/a-successful-git-branching-model/
- https://danielkummer.github.io/git-flow-cheatsheet/
- https://docs.github.com/en/get-started/using-github/github-flow
- https://docs.github.com/en/code-security/dependabot/working-with-dependabot/dependabot-options-reference
- https://graphite.dev/docs
- https://stackoverflow.com/questions/22630404/git-branch-cannot-create-branch-with-the-same-name-as-existing-directory
