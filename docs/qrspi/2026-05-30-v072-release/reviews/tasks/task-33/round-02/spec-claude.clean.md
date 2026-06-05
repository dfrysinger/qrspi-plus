# Spec Review — Task 33, Round 2 (claude)

**Status:** clean

Round-02 diff narrows `structural_lint:` from an inline bash command to a checked-in script path under `scripts/structural-lints/`, invoked as `bash <path>` from repo root with no spec-controlled arguments, and adds an empty-diff guard before granting the LOC/file-count exemption. Both target files (`skills/plan/SKILL.md`, `agents/qrspi-plan-reviewer.md`) are updated consistently:

- Mandatory trio (`sizing_exception: schema-migration`, `sizing_rationale:`, `structural_lint:`) still required together; no field optional.
- `structural_lint:` value validated as a repo-relative path with the exact prefix `scripts/structural-lints/`, no `..`, no absolute paths, no shell metacharacters, no inline commands.
- Reviewer Steps 1–4 verify field presence, validate the path, require non-empty diff + exit-0 from the script, and grant the exemption only when all gates pass.
- SKILL.md failure-mode list expanded from four to five conditions (added: empty-diff branch and inline-command rejection); prose updated to "verifies all five conditions" to match.
- Narrowness preserved — closed exception set unchanged, ordinary task-size discipline not relaxed.

The semantic shift (inline → named-script) is a security hardening that stays within the task spec's framing ("a bash check that proves the diff is mechanical-only"); a `bash <script>` invocation is still a bash check. The empty-diff guard is directly tied to the DoD's "proves the proposed diff is mechanical-only" — a vacuous pass on an empty diff would not satisfy that requirement.

All Definition-of-Done items remain satisfied. Test expectations (field-name grep audits, reviewer rubric ties to structural-lint execution, clear defect wording for missing `structural_lint`) all still hit. Target-files check: diff touches only the two listed files; matches `scope_hint`.

No findings.
