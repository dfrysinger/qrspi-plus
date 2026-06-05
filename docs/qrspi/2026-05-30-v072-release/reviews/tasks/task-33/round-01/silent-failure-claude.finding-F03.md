---
finding_id: F03
reviewer: silent-failure-claude
task: 33
round: 1
severity: low
change_type: correctness
file: agents/qrspi-plan-reviewer.md
lines: 104
category: missing-error-path
---

# Metacharacter blocklist omits newlines and braces → injection bypass

## What

Step 2 (line 104) lists the blocked shell metacharacters as:

> `;`, `|`, `&`, backtick, `$`, `(`, `)`, `<`, `>`

Missing: newline (`\n`), carriage return (`\r`), and `{` / `}`. YAML supports multi-line scalars (block scalars `|` and `>`, plus folded plain scalars across lines), so a `structural_lint:` value such as

```yaml
structural_lint: |
  grep -c 'pattern' file
  rm -rf important/
```

would parse as a two-line bash script. None of the blocklisted characters appear, so Step 2 validation passes. Step 3 then executes both commands. Brace-expansion (`rm -rf {a,b,c}`) and brace-grouping (`{ cmd1; cmd2; }`) similarly evade the blocklist (the inner `;` would be caught by the existing list, but `{ cmd1 & cmd2 }` would not — wait, `&` is listed; however `{ cmd1 \n cmd2 }` is not).

## Why this is a silent failure

The contract advertises "Reject commands containing shell metacharacters … that … could execute arbitrary code." A reader trusts that advertisement and stops examining the value. A reviewer following the rubric mechanically will run a multi-line script with arbitrary side effects, without emitting the malformed-lint finding the contract promises. This is a small attack surface (the spec is human-authored), but the silent-bypass shape is exactly what this rubric exists to prevent.

## Where

`agents/qrspi-plan-reviewer.md` § Schema-migration exception review, Step 2 bullet list (line 104).

## Suggested fix

Either:

1. Extend the blocklist to: `;`, `|`, `&`, backtick, `$`, `(`, `)`, `<`, `>`, `{`, `}`, newline, carriage return — and add a positive constraint: "the value MUST be a single line".
2. Or invert the rule: "the value MUST match the regex `^[A-Za-z0-9 _\-./:='\"]+$` (single line, no metacharacters)" and reject anything else. Allow-list is more robust than block-list for this kind of validator.

Pair the rule in `skills/plan/SKILL.md` § Plan-spec defects (line 118) so the SKILL contract and the reviewer rubric stay in sync.
