---
reviewer: security-claude
task: 40
round: 1
verdict: clean
---

# Security review — Task 40, round 1: clean

Scope reviewed (from `round-01.diff` against base):

- `tests/lint/test-bats-body-assertion-guard.bats` (new lint, 121 lines)
- `tests/unit/test-ci-workflow-shape.bats` (+42 lines, T40/G21 workflow-shape pins)
- `tests/unit/test-using-qrspi-vocab.bats` (+8 lines, `[ -n "$body" ]` guards)
- `tests/unit/test-dispatch-sites.bats` (+1 line, `bats_require_minimum_version 1.5.0`)

## Findings

None. Each OWASP-style category was examined against the diff:

1. **Injection** — Both awk programs are static string literals. The only
   dynamic input is the file list from `find "$REPO_ROOT/tests" -name "*.bats"
   ! -name "test-bats-body-assertion-guard.bats"`, passed to awk as separate
   argv entries (`"${corpus[@]}"`), never concatenated into shell or awk
   source. No `eval`, no `bash -c`, no `xargs sh`. File *contents* are read
   by awk only via `$0`/`FNR`/`FILENAME` for regex matching and `printf`
   diagnostics to stderr — not executed.
2. **AuthN/AuthZ** — N/A: local CI lint, no endpoints, no sessions.
3. **Data exposure** — Diagnostics emit `file:line: ...` to stderr from
   files already in the repository. No secrets, tokens, or PII flow
   through this code path.
4. **Input validation** — awk regexes (`/\[ -n "\$body" \]/`,
   `/\[\[ "\$body"/`, `/^@test /`, `/^\}/`, `/bats_require_minimum_version/`,
   `/run --separate-stderr/`) are short, anchored, and free of nested
   quantifiers — no ReDoS surface. `find` output is read via
   `while IFS= read -r f` which preserves any path bytes safely; the
   corpus is repo-controlled so filename-pathology is not an attacker
   primitive here.
5. **Dependencies** — No new third-party deps. The added
   `bats_require_minimum_version 1.5.0` declaration is itself a
   security-positive defensive guard (fails loud on stale bats rather
   than silently misbehaving on `run --separate-stderr`).
6. **Cryptography** — N/A.
7. **Race conditions** — Pure read-only static analysis over
   checked-in files; no shared mutable state, no TOCTOU windows.

The `.git/hooks/pre-commit` `grep -E` check in `test-ci-workflow-shape.bats`
reads a local hook file only — no traversal or injection surface, and the
file is under the developer's own `.git/`.

Attack-model summary: there is no untrusted input path. An attacker would
need commit access to the test corpus to influence this code, at which
point the lint is the least of the concerns. **No exploitable issues.**
