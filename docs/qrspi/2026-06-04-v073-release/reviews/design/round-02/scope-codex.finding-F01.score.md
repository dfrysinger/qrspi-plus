---
verifier_status: passed
score: 65
actual_model: unknown
defect_class: altitude-violation
---

Cite Check: `referenced_files` is a bare path; file exists. No specific quoted strings or named anchors to verify. Passes.

Substantive evaluation: The Design SKILL's Altitude Sub-Rule A explicitly forbids "Directory trees or where files live within the repo," "Inter-file wiring (what sources / imports / requires what)," and "Function or method signatures" — and gives a worked-example showing "`bar.sh` lives at `scripts/bar.sh` and sources `lib/baz.sh`" as NOT permitted. The artifact under review repeatedly does exactly this:

- CD-1 commits to the path `scripts/upstream-paths.sh` (directory placement, not just identity) and prescribes the exact CLI signature `--step <step>` with stdin/stdout shape.
- CD-2 specifies the CLI signature `scripts/review-prep.sh --step <step> --round <N> --artifact-dir <path>`, the inter-file wiring "invoked internally by `scripts/dispatch-agent.sh`," and output locations `<artifact-dir>/reviews/<step>/round-NN.*`.
- Acceptance criteria specify test-file directory placement (`tests/lint/` or `tests/unit/`) and exact grep/bats command shapes.

These are real altitude crossings against the documented Design DEFERS contract, and the finding's prescription (keep outcomes/contracts, relax file-placement and executable-mechanic mandates) is the appropriate remediation per the SKILL's Sub-Rule A altitude test.

Two factors hold this short of the top anchor: (1) the finding is broad-stroke ("most sections") without per-block citations, making it more of a rescoping directive than a precise defect list; (2) Sub-Rule A does permit naming artifacts when "naming IS the decision," so a non-trivial subset of the script-naming content may survive a tightening pass — the design will need judgment, not wholesale removal. Still a real, SKILL-grounded altitude issue worth high-confidence action.
