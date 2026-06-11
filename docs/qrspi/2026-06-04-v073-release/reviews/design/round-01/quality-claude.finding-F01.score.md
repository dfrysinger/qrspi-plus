---
verifier_status: passed
score: 85
actual_model: unknown
defect_class: incorrect-command
---

Cite Check: The finding references design.md and quotes
`git log <phase-base>..HEAD --author='!qrspi-' --oneline`. This string
appears verbatim at design.md line 319 (G5 solution (b) descriptive
prose) and line 328 (the prose-design block for
`skills/{integrate,test}/SKILL.md § Process Steps`). Both citations
resolve.

Technical claim: git's `--author` flag accepts a POSIX/extended regex
that is matched against the author identity; it does NOT interpret a
leading `!` as a negation operator. With `--author='!qrspi-'`, git
literally searches for author strings containing `!qrspi-`, which no
real commit will ever have, so the command produces empty output
unconditionally. Git's idiomatic negation mechanisms are
`--invert-grep` (paired with `--author`/`--grep`, but `--invert-grep`
only inverts `--grep`, not `--author`, in current git) or
`--perl-regexp --author='^(?!qrspi-)'`. The finding's proposed
`awk` post-filter pipeline is a correct alternative.

Impact: The G5 observability hook is specified as verbatim
prose-design that the implementer is instructed to carry into
`skills/{integrate,test}/SKILL.md` and into
`scripts/orchestration-boundary-check.sh`. If implemented as written,
the non-subagent-commit detection leg silently returns clean every
run, defeating one of the two observability dimensions G5 is built to
provide. Because design specifies "verbatim prose-design" blocks,
this is a load-bearing correctness defect, not a stylistic nit —
the implementer is expected to copy the broken command exactly.

The finding is well-grounded, identifies a concrete defect, and
proposes a workable fix. The only reason this is not 100 is that an
attentive implementer or Plan-step reviewer might still catch it
downstream; nonetheless, design-stage correction is the right place
to fix it.
