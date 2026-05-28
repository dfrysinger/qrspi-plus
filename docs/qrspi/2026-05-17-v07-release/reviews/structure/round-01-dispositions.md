# Structure round-1 dispositions

5 findings emitted; all 5 verified (scores 75-85, all >=70 threshold) and applied to `structure.md`. No findings deferred. No intent-class findings (none required user resolution).

## Applied (5)

- **scope-claude.R1-F01** (medium, scope; verified 85) — Trimmed `## CI Pipeline` section to remove literal shell commands (`shellcheck $(find ...)`, `docker run ... bash:3.2 ...`, `gh run list ...`) and inline ban-list regex bodies. Retained behavioral prose (trigger set, concurrency, action pinning, surface-level "what each job verifies", Integrate `gh`-CLI consumer in abstract form). `## Interfaces -> .github/workflows/ci.yml` YAML mini-schema (comment-stub form) unchanged.

- **quality-codex.R1-F01** (medium, correctness; verified 75) — Rewrote `scripts/run-codex-review.sh` row Responsibility (Slice 1 file map). Removed bogus `--transport-type codex-broker` CLI flag; framed shim as forwarding `--provider codex --model <id> --output-file <path>` only. Transport type now correctly sourced from `config.md` `providers:` block (the `codex` provider entry carries `transport_type: codex-broker`).

- **quality-codex.R1-F02** (medium, correctness; verified 78) — Allocated G5 production-tuning instrumentation. Amended `skills/implement/SKILL.md` Slice 1 Responsibility to include per-task telemetry emission to `reviews/telemetry/round-NN/task-NN.json` (routing decision, fix-cycle count, finding-category counts, citation-density rerun count). Added test row `tests/unit/test-g5-telemetry-emission.bats`.

- **quality-claude.R1-F01** (medium, correctness; verified 85) — Fixed inverted Mermaid arrows for `SkillMdHelper`. Replaced 5 `SkillMdHelper -.sourced by.-> <skill/agent>` lines with a single `G14Consumers` node listing the actual BATS test pin files, arrow `G14Consumers -.sources.-> SkillMdHelper`. Removed `TestWriter` from the G14-consumer set entirely (design Decision 7 excludes the agent file).

- **quality-claude.R1-F02** (low, correctness; verified 75) — Removed `agents/qrspi-parallelize-scope-reviewer.md | Modify | ...` row from Slice 4 file map (no-edit file; scope reviewer behavior change flows from `owns-defers.md` edit, not body edit). Removed `ParallelizeScopeReviewer` node and the `ParallelizeOwns -.OWNS source-of-truth.-> ParallelizeScopeReviewer` arrow from the Slice 4 Mermaid subgraph. Folded the consumer relationship into the `owns-defers.md` row Responsibility.

## Deferred / intent-class (0)

None.

## Stale (0)

None. All 5 findings scored >=70.

## Notes

- Verifier scores: scope-claude.F01=85, quality-codex.F01=75, quality-codex.F02=78, quality-claude.F01=85, quality-claude.F02=75.
- File grew by ~5 lines (G5 test row + amended Responsibility) and shrank by ~25 lines (CI Pipeline trim + Slice 4 row + diagram cleanup) per fix-subagent return.
- Round 1 had no diff narrowing (newly-created untracked file). Round 2 will use scope_tagger output for `scope_hint:` narrowing per #112 PR-2.
