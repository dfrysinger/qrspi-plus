# U14 violation fixture — claim-line lint

This file seeds a violation of the claim-line lint: each section's first sentence must be ≤250 chars and end with a period. The first section below opens with a 300+ character run-on sentence that does not end with a period — both failure modes intentionally co-located so a single fixture exercises the lint comprehensively against the implementation in tests/unit/test-u14-lint.bats.

## Approach

This is a deliberately overlong opening sentence that goes on and on without ending punctuation and easily exceeds the two-hundred-and-fifty character ceiling because we are stringing together many clauses joined by "and" and "but" and "however" and additional commas to ensure the line is well past the cap and also fails to end in a period

Supporting evidence and trade-offs follow here, but the lint should already have flagged the opening sentence above as the load-bearing claim line.

## Key Decisions

Short opening claim ending properly. This section's claim line is fine — only the Approach section above seeds the violation.

Additional supporting prose follows.
