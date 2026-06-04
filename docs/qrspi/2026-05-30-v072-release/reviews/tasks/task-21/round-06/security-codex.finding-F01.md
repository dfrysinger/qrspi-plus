---
finding_id: F01
reviewer: security-codex
severity: medium
change_type: scope
referenced_files: [scripts/dispatch-agent.sh:965-970, scripts/dispatch-agent.sh:1051, scripts/dispatch-agent.sh:1291, scripts/dispatch-companion.sh:559, scripts/dispatch-companion.sh:562, scripts/dispatch-companion.sh:580, scripts/dispatch-companion.sh:634-640, scripts/dispatch-companion.sh:662]
disposition: DEFER-v0.7.3
---
**TOCTOU symlink swap between path validation and use.** Pre-existing finding — already DEFERRED in T21 R3 sec-codex F02 (threat-model expansion: requires file-descriptor pinning or copy-to-trusted-tmp pattern, separate threat model from straight boundary enforcement). Tracked v0.7.3.
