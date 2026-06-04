# Resolver acceptance fixture — include-cycle rejection.
#
# `a.md` includes `b.md`; `b.md` includes `a.md`. Running the build
# pipeline (the resolver in `tools/build-plugin.mjs`) against a source
# tree that contains this fixture pair MUST fail non-zero with the full
# cycle printed (both `a.md` and `b.md` paths appearing in the
# diagnostic, plus a `cycle` / `circular` reason).
#
# Mirrors task-39 §"Definition of done" bullet on cycle detection and
# §"Test expectations" "Acceptance fixtures cover [...] a deliberate
# include-cycle failure with the required diagnostics".
