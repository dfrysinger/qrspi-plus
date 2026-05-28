---
finding_id: R17-F06
severity: low
change_type: clarity
referenced_files: [docs/qrspi/2026-05-17-v07-release/design.md:L1093]
artifact: design
round: 17
reviewer: quality-claude
---

The system diagram's `VFRAgent` node label uses a note-to-implementer phrase rather than a system component description, reducing the diagram's usefulness for implementers trying to understand component relationships.

The Reference subgraph in the system diagram (design.md line 1093) contains: `VFRAgent["Visual-fidelity reviewer (study Keeplii reference)"]`. The parenthetical "(study Keeplii reference)" is an instruction to whoever implements the reviewer agent, not a description of what the component does in the system. The rest of the diagram uses descriptive labels: "G1: routing policy schema (config.md model_routing block...)", "reference_gate human approval pause", "ui: and lift_source: task-spec fields".

A diagram label like "Visual-fidelity reviewer (study Keeplii reference)" says nothing about what the reviewer does in the pipeline — it just reminds the implementer to study a reference. A downstream Phasing or Plan agent using the diagram to understand component relationships would learn nothing useful from the parenthetical.

Fix: replace the parenthetical with a description of the component's role in the pipeline. For example: `VFRAgent["Visual-fidelity reviewer (per-task dispatch for ui:true tasks; dual-mode: wireframe refs + wave_context)"]`. The cross-reference to studying the Keeplii reference can move to a prose note in the G11 recommendation section (where it already appears at line 547).
