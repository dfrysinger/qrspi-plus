---
task: 34
status: approved
pipeline: full
task_type: code
model: opus
phase: 1
goal_ids: [G4]
dependencies: []
loc_estimate: 180
sizing_exception: reusable primitives
---

# Task 34: G4 Mechanism B three colocated section-anchor index files plus manifest

- **Phase:** 1
- **Target files:**
  - `skills/reviewer-protocol/SKILL.anchors.json` (Create) — JSON section-anchor index colocated with `skills/reviewer-protocol/SKILL.md`; maps every H2 and H3 heading text in the source to `{line_start, line_end}` so consumers can `Read(offset, limit)` a specific section verbatim. This is the highest-traffic stable artifact (every reviewer dispatch preloads `reviewer-protocol`).
  - `skills/using-qrspi/SKILL.anchors.json` (Create) — JSON section-anchor index colocated with `skills/using-qrspi/SKILL.md`; same `{H2|H3 heading → {line_start, line_end}}` shape. `using-qrspi` is preloaded at every skill entry; consumers Read specific subsections such as `## Compaction Checkpoints` or `## Standard Review Loop` rather than the whole file.
  - `skills/plan/SKILL.anchors.json` (Create) — JSON section-anchor index colocated with `skills/plan/SKILL.md`; same shape. `plan/SKILL.md` is one of the longest skill files and Plan dispatches frequently Read only the post-approval split sub-section.
  - `scripts/g4-section-anchor-manifest.json` (Create) — manifest JSON enumerating the three indexed artifacts (source path plus colocated `.anchors.json` path per entry). The refresh script in T35 reads this manifest to know which artifacts to regenerate; new entries are added later by extending the manifest.
- **Dependencies:** none
- **LOC estimate:** ~180
- **Sizing exception:** reusable primitives — the three anchor index files are a shared lookup substrate consumed by every Mechanism B narrow-read site (downstream agent dispatches use `Read(offset, limit)` against the index, not the inline awk-style anchor scans); the manifest is the registry every refresh run keys off. The combined JSON volume reflects the three source artifacts' full H2/H3 surface, which is the irreducible payload for the consumer contract — splitting the indexes across tasks would fracture the primitive.
- **Description:** Ships the G4 Mechanism B section-anchor index — the narrow-read lookup substrate that lets agents Read only the section of a long stable artifact they need, with the slice byte-identical to the source. The four target files this task creates are the three colocated `.anchors.json` index files AND the new `scripts/g4-section-anchor-manifest.json` manifest that the T35 refresh script keys off; the manifest is an additional load-bearing runtime artifact this task ships even though it is not enumerated in structure.md's Slice 7 file map. This is a documented post-approval gap noted by the round-1 Plan reviewer; the gap is recorded at `reviews/plan/structure-amendment-needed.md` as a follow-up TODO for a future Structure-skill amendment cycle. The implementer of T34 is NOT required to action the amendment as part of this task — `reviews/plan/structure-amendment-needed.md` is a tracking note, not an implementation dependency — and T34 ships the manifest at the path declared above regardless of the amendment's status. Mechanism B ships unconditionally in v0.7 independent of the T33 spike outcome; the section-anchor index is the lookup substrate that Mechanism B's narrow-read consumers (Plan dispatches reading only the post-approval split sub-section, reviewers reading only the Reviewer Dispatch Contract, every skill entry reading only the Compaction Checkpoints subsection) depend on. Each `.anchors.json` file is colocated with its source (`skills/<name>/SKILL.anchors.json` sits next to `skills/<name>/SKILL.md`) per the colocation convention declared in `structure.md`'s Section-Anchor Index section spec (authored in T35). The JSON shape maps every H2 and H3 heading text from the source file to a `{line_start, line_end}` object whose values are 1-indexed inclusive line numbers; no duplicate heading text is permitted within a single artifact. The manifest at `scripts/g4-section-anchor-manifest.json` enumerates the three initial indexed artifacts so the T35 refresh script knows which sources to regenerate against; the manifest is the single registry that future Mechanism B expansions extend rather than each new index being discovered ad-hoc. The contents of each index reflect the current heading layout of the corresponding source artifact at authoring time; T35 ships the refresh tooling that keeps them in sync as the sources evolve. The three pinned consumer contracts in T36 (`test-section-anchor-index-shape`, `test-section-anchor-narrow-read`, `test-section-anchor-refresh`) observe this primitive.
- **Test expectations:**
  - `skills/reviewer-protocol/SKILL.anchors.json` exists at the colocated path and parses as valid JSON.
  - `skills/using-qrspi/SKILL.anchors.json` exists at the colocated path and parses as valid JSON.
  - `skills/plan/SKILL.anchors.json` exists at the colocated path and parses as valid JSON.
  - Every top-level key in each `.anchors.json` corresponds to an H2 or H3 heading text that exists in the source `SKILL.md` at the matching path.
  - Every value in each `.anchors.json` is an object with integer `line_start` and `line_end` fields satisfying `line_start <= line_end`, with both fields referring to lines within the source file's actual line count.
  - No `.anchors.json` contains two keys with the same heading text (duplicates would make narrow-read targeting ambiguous).
  - `scripts/g4-section-anchor-manifest.json` exists, parses as valid JSON, and enumerates the three indexed artifact pairs (source path + colocated index path) corresponding to the three `.anchors.json` files above.
  - For each indexed artifact, a sample narrow-read using one heading's `{line_start, line_end}` and `Read(offset=line_start, limit=line_end-line_start+1)` returns a byte-identical slice of the source artifact's corresponding line range.
