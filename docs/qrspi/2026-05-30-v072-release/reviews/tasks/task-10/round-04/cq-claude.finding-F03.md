---
finding_id: R4-F03
severity: low
change_type: clarity
referenced_files: [skills/using-qrspi/SKILL.md]
---

# Inline plugin-issue backlog tracking reference in agent-facing prose

`skills/using-qrspi/SKILL.md` step 9 observations paragraph carries:

```
(Spec text disambiguation around the cluster-summary vs per-finding reading
is tracked in the plugin-issue backlog as PI-V072-T10-005.)
```

This is an inline parenthetical in operational protocol prose that gets shipped to AI agents as part of their skill context. Agents reading this sentence cannot look up `PI-V072-T10-005`, cannot act on it, and receive no useful signal from it. The disambiguation is already addressed in the surrounding prose.

**Recommended remediation (backlog):** remove the parenthetical sentence entirely; relocate human-facing note about the known ambiguity to a developer comment block outside the agent-readable prose.
