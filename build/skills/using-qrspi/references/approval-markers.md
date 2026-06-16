
When the user approves an artifact, the skill writes `status: approved` in the artifact's YAML frontmatter:

```yaml
---
status: approved
---
```

**Status values:** `draft` (initial), `approved` (user-approved), `replan-draft` (transient — used during Replan's minor path re-approval cycle; artifact gating treats this the same as `draft`, so downstream skills correctly refuse to proceed until re-approval completes).

**Writing `status: approved` is sufficient.** Pipeline progression is derived from artifact frontmatter; skills do not need to perform any explicit state update after writing the approval marker.

**Commit after approval (when applicable).** When the artifact directory is inside a git repository, commit each approved artifact (and its review file) immediately after writing the approval marker — preserves the approved state as a checkpoint. Use a message like `docs(qrspi): approve {step} for {project-slug}`. When not inside a git repository, skip the commit; the approved frontmatter on disk is the durable record.

**How to detect:** Run `git -C <artifact_dir> rev-parse --show-toplevel` and inspect the exit code. Detect from the **artifact directory**, not CWD — these can differ.

This applies to every skill terminal state that says "commit … to git" — per-skill instructions defer to this canonical rule.
