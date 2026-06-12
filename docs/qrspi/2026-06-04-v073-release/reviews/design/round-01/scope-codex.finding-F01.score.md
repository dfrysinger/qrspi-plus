---
verifier_status: passed
score: 30
actual_model: unknown
defect_class: altitude-mismatch
---

The finding cites real text in design.md at the indicated ranges, but largely
mischaracterizes the Design skill's DEFERS contract. Sub-Rule B
(Prose-as-Decision) in `skills/design/SKILL.md` § L120-L194 explicitly *requires*
verbatim authoring of prompt prose for target SKILL.md / agent files, marked
with `<!-- prose-design: <target file> § <section> -->`. The multi-line shell
snippets the finding flags (e.g., `git status --porcelain` at L327, `git log
... --author='!qrspi-'` at L328, `git diff "$(cat reviews/...)"` at L428) all
appear inside `prose-design` blocks targeting `skills/{integrate,test}/SKILL.md`
or `skills/using-qrspi/SKILL.md`. Sub-Rule B's worked-examples table
specifically lists "Skill prose rule" and "Reviewer protocol rubric" as
verbatim-by-design, and the Sub-Rule A worked example permits "Rename `foo.sh` →
`bar.sh`" with purpose + behavior. CLI flag enumeration (`--step --round
--artifact-dir`) is borderline but consistent with "script identity + behavior."

There is a narrow, defensible kernel: concrete bats test-file paths
(`tests/lint/test-design-absorption-marker-set.bats` at L219, L236) and the
acceptance criteria that bind specific tests to specific paths arguably belong
to Structure under Sub-Rule A's prohibition on directory trees. But the finding
generalizes from that narrow miss to "the artifact crosses Design DEFERS
boundaries" across four large ranges, treating Sub-Rule-B-authorized
verbatim prose as if it were Sub-Rule-A layout commitment. The severity:high
framing overstates the actual defect.

Score 30: real but small concern presented in over-broad form that ignores the
prose-design verbatim allowance the design skill itself mandates.
