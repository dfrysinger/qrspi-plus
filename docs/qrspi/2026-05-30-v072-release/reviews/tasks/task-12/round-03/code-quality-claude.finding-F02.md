---
finding_id: R3-F02
reviewer_tag: code-quality-claude
round: 3
task: 12
severity: low
change_type: clarity
referenced_files:
  - scripts/await-round.sh
---

# F02 — `import glob` placed inside the per-entry for loop instead of the module-level import block

## Location

`scripts/await-round.sh:235` (inside `for entry in manifest:`)

## Observation

`import glob` sits inside the `for entry in manifest:` loop body, one level deep in an `if split_cmd:` path. Python's import machinery caches modules after the first import, so there is no functional defect, but placing an `import` statement inside a loop:

1. Forces Python to do a module-cache dictionary lookup on every iteration.
2. Misleads readers into thinking the import is conditional or lazy on purpose.
3. Is inconsistent with the file's other imports, which are all at the top (`import json, os, shlex, subprocess, sys` at line 88).

## Suggestion

Move `import glob` to the module-level import line: `import glob, json, os, shlex, subprocess, sys`.
