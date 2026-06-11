---
finding_id: R1-F02
severity: medium
change_type: correctness
referenced_files: ["docs/qrspi/2026-06-04-v073-release/design.md"]
artifact: design
round: 1
reviewer: quality-claude
---

G9's acceptance section (footprint measurement bullet) names the output artifact as:

  `docs/qrspi/2026-06-04-v073-release/g8-footprint-report.md`

G8 is the plugin manifest version-centralization goal (VERSION file + build-plugin.mjs stamper + CI gate). G8 has no footprint measurement report. This is G9's footprint measurement artifact and should be named `g9-footprint-report.md` (or another name that does not reference G8).

An implementer following this acceptance criterion verbatim would create a file path that attributes G9's metric to G8, causing downstream confusion when auditing which goal's work produced the report. The acceptance criterion for G9 is the only place this file path is defined, so the correct name is unambiguous — the `g8` prefix is a copy/paste error.

Fix: Change `g8-footprint-report.md` to `g9-footprint-report.md` in the G9 acceptance bullet.

