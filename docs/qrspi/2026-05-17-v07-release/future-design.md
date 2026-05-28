---
status: approved
managed_by: phasing
source: design-round-18-deferrals + v07-phasing-deferrals
---

# Future design entries

Design-level entries carried out of v0.7. Two distinct categories live here, each with different semantics:

- **Category A — Future-release deferrals.** Items that v0.7 intentionally does not deliver and that are queued for a later release. Today this category holds G16 only.
- **Category B — v0.7 known issues accepted at the round-18 disposition gate.** Design-quality polish items that surfaced during Design's round-18 review loop. The user explicitly chose not to fix them in v0.7 (per the user-approved targeted-fix path); they are recorded here for future-release pickup or accept-as-is. Today this category holds FD-01..FD-04.

## Category A — Future-release deferrals

### G16 — Wave nesting in parallelization.md

**Source:** v0.7 Design round-14 disposition gate (user-approved deferral); reaffirmed by Phasing.

**Issue:** `parallelization.md` currently presents a flat Branch Map table and a separate narrative Execution Order section. Readers must cross-reference both to understand dispatch grouping, shared base, and stage commits. A presentation that nests tasks under waves would make the artifact scan in one glance.

**v0.7 deferral reason:** the current flat shape is readable enough and is not causing incorrect dispatch. Nesting tasks under waves is a presentation refactor that also requires reviewer and example updates (Plan-reviewer template that lints Branch Map shape, Parallelize worked examples for good and bad artifacts). Not worth the v0.7 cost.

**Future-design resolution to weigh when promoted:**
- The future-goal source proposes nesting tasks under each wave while keeping Mermaid and Stage Commits as separate artifact elements.
- The proposed presentation depends on earlier vocabulary cleanup — in v0.7 that vocabulary cleanup ships under G9 (Parallelize reviewer vocabulary alignment + multi-stage suffix grammar documentation), so by the time G16 is promoted the vocabulary substrate is already in place.
- Test debt: update the Plan-reviewer template that lints Branch Map shape, and update the Parallelize worked examples (good and bad artifacts).
- Treat as a bounded artifact-contract update, not a prose-only edit, because it touches reviewer expectations and examples.

**Pointers:** see `future-goals.md` (G16) and `future-research-summary.md` (Q21 finding pointers) for the full deferred bundle.

## Category B — v0.7 known issues accepted at round-18 gate

### FD-01 — G1 cross-cutting test uses non-schema-legal `cheap` alias

**Source:** quality-codex R18-F02 (medium, correctness)

**Issue:** The G1 cross-cutting routing test asserts a configuration shape `model_routing.research-collator: cheap` where `cheap` is a symbolic alias. The v0.7 G1 schema requires `model_routing:` entries to be `{ provider: <name>, model: <id> }` mappings. `cheap` is not a legal value in that schema, so the test as written would have downstream code reject the configuration it is supposed to validate.

**Two future-design resolutions to weigh:**
- (a) Rewrite the test to use a literal `{provider, model}` mapping. Loses the readability the alias provided.
- (b) Add a symbolic alias layer to the schema: `model_routing:` may also accept string values that resolve via a `model_aliases:` block (e.g., `cheap → {provider: deepseek, model: deepseek-v3}`). Restores the test's readability and gives users a way to write succinct configs. Requires its own design contract and tests.

Recommended: (b) if the cost of the alias layer is small; otherwise (a).

### FD-02 — G17 Option-A-load-bearing test fixture is not bash-3.2-incompatible

**Source:** quality-codex R18-F03 (medium, correctness)

**Issue:** The G17 test bullet for "Option B grep ban-list doesn't catch this; Option A docker job does" uses `${!array[@]}` as the bash-4-only example. This construct is valid in bash 3.2+ (indexed-array key expansion has been in bash since 3.0). The test fixture does not actually demonstrate the distinction it claims.

**Future-design resolution:** Pick a real bash-4-only construct that is also absent from Option B's ban-list. Candidates: `declare -A` (already on ban-list), `mapfile` (already on ban-list), `${var,,}` (already on ban-list), `${var^^}` (already on ban-list), `coproc` (already on ban-list), `wait -n` (already on ban-list). The ban-list may already be exhaustive enough that no non-listed bash-4 construct exists to demonstrate the distinction — in which case the test should be rewritten to assert the contrapositive: "Option B's ban-list is the load-bearing list of forbidden constructs; Option A is a backstop that re-validates the ban-list is current by execution test against a future bash-4 construct authors add to the ban-list."

### FD-03 — G3 cross-cutting test omits N=2 boundary case

**Source:** quality-claude R18-F03 (low, clarity)

**Issue:** The G3 cross-cutting test for Plan post-approval split enumerates N=1 (main chat) and N≥3 (sub-subagent dispatch), but the N=2 case (which is also inside the main-chat carve-out per the threshold) is not explicitly tested in the cross-cutting summary.

**Future-design resolution:** Add an N=2 bullet to the cross-cutting test enumeration. One sentence.

### FD-04 — G3 "~150-200 lines" estimate attribution

**Source:** quality-claude R18-F04 (low, correctness)

**Issue:** G3's task-spec size estimate "~150-200 lines" is attributed to Q6/Q7 task-file template structure, but Q6/Q7 describes the template field structure only — not observed or estimated sizes. Same class of attribution polish as R17-F05.

**Future-design resolution:** Rephrase to separate the Q6/Q7-backed fact (template field structure) from the design-time estimate (typical observed task-spec body size). Five-word fix.

## Status

draft → handed off to Phasing for absorption into a future phase or as future-goal candidates.
