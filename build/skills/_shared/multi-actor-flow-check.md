## Multi-Actor Flow Check

Before authoring any deliverable that operationalizes a design decision involving two or more actors — where "actor" means anything that performs an operation and hands off to another: scripts, subagents, orchestrators, tools, services, protocol participants, object-call participants, workflow steps, queue producers/consumers, function callers/callees — verify that the design specifies all six choreography elements:

1. **Actor inventory** — every participant named, with its role.
2. **Sequence of operations** — ordered list of who-does-what; parallelism boundaries explicit.
3. **Per-step inputs and outputs** — what each actor receives and produces at each step; where outputs are written (stdout, file path, return value, manifest entry, message).
4. **Consumer identification** — for every output, who reads it next. Outputs with no named consumer must be removed or the consumer surfaced.
5. **Loud-failure paths** — what happens when each step fails; where the failure surfaces; which actor catches it. Silent fallback is never the answer.
6. **Context-cost call-out** — for any flow that crosses a context boundary (orchestrator/subagent, process, network), explicitly state what crosses vs. what stays on disk or in the other context.

If any element is missing for an in-scope decision, **STOP** authoring against this decision and surface a concrete diagnostic to the user. Do NOT guess the missing hand-off and continue.

Diagnostic template:

> Design decision **X** enumerates actors **A, B, C** but does not specify **[missing element — e.g., "what happens if B produces no output", "how A invokes B", "who reads C's output"]**.
>
> Stopping before guessing.
>
> Recommended path: trigger the **Backward Loops** procedure (see `using-qrspi/SKILL.md` § Backward Loops) to re-open Design via its per-decision dialogue, lock the missing element, re-review + re-approve `design.md`, then cascade forward — every dependent artifact from Design onward (Phasing if phase boundaries are affected, Structure, Plan, Parallelize if task dependencies are affected) re-runs against the updated design.
>
> Alternative: provide explicit guidance to accept the gap with a documented assumption recorded against this decision in the deliverable. The assumption becomes the de-facto contract — name what you are choosing for the missing element.

**Iron law:** silently inventing a missing hand-off is a contract violation that ships half-finished features which only surface at Test or in production. Guessing-instead-of-stopping is a process failure and must be reported even if the deliverable otherwise looks complete.
