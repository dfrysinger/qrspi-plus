---
finding_id: code-quality-claude.finding-F02
severity: low
change_type: style
reviewer: code-quality-claude
round: 4
file: scripts/run-codex-review.sh
line: 200-205
at_cap: true
---

# `_validate_output_dir` comment claims a non-existent internal call site

## Location

`scripts/run-codex-review.sh`, lines 200–205 (docstring for `_validate_output_dir`).

## Description

The function comment says:

> Called from the --output-dir parse case **and also internally before writing
> the manifest**.

The second clause is inaccurate.  A grep of the file finds exactly one call
site:

```bash
--output-dir)
  require_value "--output-dir" "$#"
  _validate_output_dir "$2"          # ← the only call
  OUTPUT_DIR="$2"; shift 2 ;;
```

There is no call to `_validate_output_dir` inside `emit_dispatch_manifest_entry`,
`emit_first_party_manifest_entry`, or `_append_manifest_entry`.  The comment
implies a defense-in-depth re-validation before every manifest write, which does
not exist.  A reader relying on that comment to understand the security model
would draw the wrong conclusion about where `OUTPUT_DIR` is re-checked.

This appears to be a leftover from an earlier design draft that planned an
internal call but did not land it.

## Fix (if user authorizes cap-bend)

Remove the inaccurate clause from the docstring:

```bash
# _validate_output_dir <value> — allowlist-validate OUTPUT_DIR.
# OUTPUT_DIR is interpolated into split_cmd stored in the manifest; downstream
# consumers eval-expand that field.  Restrict to an absolute path containing
# only characters safe in an unquoted shell word (letters, digits,
# . _ / : @ -).  Called from the --output-dir parse case.
```

## At-cap escalation note

This is a cycle-3-of-3 at-cap finding.  No R5 fix-cycle fires automatically.
The fix is a one-line comment edit.  User must explicitly authorize a cap-bend
to address it, or carry it forward as a polish item in a future task.
