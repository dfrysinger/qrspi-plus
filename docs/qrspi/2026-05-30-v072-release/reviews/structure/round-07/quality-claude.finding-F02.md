---
finding_id: R7-F02
severity: medium
change_type: correctness
referenced_files:
  - docs/qrspi/2026-05-30-v072-release/structure.md:L767-L776
  - docs/qrspi/2026-05-30-v072-release/structure.md:L687-L688
  - docs/qrspi/2026-05-30-v072-release/design.md:L2471
  - docs/qrspi/2026-05-30-v072-release/design.md:L2485
  - docs/qrspi/2026-05-30-v072-release/design.md:L2502
  - docs/qrspi/2026-05-30-v072-release/design.md:L2555
  - docs/qrspi/2026-05-30-v072-release/design.md:L2510-L2520
  - docs/qrspi/2026-05-30-v072-release/design.md:L2530-L2540
artifact: structure
---

# New G31 hook-point enumeration is incomplete: missing Consumer #1 detection-only site + both wrapper-SKILL `!cat` sites + reviewer-addition surface entirely

The R6 fix added a new `### G31 prompt-prose-writer !cat include sites` subsection (L767-L776). This is the right surface for drift-prevention — but the enumeration is materially incomplete relative to the other hook-point subsections in the same section (CD-1, CD-2, CD-3, CD-4/G12, G34, G35), each of which enumerates **every** site where the named shared snippet is `!cat`'d.

Per design.md L2471, L2485, L2502, L2555 and File 4/5 verbatim bodies at L2510-L2520 and L2530-L2540, the actual `!cat` consumer sites for the G31 shared snippet trio are:

**`prompt-prose-detection.md` `!cat` sites** (design L2471 — Consumers #1, #2, #3 + Files 4 & 5 via wrappers):
- `skills/plan/SKILL.md` § Per-Task Classification — Addition A inline body contains `!cat skills/_shared/prompt-prose-detection.md` (design L2555)
- `skills/plan/SKILL.md` writer-subagent dispatch payloads, 2 sites — listed ✓
- `skills/design/SKILL.md` authoring step — listed ✓
- `skills/prompt-prose-writer/SKILL.md` — wrapper SKILL body `!cat`s detection.md (design L2517)
- `skills/prompt-prose-reviewer/SKILL.md` — wrapper SKILL body `!cat`s detection.md (design L2537)

**`prompt-prose-writer-addition.md` `!cat` sites** (design L2485 — Consumers #2, #3 + File 4):
- `skills/plan/SKILL.md` writer-subagent dispatch payloads, 2 sites — listed ✓
- `skills/design/SKILL.md` authoring step — listed ✓
- `skills/prompt-prose-writer/SKILL.md` — wrapper SKILL body `!cat`s writer-addition (design L2519)

**`prompt-prose-reviewer-addition.md` `!cat` sites** (design L2502 — File 5 only):
- `skills/prompt-prose-reviewer/SKILL.md` — wrapper SKILL body `!cat`s reviewer-addition (design L2539)

The current subsection (L767-L776) lists only **3 sites** (plan/SKILL.md × 2 + design/SKILL.md) and explicitly says "per design.md G31 Consumers #2–#3," consciously excluding the rest. The omitted sites matter for two reasons:

1. **The wrapper-SKILL `!cat`s are the load-bearing bridge** to Consumers #4–#8 (the agent files preload via `skills:` frontmatter, which only delivers content if the wrapper actually contains the `!cat` lines). A wrapper SKILL body that drifts away from its two `!cat` lines silently delivers nothing to all five preload-consumer agents. This is exactly the drift class hook-point enumeration exists to prevent.
2. **Consumer #1's detection-only `!cat`** site is the only place the Plan classifier reads the detection rule; omitting it from the include-site map leaves classifier-rule drift undetected.

Additionally, `prompt-prose-reviewer-addition.md` (a shared snippet file `Create`-d in the Slice 1.5 File Map at L122 and contract-listed at L683) has **zero** include-site mentions in the Hook-Point Locations section. Every other shared snippet under `_shared/` enumerated in the File Map appears in a corresponding hook-point subsection; this one does not.

**Suggested fix.** Restructure the G31 subsection so its scope matches the other hook-point subsections — enumerate every `!cat` site for all three shared snippets, including:
- the wrapper SKILLs themselves (which are the `!cat` boundary that the frontmatter-preload bridge depends on),
- Consumer #1's `plan/SKILL.md § Per-Task Classification` site for detection.md (via Addition A),
- a parallel subsection or table block for `prompt-prose-reviewer-addition.md` so it is not orphaned from the drift-prevention map.

Alternatively, rename the subsection to reflect its narrowed coverage (e.g. "G31 inline-`!cat` sites at SKILL.md consumer files") AND add a separate `### G31 wrapper-SKILL !cat include sites` subsection so the wrapper-`!cat` boundary still has explicit coverage.
