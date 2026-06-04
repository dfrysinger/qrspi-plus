---
finding_id: F01
reviewer: security-claude
task: 33
round: 2
severity: medium
change_type: correctness
file: agents/qrspi-plan-reviewer.md
lines: 102-105
category: argument-injection
---

# `structural_lint` path validator allows whitespace/newline → argument injection

## What

Round 2's Step 2 path validator (reviewer.md:102-105) requires the value to:
1. start with the literal prefix `scripts/structural-lints/`,
2. not contain `..`,
3. not start with `/`,
4. not contain shell metacharacters (set inherited from round 1: `;`, `|`, `&`, backtick, `$`, `(`, `)`, `<`, `>`).

**Whitespace, tab, and newline are not in the rejection set.** The contract in `skills/plan/SKILL.md:101` similarly enumerates only the three structural rules (prefix / `..` / absolute) without forbidding spaces or newlines.

Step 3 says: "run `bash <validated-path>` from the repository root with no spec-controlled arguments." The reviewer is an LLM that constructs the Bash command by interpolating `<validated-path>` into a shell command line. If the validated value contains whitespace, the words after the first split become positional arguments — contradicting the "no spec-controlled arguments" guarantee Step 3 promises.

## Concrete attack

A plan author wants the schema-migration LOC/file-count exemption while pushing a non-mechanical, behavior-changing diff:

1. Reuse a legitimate, checked-in lint script (e.g., one that runs `git diff --stat $1`).
2. Set: `structural_lint: scripts/structural-lints/check-shape.sh -- :!path/with/the/real/changes/**`
3. No blocked metacharacters; passes Step 2.
4. Reviewer expands to `bash scripts/structural-lints/check-shape.sh -- :!path/with/the/real/changes/**`.
5. The script's pathspec exclusion hides the non-mechanical files from the diff it inspects, exits 0, exemption granted against a non-mechanical diff.

A second variant uses a literal newline in the YAML value (block-scalar or quoted form with `\n`) to inject a second command line if the LLM ever interpolates the value into a multi-line heredoc or `bash -c "<value>"` form. The current prose does not pin which interpolation shape the reviewer must use.

## Why round 2's mitigation does not cover this

Round 1's vulnerability was "inline bash command — anything goes." Round 2's fix is "must be a script path under `scripts/structural-lints/`." That stops the trivial `; rm -rf /` form but treats the value as a *path* without constraining it to a *single filename token*. The "no shell metacharacters" clause inherits round 1's narrow character list which never had to worry about spaces.

## Recommended fix

Tighten Step 2 (and matching SKILL.md prose) to require the value match a strict single-token filename regex, e.g.:

```
^scripts/structural-lints/[A-Za-z0-9_.-]+\.sh$
```

Reject any value containing whitespace, tab, newline, or any character outside the token class — not just the round-1 metacharacter list. Pin Step 3's invocation form explicitly (e.g., `bash -- <path>` with the path passed as a single argv element, never interpolated into a `bash -c` string), and document that no characters after the validated filename are permitted regardless of YAML quoting.

## References

- agents/qrspi-plan-reviewer.md:102-109 — Step 2 validator and Step 3 execution prose.
- skills/plan/SKILL.md:101 — `structural_lint:` field contract.
