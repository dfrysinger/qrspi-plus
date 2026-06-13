---
reviewer: security-claude
reviewer_tag: security-claude
artifact: plan.md
round: 3
verdict: clean
prior_round_references:
  - security-claude.finding-F01.md (round 2)
  - security-claude.finding-F02.md (round 2)
---

# Round-03 security review — clean

## Prior-round findings: both resolved

### R2-F01 (T03 anchor-file SHA validation) — RESOLVED

The round-02 finding identified T03 (`scripts/review-prep.sh`) as the one
remaining consumer of an on-disk SHA file that did not require object-name
shape validation before passing the value into `git diff`. The round-03 diff
adds the parallel validation prose to T03's Description:

> Every SHA read from `reviews/<step>/round-<NN-1>-commit.txt` is validated
> against the well-formed git object-name shape (lowercase hex, 7–64
> characters) BEFORE being passed to any `git` invocation; a SHA failing the
> shape check halts non-zero with the `sha-format-invalid:` named diagnostic.

And to T03's Test expectations:

> A SHA read from `reviews/<step>/round-<NN-1>-commit.txt` that fails the
> well-formed git object-name shape (e.g., uppercase hex, length outside
> 7–64, non-hex characters) halts non-zero with the `sha-format-invalid:`
> named diagnostic — no `git` command runs against the malformed value.

T03 now carries the same shape-validation contract as T13b, T19, T25, T26,
and T27 — symmetry across all anchor-SHA consumers is restored. The
round-02 F01 "asymmetric remainder slice" gap is closed.

### R2-F02 (T28 VERSION content allowlist) — RESOLVED

The round-02 finding identified T28 as validating only structural shape
(missing/empty/multi-line) of the VERSION file without an allowlist on the
value content, leaving JSON-injection and option-shape vectors open. The
round-03 diff adds an explicit semver allowlist to T28's Description:

> Beyond the structural one-line-non-empty check, the VERSION content is
> validated against an explicit semver allowlist regex
> `^[0-9]+\.[0-9]+\.[0-9]+([+-][a-zA-Z0-9.-]+)?$` (major.minor.patch with
> optional `+build` or `-prerelease` suffix); a value that is a well-formed
> single non-empty line but does NOT match the semver shape triggers the
> distinct `version-source-malformed:` named diagnostic and halts non-zero —
> preventing arbitrary content (e.g., `latest`, `v0.7.3`, `0.7`, `0.7.3.4`,
> shell-substitution attempts) from being stamped into the five consumer
> manifests.

Test expectations cover both negative cases (`latest`, `v0.7.3`, `0.7`,
`0.7.3.4`, `$(rm -rf /)`) and positive boundary cases (`0.7.3-rc1`,
`0.7.3+build.42`). The regex anchors at `^[0-9]+\.` so option-shape values
(starting with `-` or `--`) are structurally precluded, and the character
class `[a-zA-Z0-9.-]` in the optional suffix excludes JSON metacharacters
(`"`, `\`), shell metacharacters, NUL bytes, and other control bytes. The
round-02 F02 input-validation gap is closed at the single canonical
authoring path for the v0.7.3 release artifact.

## Round-03 surface scan for new security gaps

Reviewed every diff-touched task description and test expectation against
the four security categories (fail-closed, input-validation, auth/authz,
no-insecure-defaults). Observations:

- **T03 new `--allow-empty-no-diff` flag.** The flag is opt-in; production
  default is fail-loud with `review-prep-no-diff-source:` /
  `review-prep-empty-diff:` named diagnostics. T04a's spec
  ("the high-level entry never sets `--allow-empty-no-diff`") makes the
  paired-coverage contract explicit. No silent-degrade vector for any
  in-tree caller.

- **T19 wave-1-sidecar symmetry + control-byte author-name handling.** The
  symmetrization (implement-phase wave-1 sidecar treated identically to
  integration/test phase-base.txt) closes the round-02 silent-claude R2-F03
  asymmetry. The explicit control-byte coverage (`\x00`–`\x1F` excluding
  TAB/LF) for author-name strings strengthens the fail-loud direction
  against awk-record-injection.

- **T25 new `sidecar-schema-mismatch:` diagnostic.** Fires before any SHA
  value is read or compared — closes the "valid SHA inside malformed-schema
  sidecar" sub-vector that the SHA-shape check alone would not detect.

- **T16 plan-spec reviewer dispatch-defect at Plan step.** Mirrors the
  design-reviewer dispatch-defect contract that round-02 established. The
  plan-spec reviewer no longer silently proceeds with an empty absorbed-ID
  set when `absorption_map_path:` is absent — it halts with
  `dispatch-defect:` and non-zero exit. Closes the false-satisfy-G3
  silent-pass branch at the Plan step.

- **T01 unknown-step fail-soft (returns SKILL paths only, exits 0).** The
  Author note in T03 acknowledges silent-claude R01-F03 raised the
  silent-degrade concern and correctly defers re-opening the contract to a
  Design-phase decision per the approved design.md CD-1 Acceptance bullet 2
  + structure.md row 17. This is the right plan-phase posture; the fail-soft
  direction is not a plan-spec defect and is not an authentication/
  authorization vector — at worst a verifier dispatched against an
  unrecognised step produces under-grounded review, which is a coverage
  concern (not a security one). Not flagging.

- **T04b agent-name charset validation before `GIT_AUTHOR_NAME` injection.**
  Preserved verbatim from round-02 — `<agent>` is validated against
  `[a-z0-9-]+` before any environment-variable composition. Injection vector
  is closed at the dispatch site.

- **T26 expanded target-file enumeration.** Round-03 enumerates the
  additional skill files surfaced by the `grep -rn 'HEAD~1' skills/` sweep
  (13 skill files total, up from the prior "additional skill files"
  placeholder). The anchor-file SHA validation contract from round-02 is
  unchanged — the expansion is a target-set tightening for traceability,
  not a security-shape change.

- **T28 expanded semver suffix regex.** The allowlist's optional suffix
  `([+-][a-zA-Z0-9.-]+)?` admits semver prerelease and build metadata. The
  character class excludes every category of injection-relevant byte
  (quotes, backslashes, shell metacharacters, whitespace, NUL, control
  bytes). No injection vector remains at the VERSION-read site.

No new security gaps found in the round-03 diff. Plan is clean from a
security standpoint.
