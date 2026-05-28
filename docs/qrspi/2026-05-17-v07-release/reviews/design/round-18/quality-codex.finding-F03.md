---
finding_id: R18-F03
severity: medium
change_type: correctness
referenced_files: [/Users/dfrysinger/Library/CloudStorage/Dropbox/claude-workspace/agent-bravo/docs/qrspi/2026-05-17-v07-release/design.md:L829-L833, /Users/dfrysinger/Library/CloudStorage/Dropbox/claude-workspace/agent-bravo/docs/qrspi/2026-05-17-v07-release/design.md:L878-L881]
artifact: design
round: 18
reviewer: quality-codex
---

The G17 load-bearing bash-3.2 proof uses the wrong example for a "bash-4+ construct not enumerated on Option B's ban-list": `${!array[@]}` is valid indexed-array syntax in older bash and is not a reliable 3.2-incompatibility fixture. As written, the design's "Option-A'-load-bearing test" can fail to demonstrate the distinction it claims, which weakens the rationale for Option A' as the true compatibility gate. Replace that example with a construct that is actually unavailable in bash 3.2 but also absent from the ban-list, so the test really proves the docker execution lane catches incompatibilities that the grep lane misses.
