# QRSPI Changelog

Reverse-chronological list of notable changes to the QRSPI pipeline (skills, agents, scripts, configuration, and pipeline contracts). Newest entry on top. Entries cite the issue number and the spec/plan paths under `docs/superpowers/specs/` and `docs/superpowers/plans/`.

## 2026-06-15 — v0.7.3: pipeline-correctness fixes + active-skill footprint reduction

Closes the eight P0 defects surfaced by the v0.7.2 self-host run plus a release-wide active-skill-prompt footprint reduction, shipped in a single phase with a single end-to-end slice. 45 tasks across 1 phase / 7 waves; 192 commits.

**Goals shipped (G1–G9):**
- **G1** — verifier sidecar grounding: pre-existing anchor disambiguates work-unit-external vs prior-round code; rubric band 72–78 hardening-relevant correctness fixes now reach the keep set.
- **G2** — bats `@test` description hygiene: `[Tnn]` and `R\d+-F\d+` tokens swept from the corpus + permanent CI lint (`tests/lint/test-bats-test-name-id-hygiene.bats`).
- **G3** — design absorption marker pipeline: explicit `## G<n> — <name>: absorbed by CD-<n>` headings in design.md drive `scripts/design-absorption-markers.sh` → `scripts/review-prep.sh` plan-step TSV, eliminating implicit traceability gaps.
- **G4** — plan-step upstream-paths: new `scripts/upstream-paths.sh` resolves the design absorption map to plan-task upstream pointers (closes silent-fan-out class).
- **G5** — orchestration boundary observability: new `scripts/orchestration-boundary-check.sh` runs at phase end, writes byte-empty on clean / two named sections (`## Boundary violations`, `## Dispatch defects`) when populated; non-zero exit on dispatch defects is the script-level fail-loud.
- **G6** — stage-commit-parents validator: new `scripts/validate-stage-commit-parents.sh` with `--capture --wave-id W<n>` dual-write (key=value sidecar + OBC-shaped `wave-<n>.txt`) closes the Implement batch-gate bridge.
- **G7** — anchor file lookup: `SKILL.anchors.json` schema + resolver harden the reference-gate pause + reference-extraction round-trip.
- **G8** — version source unification: repo-root `VERSION` file is the single source of truth for `.claude-plugin/marketplace.json`, `.claude-plugin/plugin.json`, `.github/plugin/*`, and `build/` outputs.
- **G9** — active-skill prompt footprint <30,000 tokens (cl100k_base): 14 SKILLs trimmed via 4-pass (three-tier placement → script-mechanic deletion → R8 tightening → regression-guard execution) against six new `_shared/` snippets `!cat`-resolved at skill-load. Heaviest active skill (using-qrspi) measured at 29,913 tokens.

**Cross-goal decisions:**
- **CD-1** — vendor-neutral dispatch rename (`scripts/dispatch-agent.sh`, was `scripts/review-prep.sh` for review-only).
- **CD-2** — implementer Pre-DONE self-check promoted from advisory to blocking.
- **CD-3** — R8 prose-density rule landed in `skills/_shared/prompt-design-rules.md` with explicit `### What NOT to tighten` carve-outs (load-bearing repetition, verbatim test-pinned strings, iron-law clauses, anchor phrases).

**In-pipeline fixes captured (Integrate + Test rounds):**
- **FX-Integrate-F01** — SKILL `printf %sn "$SHA"` write shape for `reviews/integrate/phase-base.txt` aligned with OBC consumer (bare-SHA, no key=value).
- **FX-Integrate-F02** — `validate-stage-commit-parents.sh` `--capture --wave-id W1` + `--seed-wave-1-obc` mode dual-writes the OBC-shaped wave-1.txt bridge.
- **FX-Integrate-CI** — release pin updates (agents 42, workflows 2, marketplace 0.7.3); bats off-by-one CI failures (user-trap-EXIT vs bats EXIT handler collision in `test-phase1-acceptance.bats [AC4]`; heredoc-embedded `@test` count inflation in `test-bats-test-name-id-hygiene.bats`).
- **FX-Test-FX1** — OBC report shape brought into compliance with design.md §G5(b) (byte-empty clean, two-section schema).
- **FX-Test-FX2** — `[Tnn]` token violations in two unit fixtures runtime-assembled.
- **FX-Test-FX3** — `### What NOT to tighten` H3 subheading added to `prompt-design-rules.md` per CD-3.

Test posture: 89/89 plan-level acceptance tests GREEN; 2,566/2,566 full suite GREEN locally; CI BATS-under-bash-3.2 carries 9 pre-existing environmental baselines (root-uid permission tests + missing-tiktoken footprint tests) inherited from v0.7.2.

Reviews: Implement per-task reviews + 2-round Integration review + Test 3-reviewer fan-out + dual-review (Claude Opus 4.7 high + GPT-5.5) all clean.


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
