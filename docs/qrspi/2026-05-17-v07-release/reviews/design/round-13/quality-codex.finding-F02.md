---
finding_id: R13-F02
severity: high
change_type: correctness
referenced_files: [/Users/dfrysinger/Library/CloudStorage/Dropbox/claude-workspace/agent-bravo/docs/qrspi/2026-05-17-v07-release/design.md:L485-L500]
artifact: design
round: 13
reviewer: quality-codex
---

G10's human gate does not actually validate the motivating failure case for binary references. The problem statement is specifically about wrong prototype PNGs passing visual review, but the proposed Implement behavior says to display text inline and only show the file path for binary artifacts. A file path is not enough for the user to judge whether a PNG, PDF, or other binary reference is correct, so the gate would still allow an invalid binary reference to propagate. Fix: require the gate to render or otherwise present binary reference artifacts themselves for human inspection (for example via image/PDF preview or an equivalent explicit review surface), not merely print their path.
