---
reviewer_tag: security-codex
change_type: correctness
severity: medium
artifact: plan.md
location: "Tasks 14 and 15 — sweep-task contract + cross-task consumers"
referenced_files:
  - plan.md
---

# F02 — Missing injection-safety requirements for user-supplied search commands

## Defect

T14/T15 specify plan-reviewer behavior that reruns author-provided grep/search proof commands from repo root, but test expectations do not require command-shape sanitization/restriction (metacharacters, command chaining, subshells, path escapes).

## Impact

Injection-prone input can execute unintended shell operations during review checks. A malicious or compromised task spec could include `proof_cmd: grep foo; rm -rf $HOME` and the plan-reviewer would execute it.

## Recommended fix

Add a constraint that the proof-command surface MUST be either (a) a closed allowlist of command shapes (e.g., `grep`, `rg`, `cat`, `find` with arg-pattern restrictions) or (b) executed in a no-shell-interpolation mode (argv array, not shell string). Add explicit rejection test fixtures for malicious command forms (`;`, `&&`, `|`, `$()`, backticks, redirect operators, parent-directory `..` traversal).

## Severity rationale

Medium not high because the threat model is "compromised task spec inside the QRSPI run directory" — the attacker already has artifact-write access, so the injection adds limited new capability. Still worth closing.
