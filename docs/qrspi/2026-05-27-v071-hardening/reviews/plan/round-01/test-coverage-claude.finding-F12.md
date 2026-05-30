# Finding F12: Task 10 — "Concrete model identifier" is not defined in testable terms

**Artifact:** plan.md
**Task:** Task 10 (G7b part 2 — per-host model_routing resolution)
**Category:** Test Expectation Quality
**Severity:** blocking

## Problem

Two expectations use the phrase "concrete model identifier" without defining what makes an identifier "concrete":

> "`docs/qrspi/2026-05-27-v071-hardening/config.md` contains a `model_routing:` table with at least one **concrete model identifier** entry for each of the three tier names (haiku, sonnet, opus) under the `claude-code` host"
>
> "…contains at least one **concrete model identifier** entry for each of the three tier names under the `copilot-cli` host"

The only negative constraint given is in a third expectation: "No entry in the `copilot-cli` column … is a bare Claude tier short-form (the strings 'haiku', 'sonnet', or 'opus' alone)." But "concrete" for the `claude-code` column has no constraint at all. 

Questions a test writer cannot answer:
- Is `claude-haiku-4.5` concrete for `claude-code`? What about `claude-3-haiku-20240307`?
- Is `gpt-5.3-codex` concrete for `copilot-cli`? What about just `codex`?
- Is there a format (vendor-prefix + model-name + version?) or just "not a tier name"?
- Does the Copilot constraint ("not a bare Claude tier short-form") also exclude other known non-concrete values like `inherit`?

Without an explicit definition of "concrete," the structural lint assertions in Task 10 cannot be written deterministically. The test writer will need to invent their own definition, which may not match the implementer's intent.

## Recommendation

Add a definition of "concrete model identifier" to the expectations:

- "A `concrete model identifier` is a value that is NOT one of the four reserved tier short-forms (`haiku`, `sonnet`, `opus`, `inherit`) and NOT the empty string — it must contain at least one non-alphabetic character (e.g., a hyphen, period, or digit) that distinguishes it from a tier name."

Or, if specific model IDs are already known from `design.md` DKR9, list the expected values explicitly:

- "The `claude-code` column must contain values of the form `claude-<name>-<version>` (e.g., `claude-haiku-4.5`, `claude-sonnet-4.6`). The `copilot-cli` column must contain the Copilot-native model identifiers named in `goals.md` G6."
