---
finding_id: R4-F01
severity: high
change_type: correctness
referenced_files: ["docs/qrspi/2026-06-04-v073-release/plan.md:L344-L384"]
artifact: plan
round: 4
reviewer: quality-claude
---

T11 (`Sweep [Tnn] and forbidden-finding-ID tokens from @test descriptions across tests/**/*.bats`) declares `sizing_exception: schema-migration` with `structural_lint: scripts/structural-lints/check-bats-id-hygiene-sweep.sh`. The reviewer verified the path matches the required ERE `^scripts/structural-lints/[A-Za-z0-9_.-]+\.sh$` — it does. However, the script `scripts/structural-lints/check-bats-id-hygiene-sweep.sh` does not exist (or is not readable) at the repository root; the `scripts/` directory contains only `lib/` and top-level scripts, with no `structural-lints/` subdirectory at all. The script is listed among T11's own **Target files** as a new `Create`, meaning it will not exist until T11 is implemented.

The LOC/file-count exemption is denied per `skills/plan/SKILL.md` § Schema-Migration Task Shape Step 2 existence check. Applying the standard LOC ceiling with the exemption denied: T11 operates on approximately 5,514 token instances across 115+ `.bats` files, far exceeding the 200-LOC ceiling. The task must either be restructured (split into sub-200-LOC batches) or the structural-lint script must be checked into the repository as a prerequisite deliverable in an earlier task before this exemption can be granted.

Note: the circular dependency is structural — T11 creates the very script it needs to claim the exemption. Resolution options: (a) extract `scripts/structural-lints/check-bats-id-hygiene-sweep.sh` into a new prerequisite task that creates it before T11 runs, or (b) pre-commit the script to the repository outside the plan scope, then cite it here as an existing file.

