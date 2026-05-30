---
artifact: phasing
severity: advisory
check: slice-description-accuracy
location: "phasing.md § Slices / Slice 7: Cache mechanism retirement (line 37 in phasing.md)"
change_type: fix-text
---

# Finding: Slice 7 states "Five artifacts are deleted" but enumerates only four

## What is wrong

Slice 7 opens with:

> "Five artifacts are deleted (the cache-probe script, the stub spike report, and two BATS unit suites) and the cache-control branches are removed from `skills/using-qrspi/SKILL.md` and `scripts/run-third-party-llm.sh`."

The parenthetical names three distinct items that resolve to **four** files:

| Item in parenthetical | File |
|----------------------|------|
| the cache-probe script | `scripts/g4-cache-probe.sh` |
| the stub spike report | `docs/qrspi/2026-05-17-v07-release/spikes/g4-cache-probe.md` |
| two BATS unit suites | `tests/unit/test-cache-control-capability-gate.bats` |
| (second BATS suite) | `tests/unit/test-cache-hit-rate.bats` |

This matches the four-file deletion list in `goals.md` G7a exactly. The remaining two artifacts named at the end of the sentence — `skills/using-qrspi/SKILL.md` and `scripts/run-third-party-llm.sh` — are **modified** (cache-control branches removed), not deleted.

## Source of the error

`design.md` DKR8 describes "five files" as the *total mechanism footprint*, counting the SKILL.md and `run-third-party-llm.sh` modifications alongside the four deletions, and treating the two BATS suites as a single list item. Slice 7 appears to have imported the "five" count from DKR8 without adjusting it for the deleted-vs-modified distinction that the slice's own sentence correctly captures.

## Why this matters

Slice 7's parenthetical is the implementation-level scope statement. An implementer reading "five artifacts are deleted" alongside a parenthetical listing four will either count a fifth artifact to delete that doesn't exist, or flag the discrepancy during task scoping. Neither the goals nor the design contain a fifth deleted artifact; the word "Five" is simply wrong.

## Recommended fix

Change "Five artifacts are deleted" to "Four artifacts are deleted" in the Slice 7 description. No change to any other part of the sentence or to any companion artifact is needed.
