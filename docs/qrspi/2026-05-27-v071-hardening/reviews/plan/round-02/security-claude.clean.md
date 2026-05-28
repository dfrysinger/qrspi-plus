---
reviewer: security-claude
round: 2
verdict: clean
---

# Security Review — Round 2: No Findings

All three round-1 security-claude findings and the convergent security-codex F01 finding
have been addressed by the R2 plan revision. No new security gaps were introduced.

## Resolved findings

### security-claude F01 — DEL (0x7F) in header-name position unpinned
**Status: RESOLVED.**
Task 1 test expectations now include:
> DEL (0x7F) in a header NAME (not just value) causes the script to exit before any
> network dispatch

The name-position and value-position coverage are now symmetric for all 33 target bytes.

### security-claude F02 — `check_codex_available` fail-open on unrecognized host
**Status: RESOLVED.**
Task 6 test expectations now include:
> `check_codex_available` called with an unrecognized host argument returns non-zero and
> emits a single-line diagnostic to stderr identifying the unsupported host value

The availability check is now pinned as fail-closed for unknown input, preventing
silent fall-through to "Codex available" on future-host extension.

### security-claude F03 — `codex-broker` transport scope boundary undocumented
**Status: RESOLVED.**
Task 1 description now contains an explicit scope-boundary statement:
> The `codex-broker` transport path has no configurable `default_headers` surface and
> is therefore out of scope for this task.

The injection-vector surface boundary is now documentably closed at the plan level.

### security-codex F01 — Host detection fail-open on malformed COPILOT_CLI value
**Status: RESOLVED.**
Task 6 test expectations now include:
> `detect_host` with `COPILOT_CLI` set to any non-empty value other than `1`
> (e.g., `COPILOT_CLI=0`, `COPILOT_CLI=true`) returns non-zero and emits a single-line
> diagnostic to stderr naming the rejected value — does NOT silently treat the value as
> `claude-code` or `copilot-cli`

The host-detection gate is now fail-closed for ambiguous and malformed environment signals.

## Additional R2 security hardening confirmed sound

The following new test expectations added in R2 each improve fail-closed posture and
contain no new gaps:

- **Config-mismatch propagation (Task 6/7):** When detected host disagrees with
  `codex_reviews` config, dispatch surface returns non-zero with diagnostic. Caller
  cannot mistake failure for success.

- **`check_codex_available` failure propagation (Task 7):** "No log-and-continue"
  is explicitly required — non-zero exit from the availability check is propagated,
  not swallowed.

- **Empty-input false-positive guard (Task 1):** Empty header name and empty header
  value do not trigger the die path. Correctly avoids misconfigured-provider rejection
  while preserving detection for all 33 control bytes.

- **Stderr-silent under normal operation (Task 6):** Neither `detect_host` nor
  `check_codex_available` writes to stderr on the success path, preventing
  inadvertent credential or diagnostic leakage in piped invocations.

## Security-codex F02 set-aside disposition
The plan's "Reviewer Findings Set Aside" section acknowledges security-codex F02
(Codex auth/token validation) with the disposition: out of G6 scope, handled upstream
of the dispatch surface. This is correct — the host-detection and availability-check
boundary is not the right layer for API authorization; surfacing auth failures at the
dispatch transport level is the appropriate design. No objection to the set-aside.
