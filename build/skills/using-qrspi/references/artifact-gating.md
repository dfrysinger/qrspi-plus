
Each skill checks that its required input artifacts exist on disk before proceeding:
- **Goals**: No prerequisites (first step)
- **Questions**: Requires `goals.md` with `status: approved`
- **Research**: Requires `questions.md` with `status: approved`
- **Design**: Requires `goals.md` and `research/summary.md` with `status: approved`
- **Phasing**: Requires `goals.md`, `questions.md`, `research/summary.md`, and `design.md` with `status: approved`
- **Structure**: Requires `goals.md`, `research/summary.md`, `design.md`, and `phasing.md` with `status: approved`
- **Plan**: Full pipeline requires `goals.md`, `research/summary.md`, `design.md`, `phasing.md`, and `structure.md` with `status: approved`. Quick fix requires only `goals.md` and `research/summary.md`.
- **Parallelize**: Requires `plan.md` with `status: approved`, `tasks/*.md`, `phasing.md` with `status: approved` (phase definitions), and `config.md`
- **Implement**: Mode is derived from `config.md.route` (full pipeline if `parallelize` precedes `implement`; quick fix otherwise). Full pipeline additionally requires `parallelization.md` with `status: approved`. Quick fix has no Parallelize, so no `parallelization.md`; Implement requires the per-run input set defined in `implement/SKILL.md` § Artifact Gating (approved `tasks/*.md` or `fixes/{type}-round-NN/*.md`). The `pipeline` field on individual task files is a per-task input-gating concern read by the per-task dispatch in `implement/SKILL.md` § Per-Task Execution, not by the Implement skill's run-mode derivation.
- **Integrate**: Requires all task review files in `reviews/tasks/`, `design.md` with `status: approved`, `phasing.md` with `status: approved`, `structure.md` with `status: approved`, `parallelization.md` with `status: approved` (branch map), and `config.md` (for route)
- **Test**: Requires `goals.md` with `status: approved`, `design.md` and `phasing.md` with `status: approved` (full pipeline) or `research/summary.md` with `status: approved` (quick fix), `fixes/` directory (for regression tests), codebase with implementation merged
- **Replan**: Requires completed phase code (merged), `fixes/` and `reviews/` directories, remaining `tasks/*.md`, `plan.md` with `status: approved`, `design.md` with `status: approved`, and `phasing.md` with `status: approved`

If a required artifact is missing, the skill refuses to run and tells the user which artifact is needed.
