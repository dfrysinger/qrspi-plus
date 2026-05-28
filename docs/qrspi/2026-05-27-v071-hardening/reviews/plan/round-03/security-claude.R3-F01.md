---
finding_id: R3-F01
severity: medium
change_type: correctness
referenced_files: [docs/qrspi/2026-05-27-v071-hardening/plan.md]
artifact: plan
round: 3
reviewer: security-claude
---

Task 1 canonical header-injection test covers VALUE but not NAME embedded-control case

R3 added the value-side canonical injection test ("printable text + CR/LF + printable text") but the analogous test for header NAMES is absent. Every existing name-side test covers a name consisting of a single C0 byte, not multi-segment names like `Header-Name\r\nInjected: value`.

The chosen idiom (`LC_ALL=C tr -d '[:cntrl:]' | wc -c`) handles all positions correctly today, but no test pins this for names, so any future refactor that regresses name-embedded detection would be invisible.

Fix: Add a mirror test expectation for header NAMES: "A header name containing printable ASCII immediately followed by a control byte (e.g. printable + CR/LF + printable) causes the script to exit before any network dispatch."
