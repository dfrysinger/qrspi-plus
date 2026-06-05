---
finding: F02
reviewer: silent-failure-claude
round: 2
severity: low
category: Output Shape Ambiguity — Embedded `=` in EVIDENCE Value
file: scripts/detect-interaction-mode.sh
line: 115
---

# F02: EVIDENCE value contains embedded `=` — silent truncation by `cut -d= -f2` parsers

## Location

`scripts/detect-interaction-mode.sh` line 115:

```bash
printf 'EVIDENCE=QRSPI_INTERACTION_MODE=%s override\n' "${QRSPI_INTERACTION_MODE}"
```

## What is emitted

When `QRSPI_INTERACTION_MODE=auto` the script emits:

```
EVIDENCE=QRSPI_INTERACTION_MODE=auto override
```

The value portion (`QRSPI_INTERACTION_MODE=auto override`) contains a second
`=` character.

## Silent failure scenario

Any downstream parser that uses `cut -d= -f2` to extract the value of a
`KEY=VALUE` line will silently receive `QRSPI_INTERACTION_MODE` instead of
`QRSPI_INTERACTION_MODE=auto override`:

```bash
line='EVIDENCE=QRSPI_INTERACTION_MODE=auto override'
echo "$line" | cut -d= -f2          # → QRSPI_INTERACTION_MODE   (truncated)
echo "${line#*=}"                   # → QRSPI_INTERACTION_MODE=auto override  (correct)
```

The orchestrator that consumes this script's stdout to populate the
`.interaction-mode-audit.json` entry would silently write a truncated EVIDENCE
string. The audit tuple would name the override source as
`QRSPI_INTERACTION_MODE` with no value token, making it indistinguishable from
a truncation artifact vs. an explicit override of an empty value.

## Why this matters

The task spec (task-24.md line 44) requires:

> the helper emits a direct VERDICT with **evidence naming the override value**

If the evidence is silently truncated, the "naming the override value" clause
is violated in the audit record without any error or warning — a pure silent
failure.

## Risk assessment

- **Operational impact**: Low — `VERDICT` (not `EVIDENCE`) drives orchestrator
  decisions. The truncation affects audit fidelity only.
- **Detectability**: Zero — no test exercises the parsed EVIDENCE value from a
  `cut -d= -f2` perspective. The existing test at line 197 uses `grep -q` to
  match a pattern across the raw output line, which passes regardless of
  whether an actual parser would truncate the value.
- **Parser contract gap**: The output-shape contract specifies one `KEY=VALUE`
  pair per line but does not document how consumers must parse values that
  themselves contain `=`.

## Recommended mitigations (choose one)

**Option A — Document the parser contract** (lowest-friction): Add a comment
to the output-shape section of the script header stating that values may
contain `=` and consumers MUST use `${line#*=}` (not `cut -d= -f2`).

**Option B — Restructure the EVIDENCE value** (eliminates ambiguity): Rephrase
to avoid the embedded `=`:

```bash
printf 'EVIDENCE=QRSPI_INTERACTION_MODE override (value: %s)\n' "${QRSPI_INTERACTION_MODE}"
```

This emits `EVIDENCE=QRSPI_INTERACTION_MODE override (value: auto)` — no
embedded `=`, unambiguous for all parsers.

**Option C — Add a parser-contract test**: Add a bats test that extracts the
EVIDENCE value using `${line#*=}` and asserts it contains both the env-var
name and the override value, exercising the correct parsing path.
