---
round: 16
artifact: design
status: fixing
---

# Round 16 dispositions

## Findings inventory

- quality-claude: 2 findings (high=1, medium=1)
- scope-claude: 0 (clean — 14th consecutive)
- quality-codex: 2 findings (high=2)
- scope-codex: 0 (clean — 13th consecutive)

Total: 4 findings, 3 HIGH. No intent. All correctness or clarity. All accept.

Trend: 10 → 3 → 5 → 4 → 2 → 4 → 3 → 4 → 6 → 1 → 2 → 3 → 6 → 7 → 5 → 4. The 3 HIGH this round each name a real design gap (citation_density_floor unevaluable at dispatch time; RED gate criterion too strict; Option B grep ban-list cannot be sole bash-3.2 gate) — these are fundamental design corrections, not iteration churn. Scope topology rock-stable at 27 consecutive clean rounds combined.

## R16-F01 quality-claude (HIGH, correctness) — accept. citation_density_floor unevaluable at dispatch time

The G1 routing schema declares `citation_density_floor` as a pre-dispatch predicate evaluated against task spec input, but citation density is a property of the research specialist's OUTPUT — does not exist until after the dispatch decision is made. The predicate as currently framed has no static input.

**Fix:** Two design-level alternatives; choose the latter (it preserves the routing-schema intent without inventing a fictional pre-dispatch input):

Reframe `citation_density_floor` as a **post-dispatch output validator**, not a pre-dispatch routing predicate. Update G1 routing schema:
- The legal predicate vocabulary becomes: `<none — citation_density_floor was the only listed key but it is not a pre-dispatch predicate>`.
- Drop `citation_density_floor` from the "initial legal predicate keys" list entirely. Update the forward-looking note to: "The v0.7 conditional-routing vocabulary is empty; the schema supports `when:` predicate clauses but no concrete predicate is in scope. Predicates may be added by future goals alongside dispatch-site consumers."

Update G5 dispatcher tolerance matrix row for `qrspi-research-specialist`:
- Replace "Cheap-model eligible (with citation-density floor)" with "Cheap-model eligible (with post-output citation-density validation)".
- Reasoning cell: "Research specialists run on cheap models; their output is post-validated for citation density. If post-validation fails (citation density below threshold), the dispatcher re-runs the specialist on the trusted model. Pre-dispatch routing is unconditional cheap-model dispatch."
- Add design-level test bullet: cheap-model research-specialist output that fails the citation-density floor triggers a trusted-model re-run; output that meets the floor proceeds.

This collapses G1's "conditional routing" surface to **unconditional** in v0.7 (since the only predicate was citation_density_floor, and it's not a predicate). G1 still owns the additive `model_role:` schema and post-output validators are part of G5's research-specialist contract, not G1's conditional-routing surface.

## R16-F01 quality-codex (HIGH, correctness) — accept. G6 RED gate too strict

G6 says the pre-implementer gate pauses if "any pre-implementation test passes" — but for incremental tasks adding assertions around existing behavior, some may legitimately pass before implementation. Current contract blocks valid mixed-result test suites.

**Fix:** In G6, rewrite the RED-gate criterion from "no test passes" to two-part predicate:
1. **At least one task-relevant assertion FAILS** for the missing/changed behavior the task targets. (Establishes RED on the intended change.)
2. **No test fails for infrastructure reasons** (syntax error, import error, fixture setup failure — these are caught by the per-framework adapter from round 9's fix).

Pre-passing assertions (covering behavior the task does NOT change) are explicitly permitted and do not pause the gate. They are reviewed at code-review time for vacuousness only if the overall suite has zero failing assertions.

Update G6 design-level test bullets:
- New gate test: a test suite with 3 assertions where 2 pre-pass (covering unchanged behavior) and 1 pre-fails (covering the targeted change) passes the gate.
- Existing test bullet (suite where all assertions pre-pass) updated to: "pauses on vacuous-RED — no assertion fails on the targeted behavior."

## R16-F02 quality-codex (HIGH, correctness) — accept. G17 Option B insufficient as sole bash-3.2 gate

G17 Option B (grep ban-list for `mapfile`, `declare -A`, etc.) can only catch enumerated constructs. New bash-4+ syntax outside the list passes silently. Cannot be a "true bash-3.2 gate" on its own.

**Fix:** In G17, restate the verification stack:
- **Option A (macos-latest job, `bash --posix -n` on system bash 3.2.57): LOAD-BEARING.** Real parser check; catches any unsupported syntax bash 3.2 cannot parse, including constructs not enumerated.
- **Option B (ubuntu-latest job, grep ban-list): SUPPLEMENTAL fast-fail.** Catches the most common bash-4+ constructs early in CI so authors get a fast signal before the macos job runs. NOT the load-bearing gate.
- Both layers run; Option A is the gate. If Option A fails, CI fails regardless of Option B status. If Option B catches a known bad construct early, Option A would also catch it.

Update related G17 test bullet: a file using a bash-4+ construct NOT on Option B's ban-list (e.g., `${!array[@]}` introduced as an example) is caught by Option A even though Option B does not flag it.

## R16-F02 quality-claude (medium, clarity) — accept. G11 wave_context schema underspecified

G11 introduces `wave_context:` companion parameter but does not specify format, what findings are included, how the visual-fidelity reviewer agent body interprets it, or wrapping convention.

**Fix:** Under G11's wave-aware reviewer brief subsection, add a "wave_context schema" sub-block:
- **Wrapping:** Same convention as other companion parameters — wrapped between `<<<UNTRUSTED-ARTIFACT-START id=wave_context>>>` and `<<<UNTRUSTED-ARTIFACT-END id=wave_context>>>` markers.
- **Contents:** Markdown body containing (a) the wave identifier (e.g., "Wave 2 — UI tasks"); (b) per-task entries within the wave, each showing task ID, task name, allowed_files glob, and (if available) the post-implementation visual-fidelity reviewer findings from sibling tasks in the same wave.
- **Reviewer agent interpretation:** the visual-fidelity reviewer reads `wave_context:` to understand cross-task visual consistency expectations within the wave (e.g., spacing, color tokens, typography) so its findings can cite "sibling task X already established color token Y" rather than redundantly proposing the same change.
- **Format owner:** Plan/Implement own the literal wave_context assembly; Design owns the wrapping convention + content categories.

Update G11 test bullet for wave_context presence: assertion now checks both that the parameter exists AND that its body contains the required sections (wave identifier, per-task entries).

## Fix dispatch plan

Single fix subagent. 4 accepts. All in design.md.

## Status

draft → fixing → re-review round 17.
