---
verifier_status: passed
score: 70
actual_model: unknown
defect_class: incomplete-spec
---

Verified citations:
- Lines 353-362 contain the prose-design block "Batch Gate menu (autopilot default, branched)". The non-subagent-commits branch (line 357) says "Auto-escalate: dispatch a fix-task subagent with mode `revert-orchestration-drift`... Then re-run the phase-end check; if clean, advance." It is silent on what happens if the re-check is still dirty.
- Line 375 (edge-cases bullet, design body, NOT inside a `<!-- prose-design: -->` block) contains the verbatim cap: "Cap auto-revert attempts at 1 per phase; on second violation in the same phase, fall through to halt-and-surface regardless of violation type."

The finding's core claim is correct: prose-design blocks are the verbatim text destined for skill files (what orchestrators consume at runtime), and the loop-termination cap is absent from the operational block. Edge-case prose in design.md does not propagate to skill content. An autopilot orchestrator reading only the skill instructions could loop (revert → re-check still dirty → revert → ...) until something else halts it.

This is a real specification gap with operational consequence. The fix is mechanical — either move the cap into the prose-design block, or add a sentence pointing at where the loop terminates (e.g., the `orchestration-boundary-check.sh` script enforces the cap, or the fix-task `revert-orchestration-drift` mode tracks attempts). Score 70: highly confident it's a real issue with direct functional impact on autopilot termination behavior, slightly tempered because (a) the author has clearly thought about the cap and explicitly placed it in edge cases, so they intend the cap to exist; (b) Plan-time elaboration could close the gap when the prose-design blocks are transcribed to skill files (though that's exactly the propagation surface the finding is worried about — relying on Plan to remember an unmarked edge case is the gap).
