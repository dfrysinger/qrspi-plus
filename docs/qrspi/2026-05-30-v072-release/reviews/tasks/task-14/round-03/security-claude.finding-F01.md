---
reviewer_tag: security-claude
round: 3
finding_id: R3-F01
severity: medium
change_type: correctness
referenced_files:
  - agents/qrspi-plan-reviewer.md
---

# F01 — Single quote `'` absent from rejected-metacharacter list enables extra grep-path injection

**Location:** `agents/qrspi-plan-reviewer.md:55`

**Summary:** R3 validate-before-execute rule lists nine rejected shell metacharacters (`;`, `|`, `&`, backtick, `$`, `(`, `)`, `<`, `>`) but omits `'`. The required command shape uses single quotes as pattern delimiters (`grep -rn '<pattern>' tests/`), so a crafted pattern containing `'` closes the quoting context early and injects an arbitrary extra positional argument before the legitimate `tests/` argument.

**Attack scenario:**
```
dependent_tests: none
  grep -rn 'model:' /etc/shadow 'x' tests/
```
Shape check passes (ends with `' tests/`), metachar scan passes (none in injected pattern), no-tokens-after-tests/ passes (nothing after `tests/`). Execution: `grep -rn 'model:' /etc/shadow 'x' tests/` — shell argv becomes `[model:, /etc/shadow, x, tests/]`. Grep scans `/etc/shadow` and `tests/`. If the reviewer logs grep output, sensitive content lands in the review artifact. Zero-match path silently validates a `none` claim against the wrong directory.

**Fix:** Add `'` to the explicit rejected list AND extend the test that asserts the rejected enumeration. (Companion to sec-codex F01 — same root cause: grep-argument injection. Consolidated fix should add `--` separator + reject `-`-prefix patterns + add `'` to metachar list.)
