# Schema-Migration Task Shape

Read this file only when authoring or reviewing a task that declares `sizing_exception: schema-migration`. Ordinary tasks do not invoke this contract.

A **schema-migration task** applies an identical mechanical change to N files of the same shape — for example, deleting one frontmatter key from every agent file, replacing a single identifier uniformly across all skill prose, or renaming a top-level YAML field across a glob of config files. This is the narrow exception to the ordinary LOC ceiling and file-count guidance.

## When to use this shape

Use `sizing_exception: schema-migration` only when ALL of the following hold:

- Every file in `Target files:` receives the same structural change (same pattern, same before/after; not "similar" or "related").
- The change is mechanical-only — no logic modification, no behavioral delta, no per-file judgment calls.
- A single bash check can assert the mechanical-only nature of the resulting diff.

Do not use this exception for multi-feature bundles that happen to touch many files, for behavioral changes dressed up as migrations, or for any task where per-file human judgment is needed. The closed exception set remains: schema migration, CI scaffolding, reusable primitives — no new category is added by this contract.

## Mandatory trio — all three fields required together

When `sizing_exception: schema-migration` is declared, the task spec MUST carry all three of the following fields. Omitting any one is a plan-spec defect:

- `sizing_exception: schema-migration` — declares the exception; must be exactly this value.
- `sizing_rationale: <human-readable reason>` — one sentence explaining why this specific change is a mechanical same-shape migration (e.g., "removes a deprecated frontmatter key uniformly from all 41 agent files").
- `structural_lint: <script-path>` — a repo-relative path to a checked-in script under `scripts/structural-lints/`. The value must be a single token matching the ERE `^scripts/structural-lints/[A-Za-z0-9_.-]+\.sh$`; whitespace, tab, newline, and any character outside that token class are rejected. The script must exist as a regular readable file at that path. It receives no spec-controlled arguments; it is invoked as `bash -- <path>` from the repository root with the path passed as a single argv element (never interpolated into a `bash -c` string) against the proposed diff. The script must exit 0 when the diff is mechanical-only and non-empty, and exit non-zero when non-structural content is present or the diff is empty. Inline bash commands are not accepted as the field value.

## Effect on sizing limits

When the mandatory trio is present and the `structural_lint` check executes successfully on the proposed diff:

- **N-files: ungated.** No upper limit applies to the number of files the task may touch; the structural lint is the real ceiling.
- **LOC ceiling: exempted.** The ordinary 200-LOC ceiling does not apply.

Ordinary task-size discipline is not relaxed for non-schema-migration work.

## Plan-spec defects

The exemption is NOT granted when ANY of the following holds:

- `sizing_exception: schema-migration` is declared but `sizing_rationale:` is absent or empty.
- `sizing_exception: schema-migration` is declared but `structural_lint:` is absent or empty.
- `structural_lint:` value does not match the ERE `^scripts/structural-lints/[A-Za-z0-9_.-]+\.sh$` (inline command, contains whitespace/tab/newline or `..`, absolute path, or characters outside the allowed token class).
- `structural_lint:` carries a token-valid path but the named script does not exist as a regular readable file at the repository root.
- `structural_lint:` names a valid script path but the proposed diff is empty — a vacuous pass on an empty diff does not prove mechanical-only nature.
- `structural_lint:` names a valid script path but the script exits non-zero, indicating non-structural content.

The plan reviewer (`agents/qrspi-plan-reviewer.md` § Schema-migration exception review) verifies all six conditions and emits a `severity: high, change_type: correctness` finding for each defect.
