---
finding_id: R4-F01
severity: low
change_type: scope
referenced_files: [docs/qrspi/2026-05-17-v07-release/structure.md:L53]
artifact: structure
round: 4
reviewer: scope-claude
---

The Responsibility cell for `.github/workflows/ci.yml` in Slice 3 (line 53) contains the literal command fragment `docker run --rm bash:3.2 bats tests/` as part of describing the `bash32` job behavior. This is a specific container-launch command shape, which the artifact itself explicitly defers to Plan/Implement at line 309: "Container-launch command shape and in-image package install steps are Plan/Implement-owned."

The Responsibility column in the File Map should stay at boundary-level behavioral description (what the job verifies at a functional level) rather than prescribing the literal Docker invocation. The current text reads: "bash32` runs `docker run --rm bash:3.2 bats tests/` covering unit + acceptance BATS surfaces". The fragment `docker run --rm bash:3.2 bats tests/` is a step body, not a boundary signature.

Proposed fix: replace the literal command with a boundary-level description such as "runs unit and acceptance BATS surfaces under a real bash 3.2 runtime (container-launch command shape owned by Plan/Implement)". This removes the implementation detail that the artifact itself already defers downstream, making the File Map entry consistent with the explicit DEFERS statement at line 309.
