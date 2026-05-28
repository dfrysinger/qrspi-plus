---
finding_id: R2-F01
severity: medium
change_type: scope
referenced_files: [docs/qrspi/2026-05-17-v07-release/structure.md:L305-L332, docs/qrspi/2026-05-17-v07-release/structure.md:L485-L488]
artifact: structure
round: 2
reviewer: scope-codex
---

The `.github/workflows/ci.yml` interface block crosses Structure's boundary by spelling an implementation-level workflow skeleton and command shape after the artifact itself says the container-launch command shape and in-image package install steps are Plan/Implement-owned. Lines 305-332 include concrete YAML keys, job IDs, shellcheck/ban-list step details, and a specific `docker run ... sh -c "apk add ... && bats ..."` command; lines 485-488 then explicitly defer that command shape and in-image package install work downstream.

Resolve by keeping the CI section at boundary altitude: name the workflow file, required verification surfaces, trigger families, concurrency behavior, action pinning requirement, and canonical CI signal. Remove the concrete step comments and container command, or rewrite them as behavioral requirements owned by Plan/Implement.
