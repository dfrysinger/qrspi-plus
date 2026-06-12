---
finding_id: R3-F03
severity: medium
change_type: correctness
referenced_files: [docs/qrspi/2026-06-04-v073-release/design.md]
artifact: design
round: 3
reviewer: quality-claude
---

The G5 prose-design block for the autopilot batch-gate behavior (`<!-- prose-design: skills/{implement,integrate,test}/SKILL.md § Batch Gate menu (autopilot default, branched) -->`) describes commit-based violations as: "Auto-escalate: dispatch a fix-task subagent with mode `revert-orchestration-drift` … Then re-run the phase-end check; if clean, advance." The block is silent on what happens when the re-check is still not clean after the revert. The design body's edge-cases section (which does NOT become prose-design content) says: "Cap auto-revert attempts at 1 per phase; on second violation in the same phase, fall through to halt-and-surface regardless of violation type." Because the prose-design block is verbatim content destined for the skill files — which is what orchestrators read at runtime — the 1-attempt cap is absent from the operational specification. An autopilot orchestrator following the skill-file instructions could loop indefinitely: violations found → revert → still violations → revert again → … The prose-design block must include the cap ("if violations persist after one revert attempt, halt with a named diagnostic") so the orchestrator's loop-termination behavior is specified in the artifact the orchestrator will actually consume.

