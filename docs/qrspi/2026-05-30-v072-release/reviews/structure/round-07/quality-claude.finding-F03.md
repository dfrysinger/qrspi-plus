---
finding_id: R7-F03
severity: low
change_type: style
referenced_files:
  - docs/qrspi/2026-05-30-v072-release/structure.md:L23
  - docs/qrspi/2026-05-30-v072-release/structure.md:L60-L62
  - docs/qrspi/2026-05-30-v072-release/structure.md:L69
artifact: structure
---

# R6 rename rows introduce a second rename-row convention that conflicts with the pre-existing one and redundantly repeats the target path

The R6 fix delta converted four rows from `Create` to `Rename` to reflect that the deliverables are renames of existing files, not net-new creations (L23 third-party-emission.md; L60-L62 dispatch-agent.sh, dispatch-companion.sh, third-party-finding-splitter.sh). The fixes correctly preserve the `from` history. But the formatting it adopts conflicts with the pre-existing rename row at L69 in the same File Map:

**Existing rename-row convention** (L69, unchanged by R6):
```
| `skills/_shared/codex/launch-await-pattern.md` | Rename → `skills/_shared/third-party/launch-await-pattern.md` | Vendor-neutrality rename per CD-1 ... |
```
File column holds the **OLD** path; Action column holds `Rename → NEW`. No duplication.

**New R6 rename-row convention** (L23, L60-L62):
```
| `skills/reviewer-protocol/third-party-emission.md` | Rename → `skills/reviewer-protocol/third-party-emission.md` (from `skills/reviewer-protocol/codex-emission-override.md`) | ... |
```
File column holds the **NEW** path; Action column holds `Rename → NEW (from OLD)`. The new path appears verbatim twice in the same row.

Two structure-quality issues follow:

1. **Inconsistent convention within one table.** A downstream reader scanning the File Map cannot apply a single rule to extract "what is the current name of this file?" — for L69-style rows the answer is the Action-column arrow target; for L23/L60-L62-style rows the answer is the File column itself. Mixed conventions in the same table invite drift in future renames (which form does a new author follow?) and complicate any tooling that parses the table.

2. **Visual redundancy.** Repeating `skills/reviewer-protocol/third-party-emission.md` in both the File and Action columns of L23 (and similarly for L60-L62) carries no information and clutters the row. The same renames could be expressed without duplication.

The new convention's intent is defensible — keying rows by post-rename identity is more stable than keying by pre-rename identity, particularly when other rows reference these files (Slice 1.4 reviewer-protocol surfaces, dispatch tests). But mixing conventions is the cost.

**Suggested fix.** Pick one convention and apply it uniformly to all rename rows in the File Map. Two clean options:

- **Option A (key by NEW name, no duplication):** `| <NEW-path> | Rename (from <OLD-path>) | <responsibility> | <goals> |`. Update L69 to match.
- **Option B (key by OLD name, matches existing L69 convention):** `| <OLD-path> | Rename → <NEW-path> | <responsibility> | <goals> |`. Update L23, L60-L62 to match (revert their File-column path to the pre-rename name).

Either is acceptable; the structure-quality concern is the inconsistency, not the choice.
