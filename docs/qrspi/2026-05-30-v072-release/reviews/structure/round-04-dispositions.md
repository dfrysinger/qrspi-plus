---
artifact: structure
round: 4
kept_applied: 4
dropped: 4
---

## Kept — Applied

**quality-claude.R4-F01** (medium, correctness, score 78)
Changed §3 verifier-fanout `--tier-override` argument from bare `<tier>` to `qrspi-finding-verifier=<tier>`, aligning with §7's canonical `tag=tier` assignment grammar.

**scope-claude.R4-F01** (low, scope, score implicit-keep)
Replaced §13 "Locked platform directory" sentence (which duplicated per-platform return values from design.md CD-4 §I.7) with a single-line cross-reference: "per-platform return values are listed in design.md CD-4 §I.7."

**stitching-audit.R4-F01** (HIGH, correctness, score 82)
Extended Slice 1.2 `skills/using-qrspi/SKILL.md` row responsibility to include the orchestrator-side halt-response protocol (CD-4 §I.3): reads `orchestrator_rescue` and `max_drift_per_round` from config.md; added CD-4 to the goal-ID column.

**stitching-audit.R4-F03** (medium, correctness, score 70)
Added Interface §17 (`.orchestrator-fixes.json` rescue audit schema) between §16 and `## Architectural Diagram`, with path, writer, consumer, schema, and CD-4 §I.3 citation. Updated Section Contracts preamble cross-reference list to include `<round-dir>/.orchestrator-fixes.json` → §17.

## Dropped — Not Applied

**quality-codex.R4-F01** (score 18, correctness)
False positive: glob is `.md`-anchored and sidecars are `.yml` per using-qrspi protocol; no enumeration overlap possible.

**quality-codex.R4-F02** (score 65, clarity)
Plan-altitude concern: NO_FINDINGS sentinel path underspecification is a clarity note that Plan can backfill from sibling interface patterns; below structure-altitude threshold.

**stitching-audit.R4-F02** (score 40, correctness)
`_resolve-lib.sh` "tier resolution" reasonably encompasses agent-frontmatter parsing; G22 cite in the row's goal-ID column supplies the full algorithm via design.md authority; minor wording gap unlikely to misroute Plan.

**stitching-audit.R4-F04** (score 22, correctness)
§3 PATH B is intentionally high-level; omission of `--tag` from the prose description is not a seam mismatch given §14's explicit `--tag`-required contract and the two sections' different abstraction levels.
