---
reviewer: claude
role: plan-quality-reviewer
round: 6
artifact: plan.md
severity: low
change_type: clarity
finding_id: F03
---

# Finding F03 — T16/T19 carve-out symmetry incomplete after round-05 halt-move

## Location

- `plan.md` T16 In-scope, **L986** — claims "host/vendor routing lookup" as T16's responsibility.
- `plan.md` T16 Out-of-scope, **L993–L996** — does not carve out the host × vendor matrix helpers and `[second-reviewer-same-vendor]` halt as T19-owned.
- `plan.md` T19 Out-of-scope, **L1121–L1124** — does not acknowledge that T16 creates `_resolve-lib.sh`'s tier-resolution foundation that T19 extends.

## What's wrong

Round-05 split `_resolve-lib.sh` responsibility across T16 and T19 — T16 owns "tier-to-(vendor, model) lookup" and primary-slot tier resolution; T19 owns "host × vendor matrix and default-second-reviewer lookup helpers" plus the matrix-lookup-time `[second-reviewer-same-vendor]` halt. The DoD bullets (T16 L1001–L1008; T19 L1126–L1136) now reflect that split correctly.

But the **In/Out carve-outs are stale**:

1. **T16 L986 In-scope still lists "host/vendor routing lookup"** as part of T16. After the round-05 move, "host × vendor matrix lookup" is T19's. The phrasing collision ("host/vendor routing lookup" vs "host × vendor matrix... lookup helpers") is the exact kind of ambiguity that round-05's move was meant to clean up. An implementer reading T16 in isolation would reasonably conclude they should implement the full host/vendor matrix lookup in T16, only to discover at L1116 that T19 also claims it.

2. **T16 Out (L993–L996) doesn't carve out the T19-owned surface.** The three current Out bullets defer to T17 (G23 row), T27 (Evergreen-Output snippet), and design.md ## G22 future work. There is no "host × vendor matrix lookup helpers and `[second-reviewer-same-vendor]` matrix-lookup-time halt — T19 owns" bullet. Compare to T19's Out at L1121 which **does** carve out T20's surface ("Dispatch script renames... Task 20 owns that rename-and-dispatch surface"). The carve-out symmetry is one-directional.

3. **T19 Out (L1121–L1124) doesn't acknowledge T16's upstream surface.** T19 carves out three downstream surfaces (T20 renames, T27 snippet, v0.7.3+ futures) but doesn't acknowledge that T16 owns `_resolve-lib.sh`'s primary-slot tier resolution and the `tier: none` halt. An implementer reading T19's "Extend `scripts/_resolve-lib.sh`" (L1116) needs a one-line pointer to where the file's foundation comes from.

This is low-severity because the DoD bullets disambiguate on careful reading. It's worth flagging because the round-05 surgical edit explicitly aimed at cross-task contract clarity, and the carve-outs are the highest-leverage surface for that clarity.

## Fix

Three small edits:

- **L986** (T16 In): change "tier-to-`(vendor, model)` lookup, host/vendor routing lookup, and halt-on-`none` behavior" → "tier-to-`(vendor, model)` lookup, **primary-slot** host/vendor routing lookup (the host × vendor matrix helpers consumed by T19's second-reviewer probe are deferred to T19), and halt-on-`none` behavior".
- **L996** (T16 Out): add a new bullet — "Host × vendor matrix lookup helpers, default-second-reviewer lookup, and the matrix-lookup-time `[second-reviewer-same-vendor]` halt — T19 owns the second-reviewer-facing extension of `_resolve-lib.sh`."
- **L1124** (T19 Out): add a new bullet — "Creation of `scripts/_resolve-lib.sh`, primary-slot tier resolution, and the `tier: none` halt — T16 owns the schema-migration foundation this task extends."

These three edits make the file-edit ordering plus the round-05 halt-move boundary self-documenting from either task spec alone, eliminating the need to cross-read both specs to understand who owns which slice of `_resolve-lib.sh`.
