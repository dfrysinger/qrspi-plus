---
finding: F04
reviewer: gt-claude
round: 8
task: 1
severity: info
change_type: scope
file: tests/unit/test-run-third-party-llm.bats
lines: "701,725,787,804,825,860,890,902"
persistence_note: orchestrator-persisted (reviewer chat-only fallback; see issue #216)
---

# F04 — 8 tests cover defense-in-depth behaviors not in spec bullets (advisory)

The following tests cover implementation behaviors demanded by no numbered spec bullet:

| Test | Line | Behavior |
|---|---|---|
| non-ASCII (0x80) no false-positive | 701 | `\200-\377` in tr delete set |
| NUL pre-flight fails-closed on empty wc | 725 | `_raw_file_bytes` numeric guard |
| `set -o pipefail` present | 787 | `set -o pipefail` at top |
| `_control_char_check` numeric guard | 804 | `case "$_cc_count" in ''|*[!0-9]*)` |
| ESC sanitisation in die message | 825 | `_cc_safe_hname` via tr |
| API-key die message ≠ "default_headers" | 860 | new label in call |
| `_cc_safe_hname` naming + fallback structural | 890 | rename + `\|\|` pattern |
| tr-pipeline failure → fallback string | 902 | fallback string in output |

All trace to G1's *spirit* (silent-failure injection vectors) and are sound defense-in-depth. Strict traceability finds no numbered-bullet anchor.

**Disposition**: ADVISORY. Tests are correct; behaviors are valuable. If strict traceability required, either (a) add spec bullets for pipeline-robustness, or (b) annotate tests with `# defense-in-depth: not in spec bullets` comments. Note: change_type=scope per SKILL bypasses the ≥80 filter and routes to user gate.
