---
finding_id: R4-F02
severity: high
change_type: correctness
referenced_files: ["docs/qrspi/2026-06-04-v073-release/plan.md:L253-L271"]
artifact: plan
round: 4
reviewer: quality-claude
---

T05 (`Replace per-skill diff-emission prose with high-level dispatch in 8 artifact-step SKILLs`) declares `sizing_exception: schema-migration` with `structural_lint: scripts/structural-lints/check-diff-emit-to-dispatch-replace.sh`. The path matches the required ERE. However, the script `scripts/structural-lints/check-diff-emit-to-dispatch-replace.sh` does not exist at the repository root — the `scripts/structural-lints/` directory does not exist in the repository at review time. The script is listed among T05's own **Target files** as a new `Create`.

Per `skills/plan/SKILL.md` § Schema-Migration Task Shape Step 2, the LOC/file-count exemption is denied. Applying the standard LOC ceiling with the exemption denied: T05's LOC estimate is ~80 lines, which is well below the 200-LOC ceiling. The task therefore satisfies the standard ceiling without the exemption — no task restructuring is required. However, the finding is required by the schema-migration review protocol whenever the structural-lint script is absent, regardless of whether the ceiling is met. The plan should either pre-create the script in a prerequisite task or accept the standard ceiling (which the estimate already satisfies).

