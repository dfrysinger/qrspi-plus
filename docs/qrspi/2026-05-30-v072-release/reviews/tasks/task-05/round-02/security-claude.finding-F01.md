---
finding_id: F01
reviewer_tag: security-claude
round: 2
severity: medium
change_type: correctness
referenced_files:
  - tests/unit/test-change-type-partition.bats:223
  - tests/unit/test-change-type-partition.bats:304
  - tests/unit/test-change-type-partition.bats:309
artifact: tests/unit/test-change-type-partition.bats
---

# `cp -R` preserves fixture symlinks; `FIXTURE_DEST` prefix guard provides only textual containment

Materialized from chat-only response by claude-sonnet-4.6 (438s).

## What the code does
`_run_fan_in_on_fixture` copies the fixture source into an isolated `mktemp -d` using `cp -R`. The path-guard at line 304 checks that every path read from `kept-findings.txt` has `$FIXTURE_DEST` as a textual prefix before `awk` reads it.

## The gap
`cp -R` (no `-L`) **preserves symlinks**. If any file in `tests/fixtures/change-type-enum/round-*/` is a symlink, it survives the copy. `verifier-fan-in.sh` then resolves `ROUND_DIR_ABS` via `pwd -P`, globs `*.finding-F*.md` (matching the symlink's name), passes the readability check (which follows the symlink), and writes `$FIXTURE_DEST/symlink-name.finding-F01.md` (the symlink path, not its target) into `kept-findings.txt`.

The test's prefix guard `[[ "$p" == "$FIXTURE_DEST"/* ]]` evaluates the **textual prefix** and passes. `awk "$p"` opens the path; the OS follows the symlink and reads the **target file** outside the sandbox.

## Attack scenario
An attacker who can land a single symlink in `tests/fixtures/` (malicious PR, compromised submodule, CI artifact injection) creates:
```
round-all-canonical/
  evil-claude.finding-F01.md  →  ../../../../secrets/ci-token.md
  evil-claude.finding-F01.score.md  (crafted sidecar with score:95, change_type:style)
```
After `cp -R`, both symlinks land in `$dest`. `verifier-fan-in.sh` processes the symlinked finding (target readable → passes), scores it (sidecar → score:95, change_type:style, passes threshold), writes the symlink path to `kept-findings.txt`. Test prefix-check passes; awk follows the symlink and reads the target. Any `change_type:` line in that file leaks into the test's `seen` variable.

## Fix
Replace `cp -R` with symlink-dereferencing copy:
```bash
cp -RL "$src/." "$dest/" || { echo "cp -RL failed for $src -> $dest" >&2; return 96; }
```

Defense-in-depth: also resolve `$p` via `realpath` (with fallback for systems lacking it) before the prefix check.
