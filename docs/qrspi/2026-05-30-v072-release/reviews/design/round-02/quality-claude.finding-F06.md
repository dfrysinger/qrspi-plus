---
finding_id: R2-F06
severity: low
change_type: correctness
artifact: design
round: 2
reviewer: quality-claude
referenced_files:
  - docs/qrspi/2026-05-30-v072-release/design.md
  - skills/reviewer-protocol/SKILL.md
---

## G6 acceptance — does not lint-check stale script/file names in `reviewer-protocol/SKILL.md` Delivery section

**Location:** `design.md` L1282 (G6 § Acceptance), and L1241 (G6 "emission-agnostic core only" content spec)

**Problem.** The current `skills/reviewer-protocol/SKILL.md` Delivery section (L10–14 in the pre-v0.7.2 file) describes how the skill is loaded for Codex reviewer dispatches:

> "**Codex reviewer dispatches** load it via `scripts/run-codex-review.sh` (the canonical reviewer dispatch wrapper). The wrapper concatenates the frontmatter-stripped reviewer-protocol body, the named agent body (also frontmatter-stripped), the **Codex emission override** (`skills/reviewer-protocol/codex-emission-override.md`), and the assembled dispatch params, then pipes the result to `scripts/codex-companion-bg.sh launch` on stdin. The override appears AFTER the agent body so it supersedes the agent body's 'Use the Write tool' directive — Codex runs in a read-only sandbox and must emit findings on stdout for the orchestrator's `scripts/codex-finding-splitter.sh` to materialize."

After CD-1 and G6 ship, three names in this paragraph are stale:
- `scripts/run-codex-review.sh` → renamed to `dispatch-agent.sh` (CD-1); third-party routing now via `dispatch-companion.sh`
- `skills/reviewer-protocol/codex-emission-override.md` → renamed to `third-party-emission.md` (CD-1 + G6)
- `scripts/codex-finding-splitter.sh` → renamed to `third-party-finding-splitter.sh` (CD-1)

G6's post-G6 SKILL.md content spec (L1241) describes the file as "emission-agnostic core only. Contains: 5-field finding schema, change-type classifier, untrusted-data handling, phase routing, dispatch contract, untrusted-scope-hint markers." The Delivery section is not in this list, leaving it ambiguous whether the section is removed or updated in G6.

G6's acceptance criterion (L1282) lints for `Write tool` and `stdout` strings in emission-contract context. The Delivery section contains "Use the Write tool" (which G6's grep **would** catch, requiring an update). However, once that phrase is removed, the stale file names — `run-codex-review.sh`, `codex-emission-override.md`, `codex-finding-splitter.sh` — are not covered by any acceptance criterion lint. No grep for these names appears in CD-1's acceptance (L201–211) or G6's acceptance (L1282–1288).

**Impact.** After G6's acceptance-criterion-driven update removes "Use the Write tool" from the Delivery section, an implementer might leave the file/script name references intact (they pass G6's grep). The Delivery section would describe the dispatch architecture using pre-rename names, confusing orchestrators that reference it to understand how third-party reviewers load the skill.

**Suggested fix.** Add a lint check to G6's acceptance (or CD-1's acceptance) that verifies the pre-rename names no longer appear in `skills/reviewer-protocol/SKILL.md`:
```
grep -E 'run-codex-review|codex-emission-override|codex-finding-splitter' skills/reviewer-protocol/SKILL.md
```
returns empty. Alternatively, if the Delivery section is removed entirely as part of G6's "emission-agnostic core only" redesign, state that explicitly in the G6 deliverables to make the implementer's task unambiguous.
