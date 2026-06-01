---
finding_id: R3-F04
severity: low
change_type: clarity
artifact: design
round: 3
reviewer: quality-claude
referenced_files:
  - docs/qrspi/2026-05-30-v072-release/design.md:L421
  - docs/qrspi/2026-05-30-v072-release/design.md:L457
  - docs/qrspi/2026-05-30-v072-release/design.md:L459
  - docs/qrspi/2026-05-30-v072-release/design.md:L511
  - docs/qrspi/2026-05-30-v072-release/design.md:L693
---

## CD-4 "Locked component shapes" letters appear out of order (A–G, J, then later H, I)

**Location:** `design.md` CD-4 § Locked component shapes (L419) through § I. Reviewer-side hardening (L693).

**Problem.** The component-shapes section reads as a flat alphabetic enumeration (`**A.**`, `**B.**`, ... lettered headings), but the actual order in the file is:

| Order in file | Letter | Title | Line |
|---|---|---|---|
| 1 | A | Finding file | 421 |
| 2 | B | Verifier sidecar | 425 |
| 3 | C | `scripts/verifier-fan-in.sh` | 431 |
| 4 | D | `kept-findings.txt` | 438 |
| 5 | E | `.verifier-fan-in-audit.json` | 440 |
| 6 | F | Orchestrator-side prose update | 452 |
| 7 | G | Reviewer agent updates | 457 |
| 8 | **J** | Verifier dispatch reuses CD-1's dispatch-agent.sh | 459 |
| — | (Per-goal acceptance mapping) | | 501 |
| — | (Behavioral acceptance) | | 509 |
| 9 | **H** | Halt-response protocol | 511 |
| 10 | **I** | Reviewer-side hardening | 693 |

Two clarity gaps:

1. **J appears between G and H** — a reader looking for "Component H" navigates past J first, then through ~50 lines of acceptance-criteria prose, then finds H at L511. The "letter collision fix I→J" applied mid-R2 deconflicted label collision but left the resulting order non-monotonic.
2. **H and I are placed *after* the per-goal acceptance mapping and behavioral acceptance** (L501–509). That positioning splits the locked-component-shapes section across an interruption — the acceptance subsections read as a section terminator, then H and I resume the lettered enumeration unannounced.

A first-time reader looking up "Component H — Halt-response protocol" via Ctrl-F finds it; a reader scanning the components sequentially to understand what files CD-4 introduces will miss H and I unless they read past the acceptance section, which most readers will treat as a closing.

**Impact.** Navigation friction in the largest cross-goal decision block. The cross-references inside CD-4 reinforce the friction:

- L429 (Component B) refers forward to "component J below" — but J is two components later, before H/I, which the reader hasn't seen yet.
- L591 (H.5) says "After every rescue path and every escalation resolution, the script re-runs" — readers landing on H from a backward link have to scroll up past acceptance criteria to find the script (Component C).
- R3-F01 + R3-F02 (this round) both involve cross-references inside CD-4 that are harder to verify because the components do not appear in lookup order.

This is not a correctness defect — every component is present and well-formed individually. It is a navigability defect that compounds the verification cost of every CD-4 review pass.

**Suggested fix.** Two options, roughly equal cost:

- **(a)** Relabel + reorder so the letters appear monotonically: rename J → H (it was H before the I→J collision fix made it J; renaming it back works if the original H is renamed to something else), and place all component-shape letters contiguously before the acceptance subsections. Concretely: A B C D E F G *H = old-J* I *= old-H halt-response* J *= old-I reviewer-side hardening*, all contiguous; acceptance subsections move to the end.
- **(b)** Split the section explicitly. Rename the current "Locked component shapes" heading to "Locked component shapes (data + script surfaces)" covering A–G + J (under the order A B C D E F G H *=old J*); move the current H + I out to two new top-level CD-4 subsections after acceptance: "Halt-response protocol" (no letter) and "Reviewer-side hardening" (no letter). The lettered enumeration stays compact and contiguous; the post-acceptance content is properly framed as separate subsections rather than continuations of the lettered list.

Option (b) is cleaner because H (Halt-response protocol) and I (Reviewer-side hardening) are genuinely different in shape from A–G/J (component-file specs vs. protocols + defense-in-depth) — the lettering forced them into a single visual list they don't really belong to.
