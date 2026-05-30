---
finding_id: R1-F02
severity: medium
change_type: scope
referenced_files: [docs/qrspi/2026-05-27-v071-hardening/structure.md:L17-L67]
artifact: structure
round: 1
reviewer: scope-claude
---

The File Map repeatedly pins **exact source line numbers** inside
Responsibility cells. These are line-by-line edit coordinates, which
Structure DEFERS to Plan / Implement — not section/heading-level
locations, which Structure OWNS.

Per `skills/structure/owns-defers.md`:

- **OWNS** — "Cross-cutting hook-point locations. The *places* where
  hooks fire across files ... — **locations only, never the text**"
  and "Section-list contracts per file ... **Heading-level
  granularity**, not prose content."
- **DEFERS** — "**Per-task LOC, full assertion text, per-task commit
  ranges, line-by-line logic** → Plan / Implement."

Specific source line numbers are line-by-line logic pinning — they
are coordinates into the existing file body, not section/heading
locations, and they go stale the moment the file is edited (which is
exactly what this slice does). Plan owns this granularity.

Sites in the artifact:

- L17 Slice 1: `lines 558--569` in `scripts/run-third-party-llm.sh`
- L32 Slice 3: `lines 185 and 206` and `lines 167--176` in
  `tests/unit/test-skill-md-content-patterns.bats`
- L40 Slice 4: `lines 28--34` in `agents/qrspi-parallelize-reviewer.md`
- L64 Slice 7: `lines 427--428 and 441--442` in
  `skills/using-qrspi/SKILL.md`
- L65 Slice 7: `lines 196--221 and 499--512` in
  `scripts/run-third-party-llm.sh`
- L67 Slice 7: `line 25` and `lines 208 and 210` in
  `tests/acceptance/v07-phase1/test-phase1-acceptance.bats`

Resolution: replace each line-range citation with a
section/heading-level or named-block locator (e.g., "the `grep -qP`
control-char detection block inside the `openai-chat-completions`
transport block", "the inline `extract_review_round` call sites and
its local definition", "the Branch Map structural-rule assertions",
"`supports_prompt_cache` / `emit_cache_control_markers` entries in
the providers block", "the `cache_control` marker emission branch
inside `_dispatch_openai_chat`", "the `SPIKE` export and the two
`run run_pin` invocations for the deleted cache unit suites"). Plan
re-derives the concrete line ranges at task-spec time when it owns
LOC and edit-range commitments.
