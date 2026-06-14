# Plan Apply-Fix Dispatch

Read this file when running a Plan review-loop apply-fix pass (Plan's override of `using-qrspi/SKILL.md` § Apply-fix protocol step 8) and you need the exact dispatch invocation.

Plan's apply-fix overrides `skills/using-qrspi/SKILL.md` § Apply-fix protocol step 8 ("Survivors → `Edit` on the artifact"). Instead of inline `Edit` from main chat, the orchestrator dispatches `agents/qrspi-plan-apply-fix.md`:

```
scripts/dispatch-agent.sh \
  --agent-file agents/qrspi-plan-apply-fix.md \
  --reviewer-tag plan-apply-fix \
  --output-dir <ABS_ARTIFACT_DIR>/reviews/plan/round-NN/ \
  --round NN \
  --model <tier-resolved-model-id> \
  --output-file <ABS_ARTIFACT_DIR>/reviews/plan/round-NN/plan-apply-fix.raw \
  --artifact-dir <ABS_ARTIFACT_DIR>/ \
  --artifact-body <ABS_ARTIFACT_DIR>/plan.md \
  --field artifact_path=<ABS_ARTIFACT_DIR>/plan.md \
  --field findings_dir=<ABS_ARTIFACT_DIR>/reviews/plan/round-NN/ \
  --field route=<full|quick> \
  [--field kept_findings_file=<ABS_ARTIFACT_DIR>/reviews/plan/round-NN/kept-findings.txt] \
  [--companion companion_phasing=<ABS_ARTIFACT_DIR>/phasing.md] \
  [--companion companion_design=<ABS_ARTIFACT_DIR>/design.md] \
  [--companion companion_structure=<ABS_ARTIFACT_DIR>/structure.md]
```

`--model` resolves via the Tier Resolution Chain against the agent's `tier: high` frontmatter. `--output-file` receives the apply-fix change-log; edits land directly in `plan.md` via the agent's `Edit` calls. Include `companion_design` / `companion_structure` / `companion_phasing` on full route; omit on quick. Pass `kept_findings_file` whenever `scripts/verifier-fan-in.sh` has run and `kept-findings.txt` exists — the agent prefers it over scanning `findings_dir` so sub-threshold findings cannot leak (CD-4 single-source-of-truth).

The override (vs inline `Edit`) is justified because plan.md's 1000–2000-line aggregate body and per-task contract dependencies on approved upstream artifacts exceed the safety envelope of main-chat `Edit`; the agent body's Step 3 upstream-contract pre-flight is the load-bearing safety property the dispatch carries.
