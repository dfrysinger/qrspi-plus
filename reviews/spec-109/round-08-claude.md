# Round 8 review — spec-109 (claude)

Scope: NEW issues introduced or surfaced by the round-7 rewrite (post-staging
array discipline, `.snapshots.txt` disk-persistence, empty-codex marker,
unspoofability reframing around wrapper-side determinism, brief-return
rename to `<reviewer_tag>.<finding_id>: <score>`, §6 step-ref `9→5`). Round-7
fixes that landed cleanly are NOT re-flagged.

---

1. `finding_id`: `R8-F01`
   `severity`: `medium`
   `change_type`: `correctness`
   `message`: `The post-staging-array discipline did not propagate to the §3
   ASCII data-flow diagram. §2 step 7 (line 174) was correctly updated in
   round 7 to read "The cat operation uses the **post-staging arrays from
   step 4** (NOT the step-1 arrays — those reference paths that no longer
   exist for any crashed-tag finding files)." But the §3 ASCII step 7 (lines
   372–374) still reads: "Bash assembly (nullglob-safe; uses the
   path-qualified arrays from step 1): cat \"${findings[@]}\" \"${cleans[@]}\"
   \"${crashes[@]}\"". This is exactly the staleness bug Codex R7-F01 (high)
   raised against the normative §2 path; the normative path was fixed but
   the visual reference half of the same fix was left pointing at the stale
   step-1 arrays. An implementer who reads §3 first (or who cross-checks §2
   against §3 to disambiguate "which arrays") will see contradictory
   guidance. Fix: change "uses the path-qualified arrays from step 1" to
   "uses the post-staging arrays from step 4 (the step-1 arrays are stale
   after crash-staging moved files into .crash-skipped/)" so §2 and §3
   agree byte-for-byte on the array-source rule.`
   `referenced_files`: `["docs/superpowers/specs/2026-05-04-109-sonnet-haiku-verifier-design.md"]`

2. `finding_id`: `R8-F02`
   `severity`: `low`
   `change_type`: `clarity`
   `message`: `The verifier agent-file frontmatter description (line 31)
   describes the brief return as "a brief ID:score line", which predates
   the round-7 rename to `<reviewer_tag>.<finding_id>: <score>`. The
   procedure body (step 8 at line 58), §3 ASCII step 5 (lines 337–340),
   §4 verifier-failure section (line 470), and test #1 (line 526) were
   all updated to the tag-prefixed shape. The frontmatter description is
   the only place the legacy "ID:score" phrasing survives. The description
   field is what the orchestrator's dispatch sees as the agent's contract
   summary; mismatch between the description ("ID:score") and the procedure
   ("<reviewer_tag>.<finding_id>: <score>") is shorthand-not-incorrect but
   still a stale reference that an implementer auditing for round-7
   propagation would either flag or paper over inconsistently. Fix: change
   "return a brief ID:score line" to "return a brief
   `<reviewer_tag>.<finding_id>: <score>` line" so the description matches
   the procedure step 8 verbatim.`
   `referenced_files`: `["docs/superpowers/specs/2026-05-04-109-sonnet-haiku-verifier-design.md"]`

---

Findings: 2 total — 0 high, 1 medium, 1 low.
