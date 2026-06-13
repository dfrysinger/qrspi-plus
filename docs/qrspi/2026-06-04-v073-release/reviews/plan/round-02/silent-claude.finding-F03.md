---
finding_id: R2-F03
severity: medium
change_type: behavior
referenced_files: [docs/qrspi/2026-06-04-v073-release/plan.md:L501, docs/qrspi/2026-06-04-v073-release/plan.md:L509, docs/qrspi/2026-06-04-v073-release/plan.md:L511]
artifact: plan
round: 2
reviewer: silent-claude
---

T19's `orchestration-boundary-check.sh` carries asymmetric fail-loud direction across the three supported phases: missing/malformed `phase-base.txt` for `--phase integration` and `--phase test` is a named dispatch defect, but missing/malformed G6 wave-1 sidecar for `--phase implement` is **not** named — leaving the implement-phase phase-base read on the silent default path.

Plan text — T19 description (L501): "Phase-base resolution is per-phase: `implement` reads the G6 wave-1 sidecar at `reviews/implement/wave-state/`; `integration` reads `reviews/integration/phase-base.txt`; `test` reads `reviews/test/phase-base.txt`. Every SHA read from disk (from either the sidecar or the phase-base.txt file) is validated against the well-formed git object-name shape (lowercase hex, 7–64 characters) BEFORE being passed to any `git` invocation; a malformed SHA triggers a `sha-format-invalid:` named diagnostic, exits non-zero, and writes a violation entry under `## Dispatch defects`. Missing or malformed `phase-base.txt` is itself a dispatch defect — the script writes a violation entry under a distinct `## Dispatch defects` section of the report (separate from the existing commit and workspace sections) and exits non-zero."

The fail-loud direction is explicit for `phase-base.txt` (integration + test). It is silent on the implement-phase counterpart. Two conditions are asymmetrically uncovered:

1. **Missing G6 wave-1 sidecar** at `reviews/implement/wave-state/`. The integration/test counterparts (missing `phase-base.txt`) surface as a dispatch defect with non-zero exit. The implement counterpart is undefined.
2. **Malformed wave-1 sidecar** (corrupt schema, missing the SHA field, schema-drift between G6's sidecar writer and T19's reader). Same gap — only the SHA-format validation step (lowercase hex 7–64 chars) would catch a malformed SHA value, but a sidecar with the wrong schema or a missing field would slip past SHA validation and hit silent-default behaviour.

The test expectations confirm the asymmetry. L509: "For `--phase implement`, the script reads phase-base from the G6 wave-1 sidecar under `reviews/implement/wave-state/`; for `--phase integration` or `--phase test`, the script reads `reviews/<phase>/phase-base.txt`." L511: "Missing or malformed `phase-base.txt` writes a violation entry under a distinct `## Dispatch defects` section of the report and exits non-zero (silent-claude F02 dispatch-defect direction)." No expectation covers "missing or malformed wave-1 sidecar."

The silent default on the implement-phase branch is the failure-mode the G5 work was created to surface. T19's whole purpose is to detect orchestration drift in the Implement phase — that's the phase with the most parallel subagent activity and the highest risk of a non-`qrspi-` author commit landing in the integration tree. If the wave-1 sidecar is missing (because G6's writer never ran, because a path typo silently emitted to the wrong location, because a `mkdir -p` failed earlier in the wave) the OBC check at the end of the Implement phase has no anchor SHA. The script's silent-default branches (when bash variable expansion produces an empty string for the phase-base SHA) include:

- `git log ..HEAD` (empty left side) — git emits the full history of HEAD, every commit on the branch since the repo's first commit. Every non-`qrspi-` author commit in the entire history surfaces as a violation. The report is gigantic, full of unrelated history, and the actual dispatch defect (no anchor) is invisible under the noise.
- `git log <empty>..HEAD` may also be rejected by git with a non-zero exit and an error on stderr that the OBC script then doesn't classify under `## Dispatch defects`. The script's caller (T20b's batch gate) sees a non-zero exit from OBC without a `## Dispatch defects` section in the report, and the autopilot's branched-default has no branch defined for that combination (clean report + non-zero exit). The branch undefined here is the autopilot's failure mode.

Either path is silent in a different sense than the integration/test gap: integration/test phases would produce a report with a clean `## Dispatch defects` entry; implement phase produces either a noisy false-positive report or an empty report with a non-zero exit that doesn't match the autopilot's three-branch decision shape from T20b.

The dispatch-defect partition T19 introduces is load-bearing only if it covers every phase's phase-base resolution failure mode symmetrically. The current text covers two of three.

Resolution scope: T19 description and test expectations add the implement-phase counterpart to the explicit dispatch-defect direction:

- T19 description: rewrite the "Missing or malformed `phase-base.txt` is itself a dispatch defect" sentence to read "Missing or malformed phase-base source (the G6 wave-1 sidecar at `reviews/implement/wave-state/` for `--phase implement`, or `reviews/<phase>/phase-base.txt` for `--phase integration` or `--phase test`) is itself a dispatch defect — the script writes a violation entry under a distinct `## Dispatch defects` section of the report and exits non-zero."
- T19 test expectations: add a bullet "Missing or malformed G6 wave-1 sidecar writes a violation entry under `## Dispatch defects` and exits non-zero for `--phase implement`" mirroring the L511 expectation. Add named diagnostics (e.g., `wave-1-sidecar-missing:` / `wave-1-sidecar-malformed:`) that the autopilot's third branch in T20b can grep for.
- T20b's autopilot third branch (the "unconditional halt" branch keyed on the `## Dispatch defects` section) then covers the implement-phase missing-sidecar case via the same mechanism that covers the integration-phase missing-phase-base.txt case.
