---
status: draft
question_ids: [15]
research_type: web
---

# Q15: Established patterns for resolving stable git references in automated fix-cycle workflows where multiple commits may land per iteration

## Summary

**TL;DR:** Several established patterns exist for resolving stable git references in automated fix-cycle workflows. The dominant approaches are full-length commit SHA pinning (the only truly immutable reference), merge queues that create temporary branches resolving to a tested combined SHA, semantic-version tag tracking (SemVer ranges that resolve deterministically to a specific tagged commit), and GitOps tools that accept mutable branch/tag refs but internally record and act on the resolved SHA. When multiple commits land per iteration, the stable handle is always a resolved SHA captured at a specific point in time, not a mutable symbolic ref.

**Key findings:**
- **Full SHA pinning is the only immutable reference**: GitHub's official security guidance states that "pinning an action to a full-length commit SHA is currently the only way to use an action as an immutable release" because SHAs cannot change meaning. (Source: docs.github.com/en/actions/security-for-github-actions/security-guides/security-hardening-for-github-actions)
- **Merge queues resolve multiple queued PRs to a single tested SHA**: GitHub's native merge queue creates temporary `refs/heads/gh-readonly-queue/{base_branch}/...` branches containing the combined changes of batched PRs. CI runs against this combined SHA (`GITHUB_SHA` for `merge_group` events equals the merge-group SHA, not the PR's original SHA). Only after CI passes does the queue advance the base branch. (Source: docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/configuring-pull-request-merges/managing-a-merge-queue)
- **Bors-ng staging branch pattern (predecessor to merge queues)**: Bors merges one or more approved PRs into a `staging` branch, runs CI against that branch's SHA, and only fast-forwards `main` on success. The key property is that CI always runs against a specific commit SHA, not a branch label.
- **SemVer tag ranges**: Tools like ArgoCD and Flux CD support SemVer range constraints (e.g., `>=1.2.0 <2.0.0`) that resolve deterministically to the latest matching annotated tag. This shifts the "latest" determination from a mutable branch head to a controlled tagging event.
- **GitOps SHA recording**: Flux CD records the resolved SHA (e.g., `master@sha1:132f4e719...`) in the resource's `.status.artifact.revision` field, providing an auditable trace. The mutable branch ref is used for polling, but operations are performed against the immutable resolved SHA.
- **Automated digest/SHA pinning by Renovate**: Renovate's `pinDigests` option pins Docker images and GitHub Actions by their SHA-256 digest/commit SHA, then opens automated PRs to update those pins when a newer version is published, enabling machine-managed stable references.
- **Fully-qualified ref names prevent ambiguity**: ArgoCD recommends using fully-qualified refs (`refs/heads/release-1.0`, `refs/tags/release-1.0`) to prevent reconciliation loops when a branch and tag share a name.
- **Moving major version tags with SHA commentary**: GitHub's action release workflow uses `v1.1.3`-style pinned tags alongside moving `v1` and `v1.1` major/minor tags (force-pushed on each release), with the advice that SHA pinning is more secure than tag pinning because tags can be moved or deleted.
- **`git describe` for human-readable stable ref strings**: The `git describe` command produces strings like `v1.2.3-4-gabc1234` (most recent annotated tag, N commits ahead, abbreviated SHA), widely used in automated pipelines to encode both a human-readable version and the underlying commit identity.

**Surprises:** The GitHub merge queue creates a temporary branch with a *different SHA* from the PR's own commits—this SHA represents the combined state of the batch. Third-party CI providers must explicitly trigger on the `gh-readonly-queue/{base_branch}` branch prefix to observe this resolved SHA, rather than the PR's original SHA.

**Caveats:** This investigation focused on publicly documented, mainstream tooling (GitHub, ArgoCD, Flux CD, Renovate, Bors-ng, semantic-release). Patterns specific to GitLab merge trains, Bitbucket pipelines, or custom build systems were not exhaustively covered. The SLSA/provenance angle was noted but not explored deeply. The "fix-cycle" context is interpreted as any automated loop that creates commits iteratively (e.g., bot-driven dependency updates, automerge queues, automated patch application).

---

## Full findings

### Pattern 1: Full commit SHA pinning

The most fundamental stable reference is the full 40-character commit SHA (SHA-1 or SHA-256). GitHub's security hardening documentation for GitHub Actions states:

> "Pinning an action to a full-length commit SHA is currently the only way to use an action as an immutable release. Pinning to a particular SHA helps mitigate the risk of a bad actor adding a backdoor to the action's repository, as they would need to generate a SHA-1 collision for a valid Git object payload."

Example (GitHub Actions workflow):
```yaml
- uses: actions/checkout@11bd71901bbe5b1630ceea73d27597364c9af683  # v4.2.2
```

SHA-based references cannot be moved or deleted (unlike branches and tags), making them the gold standard for immutability. In workflows where multiple commits land per iteration, capturing the SHA at the moment a run is initiated (via `$GITHUB_SHA`) ensures subsequent jobs operate on the same commit even if the branch advances.

**Source:** https://docs.github.com/en/actions/security-for-github-actions/security-guides/security-hardening-for-github-actions

---

### Pattern 2: Merge queues with temporary SHA-resolved branches

GitHub's merge queue (available for public repos in any GitHub organization, or private repos on GitHub Enterprise Cloud) addresses the multi-commit-per-iteration problem directly.

**How it works:**
1. Once a PR passes its branch protection checks, it is added to the merge queue.
2. The queue batches one or more queued PRs and creates a temporary branch named `refs/heads/gh-readonly-queue/{base_branch}/pr-{number}-{sha}` containing the combined changes applied on top of the current base.
3. CI runs against this temporary branch. The `GITHUB_SHA` context variable for a `merge_group` event equals the SHA of this temporary combined commit—*not* the PR's own SHA.
4. Only if CI passes does the queue atomically merge the batch into the base branch.

**Key ref facts:**
- The `merge_group` GitHub Actions event exposes `GITHUB_SHA` = SHA of the merge group and `GITHUB_REF` = ref of the merge group.
- Third-party CI providers must trigger on the `gh-readonly-queue/{base_branch}` branch prefix, since the temporary branch has a different SHA from the PR.
- Build concurrency can be configured (1–100 concurrent `merge_group` webhooks).

This pattern guarantees that each merge to the base branch has been validated against a specific, stable, tested SHA representing the combined state of everything in the batch.

**Source:** https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/configuring-pull-request-merges/managing-a-merge-queue

---

### Pattern 3: Bors-ng staging branch pattern (predecessor to GitHub Merge Queues)

Bors-ng implements a variant of the same concept. When `bors r+` is called on one or more PRs:

1. Bors creates a `staging` (or `staging.tmp`) branch by merging the approved PRs onto the current `master`.
2. CI is triggered against the `staging` branch's HEAD SHA.
3. If CI passes, Bors fast-forwards `master` to the `staging` SHA.
4. If CI fails, Bors bisects batches to find the failing PR.

The `staging` branch is a stable SHA-anchored intermediate reference. Bors-ng's documentation notes this is now being superseded by GitHub's native merge queues:

> "Heads up! Bors-NG's public instance is being phased out in favor of GitHub Merge Queues."

**Source:** https://bors.tech/documentation/getting-started/

---

### Pattern 4: SemVer tag range resolution

Tools like ArgoCD and Flux CD support resolving to a specific commit by specifying a SemVer range constraint against annotated tags:

**ArgoCD** (`targetRevision` field):
| Use Case | Pattern | Notes |
|---|---|---|
| Pin to version (production) | `v1.2.0` (exact tag) or commit SHA | Most stable |
| Track patches (pre-production) | `1.2.*` or `>=1.2.0 <1.3.0` | Resolves to latest matching tag |
| Track minor releases (QA) | `1.*` or `>=1.0.0 <2.0.0` | |
| Latest (dev) | HEAD or branch name | Most volatile |

ArgoCD evaluates the constraint against all annotated tags at sync time and resolves to the latest qualifying tag's commit SHA.

**Flux CD** (`spec.ref.semver` field):
```yaml
spec:
  ref:
    semver: ">=1.2.0 <2.0.0"
```
Flux resolves the SemVer range to the latest matching tag, then clones that commit and records the resolved SHA in `.status.artifact.revision`.

The key property for fix-cycle workflows: when multiple commits land, only those that have an associated tag satisfying the range constraint are selected. Untagged commits are invisible to this mechanism.

**Sources:**
- https://argo-cd.readthedocs.io/en/stable/user-guide/tracking_strategies/
- https://fluxcd.io/flux/components/source/gitrepositories/

---

### Pattern 5: GitOps SHA recording (mutable ref + resolved SHA tracking)

Both Flux CD and ArgoCD accept mutable references (branch names, SemVer ranges) but internally resolve them to immutable SHAs before acting on them. The resolved SHA is then persisted in status fields, creating an auditable trail.

**Flux CD example** (from the `kubectl get gitrepository` output):
```
stored artifact for revision 'master@sha1:132f4e719209eb10b9485302f8593fc0e680f4fc'
```

The `.status.artifact.revision` field holds the format `{branch}@sha1:{SHA}`. A new artifact is archived only when this resolved SHA differs from the previous one.

**ArgoCD commit pinning:**
> "If a Git commit SHA is specified, the app is effectively pinned to the manifests defined at the specified commit. This is the most restrictive of the techniques and is typically used to control production environments. Since commit SHAs cannot change meaning, the only way to change the live state of an app which is pinned to a commit, is by updating the tracking revision in the application to a different commit."

This pattern handles multiple commits per iteration by recording a stable SHA snapshot at the time of each reconciliation, preventing any state drift between the moment a decision is made and the moment it is acted on.

**Sources:**
- https://fluxcd.io/flux/components/source/gitrepositories/
- https://argo-cd.readthedocs.io/en/stable/user-guide/tracking_strategies/

---

### Pattern 6: Moving major/minor version tags (semantic release)

GitHub's recommended process for releasing GitHub Actions uses a multi-layer tagging scheme:

1. Individual release tags like `v1.1.3` point to specific commits.
2. Moving major (`v1`) and minor (`v1.1`) tags are force-pushed to the latest appropriate commit on each release, allowing users to pin at different stability levels.

From the GitHub Actions release documentation:
> "We recommend creating releases using semantically versioned tags – for example, v1.1.3 – and keeping major (v1) and minor (v1.1) tags current to the latest appropriate commit."

The automation is handled by tools such as `JasonEtco/build-and-tag-action`, which compiles the action and force-pushes the semantic tags.

**Important caveat:** GitHub's "immutable releases" feature, when enabled for a repository, prevents force-pushing tags tied to releases. Organizations that enable immutable releases must use a different strategy (such as always referencing full SHA pins).

This pattern handles multiple-commits-per-iteration by making each release commit produce a stable pinned tag (`v1.1.3`), while the moving tags (`v1`, `v1.1`) provide a stable *latest* pointer that advances automatically.

**Source:** https://docs.github.com/en/actions/sharing-automations/creating-actions/releasing-and-maintaining-actions

---

### Pattern 7: Automated digest/SHA pinning with Renovate

Renovate's `pinDigests` configuration option:

> "If enabled Renovate will pin Docker images or GitHub Actions by means of their SHA256 digest and not only by tag so that they are immutable."

The workflow:
1. Renovate scans dependency definitions and replaces mutable tag references with `tag@sha256:...` or `tag@sha1:...` forms.
2. When a new version is published, Renovate opens a PR updating the pinned digest to the new version's digest.
3. Human review + automerge policies then land that PR.

This pattern separates the *resolution step* (Renovate determines the SHA for a given version) from the *usage step* (CI workflows use the immutable SHA-pinned reference). In fix-cycle workflows where multiple dependency updates land per iteration, each PR introduces exactly one SHA update per dependency, and the SHA is always a fully-resolved, stable reference.

Configuration:
```json
{
  "pinDigests": true
}
```

**Source:** https://docs.renovatebot.com/configuration-options/

---

### Pattern 8: Fully-qualified ref names to prevent ambiguity

When a repository has both a branch and a tag with the same name (e.g., `release-1.0`), tools may resolve the reference ambiguously. ArgoCD documents this issue:

> "If your application's targetRevision is set to release-1.0, Argo CD may resolve it to either commit A or commit B. If the resolved commit differs from what is currently deployed, Argo CD will continuously attempt to sync, causing constant reconciliation."

**Best practices:**
- Use fully-qualified refs: `refs/heads/release-1.0` for branches, `refs/tags/release-1.0` for tags.
- Avoid naming branches and tags identically.
- Flux CD's `spec.ref.name` field accepts fully-qualified refs: `refs/heads/main`, `refs/tags/v0.1.0`, `refs/pull/420/head`, `refs/merge-requests/1/head`.

In automated fix-cycle workflows, this matters when the workflow script constructs a ref string dynamically: always use the full `refs/...` form to guarantee deterministic resolution.

**Source:** https://argo-cd.readthedocs.io/en/stable/user-guide/tracking_strategies/

---

### Pattern 9: `git describe` for human-readable stable version strings

`git describe` finds the most recent annotated tag reachable from a commit and produces a string that encodes the tag, commit distance, and abbreviated SHA:

```
<tag>-<N>-g<abbrev-SHA>
```

For example: `v1.2.3-4-gabc1234d` means "4 commits after tag v1.2.3, commit hash starting with abc1234d."

From the git documentation:
> "The command finds the most recent tag that is reachable from a commit. If the tag points to the commit, then only the tag is shown. Otherwise, it suffixes the tag name with the number of additional commits on top of the tagged object and the abbreviated object name of the most recent commit."

In automated fix-cycle workflows, `git describe --tags --long` (or with `--abbrev=40` for the full SHA) is used to:
1. Produce a build-time version string that embeds the SHA, enabling reproducibility.
2. Determine whether the current commit is "on a tag" (exact release) or "post-tag" (development build).

When multiple commits land per iteration, the `-<N>` component of the `git describe` output tracks how far the current HEAD is from the last stable tag, providing a stable and informative reference without requiring a new tag for each commit.

**Source:** https://git-scm.com/docs/git-describe

---

### Pattern 10: `GITHUB_SHA` capture and job output propagation

In GitHub Actions workflows, `$GITHUB_SHA` is set at workflow trigger time and does not change during a run, even if additional commits are pushed to the branch. However, when running in a multi-job workflow where a later job checks out the repo, it might get a newer commit than the one `GITHUB_SHA` refers to.

The established pattern for ensuring all jobs in a workflow operate on the same commit:

```yaml
jobs:
  resolve:
    outputs:
      sha: ${{ steps.get-sha.outputs.sha }}
    steps:
      - id: get-sha
        run: echo "sha=$GITHUB_SHA" >> $GITHUB_OUTPUT

  use-sha:
    needs: resolve
    steps:
      - uses: actions/checkout@...
        with:
          ref: ${{ needs.resolve.outputs.sha }}
```

By capturing `GITHUB_SHA` in an early job's output and passing it to dependent jobs via `needs.<job>.outputs.<output>`, each job checks out the *same* specific commit even if the branch has advanced between job executions. This is particularly important in fix-cycle workflows where multiple commits can land in the time between when a workflow is queued and when individual jobs run.

**Source:** https://docs.github.com/en/actions/using-workflows/events-that-trigger-workflows (table of per-event `GITHUB_SHA` values)

---

### Summary table

| Pattern | Reference type | Handles multiple commits | Mutability | Primary tools |
|---|---|---|---|---|
| Full SHA pinning | 40-char hex SHA | Yes (snapshot at trigger time) | Immutable | GitHub Actions, any git client |
| Merge queue / staging branch | Temporary branch → resolved SHA | Yes (batches multiple commits into one tested SHA) | Immutable SHA | GitHub merge queue, Bors-ng |
| SemVer tag range | Annotated tag → SHA | Only via new tags | Effectively immutable between tags | ArgoCD, Flux CD |
| GitOps SHA recording | Mutable ref + recorded SHA | Yes (records SHA per reconcile) | Immutable after resolution | Flux CD, ArgoCD |
| Moving major/minor tags | Force-pushed tag | Yes (tag advances per release) | Mutable (until immutable releases enabled) | GitHub Actions, semantic-release |
| Renovate digest pinning | `tag@sha256:…` | Yes (one PR per update) | Immutable | Renovate |
| Fully-qualified refs | `refs/heads/…` or `refs/tags/…` | Prevents ambiguity | Depends on ref type | ArgoCD, Flux CD, git |
| `git describe` output | `<tag>-<N>-g<SHA>` string | Yes (encodes distance from tag) | Immutable as a string | Any git pipeline |
| `GITHUB_SHA` job output | Captured SHA passed between jobs | Yes (snapshot at workflow trigger) | Immutable | GitHub Actions |
