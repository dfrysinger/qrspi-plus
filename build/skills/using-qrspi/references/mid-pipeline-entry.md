Users can enter mid-pipeline if they already have artifacts from prior work. As long as the required input files exist with `status: approved`, any step can run. This is an escape hatch, not the default path.

### Validation and Repair

Before checking artifact status, run these validation checks in order:

**1. Config validation**

Apply the **Config Validation Procedure** below. Do not silently patch any field.

**2. Task spec scan (advisory, non-blocking)**

After config is valid, scan `tasks/task-*.md` for missing fields (`enforcement`, `allowed_files`, `constraints`). Output any warnings to stdout and continue — this is advisory only.

**Run selection for mid-pipeline entry:** When entering mid-pipeline, glob for `docs/qrspi/*/goals.md` directories. If multiple exist, present the list and ask the user which run to resume. Load `config.md` from the chosen directory to read the `route` list. Scan for approved artifacts, then invoke the first step in the route list that is not yet complete.

**Determining the next step:** Iterate through the `route` list in order. The first entry without a corresponding approved artifact is the next step to run. Do not hardcode the sequence — always derive it from `config.md`'s `route` field.

**Replan resume exception:** Replan is not in any route list. Detect the need to resume Replan when: all steps in the `route` list have approved artifacts AND `replan-pending.md` exists in the artifact directory (written by Test before invoking Replan, deleted by Replan before invoking the next step). If `replan-pending.md` exists, invoke Replan to resume. Note: for major changes, Replan deletes the marker and then invokes the loop-back target (Design or Structure) — the normal pipeline resumes from there. If a session is interrupted during the cascade (after Replan exits), the standard mid-pipeline resume logic handles it: it finds the first step in the route without an approved artifact (e.g., Design was reset to draft) and resumes there.

**Run selection for direct skill invocation:** When a skill is invoked directly (not via `using-qrspi`), it must resolve the artifact directory: glob for `docs/qrspi/*/goals.md`, filter to directories containing the skill's required input artifacts, and if multiple match, ask the user which run to use.
