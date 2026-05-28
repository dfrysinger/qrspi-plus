---
task: 35
status: approved
pipeline: full
task_type: code
model: opus
phase: 1
goal_ids: [G4]
dependencies: [T34]
loc_estimate: 150
---

# Task 35: G4 Mechanism B anchor-refresh script and structure-skill Section-Anchor Index section spec

- **Phase:** 1
- **Target files:**
  - `scripts/g4-section-anchor-refresh.sh` (Create) — bash 3.2-compatible shell script that reads `scripts/g4-section-anchor-manifest.json` from T34, walks every `(source, index)` pair in the manifest, regenerates the `<source>.anchors.json` file from the source artifact's current H2/H3 heading layout, and writes the regenerated JSON to the colocated index path. Idempotent: re-running against an in-sync source produces a byte-identical index. Fail-loud on duplicate heading text within a single source artifact.
  - `skills/structure/SKILL.md` (Modify) — add a new `## Section-Anchor Index` section that documents the colocation convention (`skills/<name>/SKILL.anchors.json` sits next to `skills/<name>/SKILL.md`), the manifest's role as the single registry of indexed artifacts, the refresh ownership (the refresh script is the source-of-truth regenerator; index files are not hand-edited), and the consumer contract (an agent that wants section X of artifact Y looks up the range from `<artifact>.anchors.json`, then uses `Read(offset, limit)` to fetch the slice verbatim).
- **Dependencies:** T34
- **LOC estimate:** ~150
- **Description:** Ships the G4 Mechanism B refresh tooling and the Structure-skill section spec that documents the Mechanism B contract for consumers. Mechanism B ships unconditionally in v0.7 independent of the T33 spike outcome; this task closes the Mechanism B substrate by providing the regeneration tool that keeps the T34 anchor indexes in sync with their sources as the sources evolve, and by anchoring the consumer contract in the Structure skill body so downstream skill authors and reviewers can verify Mechanism B sites at design time rather than discovering the index shape ad-hoc. The `scripts/g4-section-anchor-refresh.sh` script reads `scripts/g4-section-anchor-manifest.json` (authored in T34), iterates over each `(source, index)` entry, extracts every H2 and H3 heading text from the source artifact together with the `{line_start, line_end}` range each heading spans (where the range ends at the line immediately before the next same-or-higher-level heading), and writes the resulting `{heading_text → {line_start, line_end}}` JSON object to the colocated index path. The script is idempotent — a second invocation against an in-sync corpus produces byte-identical indexes — and fails loud with a named diagnostic if any single source artifact contains two H2 or H3 headings whose text is identical (duplicates would make narrow-read targeting ambiguous). The new `## Section-Anchor Index` section in `skills/structure/SKILL.md` documents: (1) the colocation convention so future indexed artifacts ship their index alongside the source; (2) the manifest as the single registry that gates which artifacts the refresh script regenerates; (3) refresh ownership — index files are regenerator output, not hand-authored; (4) the consumer contract — agents Read the slice via index lookup + `Read(offset, limit)`, not by re-scanning the source for headings. The contract surfaces in T36's `test-section-anchor-refresh.bats` pin (regenerated index reflects current heading layout after a source heading is added, removed, or renamed).
- **Test expectations:**
  - Running `scripts/g4-section-anchor-refresh.sh` against the manifest from T34 produces three regenerated `.anchors.json` files at the colocated paths.
  - The regenerated index for each indexed artifact contains exactly the H2 and H3 heading texts present in the corresponding source artifact at refresh time.
  - Each regenerated index entry's `{line_start, line_end}` matches the actual line span of the heading in the source artifact (line_end is the line before the next same-or-higher-level heading, or the last line of the source for the final section).
  - A second invocation of the refresh script against an unchanged source corpus produces byte-identical index files (idempotency).
  - Adding a new H2 heading to a source artifact and re-running the script produces an index containing the new heading; removing a heading and re-running produces an index without the removed entry; renaming a heading replaces the old key with the new key.
  - A source artifact containing two H2 or H3 headings with identical text causes the script to exit non-zero with a loud diagnostic naming the offending artifact, the duplicate heading text, and the line numbers of the collision, without writing a partial or corrupt index.
  - `skills/structure/SKILL.md` contains a new `## Section-Anchor Index` H2 section that documents the colocation convention, the manifest registry, the refresh ownership rule (regenerated, not hand-edited), and the consumer contract (index lookup + `Read(offset, limit)` for byte-identical slices).
  - Running the refresh script when `scripts/g4-section-anchor-manifest.json` is absent exits non-zero with a loud diagnostic naming the missing manifest file (no silent skip).
  - Running the refresh script when the manifest JSON is malformed exits non-zero with a loud diagnostic naming the manifest file and the parse error.
  - Running the refresh script when a manifest entry's source path does not exist exits non-zero with a loud diagnostic naming the missing source path and the manifest entry that referenced it.
