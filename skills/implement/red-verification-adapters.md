# RED-Verification Adapter Contract

This document is the authoritative contract consumed by:
- The four per-framework adapter scripts (T10): `scripts/red-verify-bats.sh`, `scripts/red-verify-vitest.sh`, `scripts/red-verify-jest.sh`, `scripts/red-verify-pytest.sh`
- The Implement-skill RED-verification gate (T11) that invokes adapters after `qrspi-test-writer` completes in Implement-phase mode

Adapter scripts implement; this document owns their interface. The orchestrator gate consumes; this document owns the classification semantics it acts on.

## Adapter Call Surface

Each adapter is a standalone executable script invoked by the orchestrator gate with exactly three required flags:

```
scripts/red-verify-<framework>.sh \
  --runner-exit <int> \
  --stdout-file <path> \
  --stderr-file <path>
```

**Required flags:**

| Flag | Type | Description |
|------|------|-------------|
| `--runner-exit` | integer | The exit code returned by the test runner process |
| `--stdout-file` | path | Absolute path to a file containing the runner's captured stdout |
| `--stderr-file` | path | Absolute path to a file containing the runner's captured stderr |

All three flags are required. An adapter that receives fewer than three flags, or receives a flag with a missing or invalid value, must emit a loud diagnostic to stderr and exit 1 without emitting a classification token.

## Classification Output Contract

Each adapter emits exactly one classification token on stdout, followed by a newline. No other output is written to stdout. The three legal tokens are:

| Token | Meaning |
|-------|---------|
| `pass` | The test suite ran to completion and all tests passed (no assertion failures detected) |
| `assertion-failure` | The test suite ran to completion and at least one assertion failed (the runner exit was non-zero due to test failures, not infrastructure) |
| `infrastructure-failure` | The runner could not execute the tests: setup failure, missing binary, import error, compilation error, timeout, or any non-assertion cause that prevented the suite from reaching assertion evaluation |

The adapter MUST emit exactly one of these tokens. Emitting more than one token, emitting a token not in this set, or emitting no token on exit 0 is a contract violation and will be treated as an unrecognized-output error by the orchestrator gate.

## Adapter Exit-Code Contract

| Exit code | Condition |
|-----------|-----------|
| `0` | A classification token was successfully emitted on stdout |
| `1` | The runner output was unrecognized or a flag validation error occurred; a loud diagnostic was emitted to stderr; no classification token was written to stdout |

The orchestrator gate checks the adapter exit code before reading stdout. A non-zero exit causes the orchestrator to treat the classification as `infrastructure-failure` and pause with a diagnostic naming the adapter and the stderr content.

## Initial Framework Set

The four adapter scripts in the initial set cover these test frameworks:

| Framework | Script | Runner binary |
|-----------|--------|--------------|
| **BATS** | `scripts/red-verify-bats.sh` | `bats` |
| **Vitest** | `scripts/red-verify-vitest.sh` | `vitest` / `npx vitest` |
| **Jest** | `scripts/red-verify-jest.sh` | `jest` / `npx jest` |
| **pytest** | `scripts/red-verify-pytest.sh` | `pytest` / `python -m pytest` |

Each adapter is framework-specific: it interprets the runner's stdout, stderr, and exit code according to that framework's documented output conventions. Adapters for additional frameworks can be added without changing this contract or the orchestrator gate.

## Orchestrator Pause-Behavior

After invoking the adapter for each targeted test, the orchestrator gate acts on the classification token as follows:

| Classification | Orchestrator action |
|---------------|-------------------|
| `assertion-failure` (at least one task-relevant assertion failing) | Proceed to implementer dispatch — the suite is RED against the targeted behavior; TDD cycle can begin |
| `pass` (targeted behavior already passes before implementation) | Proceed to implementer dispatch — the test was written but does not isolate new behavior (vacuous-RED detected at suite level); see Vacuous-RED below |
| `infrastructure-failure` | **Pause** with a load-bearing diagnostic: name the adapter, the framework, and the stderr content; wait for user resolution before continuing |
| Adapter exit non-zero | **Pause** with a load-bearing diagnostic: name the adapter, its exit code, and the stderr content; treat as `infrastructure-failure` |

### Vacuous-RED

Vacuous-RED is the suite-level condition where:
- All targeted tests return `pass` (no assertion failures on the new behavior), AND
- No targeted test returns `assertion-failure`

Even when individual adapters return `pass`, if the expected-RED behavior is absent across the entire targeted test suite, the orchestrator pauses with the following diagnostic before dispatching the implementer:

> `RED-verification vacuous: no assertion failure observed for the targeted behavior. The test-writer may have written a test that trivially passes without implementation. Review the test before proceeding.`

The user may choose to proceed (accepting the test as written) or loop back to `qrspi-test-writer` to strengthen the test. This pause is non-negotiable — the orchestrator does not auto-proceed on vacuous-RED.

`infrastructure-failure` always takes precedence over vacuous-RED detection: if any adapter returns `infrastructure-failure`, the orchestrator pauses for infrastructure resolution before any vacuous-RED check runs.
