---
finding: F01
reviewer: cq-claude
round: 5
task: 1
severity: medium
category: id-hygiene / committed-process-artifact-tokens
file: tests/unit/test-run-third-party-llm.bats
lines: 696, 715-716, 758
---

# F01 — Reviewer-round finding IDs committed into test-file comments

## What the code does

Three section-header comments immediately above new `@test` blocks contain
embedded QRSPI reviewer-round finding IDs:

```bash
# tests/unit/test-run-third-party-llm.bats  line 696
# security-claude F03: _control_char_check must NOT reject non-ASCII (0x80-0xFF).

# line 715-716
# sf-codex F01 / sf-claude F02: NUL pre-flight must die when the byte-count
# pipeline returns empty (fail-closed on tool failure, not fail-open).

# line 758
# security-claude F01: API key value must be screened for control characters
# before being placed into the Authorization header.
```

## ID hygiene analysis

Applying the grep-lint procedure across the task diff with the canonical
QRSPI-internal pattern `\b[GRDFTQ]-?[0-9]+[A-Za-z]?\b`:

- `F03` — matches (F in `[GRDFTQ]`, followed by `03`)
- `F01` — matches (twice: once in `sf-codex F01`, once in `security-claude F01`)
- `F02` — matches (`sf-claude F02`)

These tokens are run-specific traceability references — they record *which
reviewer finding in which round motivated the addition of the test*.  That
metadata belongs in the PR description or a CHANGELOG entry, not in committed
code comments.

## Why this is a problem

A future maintainer reading the test file has no path back to `sf-codex F01`
or `security-claude F03`.  The review round is not in the repository;
the tokens are opaque without the external review thread.  The comment adds
no behavioral understanding beyond what the `@test` name already states —
it is pure process-artifact metadata committed into production-committed code.

This is precisely the failure mode the ID-hygiene rule targets: an implementer
copying run-specific tokens from the review process into the diff.

The three occurrences are in **code comments** only (not inside `@test` names,
`describe`, or `it` blocks), so the finding is scoped to comment surfaces.

## Recommended fix

Replace each section-header comment with a plain description of why the test
exists as a behavioral statement.

| Current | Replacement |
|---|---|
| `# security-claude F03: _control_char_check must NOT reject non-ASCII (0x80-0xFF).` | `# Scope guard: bytes 0x80-0xFF are outside the detection spec and must not cause false-positive abort.` |
| `# sf-codex F01 / sf-claude F02: NUL pre-flight must die when the byte-count pipeline returns empty (fail-closed on tool failure, not fail-open).` | `# Fail-closed: NUL pre-flight must die (not silently pass) when the wc pipeline returns empty or non-numeric output (tool-failure guard).` |
| `# security-claude F01: API key value must be screened for control characters before being placed into the Authorization header.` | `# API-key injection guard: the key is placed verbatim into the Authorization header; same control-char injection risk applies as for default_headers values.` |

The behavioral replacements preserve all meaningful context while removing
the opaque finding-ID coupling.
