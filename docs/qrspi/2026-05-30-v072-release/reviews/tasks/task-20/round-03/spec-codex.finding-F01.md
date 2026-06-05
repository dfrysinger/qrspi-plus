---
finding_id: R3-F01
severity: high
change_type: correctness
referenced_files:
  - scripts/dispatch-agent.sh
  - scripts/await-round.sh
---
End-to-end async drain remains non-functional: await-round.sh path-validation rejects the manifest's relative-path commands.

`dispatch-agent.sh:423-424` writes manifest entries with **repo-relative paths**:
  - `await_cmd: "scripts/dispatch-companion.sh await $job_id"`
  - `split_cmd: "scripts/third-party-finding-splitter.sh --round-dir $OUTPUT_DIR --tag $REVIEWER_TAG"`

`await-round.sh:204-219` validates path-shaped argv[0] by:
  1. `realpath(os.path.join(DISPATCH_CWD, exe))` where DISPATCH_CWD = `<round-dir>/.dispatch/`
  2. Requiring the resolved path be under one of EXEC_ROOTS (computed from `git rev-parse --show-toplevel` of round-dir + `$QRSPI_AWAIT_EXEC_ROOTS`)

For the manifest's `scripts/dispatch-companion.sh`, the realpath resolves to `<round-dir>/.dispatch/scripts/dispatch-companion.sh` — outside EXEC_ROOTS. Drain is REJECTED before the await even runs. Empirical reproduction (orchestrator-verified, 2026-06-03):

```
$ scripts/dispatch-agent.sh --step spec --round 1 --output-dir /tmp/X --artifact /tmp/a.txt \
    --agents "spec-codex=.../qrspi-spec-reviewer.md"
[dispatch-agent] manifest: /tmp/X/.dispatch-manifest.json
$ scripts/await-round.sh --round-dir /tmp/X
await-round: await_cmd rejected for 'spec-codex': argv[0] 'scripts/dispatch-companion.sh' resolves
to '/private/tmp/X/.dispatch/scripts/dispatch-companion.sh' which is outside permitted exec roots [].
await-round: drained 1 background dispatch(es); 0 with findings, 0 clean.
rc=1
```

This violates DoD bullet 3 (end-to-end async chain functional) and Test expectations bullet (no end-to-end test exercises await-round.sh against a real dispatch-agent-emitted manifest).

**Pre-existing scope note:** the same relative-path defect existed pre-T20 with the old script names (`scripts/run-third-party-llm.sh await $job_id`) at base commit `44605c7~1`. Spec-claude r1 noted it as advisory out-of-scope. However, T20's DoD bullet 3 explicitly claims to wire the end-to-end async chain functional — leaving an inherited break that prevents the chain from working contradicts the DoD claim. User has authorized cap-bends for quality.

**Fix path (one of):**
(a) Emit absolute paths in `await_cmd` and `split_cmd` (resolve `$REPO_ROOT/scripts/...` at manifest emission time; await-round's argv[0] absolute-path branch then validates against EXEC_ROOTS correctly).
(b) Use bare-name allowlist: register `dispatch-companion` and `third-party-finding-splitter` in BARE_NAME_ALLOWLIST (await-round.sh:131) and emit `await_cmd: "dispatch-companion await $job_id"` — but this requires PATH wiring at runtime, brittle.
(c) Adjust the realpath base from DISPATCH_CWD to repo-root (more invasive — changes await-round's security model).

(a) is the smallest defensible fix and matches the absolute-path pattern already used elsewhere in the codebase. Set `await_cmd: "$REPO_ROOT/scripts/dispatch-companion.sh await $job_id"` and analogous for split_cmd in dispatch-agent.sh:423-424.
