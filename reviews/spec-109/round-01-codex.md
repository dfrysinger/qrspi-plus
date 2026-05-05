1. `finding_id`: `R1-F01`
   `severity`: `high`
   `change_type`: `correctness`
   `message`: `The proposed per-finding file format is not compatible with QRSPI’s current 5-field reviewer schema. In the spec, §2 says the file contains a “5-field finding object in YAML frontmatter” with the message moved into the markdown body and an optional appended verifier block (lines 59-62), and the sample file actually adds extra frontmatter keys \`artifact\`, \`round\`, and \`reviewer\` while omitting \`message\` from the object entirely (lines 183-199). Today the reviewer protocol defines the finding schema as exactly five fields, including \`message\`, and the disk-write contract expects findings in that shape (skills/reviewer-protocol/SKILL.md lines 19-27, 137-158). As written, downstream readers that rely on the existing 5-field object will drift immediately. The design needs either a deliberate schema migration for every consumer, or it needs to keep the existing 5 fields intact and store verifier metadata outside that object.`
   `referenced_files`: `["docs/superpowers/specs/2026-05-04-109-sonnet-haiku-verifier-design.md","skills/reviewer-protocol/SKILL.md"]`

2. `finding_id`: `R1-F02`
   `severity`: `high`
   `change_type`: `correctness`
   `message`: `§9’s migration order is not independently shippable. Step 3 says to migrate reviewer agent files in batches so they emit per-finding files (lines 282-283), but the current orchestrator still reads per-reviewer files in Apply-fix until step 6 lands (skills/using-qrspi/SKILL.md lines 518-525). That means any reviewer migrated in step 3 will stop producing the only files main currently knows how to consume, so main breaks between commits instead of staying green. The “reversible at any step before step 6” claim on line 288 is therefore false once step 3 ships. Reviewer-file migration has to land atomically with the orchestrator consumer change, or behind a compatibility path that supports both shapes.`
   `referenced_files`: `["docs/superpowers/specs/2026-05-04-109-sonnet-haiku-verifier-design.md","skills/using-qrspi/SKILL.md"]`

3. `finding_id`: `R1-F03`
   `severity`: `high`
   `change_type`: `correctness`
   `message`: `The spec says the verifier sits between reviewer subagents and apply/pause dispatch for artifact reviewers, per-task implementation reviewers, the implement-gate reviewer, and integration/security reviewers (spec lines 15, 117-123), but the only orchestrator change it actually designs is the artifact-level Apply-fix path in \`skills/using-qrspi/SKILL.md\` (lines 65-80). Per-task implementation review uses its own loop and its own \`reviews/tasks/task-NN-review.md\` aggregation path in \`skills/implement/SKILL.md\` (lines 352-376, 446-523), and Integrate has a separate review/fix loop in \`skills/integrate/SKILL.md\` (lines 98-139). As written, the design does not specify where verifier dispatch happens for those non-artifact review loops or how their verifier output feeds the existing implement/integrate fix prompts. Either narrow the scope to artifact reviews only, or add concrete verifier integration for Implement and Integrate.`
   `referenced_files`: `["docs/superpowers/specs/2026-05-04-109-sonnet-haiku-verifier-design.md","skills/using-qrspi/SKILL.md","skills/implement/SKILL.md","skills/integrate/SKILL.md"]`

4. `finding_id`: `R1-F04`
   `severity`: `high`
   `change_type`: `correctness`
   `message`: `The Codex splitter design does not reconcile with the current Codex contract. §2 assumes \`await\` returns a finding stream on stdout that can be split on \`<<<FINDING-BOUNDARY>>>\` (spec lines 95-108), but current Codex dispatches still pass an \`output:\` path into the reviewer prompt while the orchestrator also redirects Codex stdout to that same path (for example, skills/parallelize/SKILL.md lines 165-185 and skills/implement/SKILL.md lines 378-446). A compliant reviewer could write to \`output\` and emit only the brief return summary to stdout, in which case the splitter would receive no finding bodies to split. The fallback is also internally broken: lines 103-105 require each segment to conform to the per-finding contract, but line 104 says a missing-delimiter stream is dumped wholesale to \`codex.finding-F00.md\` and “verifier still scores it”, even though that raw stream may not be a valid finding object at all. The design needs one unambiguous Codex source of truth: either reviewers write files directly, or stdout is the canonical artifact and the prompt must stop pretending \`output\` is authoritative.`
   `referenced_files`: `["docs/superpowers/specs/2026-05-04-109-sonnet-haiku-verifier-design.md","skills/parallelize/SKILL.md","skills/implement/SKILL.md","scripts/codex-companion-bg.sh"]`

5. `finding_id`: `R1-F05`
   `severity`: `high`
   `change_type`: `correctness`
   `message`: `The design has no valid “zero findings” path. §2 says reviewers emit N per-finding files and no per-reviewer file (lines 61-62), so a clean review round emits zero files. But Apply-fix starts by globbing \`reviews/{step}/round-NN/*.finding-*.md\` (lines 69-72), and §4 treats “zero per-finding files” as a schema-violation case if a legacy summary file exists (lines 209-211). Current reviewer-protocol explicitly allows clean outputs with “No issues found” and a brief \`Findings: 0\` summary (skills/reviewer-protocol/SKILL.md lines 157, 165-169). Under the proposed shape, a clean round is indistinguishable from a broken round unless you add a round-level sentinel or retain a machine-readable per-reviewer summary that the orchestrator can trust.`
   `referenced_files`: `["docs/superpowers/specs/2026-05-04-109-sonnet-haiku-verifier-design.md","skills/reviewer-protocol/SKILL.md"]`

6. `finding_id`: `R1-F06`
   `severity`: `high`
   `change_type`: `correctness`
   `message`: `Filtering on verifier score before change-type dispatch changes the meaning of \`scope\` and \`intent\` findings in a way that conflicts with the current reviewer protocol. The spec’s goal and Apply-fix flow explicitly drop findings before they ever reach apply/pause dispatch (spec lines 5, 75, 172-175). But today \`scope\` and \`intent\` are guaranteed to pause for explicit user resolution, and reviewer-protocol is explicit that findings contradicting prior user decisions should still be emitted and surfaced via the pause gate (skills/reviewer-protocol/SKILL.md lines 35-42, 83-89). With the proposed ordering, Haiku becomes the final arbiter of whether a user-decision conflict is even shown to the user. If that semantic change is intended, it needs to be argued explicitly; otherwise the verifier should only gate auto-apply findings and should not be allowed to suppress \`scope\`/\`intent\` pauses.`
   `referenced_files`: `["docs/superpowers/specs/2026-05-04-109-sonnet-haiku-verifier-design.md","skills/reviewer-protocol/SKILL.md"]`

7. `finding_id`: `R1-F07`
   `severity`: `medium`
   `change_type`: `correctness`
   `message`: `The “disable verifier for the rest of this run” behavior is not actually run-scoped. §5 says option 1 disables the verifier for the rest of the run (lines 222-224, 233-234), but the mechanism is to mutate persisted \`config.md\` (lines 84-89). \`config.md\` is the durable run configuration on disk, reused across resume flows and later skill invocations (skills/using-qrspi/SKILL.md lines 339-375), so this setting survives compaction, pauses, and re-entry. Without an explicit reset rule, a user choice made for one transient outage silently disables verifier behavior for later rounds and later sessions too. Either make the persistence intentional and say so, or keep this as ephemeral state rather than storing it in \`config.md\`.`
   `referenced_files`: `["docs/superpowers/specs/2026-05-04-109-sonnet-haiku-verifier-design.md","skills/using-qrspi/SKILL.md"]`

8. `finding_id`: `R1-F08`
   `severity`: `medium`
   `change_type`: `clarity`
   `message`: `Several internal contradictions leave the scoring/disabled-mode state machine underspecified. The rubric is described as verbatim 0/25/50/75/100 scoring (lines 30, 51), but the verifier return example and sample file both use \`87\` (lines 54, 197), so it is unclear whether arbitrary scores are allowed. Disabled-mode flow is also inconsistent: step 5 says verifier-disabled rounds still assemble \`round-NN-verified.md\` without verifier blocks (line 73), but test #8 says disabled mode skips verifier dispatch and assembly entirely (line 266), and the data-flow diagram says \`verifier_enabled=false\` jumps to step 9 (lines 147-149), which is inside the Haiku lane rather than the assembly path. These contradictions need to be resolved before implementation because they directly affect parser behavior, totals-header math, and the retry/disable control flow.`
   `referenced_files`: `["docs/superpowers/specs/2026-05-04-109-sonnet-haiku-verifier-design.md"]`

9. `finding_id`: `R1-F09`
   `severity`: `medium`
   `change_type`: `correctness`
   `message`: `The config-schema target in §2 points to a file that does not exist. The spec says to add \`verifier_enabled\` under \`skills/{config}/SKILL.md\` (lines 82-89), but this repo has no \`skills/config/\` skill; the authoritative \`config.md\` contract lives in \`skills/using-qrspi/SKILL.md\` under “Config File” (lines 339-375). If implemented literally, the docs/tests will update the wrong location and the runtime contract used by the rest of the pipeline will remain stale. Point this change at the actual config contract file.`
   `referenced_files`: `["docs/superpowers/specs/2026-05-04-109-sonnet-haiku-verifier-design.md","skills/using-qrspi/SKILL.md"]`