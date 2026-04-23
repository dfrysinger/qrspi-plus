# Upstream QRSPI / ACE Reference Material

Local mirrors and pointers to HumanLayer and community writing on QRSPI, RPI, CRISPY, and Advanced Context Engineering for Frequent Compaction (ACE-FCA). Used as research substrate for qrspi-plus skill design.

## Licensing note

The HumanLayer reference repo publishes no explicit license. Mirrored files below are included for offline research reference. Before redistributing qrspi-plus in a way that embeds this content, confirm licensing with HumanLayer or drop the mirrors in favor of URL pointers.

## Mirrored

| File | Source | Fetched |
|---|---|---|
| `ace-fca.md` | [github.com/humanlayer/advanced-context-engineering-for-coding-agents](https://github.com/humanlayer/advanced-context-engineering-for-coding-agents/blob/main/ace-fca.md) | 2026-04-22 |

## Link-only (not mirrored; fetch via browser / WebFetch when needed)

### Talks

- **"No Vibes Allowed: Solving Hard Problems in Complex Codebases"** — Dex Horthy, AI Engineer World's Fair (original RPI talk). [youtube.com/watch?v=rmvDxxNubIg](https://www.youtube.com/watch?v=rmvDxxNubIg)
- **"Everything We Got Wrong About Research-Plan-Implement"** — Dex Horthy, Coding Agents Conference (Computer History Museum, March 3 2026). [youtube.com/watch?v=YwZR6tc7qYg](https://www.youtube.com/watch?v=YwZR6tc7qYg)
- **"From RPI to QRSPI"** — Dex Horthy, Coding Agents 2026 (Mountain View, CA). [youtube.com/watch?v=5MWl3eRXVQk](https://www.youtube.com/watch?v=5MWl3eRXVQk)
- **"How to Ship Complex Features 10x Faster with AI Agents"** — Dex Horthy. [youtube.com/watch?v=c630qv03i8g](https://www.youtube.com/watch?v=c630qv03i8g)

### Interviews and articles

- **Heavybit: "What's Missing to Make AI Agents Mainstream?"** — Dex Horthy interview, March 17 2026. Stage count update ("CRISPY / QRSPI"): 8 stages = 5 alignment + 3 execution. [heavybit.com/library/article/whats-missing-to-make-ai-agents-mainstream](https://www.heavybit.com/library/article/whats-missing-to-make-ai-agents-mainstream)
- **Alex Lavaee: "From RPI to QRSPI: Rebuilding the First Structured Workflow for Coding Agents"** — Extensive stage scope notes (design ~200 lines, structure ~2 pages, <40 instructions per stage). [alexlavaee.me/blog/from-rpi-to-qrspi](https://alexlavaee.me/blog/from-rpi-to-qrspi/)
- **Dev Interrupted (Substack): "Dex Horthy on Ralph, RPI, and escaping the Dumb Zone"**. [devinterrupted.substack.com/p/dex-horthy-on-ralph-rpi-and-escaping](https://devinterrupted.substack.com/p/dex-horthy-on-ralph-rpi-and-escaping)
- **HumanLayer blog: "Context-efficient backpressure"**. [humanlayer.dev/blog/context-efficient-backpressure](https://www.humanlayer.dev/blog/context-efficient-backpressure)
- **HumanLayer blog: "Skill Issue: Harness Engineering for Coding Agents"** (cross-references Q15/Q26/Q55 OpenAI harness research).

### Related framework docs

- **12-Factor Agents** — precursor framework cited in ACE-FCA. [hlyr.dev/12fa](https://hlyr.dev/12fa)
- **Sean Grove: "Specs are the new code"** — AI Engineer 2025 grounding talk. [youtube.com/watch?v=8rABwKRsec4](https://www.youtube.com/watch?v=8rABwKRsec4)
- **Stanford study on AI's impact on developer productivity**. [youtube.com/watch?v=tbDDYKRFjhk](https://www.youtube.com/watch?v=tbDDYKRFjhk)

## Known discrepancies with qrspi-plus notes

| Topic | qrspi-plus/docs/qrspi-deep-dive.md says | Newer source says | Source |
|---|---|---|---|
| Stage count | 7 (Q/R/D/S/P/W/I → PR) | 8 (Q/R/D/S/P + Worktree/Implement/PR with PR as its own stage) | Lavaee, Heavybit |
| Design artifact size | not specified | ~200 lines ("brain dump") | Lavaee, Heavybit |
| Structure artifact size | not specified | ~2 pages | Heavybit |
| Instructions-per-stage budget | not specified | <40 per stage (down from 85+ monolith) | Heavybit |
| Alternative name | not mentioned | "CRISPY (technically QRSPI)" per Heavybit interview | Heavybit |

The qrspi-plus plugin already extends the original 7/8-stage framework to 9 steps (adds Goals, Integrate, Test, Replan). See `../qrspi-reference.md` "What qrspi-plus Adds" section for the full mapping.
