---
finding_id: F01
reviewer: silent-failure-claude
severity: medium
change_type: correctness
referenced_files: [skills/design/SKILL.md, skills/plan/SKILL.md]
---
**PRECONDITION "named diagnostic" has no output channel.** Halt blocks reference "named diagnostic" without specifying where output goes. Pre-existing QRSPI pattern (subagent halts surface via stderr to orchestrator).

**Adjudication:** DEFER to v0.7.3. Generic pattern across QRSPI skill set, not introduced by T26; T26 inherits idiom. Architectural cleanup deferred.
