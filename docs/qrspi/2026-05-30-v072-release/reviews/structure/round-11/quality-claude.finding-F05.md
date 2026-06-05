---
artifact: structure
reviewer_tag: quality-claude
finding_id: R11-F05
referenced_files:
  - docs/qrspi/2026-05-30-v072-release/structure.md:1059-1074
  - docs/qrspi/2026-05-30-v072-release/structure.md:19
  - docs/qrspi/2026-05-30-v072-release/design.md:117-125
  - docs/qrspi/2026-05-30-v072-release/design.md:2192-2200
severity: medium
change_type: correctness
---

# Host × vendor matrix verbatim lift cites the wrong design.md location and uses a synthetic (non-grep-able) marker phrase

## What is broken

The `scripts/_resolve-lib.sh` per-file block (structure.md L1052-1086) carries a verbatim payload — the host × vendor routing matrix — with the following provenance header (L1061-L1064):

```
**Source:** design.md §CD-1 component #10 (L117-L125)
**Marker phrase:** "Host × vendor matrix (extended by G27 D5 with the "Default second-reviewer vendor" column at L2201-L2205)"
**Lift type:** Insertion delta
**Insertion site (in target file):** Authored into the header / leading-documentation block of `scripts/_resolve-lib.sh` …
```

The actual verbatim payload at L1066-L1074 is the **5-column** extended matrix:

| Host | Claude | Codex | DeepSeek (v0.7.3+) | Default second-reviewer vendor |

Two distinct contract violations:

### 1. Source line range points at the wrong matrix version

design.md **L117-L125** carries the **4-column** unextended matrix (no "Default second-reviewer vendor" column). The 5-column version that the structure.md payload reproduces verbatim actually lives at **design.md L2192-L2200** (inside §G27 D5 — "CD-1 host×vendor matrix extension").

Per the Prose Provenance Convention (L19), `**Source:**` is the citation a verifier uses to locate the lift. A reader following the cited L117-L125 will land on a 4-column table and observe a mismatch with the 5-column structure.md payload — concluding (incorrectly) that the lift is unfaithful, when in fact the citation is pointing at the wrong design.md section.

### 2. Marker phrase is synthetic, not a literal grep-target

The Prose Provenance Convention (L19) defines marker phrase as: "the **exact bounding phrase in design.md** that a verifier can use to relocate the lift when line numbers drift."

The structure.md marker phrase `"Host × vendor matrix (extended by G27 D5 with the 'Default second-reviewer vendor' column at L2201-L2205)"` is **not** a phrase from design.md. It is authored prose summarizing the lift's provenance. `grep -F` against design.md returns zero matches.

The actual grep-able phrases for the two source sections are:
- design.md L117 (4-col matrix lead-in): `"Host × vendor matrix"`
- design.md L2192 (5-col matrix lead-in): `"D5 — CD-1 host×vendor matrix extension."`

A verifier cannot relocate this lift when line numbers drift — exactly the failure mode the convention is designed to prevent.

## Why it matters

The matrix is the canonical routing table consumed by `_resolve-lib.sh`, `dispatch-agent.sh`, and `second-reviewer-available.sh` — three scripts that drive every reviewer dispatch in the release. The lift must be authoritatively traceable to a single design.md source so Plan/Implement can:

1. Confirm the payload landing in `_resolve-lib.sh` is byte-identical to the locked design.md authority.
2. Re-locate the source if design.md line numbers drift before Plan starts.

Today the per-file block fails both: the cited L117-L125 disagrees structurally with the payload, and the marker phrase doesn't grep. The structure-reviewer's stitching audit cannot pass on this block as authored.

A related concern (worth surfacing for awareness, not as a separate defect): the convention enumerates three `Lift type` values — `Full file body`, `Insertion delta`, `Section body`. None of them describes a "stitch a column from §G27 D5 onto the matrix from §CD-1 #10" composite. Even with the citation fixed, the lift is more accurately a Full reproduction of design.md L2194-L2200 (the 5-col matrix), since the 5-col version is design.md's locked authority — the 4-col version at L119-L123 is design.md's prior-draft display before the G27 D5 extension. Treating the lift as `Lift type: Section body` (full reproduction of the 5-col matrix block at L2192-L2200) is the clean shape.

## Suggested fix

Replace L1061-L1063 of structure.md with:

```
**Source:** design.md §G27 D5 (L2192-L2200)
**Marker phrase:** "D5 — CD-1 host×vendor matrix extension."
**Lift type:** Section body
```

The payload at L1067-L1074 (the 5-col matrix) does not change — it is already byte-identical to design.md L2194-L2200 (subject to the design-display blockquote stripping carve-out, which does not apply here since the design.md source is not blockquoted).

Optionally add a one-line note in the Insertion site field clarifying that the 5-col matrix at design.md L2192-L2200 supersedes the prior 4-col version at L117-L125 inside design.md's own structure — so a reader who finds the 4-col version first knows where the load-bearing version lives.
