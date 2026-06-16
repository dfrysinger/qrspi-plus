# `visual-fidelity-claude.skipped.md` schema (reference)

Companion to `skills/using-qrspi/SKILL.md` § Review Output Handling → Apply-fix step 2 → "`visual-fidelity-claude` tag — third valid sentinel form". Read this only when authoring or auditing the visual-fidelity skip path; the SKILL body carries the load-bearing summary.

## Closed `skip_reason:` value set

Exactly one value, matching the trigger that caused the skip:

- `visual_fidelity_required_false` — `config.md` carried `visual_fidelity_required: false`.
- `missing_visual_fidelity_check` — the task spec carried no `visual_fidelity_check` field.
- `empty_wireframe_paths` — after path validation, the `wireframe_paths` list was empty.
- `empty_screenshot_paths` — after path validation, the `screenshot_paths` list was empty.

## `path_filtered:` frontmatter field

- `path_filtered: true` — the `empty_*_paths` trigger fired as a result of path-validation dropping entries (the `path-filtered.md` audit record was written for this round). Distinguishes "all refs rejected by path validation" from "task genuinely had no refs."
- `path_filtered: false` — default; no paths were dropped by validation.

A `skipped.md` with a valid `skip_reason:` but missing/unrecognized `path_filtered:` is treated as `path_filtered: false` (conservative).

The orchestrator is the EXCLUSIVE writer of `path-filtered.md`, the `path_filtered:` frontmatter field on `skipped.md`, and `bypass-attempt-NN.md`. The apply-fix guard derives `path_filtered:` from the FRONTMATTER FIELD, not from `path-filtered.md` presence. If the guard observes `path_filtered: false` while `path-filtered.md` is present, it surfaces a bypass-attempt record rather than trusting either source.

## `path_encoding:` delimiter-injection guard

When reading `path-filtered.md` to verify path drops, the guard MUST respect `path_encoding:`:

- `path_encoding: literal` (default) — dropped path strings are recorded verbatim.
- `path_encoding: base64` — the path itself contained the closing `UNTRUSTED-PATH-END` marker sequence; the recorded path is base64-encoded using the RFC 4648 §4 standard alphabet with padding (`+`, `/`, `=`).

URL-safe (`-`, `_`) and unpadded variants are NOT recognized. Comparison is CASE-SENSITIVE — `BASE64`, `Base64`, `LITERAL`, etc. trigger a bypass-attempt. An audit record carrying any `path_encoding:` value outside this closed set is treated as malformed: do NOT fall through to `literal` decoding (that would silently defeat the delimiter-injection protection). Halt and emit a `visual-fidelity-claude.bypass-attempt-NN.md` finding-shaped record naming the unrecognized value.

## `bypass-attempt-NN.md` finding-shaped record

Five required schema fields:

- `finding_id: R{round}-bypass-{NN}` — `{NN}` is the 2-digit zero-padded per-round monotonic sequence number. Form satisfies the schema-guard regex `^R\d+-(F|bypass-)\d+$`.
- `severity: high`
- `change_type: correctness`
- `referenced_files: [reviews/tasks/task-NN/round-NN/visual-fidelity-claude.skipped.md]` (the malformed sentinel file)
- `message`: one paragraph naming the malformation, e.g. "Sentinel file contains [missing|unrecognized] `skip_reason:` value `<value>`. Recognized values: visual_fidelity_required_false, missing_visual_fidelity_check, empty_wireframe_paths, empty_screenshot_paths."

The orchestrator is the EXCLUSIVE writer; reviewer subagents' disk-write surface is restricted to `<reviewer_tag>.finding-FNN.md` and `<reviewer_tag>.clean.md` per the reviewer-protocol dispatch contract. The round-directory-empty precondition closes the round-START forgery vector.
