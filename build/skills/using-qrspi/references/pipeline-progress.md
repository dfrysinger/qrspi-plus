
Pipeline task tracking uses a two-phase approach to avoid creating tasks for a route that hasn't been selected yet.

**Phase 1 — Provisional task (this skill):** Before invoking Goals, create a single Level 1 task:

```
[ ] Goals
```

Do not create tasks for any other steps yet. The pipeline mode (and therefore the full route) is not known until Goals runs.

**Phase 2 — Full task list (Goals skill):** After the user selects a pipeline mode and `config.md` is written with the `route` field, the Goals skill rewrites the task list based on `config.md`'s route. The Goals task itself is already `in_progress` at this point; Goals marks it `completed` after approval and then creates the remaining tasks.

**Example — task list written by Goals after route selection:**
```
[x] Goals
[ ] Questions
[ ] Research
[ ] Design          # full pipeline only
[ ] Phasing         # full pipeline only
[ ] Structure       # full pipeline only
[ ] Plan
[ ] Parallelize     # full pipeline only
[ ] Implement
[ ] Integrate       # full pipeline only
[ ] Test
```

The exact list mirrors the `route` field in `config.md`. Update each task as the pipeline progresses (mark `in_progress` when a step starts, `completed` when approved).

**Mid-pipeline entry:** When a user enters mid-pipeline with pre-existing approved artifacts, read the `route` from `config.md`. Create the full route task list and immediately mark steps with approved artifacts as `completed`. Then invoke the first incomplete step's skill.
