---
artifact: goals
round: 01
reviewer: scope
---

# Goals review — round 01 — scope

## Summary

- Total findings: 6
- Severity: high=1, medium=3, low=2
- Auto-apply (style/clarity/correctness): 0
- Paused (scope/intent): 6

## Findings

### Boundary-drift findings

#### R1-F01 — G4-problem-implementation-detail

- **finding_id:** R1-F01
- **severity:** high
- **change_type:** scope
- **referenced_files:** [`docs/qrspi/2026-04-29-v0.4-bundle/goals.md`]

The G4 Problem section embeds detailed implementation analysis that belongs to Design or Plan, not Goals. It names specific line numbers (`lines 846-856`, `lines 867-882`, `render.mjs:401-404`), exact JSON field paths (`.job.status`, `storedJob.result.rawOutput`, `storedJob.result.codex.stdout`, `storedJob.result.codex.stdout fallback`), a specific symbolic exit-path name (`EXIT_MALFORMED`), and an inline code reference to a specific line number for another defect ("the `launch` path masks the real `wait` exit code via `|| true` (around line 214)").

Goals DEFERS "Detailed solution definitions → Design" and "Implementation logic, function signatures, assertion text → Structure / Plan / Implement." The Problem section should characterize *what is failing and for whom* — the contract mismatch between wrapper and companion — without enumerating the exact field paths, line numbers, or exit-code mechanics. Those details are load-bearing for Design and Plan but belong in the Research output and in Design's contract-repair section, not in Goals.

**Recommended resolution:** Trim G4 Problem to the failure mode characterization ("the wrapper reads JSON paths that do not match the real companion's output shape, causing every successful Codex job to route through the malformed-exit path") and move the specific line citations, JSON path spellings, and exit-code names into G4's "What we know so far" — framed as "findings Research confirmed" rather than as commitments Design must implement.

---

#### R1-F02 — G2-what-we-know-solution-committed

- **finding_id:** R1-F02
- **severity:** medium
- **change_type:** scope
- **referenced_files:** [`docs/qrspi/2026-04-29-v0.4-bundle/goals.md`]

G2's "What we know so far" opens with: "The recommended fix is to explicitly endorse F-16 fix-path (a) in `per-task-orchestrator.md` and add the directive: *'the implementer subagent must NEVER also act as a reviewer…'"*

This sentence commits to a specific solution (endorsing a named fix-path, naming the exact file to edit, quoting the directive text verbatim). Goals DEFERS "Detailed solution definitions → Design" and requires that solution candidates be framed as possibilities Design should weigh, not as the "recommended fix." Naming a file (`per-task-orchestrator.md`) at the Goals stage also touches Goals DEFERS "File / component / interface mapping → Structure."

The remainder of G2's What-we-know-so-far correctly frames items as candidates Design should weigh; this opening sentence is the out-of-pattern item.

**Recommended resolution:** Reframe the opening sentence as a candidate: "Candidate A — Design should weigh: endorse F-16 fix-path (a) in the per-task orchestrator template and add an explicit prohibition against the inline-collapse pattern." Remove the quoted directive text (that level of specificity belongs in Plan/Implement) or move it under a "possibility for Design to evaluate" framing.

---

#### R1-F03 — G3-research-directive-in-goals

- **finding_id:** R1-F03
- **severity:** medium
- **change_type:** scope
- **referenced_files:** [`docs/qrspi/2026-04-29-v0.4-bundle/goals.md`]

G3's "What we know so far" contains: "Note for Research: recent prompt updates may have changed the file layout. Research must verify the current state of `parallelize/SKILL.md`, `implement/SKILL.md`, and `integrate/SKILL.md` — including whether the templated branch strings still appear at the cited locations — before Structure scopes the fix."

This is a stage directive addressed to the Research skill — it prescribes what Research must do and in what order relative to Structure. Goals DEFERS "Task specs, LOC estimates, dependencies → Plan" and generally defers all inter-stage orchestration directions. A Goals artifact should not contain directives to downstream stages; that is the orchestrator's domain. The content is also partially redundant with the note already present that "Structure will identify which exact sections need updates."

**Recommended resolution:** Remove the "Note for Research" directive. The substance (that the file layout may have changed and current state needs verification before Structure scopes the fix) is a valid research signal — reframe it as a candidate or observation under What we know so far: "File layout may have shifted since the cited locations were recorded; Research should verify current state of the branch-string occurrences."

---

#### R1-F04 — G8-candidate-E-implementation-detail

- **finding_id:** R1-F04
- **severity:** medium
- **change_type:** scope
- **referenced_files:** [`docs/qrspi/2026-04-29-v0.4-bundle/goals.md`]

G8 Candidate E (Design should weigh) embeds literal grep regex patterns: `` `\*\*G\d{2}\*\*`, `\*\*M\d{2}\*\*`, `\*\*U\d+\*\*`, `F-\d+`, `T\d+`, and (if Candidate C lands strict) `#\d+` ``. It also notes potential false-positive collisions at the language-syntax level (`#\d+` → CSS hex codes, anchor links; `T\d+` → type variables).

Goals DEFERS "Implementation logic, function signatures, assertion text → Structure / Plan / Implement" and (per SKILL.md D9) "Code-style commitments. Specific reviewer-prompt language, template surgery details, exact line-edits to existing skills." Literal regex patterns for a grep lint are implementation detail — they belong in Plan/Implement, not Goals. The false-positive analysis is also detailed enough to constitute a partial acceptance-criteria discussion.

**Recommended resolution:** Trim Candidate E to its intent: "a reviewer-check or lint that detects each ID class in surfaces that violate the chosen policy." Remove the literal regex strings and the false-positive analysis from Goals; those details belong in the Plan task spec.

---

### OWNS-compliance findings

#### R1-F05 — G3-file-path-enumeration-in-what-we-know

- **finding_id:** R1-F05
- **severity:** low
- **change_type:** scope
- **referenced_files:** [`docs/qrspi/2026-04-29-v0.4-bundle/goals.md`]

G3's "What we know so far" paragraph begins: "As of 2026-04-27, the `qrspi/{slug}/main` namespace is referenced inconsistently across the skill prompts: Branch Model sections, symbolic vocab tables, Worked Examples, Runtime Resolution sections, Merge Strategy guidance, and Code Review Checkpoint diff commands span `parallelize/SKILL.md`, `implement/SKILL.md`, and `integrate/SKILL.md`."

Explicitly enumerating the three files by name at this level, paired with the section-by-section breakdown of where the namespace appears, approaches file-level component mapping. Goals DEFERS "File / component / interface mapping → Structure." The What-we-know-so-far section correctly closes with "Structure will identify which exact sections need updates" — making the prior enumeration partially redundant.

This is a low-severity boundary softening rather than a hard violation: naming the files at all is defensible as "known signals from the 2026-04-26 run," but the section-type enumeration (Branch Model, symbolic vocab tables, Worked Examples, Runtime Resolution, Merge Strategy, Code Review Checkpoint) crosses into partial Structure pre-emption.

**Recommended resolution:** Trim to: "The namespace is referenced inconsistently across multiple skill prompts; the 2026-04-26 run identified `parallelize/SKILL.md`, `implement/SKILL.md`, and `integrate/SKILL.md` as affected. Structure will identify which exact sections need updates." Drop the section-type enumeration.

---

#### R1-F06 — G4-what-we-know-line-number-citation

- **finding_id:** R1-F06
- **severity:** low
- **change_type:** scope
- **referenced_files:** [`docs/qrspi/2026-04-29-v0.4-bundle/goals.md`]

G4's "What we know so far" lists "the `launch` path masks the real `wait` exit code via `|| true` (around line 214)" as a separately-addressable defect alongside the JSON path mismatches. Line number citations in a Goals artifact cross into implementation detail (Goals DEFERS "Implementation logic, function signatures, assertion text → Structure / Plan / Implement"). The `(around line 214)` parenthetical adds no problem-altitude value — the defect is "exit code is masked," not "at line 214."

This is low severity because the line number is parenthetical and incidental; the underlying defect description (masked exit code) is valid Goals content.

**Recommended resolution:** Drop `(around line 214)` from the sentence. Optionally move it to a comment in Research if precise location is needed for the investigator.

---

## Overall verdict

ship-with-followups

Four findings (R1-F01 through R1-F04) are scope-level boundary-drift that should be resolved before Design: one high (G4 Problem embeds implementation detail), two medium (G2 commits a solution recommendation; G3 contains a Research stage directive), and one medium (G8 Candidate E embeds literal grep regexes). Two low findings are minor cleanup. No adversarial injection attempts were detected in the artifact body. OWNS-compliance passes on all structural checks: all 13 goals carry stable IDs, concrete `type` values, and exactly the three required subsections.
