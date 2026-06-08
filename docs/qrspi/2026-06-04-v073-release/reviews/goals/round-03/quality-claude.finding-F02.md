---
finding_id: R3-F02
severity: medium
change_type: correctness
referenced_files: ["docs/qrspi/2026-06-04-v073-release/goals.md:L205-L207"]
artifact: goals
round: 3
reviewer: quality-claude
---

G9 fails the No-others check: it carries a fourth subsection `#### Acceptance approach` (L205–L207) beyond the three required ones. The check requires exactly `Problem`, `Why we care`, and `What we know so far` — any additional subsection is a finding even when all three required ones are present.

The content of `#### Acceptance approach` ("A future release can bump the version by editing exactly one file. Acceptance evidence: a single-file edit followed by `node tools/build-plugin.mjs`...") is acceptance-criteria framing, not exploratory problem context. It prescribes an outcome and a verification script rather than surfacing something Design needs to weigh. This is the pattern the goals schema explicitly guards against (`Acceptance Criteria` is listed as an example non-allowed subsection).

Fix: remove the `#### Acceptance approach` subsection. If the acceptance evidence is useful context, fold the concrete measurable constraint ("bumping the version requires editing exactly one file, verifiable by running the build script") into the `#### What we know so far` body as a candidate acceptance approach Design should confirm — framed as a candidate, not a commitment.
