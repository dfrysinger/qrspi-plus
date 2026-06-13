---
finding_id: F02
reviewer: security-claude
reviewer_tag: security-claude
artifact: plan.md
round: 2
severity: medium
change_type: defect
category: input-validation
referenced_files:
  - docs/qrspi/2026-06-04-v073-release/plan.md
tasks_affected: [T28]
---

# F02 — T28 VERSION content validation rejects only structural shape (missing/empty/multi-line); no allowlist on the value content, leaving JSON-injection / option-shape vectors open

## Summary

T28 specifies that `tools/build-plugin.mjs` reads the repo-root `VERSION` file
and writes the value into the `"version"` field of all five consumer JSON
manifests. The build script's fail-loud contract names exactly three rejection
classes — **missing**, **empty**, **multi-line** — under the single named
diagnostic `version-source-missing-or-malformed:`. The plan does NOT require
any **content-shape** validation of the value itself (e.g., a semver-like
allowlist `^[0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z0-9.-]+)?$`).

Without a value-content allowlist, a `VERSION` file containing JSON
metacharacters (`"`, `\`, control bytes) or a single-line option-shaped string
is propagated into every consumer manifest. The CI build-then-diff gate (T29)
catches **divergence between the built tree and the committed tree** but does
NOT catch malicious content that propagates consistently across all five
consumer files (the build is the sole writer, so the output is
self-consistent regardless of how malformed the input is).

## Where the gap is, verbatim from plan.md round-02

T28 § Description (plan.md lines ~656):

> The build script halts non-zero with `version-source-missing-or-malformed:
> VERSION at repo root must contain a single non-empty version string` on
> missing, empty, or multi-line `VERSION`.

T28 § Test expectations:

> - The build script halts with the named diagnostic
>   `version-source-missing-or-malformed:` on missing-file and empty-file
>   cases (G8 Acceptance bullet 4).
> - A multi-line `VERSION` triggers the same named diagnostic (edge case per
>   design § Dependencies bullet 1).

No expectation covers content-shape rejection. No fixture asserts that
`VERSION` containing `"} {"x":"foo` (a JSON-breaking single line) is rejected.
No fixture asserts that `VERSION` containing leading whitespace, a NUL byte,
or a backslash-escape sequence is rejected.

## Concrete failure modes

### (a) JSON injection if the build script does string substitution

The plan does not specify HOW `tools/build-plugin.mjs` writes the version
into the consumer JSON files. Two plausible implementations:

1. **JSON-aware:** `obj.version = readFileSync('VERSION', 'utf8').trim();
   writeFileSync(path, JSON.stringify(obj, null, 2))`. Here `JSON.stringify`
   escapes the value, so a malicious `VERSION` becomes a valid (but bizarre)
   JSON string. The consumer manifest is structurally valid but its
   `"version"` field carries attacker-controlled escaped content.
2. **Template substitution:** `text.replace(/"version": "[^"]*"/, '"version":
   "' + version + '"')`. Here a `VERSION` containing `"` breaks out of the
   string and emits arbitrary JSON. Marketplace clients consuming the
   manifest see attacker-chosen JSON keys.

The plan locks neither implementation, so the security property depends on
which interpretation a future implementer picks. An input-validation step at
read time defeats both classes.

### (b) Option-shape values propagate to consumer-side tooling

`VERSION` flows into consumer manifest fields that downstream tooling
(marketplace clients, Claude plugin loaders, `.github/plugin/` consumers)
reads. A `VERSION` containing `--exec` or `--config=/tmp/x` is propagated as
the literal `"version"` field. If any downstream consumer ever passes
`manifest.version` as a CLI argument (e.g., to a packaging tool, a release
notifier, or an upgrade script), the option-shape value is now an attack
vector — and the plan offers no defense against malformed input at the
single authoring path.

### (c) Hidden control bytes pollute display surfaces

A `VERSION` containing a single line with embedded ANSI escapes, NUL bytes,
or terminal-control sequences passes the "single non-empty line" check and
propagates into release-runbook diagnostics, CI logs, and marketplace UI.
This is a low-severity polution vector but trivial to close.

## Why the build-then-diff CI gate (T29) does NOT catch this

T29's contract is `node tools/build-plugin.mjs && git diff --exit-code` —
asserting that the build output matches the committed tree. If a release PR
commits a malicious `VERSION` value AND the propagated manifests AND the
regenerated `build/` content together (which is exactly the single-commit
release flow T30 documents), the build is fully self-consistent. CI passes
green. The attack lands.

The defense must live at the input-read site (T28 build script), not at the
output-consistency site (T29 CI gate).

## Plan-spec gap

The single canonical authoring path (`VERSION`) is the right place to
constrain content. The plan currently treats the file as raw text; it should
treat it as a structured-value entrypoint.

## What the plan should require

Update T28 § Description (insert after the `version-source-missing-or-malformed:`
sentence):

> The value content is validated against an allowlist regex (recommended:
> `^[0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z0-9.-]+)?$` for semver-with-prerelease, or
> the narrower `^[0-9]+\.[0-9]+\.[0-9]+$` if the project does not ship
> prerelease tags). A `VERSION` whose trimmed content fails the allowlist
> halts with the same `version-source-missing-or-malformed:` named diagnostic
> (or a more specific `version-content-malformed:` diagnostic naming the
> offending characters). No silent acceptance of values containing JSON
> metacharacters (`"`, `\`), shell metacharacters, whitespace inside the
> value, control bytes, or option-shape prefixes (`-`, `--`).

Update T28 § Test expectations to add:

- A fixture `VERSION` containing `"}` triggers the
  `version-source-missing-or-malformed:` (or `version-content-malformed:`)
  diagnostic and exits non-zero.
- A fixture `VERSION` containing `--exec=evil` (an option-shape value)
  triggers the diagnostic.
- A fixture `VERSION` containing a NUL byte or other non-printable control
  byte triggers the diagnostic.
- A fixture `VERSION` containing `0.7.3` (canonical semver) AND a fixture
  containing `0.7.3-rc.1` (semver with prerelease) both PASS the validation
  and propagate correctly (boundary case for the allowlist).
- A fixture `VERSION` containing leading or trailing whitespace inside the
  single line (e.g., ` 0.7.3 `) is rejected, OR is explicitly trimmed by the
  build script before validation (the test expectation names which behavior
  is contracted).

## Defense-in-depth rationale

Today the threat model is "maintainer typo," and the cost of typo is one
broken release. After the v0.7.3 release, the marketplace-distribution
posture changes — `VERSION` is the version string that ends up in every
client's plugin loader, in marketplace search results, in release notifier
output. A misshaped value that lands in production now requires a coordinated
manifest rebuild across all five consumer paths to fully clean.

The cost of the fix is one regex match and three additional fixture cases at
the read site. The benefit is closing the entire class of "malicious or
malformed value propagated into structured outputs" failure modes at the
single authoring point, BEFORE the value ever reaches `JSON.stringify` or
template substitution.

## Severity

Medium. Input-validation defense-in-depth at the single canonical authoring
path for the v0.7.3 release artifact. The class of risk (JSON-injection,
option-injection through value content) is well-known and the fix is
mechanical; leaving it to the implementer to "do the right thing" without
plan-spec direction will reliably produce the unvalidated shape.
