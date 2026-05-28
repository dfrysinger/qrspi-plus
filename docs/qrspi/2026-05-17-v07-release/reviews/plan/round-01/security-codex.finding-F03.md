---
finding_id: R1-F03
severity: medium
change_type: correctness
referenced_files: [docs/qrspi/2026-05-17-v07-release/plan.md:L488-L496, docs/qrspi/2026-05-17-v07-release/plan.md:L619-L631]
artifact: plan
round: 1
reviewer: security-codex
---

Task 14 calls the `bash:3.2` Docker container "pinned" and Task 19 only pins third-party GitHub Actions, but a Docker tag such as `bash:3.2` is mutable. That leaves the load-bearing bash 3.2 CI gate dependent on an unpinned image, so a registry tag update can change the runtime or supply-chain contents without a repository change.

Fix: require the workflow to reference the bash image by immutable digest, for example `bash:3.2@sha256:<digest>`, and extend `test-ci-workflow-shape.bats` to fail on a bare Docker tag for the `bash32` job.
