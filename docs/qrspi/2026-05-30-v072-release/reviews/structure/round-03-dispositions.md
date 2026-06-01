# Structure R3 dispositions

| Finding | Disposition | Change |
|---|---|---|
| quality-claude F02 (HIGH) | applied | §14 side effect changed from manifest-append to "returns JOB_ID on stdout (consumed by dispatch-agent.sh, which appends…)"; §3 gains manifest side-effect note. |
| quality-codex F01 | applied | Added `agents/qrspi-design-scope-reviewer.md` Modify row to Slice 1.5 file map with G34, between qrspi-design-reviewer.md and qrspi-plan-reviewer.md. |
| scope-claude F01 | applied | Build-sync gate CI bullet trimmed to heading-level; removed command invocations and step sequencing, kept G32 gate identity. |
| stitching-audit F01 (HIGH) | applied | §3 extended with `--verifier-fanout` invocation form and stdout contract; dispatch-agent.sh Slice 1.4 row updated to mention `--verifier-fanout` mode. |
| stitching-audit F02 (HIGH) | applied | config.md Modify row extended with `orchestrator_rescue`/`max_drift_per_round`; Interface §4 schema block gains both CD-4 §I.4 fields with default values. |
| stitching-audit F05 | applied | Added Rename row to Slice 1.4 for `skills/_shared/codex/launch-await-pattern.md` → `skills/_shared/third-party/launch-await-pattern.md` with goals G3, G32. |
| stitching-audit F06 | applied | Added `agents/*.md (sweep — all 41 files)` schema-migration Modify row to Slice 1.4 after the 4 representative agent rows, goals G22. |
| stitching-audit F07 | applied | Chose option (a): added `--tag <reviewer-tag>` to §16 CLI spec and updated §10 `split_cmd` example to include `--tag quality-codex`; §16 side-effect clarified to read `<tag>.raw`. |

## Dropped (verifier filter, score < 70)
- quality-claude F01 (68): T1 Feeds missing G25 — partial T6 compensation
- quality-codex F02 (45): NO_FINDINGS sentinel name — Plan-altitude
- stitching-audit F03 (65): CD-4 §I halt-protocol test coverage — partial T6 compensation
- stitching-audit F04 (40): verifier-dispatch-prose Modify row — Hook-Point Locations table is canonical
