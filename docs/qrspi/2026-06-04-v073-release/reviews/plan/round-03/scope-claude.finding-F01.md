---
reviewer: scope-claude
artifact: plan.md
round: 3
finding_id: F01
severity: blocking
change_type: scope
location: plan.md § T28 (Create VERSION file …) — Description and Test Expectations
---

# F01 — T28 invents a semver-validation contract that design.md G8 explicitly defers

## What the artifact does (round-3 diff, plan.md T28 lines ~719, ~726–727)

T28's Description now mandates a specific semver-validation contract beyond the design-approved one:

> "Beyond the structural one-line-non-empty check, the VERSION content is validated against an explicit semver allowlist regex `^[0-9]+\.[0-9]+\.[0-9]+([+-][a-zA-Z0-9.-]+)?$` (major.minor.patch with optional `+build` or `-prerelease` suffix); a value that is a well-formed single non-empty line but does NOT match the semver shape triggers the distinct `version-source-malformed:` named diagnostic and halts non-zero — preventing arbitrary content (e.g., `latest`, `v0.7.3`, `0.7`, `0.7.3.4`, shell-substitution attempts) from being stamped into the five consumer manifests (security-claude R2-F02)."

T28's Test Expectations bind two new behavioral contracts:

> "A single-line VERSION whose content does NOT match the semver shape `^[0-9]+\.[0-9]+\.[0-9]+([+-][a-zA-Z0-9.-]+)?$` … triggers the `version-source-malformed:` named diagnostic and a non-zero exit — distinct from the `version-source-missing-or-malformed:` structural-class failure (security-claude R2-F02)."
> "A single-line VERSION that DOES match the semver shape (including suffixes like `0.7.3-rc1`, `0.7.3+build.42`) passes validation and stamps successfully into the five consumer files."

## Why this is a scope finding

`docs/qrspi/2026-06-04-v073-release/design.md` G8 § Dependencies + edge cases (line 484, status: approved) explicitly defers semver validation:

> "Edge case — version string format. Honor whatever the existing manifests use (e.g., `0.7.3` semver-ish). Build script does not parse or validate semver — just reads the line and writes it through. **Stricter validation can land later if it matters.**"

Plan T28 is unilaterally:

1. Re-opening that deferral — adopting "stricter validation now" rather than "later if it matters."
2. Choosing the validation policy (semver allowlist with build/prerelease suffix support, rejecting `v` prefix, rejecting four-segment forms, etc.).
3. Defining a new contract-level named diagnostic (`version-source-malformed:`) distinct from the design-named `version-source-missing-or-malformed:`.

Per `skills/plan/owns-defers.md`, **"Architecture decisions, key trade-offs, system diagrams" → `design.md` (locked upstream; Plan consumes, does not re-author)**. The validation policy (whether to validate, what shape to accept, which diagnostics to emit at the contract surface) is a design.md G8 architectural decision; Plan is consuming a deferral and replacing it with an opposite-direction contract.

Plan itself demonstrates it knows this rule. T01's round-3 Author note (responding to silent-claude R01-F03, the symmetric situation for CD-1):

> "Addressing it would require a design.md amendment changing CD-1 Acceptance bullet 2 from fail-soft to fail-loud; the approved design currently mandates the fail-soft direction… This plan honours the design contract and does not introduce a plan-side workaround. **Re-opening the contract is a Design-phase decision, not a Plan-phase one.**"

That same logic applies verbatim to T28's security-claude R2-F02: addressing it requires a design.md amendment to G8's deferral; the approved design currently does not validate; re-opening the contract is a Design-phase decision.

## Additional boundary-drift signal (lexical leakage)

Per `owns-defers.md` § Boundary-drift signals:

> **"Line-by-line logic, control-flow detail, algorithm pseudocode" — Implement-layer leak.**

The literal regex `^[0-9]+\.[0-9]+\.[0-9]+([+-][a-zA-Z0-9.-]+)?$` is algorithm-precise prose. Even if the validation contract itself were approved at the design layer, the exact regex (anchors, character classes, quantifiers, suffix grouping) is an Implement-layer choice. The OWNS/DEFERS framing — "Plan says the contract, Implement chooses the regex" — is violated: Plan picks both the shape and the literal pattern.

## Recommended remediation (Plan-layer)

Either:

(a) Drop T28's semver-validation additions: restore the round-2 description (structural one-line-non-empty check only); remove the `version-source-malformed:` diagnostic; remove the semver-shape and regex-literal test expectations; add a T28 Author note analogous to T01's, deferring security-claude R2-F02 to a Design-phase re-open of G8's "stricter validation can land later if it matters" deferral. OR

(b) Block T28 on a design.md amendment (BLOCKED status until G8's edge-case prose is updated and re-approved); once design.md owns the validation contract, T28's description and test expectations reference design.md as the authority and stop carrying the regex literal (Plan describes the shape behaviorally; Implement chooses the regex).

The first option is the closer parallel to the T01 disposition and preserves the round-3 boundary discipline the T01 Author note set.
