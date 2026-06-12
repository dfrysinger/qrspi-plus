---
finding_id: R1-F02
severity: low
change_type: scope
referenced_files: [docs/qrspi/2026-06-04-v073-release/phasing.md:L21]
artifact: phasing
round: 1
reviewer: scope-claude
---

The second replan-gate bullet names specific manifest file paths:

> "Plugin installs cleanly from `.github/plugin/plugin.json` + `.github/plugin/marketplace.json` (G8 lockstep) on a fresh Copilot CLI session."

DEFERS places file paths in Structure. Low severity because the manifests are user-observable plugin artifact identities and G8 lockstep arguably requires naming the pair.

Proposed resolution: (a) "Plugin installs cleanly from the published plugin and marketplace manifests (G8 lockstep) on a fresh Copilot CLI session," letting Structure carry the paths; or (b) accept as scoped exception specific to G8 lockstep semantics.
