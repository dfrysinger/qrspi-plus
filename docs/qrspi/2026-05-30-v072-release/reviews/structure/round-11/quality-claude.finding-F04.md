---
artifact: structure
reviewer_tag: quality-claude
finding_id: R11-F04
referenced_files:
  - docs/qrspi/2026-05-30-v072-release/structure.md:184
  - docs/qrspi/2026-05-30-v072-release/structure.md:221
  - docs/qrspi/2026-05-30-v072-release/structure.md:223
  - docs/qrspi/2026-05-30-v072-release/structure.md:242
  - docs/qrspi/2026-05-30-v072-release/structure.md:387
  - docs/qrspi/2026-05-30-v072-release/structure.md:538
  - docs/qrspi/2026-05-30-v072-release/structure.md:559
  - docs/qrspi/2026-05-30-v072-release/structure.md:2935-2937
severity: medium
change_type: correctness
---

# Stale post-restructure cross-references: per-file blocks cite structure.md `§3` and `§4` sections that no longer exist, and `L<NNN>` line ranges that point at vacated lines

## What is broken

The restructure renumbered `## Cross-Cutting Schemas` to start at **§7** (structure.md L2939, items 7–16 contiguous). Sections numbered §1–§6 were retired. But multiple per-file blocks still reference `§3` and `§4` as if those sections exist, and several cite stale line ranges (`L<NNN>`) that pointed at content's pre-restructure location.

### Stale §N references

- **L184** (verifier-fan-in.sh outline): "the canonical `change_type` enum (`[style, clarity, correctness, scope, intent]` per **structure.md §4** `validators.change_type_enum`)"
- **L221** (verifier-dispatch-prose.md outline): "per structure.md §3 'Verifier-fanout mode' + design.md CD-4 §H invocation form"
- **L242** (reviewer-protocol/SKILL.md outline): same §4 reference
- **L387** (test-change-type-partition.bats responsibility): same §4 reference
- **L538** (Slice 1.2 run-codex-review.sh): "per **structure.md §3** 'Universal dispatch CLI,' L197-218"
- **L559** (same file outline): "per structure.md §10 'Dispatch manifest schema,' **L328-363**"

`## Cross-Cutting Schemas` (L2935-3142) contains items 7-16; no §3 and no §4 exist. The `validators.change_type_enum` content is not present anywhere in the current structure.md as a named §N item. The "Universal dispatch CLI" content is presented per-file in the `scripts/dispatch-agent.sh` block (L832-892), not as a §N entry.

### Stale line-range references

- **L223** ("per structure.md §7 note at L289"): §7 (Host-and-tier-aware second-reviewer override) is at L2939, not L289. L289 falls inside the Slice 1.1 per-file block for `skills/reviewer-protocol/codex-emission-override.md`.
- **L538, L559** ("§10 'Dispatch manifest schema,' L328-363"): §10 is at L2990-3025, not L328-363. L328-363 falls inside the Slice 1.1 verifier sidecar block.

### Stale Hook-Point Locations line citations

Multiple per-file blocks cite Hook-Point line numbers that referenced the **prior** Hook-Point Locations table position. `## Hook-Point Cross-Slice Index` (the post-restructure replacement) now lives at **L3340**, but blocks cite line numbers in the 600-800 range:

- **L261, L289**: "per structure.md §Hook-Point file table at **L686** / **L687**"
- **L527**: "per structure.md §Hook-Point Locations 'CD-4 / G12 verifier-dispatch-prose `!cat` include sites,' **L747**"
- **L710**: "Hook-Point Locations **L695-712**" — actual table is at L3344-3362
- **L794-795**: "structure.md §Hook-Point Locations **L748** … **L710**"
- **L756, L765-766**: "structure.md §Hook-Point Locations **L756 / L765 / L766**"
- **L781, L782, L783, L784, L785**: "structure.md §Hook-Point Locations **L781-L785**"
- **L1257**: "per structure.md §Hook-Point Locations **L701**"
- **L1507, L1520, L1536**: "Hook-Point Locations **L710, L711, L712**"
- **L1701, L1704**: "per `## Cross-Cutting Schemas` §7 below" — this one IS correct (§7 exists), but `L289` cite at L223 in the same neighborhood is not.

All of the cited "Hook-Point Locations L<6xx-8xx>" point at content that, post-restructure, no longer lives in that line range.

## Why it matters

These are the navigation pointers Plan and Implement consumers (and the structure-reviewer's stitching audit, per the convention at L24) use to resolve "where in structure.md is the contract this per-file block is reading from?" Every stale pointer is a dead link in the artifact's internal navigation graph.

Concretely:

1. The §3 / §4 references send a Plan-author to a section that does not exist. They cannot find the canonical `change_type` enum or the "Universal dispatch CLI" definition without re-reading the file from top to bottom.
2. The L<NNN> citations are off by 2000-3000 lines after the restructure. CTRL-F by line number resolves to unrelated content (e.g., L289 lands inside the codex-emission-override.md block, not the §7 second-reviewer-override schema).
3. Per the Convention at L24: "Cross-file interface coordination (caller-callee contracts) is verified by the structure-reviewer's stitching audit." The audit requires the references to resolve. Currently they don't.

## Suggested fix

Two sweeps:

1. **Replace §3 / §4 references with the correct post-restructure target.** Most appear to be `validators.change_type_enum` and "Universal dispatch CLI" — neither lives in `## Cross-Cutting Schemas` post-restructure. Either (a) add the missing schemas to `## Cross-Cutting Schemas` and assign them new §N numbers (e.g., §17, §18 to keep the contiguous range), then update the references; or (b) remove the §N citation entirely and replace with a per-file pointer (e.g., "per the canonical enum locked in `skills/reviewer-protocol/SKILL.md` and the `scripts/verifier-fan-in.sh` header constants — see §11 audit schema for the threshold rule that consumes it").

2. **Sweep all `L<NNN>` citations and either update or remove them.** Line-number citations are the most fragile form of cross-reference and rot on every restructure. Prefer named anchors over line numbers — `per § Hook-Point Cross-Slice Index → CD-4/G12 verifier-dispatch-prose !cat include sites` is more durable than `per structure.md Hook-Point Locations L747`. Specifically: every `L7xx` reference to the prior Hook-Point Locations table should be replaced with `## Hook-Point Cross-Slice Index → <subsection name>` and the L<NNN> dropped.

Both sweeps are mechanical. The §N count is small (≤6 sites); the L<NNN> sweep is larger (~15-20 sites) but each edit is local.
