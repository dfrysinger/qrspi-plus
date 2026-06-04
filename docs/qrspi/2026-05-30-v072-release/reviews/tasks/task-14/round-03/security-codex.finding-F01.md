---
reviewer_tag: security-codex
round: 3
finding_id: R3-F01
severity: high
change_type: correctness
referenced_files:
  - agents/qrspi-plan-reviewer.md
  - skills/plan/SKILL.md
---

# F01 — grep-proof validation still allows argument injection (bypass of sweep dependent-test enforcement)

**Location:** `agents/qrspi-plan-reviewer.md:55` (validation rule), related contract shape in `skills/plan/SKILL.md:627`

**Issue:** The R3 mitigation forbids shell metacharacters (`;`, `|`, `&`, etc.) but still permits attacker-controlled grep pattern values that start with `-`. Because the reviewer executes the provided command string verbatim, grep can interpret the "pattern" as flags instead of a pattern.

**Concrete attack scenario:** A malicious plan author submits:
- `dependent_tests: none`
- `grep -rn '--exclude=*' tests/`

The single quotes around `--exclude=*` are stripped by the shell, so grep's argv becomes `[-rn, --exclude=*, tests/]`. Grep interprets `--exclude=*` as a flag (exclude all files), suppressing scanning results and returning zero hits — letting a false `none` claim pass. The task then ships without enumerating dependent tests, bypassing the sweep gate.

**Why R3 mitigation is insufficient:** Banning shell separators blocks command injection but not option/argument injection into `grep` itself.

**Fix direction:** Require the rubric to (a) reject patterns that start with `-` as malformed (single-character regex `-` is unlikely to be a real test reference and is trivially bypassed by quoting), and/or (b) prescribe the `--` argument separator in the canonical shape: `grep -rn -- '<pattern>' tests/`. Adding `--` is the surgical fix — it tells grep to treat everything after as positional args, neutralizing flag-shaped patterns. Update the canonical shape in `skills/plan/SKILL.md` AND the reviewer rubric in `agents/qrspi-plan-reviewer.md` together. Add 1-2 defensive bats pins covering the `--` separator and the `-`-prefix rejection.
