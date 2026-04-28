# U14 violation fixture — no-brevity lint

This file seeds violations of the no-brevity grep. Three forbidden patterns appear below as bare instructions (not quoted, not in U14 documentation context, not part of a length-target band). The lint must fire on each of the three lines below.

## Approach

Be concise in your synthesis output.

Provide a brief summary of the trade-offs considered.

Keep your response ≤ 5 lines per section.

## Allowlisted patterns (must NOT trigger)

The U14 lint allowlist exempts the following legitimate cases:

- Soft length target: 200–400 lines for this SKILL.md (numeric length-target band, not a brevity instruction).
- Soft length target: 300–500 lines for SKILL.md (M51 band).
- Soft length target: 1000–2000 lines for plan.md aggregate (M52 band).
- The phrase "be concise" appearing inside quotes when documenting the U14 prohibition itself (meta-mention, not an instruction).
- "brief summary" cited inside quotes as a forbidden pattern in U14 conformance documentation.
- "≤ N lines" cited inside quotes as a forbidden pattern in the U14 prohibition list.

These allowlisted lines must NOT trigger the no-brevity lint. The three bare instructions in the Approach section above MUST trigger.
