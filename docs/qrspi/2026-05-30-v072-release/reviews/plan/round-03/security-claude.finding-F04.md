---
finding_id: F04
reviewer: security-claude
round: 3
artifact: plan.md
change_type: correctness
severity: medium
task_refs: [T20]
---

# F04 — T20 `third-party-finding-splitter.sh` test expectations omit adversarial reviewer-controlled boundary inputs

## Summary

Task 20 collapses the third-party reviewer pipeline into
`dispatch-companion.sh` (capture raw output to `<round-dir>/.dispatch/<tag>.raw`)
plus `third-party-finding-splitter.sh` (materialize stable per-finding files
`F01`, `F02`, ... or a `NO_FINDINGS` sentinel). The splitter consumes
reviewer-produced raw text — **fully untrusted, third-party LLM output** — and
writes filesystem artifacts that downstream verifier and apply-fix steps
trust by path.

The DoD (line 1201) says the splitter "fails loudly for missing flags, missing
raw output, missing boundaries, or write errors." The Test Expectations
(line 1212) exercise stable `F01, F02, ...` materialization, the
`NO_FINDINGS` sentinel, and loud failure for missing flags/raw output/boundaries
/write errors.

What's missing: any **adversarial-content** test for reviewer-controlled
content that **is well-formed enough to parse** but contains payloads
designed to subvert the splitter's filesystem semantics. The splitter walks
untrusted text and produces filesystem paths; that boundary deserves explicit
hostile-input fixtures.

## Specific gaps

1. **No fixture for an injected per-finding identifier.** The splitter
   produces `F<NN>` files. If the splitter computes the `<NN>` from a
   reviewer-controlled header (e.g., `## Finding F01`) rather than from its
   own monotonic counter, a hostile reviewer could emit
   `## Finding F../../etc/passwd` or `## Finding F01.md\0extra` and trick the
   splitter into writing outside the round directory or overwriting an
   adjacent finding's score sidecar. The plan does not pin
   "identifier is splitter-assigned, not reviewer-supplied" and the tests do
   not include any path-traversal-via-finding-id fixture.

2. **No fixture for boundary tokens embedded in finding bodies.** If a
   reviewer emits a finding body containing the splitter's section-boundary
   sentinel (e.g., a finding whose text contains the literal start-of-next-finding
   marker), the splitter may split mid-content, producing F01 with truncated
   body and F02 with reviewer-controlled prefix. The verifier then scores
   these as if they were authentic separate findings. Test expectations cover
   "missing boundaries" but not "extra/injected boundaries."

3. **No fixture for a forged `NO_FINDINGS` sentinel inside a finding body.**
   A reviewer that emits both real findings and a body containing the literal
   `NO_FINDINGS` string can produce a state where the splitter writes both a
   findings set AND a clean sentinel (or chooses the sentinel and drops the
   findings). The downstream consumer cannot tell. Plan DoD does not pin
   "sentinel detection is whole-document, not substring, and is mutually
   exclusive with finding emission."

4. **No fixture for control characters / NUL bytes in finding text.** Bash
   string handling and many splitter implementations mishandle NUL or CR
   silently. The splitter writes files whose contents become "untrusted data"
   read by other agents; if the reviewer can embed terminator bytes, the
   downstream wrapper-based protections may be bypassed at consumption time.

## Why this matters at plan level

The whole T20 contract is "reviewer output persistence stays inside the
script chain instead of repeated orchestrator-side prose" (line 1177). The
script chain is now the **trust boundary** between third-party LLM output and
the verifier. The plan correctly puts payloads into files (good — wrapper
markers can be applied by readers) but treats the splitter's parsing of
those payloads as a structural problem (missing/unmatched boundaries) rather
than as a hostile-input problem.

Without these fixtures, the implementer will build a splitter that handles
well-formed and structurally-broken input but is silently unsafe against any
adversarial reviewer payload that lands within the structural envelope.

## Recommended remediation (do not require any specific wording)

Add to T20 Test Expectations:

- A fixture proving `F<NN>` identifiers are splitter-assigned
  (monotonic counter), and that any reviewer-emitted `F<...>`-shaped token
  in section headers is treated as content, not as a write-path component.
- A fixture proving boundary-token injection within a finding body does not
  cause mid-content split or per-finding-file boundary confusion.
- A fixture proving `NO_FINDINGS` sentinel detection requires the canonical
  whole-document shape and is mutually exclusive with per-finding emission
  (presence of both fails loud).
- A fixture proving NUL / CR / other control bytes in reviewer text are
  either stripped pre-write or fail the splitter loudly — and that whatever
  the chosen policy is, it is uniform.

## Files / sections to update

- `plan.md` Task 20 → **Definition of done** for splitter behavior
  (line 1201).
- `plan.md` Task 20 → **Test expectations** for splitter coverage
  (line 1212).
