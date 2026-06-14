## Clarifying Amendments

Clarifying amendments are changes to approved artifacts that refine wording, fix ambiguity, or add detail without changing intent. They are distinct from Replan proposals because they don't arise from phase learnings — they arise from noticing that an artifact could be clearer.

### Amendment Classification

| Type | Description | Cascade behavior | Example |
|---|---|---|---|
| **Clarifying** | Refines wording or fixes ambiguity without changing intent | `--skip-cascade` — no downstream reset | "Change 'handle errors' to 'return HTTP 4xx on validation failure'" |
| **Additive** | Adds new detail that doesn't contradict existing content and doesn't touch goals, per-task test expectations, or per-phase acceptance criteria | `--skip-cascade` — no downstream reset | "Add a note to a `structure.md` interface explaining the timeout default" |
| **Architectural** | Changes intent, structure, or approach | Full cascade — treat as Replan Major | "Change 'REST API' to 'GraphQL'" — this is NOT an amendment, route through Replan |

**Goals, per-task test expectations, and per-phase acceptance criteria are never amendments.** Changes to `goals.md` (purpose, constraints, problem framing, out-of-scope) route to Goals as a Replan Major; changes to per-task `## Test Expectations` or to a `plan.md` per-phase acceptance block route to Plan as a Replan Major (per the strip-from-goals contract — Plan owns acceptance criteria) — see Severity Classification above. The Clarifying/Additive shortcut applies only to non-goal, non-acceptance artifacts.

### Rationale Presentation

Before applying any amendment, present to the user:

1. **Diff:** Show the exact text change (old vs new)
2. **Classification:** Clarifying, Additive, or Architectural
3. **Rationale:** Why this amendment improves the artifact
4. **Confirm/Reject:** User must explicitly approve before application

If the user classifies an amendment as Architectural, stop and route through the normal Replan process instead.

### Application

After user approval:

1. Apply the text change to the artifact file
2. Call `pipeline_cascade_reset <step> <artifact_dir> --skip-cascade` — this resets only the amended artifact's state to draft, leaving downstream artifacts untouched
3. Log the amendment in the artifact's frontmatter or a dedicated amendment log

### Amendment Log Format

Append to the artifact file, inside the frontmatter:

```yaml
amendments:
  - date: YYYY-MM-DD
    type: clarifying|additive
    summary: "Brief description of what changed"
```

This log provides an audit trail of refinements without polluting the main content. Architectural changes are never logged here — they go through Replan and produce feedback files.
