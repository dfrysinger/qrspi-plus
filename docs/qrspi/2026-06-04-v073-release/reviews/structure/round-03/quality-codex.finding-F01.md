---
artifact: structure
reviewer_tag: quality-codex
change_type: correctness
---

# Finding: G5 per-phase phase-base source is not structurally defined for integration/test

`structure.md` now says `scripts/orchestration-boundary-check.sh` resolves `<phase-base>` from a per-phase source, with `integration` and `test` anchors "recorded at phase start" and concrete read paths left to Plan (lines 326-338; also file-map line 88). But Structure never defines the corresponding files/modules, write-site, or read contract for those integration/test anchors. The only concrete anchor path in the structure is the G6 Implement wave sidecar (`reviews/implement/wave-state/wave-WN-expected-parents.txt`, lines 384-389), and the architecture diagram still shows OBC reading the implement-only `SIDECAR` node even after relabeling it "per-phase source" (lines 546-575).

This leaves the G5 script interface incomplete for `--phase integration` and `--phase test`: an implementer cannot know what path to read or what component creates it, and the unified diagram misrepresents non-Implement flows as reading an Implement-only sidecar.

**Expected fix:** Add concrete Structure-owned anchor components/paths for each non-Implement phase, specify which SKILL/script records them and when, define the read contract in the OBC interface, and update the diagram so OBC reads distinct per-phase anchor nodes instead of the Implement wave sidecar for all phases.
