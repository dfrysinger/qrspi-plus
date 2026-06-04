# Code Quality Review — Task 39, Round 4 (claude)

**Verdict: clean**

R3 fix-cycle 3 made test-only changes (+138/-12). Production code unchanged.
Reviewed all five new/modified test additions plus the three doc-path bumps:

1. **tc-F05 (CR-strip portability)** — `grep -U $'\r'` replaced with `wc -c`
   vs `tr -d '\r' | wc -c` size-diff. Portable across bash 3.2 + BSD/GNU/
   BusyBox. Inline comment names the vacuous-pass failure mode it fixes.
   Textbook Self-Consistent-Defense (§12) repair.

2. **tc-F02 (tightened cache-retirement greps)** — `grep -RF '<path>'`
   tightened to `grep -RnE '(bash[[:space:]]+|\\./)scripts/<name>\\.sh'`,
   matching invocation forms only. `--exclude-dir=docs` intentionally
   dropped; the three doc-path bumps in `fixes/integration-round-05/`
   and `fixes/task-10-round-{01,02}/` align the only legacy invocation-
   form callers with the tightened pattern.

3. **tc-F01 (acceptance resolver tests for fixtures)** — Two new tests
   close a real spec gap (task-39 §Test expectations line 70: "with the
   required diagnostics"). Both stage minimal manifest-shaped roots,
   copy fixture bytes into `skills/<n>/SKILL.md`, invoke the documented
   `--root`/`--out` CLI, and assert non-zero status plus the load-bearing
   diagnostic phrases. Diagnostic asserts align with production strings
   (`assertNoClaudeSkillDir`, cycle-detector chain print).

4. **tc-F03 (denylist coverage)** — Three tests covering `.env` under
   `skills/`, `id_rsa` under `scripts/`, `*.pem` under `.claude-plugin/`.
   Asserts diagnostic regex `denylist|secret|refused` (matches production
   string at `recurseDir` line 316), file-path inclusion via `grep -F`,
   AND that no build/ output exists at the offending path — a valuable
   second-order check.

Comment blocks add WHY content (gap rationale, portability rationale,
call-path coverage rationale, exclude-dir rationale) without ceremonial
restatement. ID-hygiene-relevant tokens (`[T39/G32]` test-name prefixes)
follow pre-existing file convention. No DRY violations of consequence.
No YAGNI. No mock discipline issues (tests exercise the real CLI surface).

No findings.
