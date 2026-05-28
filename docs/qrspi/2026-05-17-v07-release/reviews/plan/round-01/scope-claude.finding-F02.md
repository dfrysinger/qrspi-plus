---
finding_id: R1-F02
severity: medium
change_type: scope
referenced_files: [docs/qrspi/2026-05-17-v07-release/plan.md:L198, docs/qrspi/2026-05-17-v07-release/plan.md:L379]
artifact: plan
round: 1
reviewer: scope-claude
---

Task descriptions for T03 and T10 encode Implement-layer control-flow detail — logic the OWNS/DEFERS rule explicitly defers to the Implement agent.

T03 (line 198): The description specifies the internal branching logic at the level of individual shell calls: "for `codex-broker` it internally chains `scripts/codex-companion-bg.sh launch` then `scripts/codex-companion-bg.sh await <jobId>` and writes the result to `--output-file`." This names the specific internal invocation sequence the script must execute — a line-by-line logic walkthrough. Per the OWNS/DEFERS rule, "Line-by-line logic, control-flow detail, algorithm pseudocode → Implement (the implementation agent owns local logic decisions inside the task's bounded scope). Conversation, not contract: Plan says 'increment Redis counter on each allowed request'; Implement chooses `INCR` vs. `EVAL` with a Lua script."

T10 (line 379): The description names specific parsing markers the adapters must match: "parses framework-specific signals (BATS `not ok`/`# (in test file ` markers, Vitest `FAIL`/`SyntaxError` markers, Jest `FAIL`/`Cannot find module` markers, pytest `FAILED`/`ERRORS`/`collection errors` markers) to distinguish assertion failures from infrastructure failures." These are specific regex/string patterns that determine branching — Implement-layer decision-making that the plan is pre-empting. The INVEST Negotiable framing prohibits encoding this level of detail in plan.md: "Implement chooses `INCR` vs. `EVAL` with a Lua script" is the exemplar; specifying which exact markers to scan for is the same kind of foreclosure.

Additionally, T03's description enumerates every CLI flag with type-annotated parameter shapes: "`--artifact-dir <abs-path>`, `--provider <name>`, `--model <id>`, and `--output-file <abs-path>`; and accepts optional `--scope-hint <text>` and `--timeout-seconds <int>`." This is CLI signature territory that belongs in structure.md's interface-contract section (the same DEFERS → structure.md rule that covers function signatures applies to CLI flag contracts).

Resolution: For T03, trim the internal chaining detail to the behavioral claim: "For `codex-broker` transport, the dispatcher chains through the codex-companion lifecycle and writes the result to `--output-file`." Remove the specific `launch`/`await <jobId>` invocation sequence. Move CLI flag names and types to structure.md. For T10, trim the parsing-signal enumeration to the behavioral claim: "Each adapter distinguishes assertion failures from infrastructure failures using framework-specific output signals." Implement selects the specific markers; the plan sets the observable classification contract.
