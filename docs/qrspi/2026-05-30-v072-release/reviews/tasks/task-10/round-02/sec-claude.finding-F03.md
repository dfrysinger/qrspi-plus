---
finding_id: R2-F03
reviewer_tag: sec-claude
severity: low
change_type: correctness
referenced_files:
  - skills/using-qrspi/SKILL.md#L995,L999
  - tests/acceptance/v07-phase1/test-phase1-acceptance.bats#L2065-L2067
---

# summary field has no mandatory-quoting rule; orchestrator-synthesized content with YAML-structural chars can corrupt block

The `summary:` field value is a one-liner the orchestrator synthesises from analysis of dropped findings. Canonical example shows double-quote wrapping. Prose says only "a `summary` one-liner" with no explicit requirement to quote, and no test verifies runtime-generated observations documents are well-formed YAML.

**Concrete attack scenario:** A reviewer writes a finding whose `message` body contains YAML-structural characters in its first sentence — e.g. *"This spec section: goal-leakage[1] fails to define thresholds"*. The orchestrator synthesising a one-liner summary may incorporate reviewer language verbatim:

```yaml
- summary: This spec section: goal-leakage[1] fails to define thresholds
  defect_class: goal-leakage
  ...
```

YAML parsers interpret the bare colon-after-non-whitespace as a mapping indicator: the entire entry becomes malformed. `yaml.safe_load` raises `ScannerError`, silently (currently) because no script parses `dispositions.md`. Variants: YAML anchor (`&anchor`) or alias (`*anchor`) sequences from reviewer prose can cause cross-document resolution attempts.

AC5's `yaml.safe_load` call validates only the static template embedded in SKILL.md — never runs against an actual runtime `round-NN-dispositions.md`.

**Fix:** SKILL.md prose: the `summary:` value MUST be enclosed in double quotes; any `"` characters within the value MUST be escaped as `\"`. Orchestrators MUST NOT copy reviewer finding text verbatim without stripping/escaping YAML-unsafe characters. Run `yaml.safe_load` against real dispositions.md fixtures in CI when available.
