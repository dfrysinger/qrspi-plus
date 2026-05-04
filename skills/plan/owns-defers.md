This section is the **single source of truth** for plan.md scope boundaries. The parameterized scope-reviewer (instantiated with `{ARTIFACT_TYPE}=plan`) parses the OWNS and DEFERS lists below as its locked rule input — boundary-drift findings, scope-compliance findings, and lexical-leakage checks all run against the enumerated items here.

**Length target.** plan.md aggregate length sits in the **1000–2000 lines** soft window once all task specs are appended for review (the Keeplii corpus averages ~52 lines per task spec; a 10-20-task phase lands inside this band). Per-task specs are intentionally **short** — terse bullets, no narrative preamble, no design rationale repetition. The aggregate band is a soft target, not a ceiling: reviewers should flag a plan that drifts well outside it (e.g., 200 lines for 10 tasks signals under-specification; 4000 lines signals task specs that have grown into design or implementation prose).

**INVEST Negotiable framing.** A plan task spec is a **conversation, not a contract**. Plan owns the scoping decisions and the test expectations; downstream skills (Structure, Implement, Implement-TDD) own the implementation choices that flow from those decisions. The DEFERS list below is the operational form of "Negotiable": the items deferred to later artifacts MUST stay out of plan.md — encoding a function signature or a line-by-line algorithm in a task spec turns the spec into a contract, forecloses Structure/Implement's negotiation room, and is grounds for a scope finding from the scope-reviewer.

### Plan OWNS

The plan.md artifact is the only authoring location for these concerns. Every paragraph or bulleted item in plan.md must trace to one of these:

- **Ordered task specs** — the per-phase ordered list of tasks, each implementing exactly one observable behavior (one request handler, one use case, one user-visible change).
- **Test expectations** in plain language per task — behaviors, inputs/outputs, edge cases, error conditions. Plain language only; not assertion code, not `expect(...)` strings.
- **Dependencies** — explicit task-to-task ordering (`Task 3 depends on Task 1, Task 2` or `Dependencies: none`). Forward dependencies are forbidden.
- **LOC estimates per task** — `~N` per task; the policy ceiling is 200 LOC and the target is ~100 LOC; see Task Sizing for the splitting protocol.

### Plan DEFERS

The following concerns are explicitly **out of plan.md scope**. Each DEFERS entry names the destination artifact that owns the concern. A finding that observes any of these in plan.md is a boundary-drift finding (`change_type: scope`); per the INVEST Negotiable framing above, the spec's job is to set the conversation, not pre-empt the downstream skill's negotiation.

- **Function signatures, type definitions, parameter shapes** → `structure.md` (interface contracts per file are Structure's OWNS, not Plan's). Conversation, not contract: Plan says "rate limiter middleware exposes a single Express handler"; Structure says `rateLimiter(req, res, next)`.
- **Full assertion text / `expect(...)` / test code** → Implement-TDD (Implement's TDD cycle authors the failing test first). Conversation, not contract: Plan says "returns 429 when client exceeds 100 requests/minute"; Implement-TDD writes `expect(res.statusCode).toBe(429)`.
- **Line-by-line logic, control-flow detail, algorithm pseudocode** → Implement (the implementation agent owns local logic decisions inside the task's bounded scope). Conversation, not contract: Plan says "increment Redis counter on each allowed request"; Implement chooses `INCR` vs. `EVAL` with a Lua script.
- **Architecture decisions, key trade-offs, system diagrams** → `design.md` (locked upstream; Plan consumes, does not re-author).
- **Phasing, vertical slice authoring, roadmap maintenance, replan-gate criteria** → `phasing.md` / Phasing skill. Plan consumes phase boundaries from Phasing; it does not re-decide them.

### Boundary-drift signals (lexical leakage)

The following lexical patterns in plan.md indicate boundary drift from a later pipeline stage and trigger a boundary-drift finding from the scope-reviewer:

- **Function signatures inline in a task spec** (parenthesized parameter lists, return-type arrows) — Structure-layer leak.
- **`expect(`, `assert.`, `assertEqual`, `toBe(` in a Test Expectations bullet** — Implement-TDD-layer leak.
- **`if/else`, `for`, `while`, line-numbered logic walkthroughs** — Implement-layer leak.
- **"trade-off", "we considered", "alternative approach"** in task description — Design-layer leak.
- **"phase 2 will...", "future phases", roadmap-style forward references** — Phasing-layer leak.
