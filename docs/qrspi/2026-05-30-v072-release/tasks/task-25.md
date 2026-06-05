---
status: approved
task: 25
phase: 1
pipeline: full
goal_ids: [G31]
task_type: lightweight
model: sonnet
sizing_exception: reusable primitives
---

# Task 25: G31 prompt-prose primitives (`prompt-prose-detection` + `-writer-addition` + `-reviewer-addition` + `prompt-design-rules` + new prompt-prose-writer SKILL + new prompt-prose-reviewer SKILL + docs rename)

- **Target files:** skills/_shared/prompt-prose-detection.md (create), skills/_shared/prompt-prose-writer-addition.md (create), skills/_shared/prompt-prose-reviewer-addition.md (create), skills/_shared/prompt-design-rules.md (create-via-migrate from docs/prompt-design-guide.md), skills/prompt-prose-writer/SKILL.md (create), skills/prompt-prose-reviewer/SKILL.md (create), docs/prompt-design-guide.md (delete post-migration)
- **Dependencies:** none. **Blocks:** T26 (G31 `!cat` include sites + skill-frontmatter preloads), T39 (G32 build pipeline's defensive copy of `skills/_shared/prompt-prose-detection.md`).
- **LOC estimate:** ~340

**Overview**

Create the shared prompt-prose primitives — three import snippets, two wrapper SKILLs, and a migrated rules file — that make the G31 prompt-prose-coverage contract enforceable across the plugin. All downstream G31 tasks (T26-T31) consume these primitives; without them, every consumer site would duplicate prose inline or reference runtime contracts that do not exist yet. (Why: see goals.md ### G31. Approach: see design.md ## G31.)

**Scope**

- **In:**
  - Author the three new shared snippet files at the canonical `skills/_shared/` paths, with bodies lifted **verbatim** from design.md ## G31 File 1, File 2, and File 3 respectively.
  - Author the two wrapper SKILLs at `skills/prompt-prose-writer/SKILL.md` and `skills/prompt-prose-reviewer/SKILL.md` with `description:` frontmatter plus `!cat` preload chains in the order specified by design.md ## G31 File 4 / File 5 (cross-check against structure.md per-file blocks).
  - Migrate `docs/prompt-design-guide.md` to `skills/_shared/prompt-design-rules.md` using `git mv` so `git log --follow` traces history through the rename, then apply the 8 inline refresh edits A-H named in design.md ## G31 (modern-negation positive-substitute principle; CD-2 named antagonist patterns; Evergreen Litmus Test; Anchor phrases principle; vendor-neutral R5 wording; remove external `general2/...` source paths; refresh `Last applied:` / May 2026 model annotations; compaction-resilient prompt-design principle).
  - Delete the old `docs/prompt-design-guide.md` path in the same commit as the migration (single source of truth).

- **Out:**
  - Adding `!cat` include sites in Plan / Design / reviewer-agent consumers — T26 owns.
  - Wiring the wrapper SKILLs into agent frontmatter `skills:` preload lists — T27-T31 own per consumer.
  - Authoring new rule content beyond the 8 refresh edits A-H — the rules file body is otherwise migrated as-is.
  - Editing the fast-path glob list in design.md ## G31 — already authoritative there; not re-authored here.

**Definition of done**

- All 6 new files exist at their canonical paths; `docs/prompt-design-guide.md` is deleted.
- Snippet bodies (Files 1-3) match design.md ## G31 File 1 / File 2 / File 3 byte-for-byte (modulo any one-line header comment specified by the corresponding structure.md per-file block).
- Wrapper SKILLs (Files 4-5) carry `description:` frontmatter and the `!cat` preload directives in the exact order specified by design.md ## G31 + structure.md per-file blocks.
- `skills/_shared/prompt-design-rules.md` carries all 8 refresh edits A-H; `git log --follow` reaches the historical `docs/prompt-design-guide.md` commits.
- No stale `docs/prompt-design-guide.md` references remain in runtime surfaces (grep over `skills/`, `agents/`, `scripts/`, and top-level docs returns zero matches; planning artifacts under `docs/qrspi/` and `.restructure-v2/` and historical CHANGELOG entries are intentionally excluded — they describe the migration, they don't consume the path).
- Each addition snippet (Files 2-3) pairs negative guidance with a positive substitute (per R5 / modern-negation).
- The detection snippet (File 1) clearly distinguishes universal content-semantic detection from the qrspi-plus-internal fast-path globs.
- References to the rules-file location use exactly the anchor phrase `skills/_shared/prompt-design-rules.md (resolved from the installed plugin path per host convention)`.

**Test expectations**

- File-existence checks for all 6 new files; deletion check for `docs/prompt-design-guide.md`.
- Runtime-surface grep audit (over `skills/`, `agents/`, `scripts/`, and top-level docs; excluding `docs/qrspi/` planning artifacts, `.restructure-v2/` intermediate structure work, and historical CHANGELOG entries) asserts zero remaining live references to `docs/prompt-design-guide.md` (matches DoD invariant — fails the build on any stale source-of-truth reference in a runtime-consumer surface).
- Verbatim diff of File 1 / File 2 / File 3 bodies vs design.md ## G31 File 1 / File 2 / File 3 — exact match.
- Frontmatter inspection of Files 4-5: `description:` field present; `!cat` directives appear in the expected order.
- `git log --follow skills/_shared/prompt-design-rules.md` reaches commits older than the rename.
- Grep-based audit confirms all 8 refresh edits A-H are present (anchor phrases per edit listed in design.md ## G31).
- Apply R1-R7 + cross-cutting principles from the migrated rules file to the new snippets themselves (meta-acceptance pass).
- Anchor-phrase audit: rules-file location references match the exact form named in DoD.

**References**

- goals.md ### G31 — problem framing (prompt-prose-coverage contract not yet enforceable).
- design.md ## G31 — Files 1-5 detailed solutions + Additions A-D + Distribution Table (single sweep point for completeness + drift detection).
- structure.md per-file blocks for the 6 new files (each tagged `**Goal IDs:** {G31}`).
- structure.md `## Hook-Point Cross-Slice Index` → G31 prompt-prose `!cat` include sites (downstream consumer context).
