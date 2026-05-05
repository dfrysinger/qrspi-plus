This section is the **single source of truth** for Replan scope boundaries. Phase-transition execution (the minor-path archive-and-populate sequence) is owned here; all phasing decisions and roadmap authoring are deferred to Phasing.

### Replan OWNS

- **Phase-transition execution (minor path)** — the five-step archive-and-populate sequence at phase boundary: (a) archive the completed phase's four synthesizing artifacts (`goals.md`, `questions.md`, `research/summary.md`, `design.md`) to the runtime path `docs/qrspi/{slug}/phases/phase-NN/`; (b) read `roadmap.md` to identify next-phase goal IDs; (c) extract entries for those goal IDs from `future-goals.md`, `future-questions.md`, `future-research-summary.md`, `future-design.md`; (d) write the populated next-phase drafts with `status: draft`; (e) invoke `qrspi:goals` for the next-phase Restart Mode pass.
- **Severity classification of phase learnings** — categorize each proposed change as Minor, Major, or Scope Unknown per the Severity Classification table; identify the earliest loop-back target for any Major change.
- **Minor-path artifact updates** — apply approved minor changes to `tasks/*.md` and `plan.md`; transition status to `replan-draft` and back to `approved` on re-approval.
- **Major-path feedback authoring** — write `feedback/replan-phase-NN-round-MM.md`, reset target + downstream artifacts to `status: draft`, invoke the loop-back skill (Goals, Design, Phasing, or Structure — chosen per the Severity Classification table). Major path is unchanged from baseline (loop back to upstream skill on substantive learnings).
- **Marking next-phase drafts** — every populated next-phase artifact carries `status: draft` so the downstream skill (Goals first, then Questions, Research, Design) re-reviews before proceeding.

### Replan DEFERS

- **Phasing decisions** (slice decomposition, phase boundaries, replan-gate criteria, Iron Laws 1/2 vertical-slice and Phase-1-PoC enforcement) → owned by **Phasing** (`skills/phasing/SKILL.md`). Replan consumes the existing roadmap; it does NOT re-decide which goals belong to which phase or re-author phase boundaries.
- **Authoring of `roadmap.md`** → owned by **Phasing**. Replan READS the roadmap to find next-phase goal IDs; it does NOT write or amend the roadmap. Roadmap edits between phases are a Phasing-owned operation, not a Replan-owned one.
- **Authoring of `future-*.md` artifacts** → owned by **Phasing** (initial pruning) and by the upstream skill on a Major loop-back. Replan READS the future-* artifacts to extract the next-phase entries; it does NOT add new entries to them.
- **Goal-text expansion or new goal creation** → owned by **Goals**. The scope-mapping check (below) makes this explicit: if a proposed change is not covered by existing goal text, classify Major and loop back to Goals — never silently expand.
- **Architecture, file maps, task specs** → owned by Design / Structure / Plan respectively. Replan proposes severity classifications and (on Minor) applies wording/LOC/split changes inside the existing scope; it does NOT re-author these artifacts.
