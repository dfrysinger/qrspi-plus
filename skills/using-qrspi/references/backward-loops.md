
When a later step surfaces new requirements or contradictions (e.g., Figma wireframes reviewed during Structure reveal missing features; implementation reveals a design flaw), **do not patch the current artifact in isolation.** Loop backward to the earliest affected artifact and cascade forward:

1. Identify the earliest artifact that needs updating (usually goals.md or design.md)
2. Update it with the new information
3. Run its review round (Claude + Codex if enabled) until clean
4. Present for re-approval
5. Move forward to the next artifact, updating to reflect the changes
6. Repeat review + approval at each step until you reach the step where the learning was discovered
7. Resume the original step with consistent, reviewed artifacts

**This is not optional.** Skipping backward loops creates drift — goals say one thing, design says another, structure implements a third. Each artifact is a contract downstream steps depend on.

**Common triggers:** user shares wireframes/mockups revealing new features or UX patterns; implementation exposes a design flaw or missing edge case; research findings invalidate earlier assumptions; user changes their mind about scope or approach during a later step.
