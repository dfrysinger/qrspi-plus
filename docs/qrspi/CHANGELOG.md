# QRSPI Changelog

Reverse-chronological list of notable changes to the QRSPI pipeline (skills, agents, scripts, configuration, and pipeline contracts). Newest entry on top. Entries cite the issue number and the spec/plan paths under `docs/superpowers/specs/` and `docs/superpowers/plans/`.

## 2026-05-30 — v0.7.1 hardening: close G7b silent-fallback class + per-host model_routing

Closes the silent-fallback class tracked under G7 / G7a / G7b at all three reachable dispatch paths in `skills/using-qrspi/SKILL.md`: the `trusted_path:` short-circuit, the `validators:` trusted-model re-run, and the missing `model_routing:` backfill path. Each path now halts and reports rather than silently degrading to the agent-bundled default. Anti-pattern vocab pins in `tests/unit/test-using-qrspi-vocab.bats` forbid the literal "silently fall back" / "silently degrade" wording the class was filed against.

Wires per-host `model_routing:` into `config.md` under `claude-code:` and `copilot-cli:` host keys, mapping the `inherit / haiku / sonnet / opus` tier rows to fully versioned model IDs. The dispatcher now resolves agent tier names to versioned model IDs deterministically across both supported hosts. Removes the `model:` frontmatter key from all 41 `agents/*.md` files — tier source canonicalized as `model_role:` plus the per-host `model_routing:` lookup.

Three hotfixes landed alongside the main work (issues closed by this release):
- **#215** — `agents/qrspi-test-writer.md` tools expanded to `Read, Write, Edit, Bash, Grep, Glob`; behavioral discipline now enforced at the prompt level via a new `## Tool-grant scope (HARD CONSTRAINT)` section.
- **#222** — `agents/qrspi-finding-verifier.md` "pre-existing" anchor disambiguates work-unit-external vs prior-round code on the same task's branch, using `<diff_file_path>` overlap as the grounding test.
- **#223** — Apply-fix protocol threshold split: `style|clarity` keep at ≥80, `correctness` keep at ≥70 (lower bar for hardening-relevant correctness gaps that cluster in the 72-78 rubric band).

Test posture: `bats tests/unit/` — 1325/1325 GREEN.

Closes: #42, #175, #185, #186, #187, #202, #204, #205, #215, #222, #223.

Follow-up issues: #248 (agent tool-grant audit), #249 (verifier rubric re-score validation), #250 (verifier threshold tuning).

## 2026-05-05 — Sonnet→Haiku confidence verifier (#109)

Added a Haiku-class confidence verifier between artifact-level reviewer subagents and the orchestrator's apply/pause dispatch. Reviewers now emit one finding per file under `reviews/{step}/round-NN/<reviewer_tag>.finding-F<NN>.md`; main chat dispatches one `qrspi-finding-verifier` (Haiku) per finding-file in parallel; each verifier writes a sidecar `.score.yml` (it never mutates the original); main chat assembles findings + sidecars + clean markers into `round-NN-verified.md` and reads it exactly once.

Findings with `change_type` ∈ {`style`, `clarity`, `correctness`} are filtered at score ≥80 against the verbatim 0–100 rubric from `/code-review`. Findings with `change_type` ∈ {`scope`, `intent`} are NEVER score-filtered — they always reach the user via the existing pause gate.

Configuration: `verifier_enabled` (boolean, default `true`) in `config.md`. The §3 menu's `skip` option disables the verifier for the current round only (no `config.md` mutation); to disable across the whole run, edit `config.md` directly between rounds. CLI-flag opt-out at `/qrspi` invocation is out of scope.

Scope: 14 artifact-level reviewers for `goals`, `questions`, `research`, `design`, `phasing`, `structure`, `parallelize`, `replan`. The 18 deferred reviewers (plan-artifact, plan quality/scope, per-task, implement-gate, security-integration, integration-quality) migrate atomically in follow-up issue #125, which also collapses the bifurcated `reviewer-protocol/SKILL.md` back to a single per-finding contract. Pre-merge smoke-matrix cases (e)/(f)/(g) are pinned by the unit suite rather than executed as real review rounds; end-to-end coverage of those failure paths is tracked in #126.

Wallclock cost: ~3–5 sec per round (parallel Haiku dispatch); token cost: ~$0.045/round at typical N=8 finding-file count. Negligible.

Spec: `docs/superpowers/specs/2026-05-04-109-sonnet-haiku-verifier-design.md`.
