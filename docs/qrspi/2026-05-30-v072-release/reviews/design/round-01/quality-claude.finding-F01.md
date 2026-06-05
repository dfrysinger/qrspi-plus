---
finding_id: F01
artifact: design
reviewer: quality-claude
round: 1
severity: high
change_type: correctness
referenced_files:
  - docs/qrspi/2026-05-30-v072-release/design.md
  - docs/qrspi/2026-05-30-v072-release/research/summary.md
---

## CD-4 § I reviewer-hardening prose prescribes `security` as a `change_type` value; omits `scope` and `intent` — internal contradiction with canonical enum and CD-4's own Iron Law

### Where

`design.md` § CD-4 "I. Reviewer-side hardening" (line 636):

> "Required frontmatter field: `change_type:`. Allowed values: `style`, `clarity`,
> `correctness`, `security`. NO other values."

### What is wrong

The hardening instruction enumerates four `change_type` values: `style`, `clarity`,
`correctness`, `security`. The canonical enum — per research `summary.md` Q2 (line 32),
which reads the live `skills/reviewer-protocol/SKILL.md:232` source of truth — is:

```
style | clarity | correctness | scope | intent
```

Two problems:

1. **`security` is not a valid `change_type` value.** It does not appear in the canonical
   enum at any version of `reviewer-protocol/SKILL.md` verified by Q2. `verifier-fan-in.sh`
   rejects `change_type_out_of_enum` events; a reviewer that emits `change_type: security`
   will trigger the fan-in script's out-of-enum rejection path — producing the "zero kept
   findings for your tag for this round" outcome that the very Iron Law text at line 640
   warns about. The hardening instruction would cause the failure it exists to prevent.

2. **`scope` and `intent` are absent.** The `scope` and `intent` values have special
   semantics in the filter rule (they bypass score thresholds and are always kept, per Q3).
   If a reviewer agent is hardened with the CD-4 § I text and later emits `change_type:
   scope`, the self-check instruction ("the value is one of the enum members listed above")
   would flag a valid emission as a self-reported error, suppressing correct behavior.

### Internal contradiction

CD-4 § I line 640 states: "Emitting the wrong field name or an out-of-enum value produces
zero kept findings for your tag for this round." By prescribing `security` — a value that
IS out-of-enum — the hardening text sets up the reviewer to receive exactly this penalty.
The hardening and the iron law are directly inconsistent within the same cross-goal
decision section.

### Fix

Replace the enum in the § I hardening verbatim text with the canonical set from
`reviewer-protocol/SKILL.md`:

```
Allowed values: `style`, `clarity`, `correctness`, `scope`, `intent`. NO other values.
```

Additionally, note that `scope` and `intent` bypass score filtering entirely (always kept).
The self-check instruction should reflect this for completeness.

If `security` was intended as a separate finding-classification tag, it belongs in a
different field (e.g., a topic tag), not in `change_type`.
