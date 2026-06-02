---
reviewer_tag: scope-codex
change_type: scope
severity: medium
artifact: plan.md
location: Task 39 → Definition of done
referenced_files: [plan.md]
---

# F01 — Plan embeds implementation helper signature/parameter shape

`plan.md` specifies an implementation-level helper-call shape in the task spec: `assert_path_under_repo_root <label> <abs-path>` (plan.md:2252), alongside concrete canonicalization API guidance (`fs.realpathSync`/`readlink -f`) and guard mechanics. That is a Structure/Implement altitude detail, not Plan task-spec altitude.

This conflicts with the Plan DEFERS contract: function signatures and parameter shapes are explicitly deferred to Structure (`skills/plan/owns-defers.md:20`), and line-by-line implementation logic is deferred to Implement (`skills/plan/owns-defers.md:22`).
