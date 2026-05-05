# QRSPI Changelog

Reverse-chronological list of notable changes to the QRSPI pipeline (skills, agents, scripts, configuration, and pipeline contracts). Newest entry on top. Entries cite the issue number and the spec/plan paths under `docs/superpowers/specs/` and `docs/superpowers/plans/`.

## 2026-05-05 — Sonnet→Haiku confidence verifier (#109)

Added a Haiku-class confidence verifier between artifact-level reviewer subagents and the orchestrator's apply/pause dispatch. Reviewers now emit one finding per file under `reviews/{step}/round-NN/<reviewer_tag>.finding-F<NN>.md`; main chat dispatches one `qrspi-finding-verifier` (Haiku) per finding-file in parallel; each verifier writes a sidecar `.score.yml` (it never mutates the original); main chat assembles findings + sidecars + clean markers into `round-NN-verified.md` and reads it exactly once.

Findings with `change_type` ∈ {`style`, `clarity`, `correctness`} are filtered at score ≥80 against the verbatim 0–100 rubric from `/code-review`. Findings with `change_type` ∈ {`scope`, `intent`} are NEVER score-filtered — they always reach the user via the existing pause gate.

Configuration: `verifier_enabled` (boolean, default `true`) in `config.md`. The §3 menu's `skip` option disables the verifier for the current round only (no `config.md` mutation); to disable across the whole run, edit `config.md` directly between rounds. CLI-flag opt-out at `/qrspi` invocation is out of scope.

Scope: 14 artifact-level reviewers for `goals`, `questions`, `research`, `design`, `phasing`, `structure`, `parallelize`, `replan`. The 18 deferred reviewers (plan-artifact, plan quality/scope, per-task, implement-gate, security-integration, integration-quality) migrate atomically in follow-up issue #125, which also collapses the bifurcated `reviewer-protocol/SKILL.md` back to a single per-finding contract. Pre-merge smoke-matrix cases (e)/(f)/(g) are pinned by the unit suite rather than executed as real review rounds; end-to-end coverage of those failure paths is tracked in #126.

Wallclock cost: ~3–5 sec per round (parallel Haiku dispatch); token cost: ~$0.045/round at typical N=8 finding-file count. Negligible.

Spec: `docs/superpowers/specs/2026-05-04-109-sonnet-haiku-verifier-design.md`.
