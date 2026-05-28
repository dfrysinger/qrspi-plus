---
status: approved
managed_by: phasing
source: v07-release-deferrals
---

# Future goals

Goals deferred from the v0.7 release. Each entry carries enough context that a future Goals invocation can promote it cleanly.

## Formal

### G16 — Wave nesting in parallelization.md

- **type:** `known-fix`
- **deferred at:** v0.7 round-14 disposition gate (user-approved)

#### Problem
`parallelization.md` currently presents a flat Branch Map table and a separate narrative Execution Order section. Readers must cross-reference the table and the wave narrative to understand which tasks dispatch together, what base they share, and how stage commits fit into the sequence. This makes the artifact harder to scan than it needs to be for humans and reviewers.

#### Why we care
Parallelize is the handoff point where execution ordering must be unambiguous. A presentation that nests tasks under waves would make dispatch grouping, task identity, branch naming, shared base, and touched files visible in one glance. Better shape reduces reader friction and reviewer ambiguity even if the underlying schedule is already correct.

#### What we know so far
- The future-goal source proposes nesting tasks under each wave while keeping Mermaid and Stage Commits as separate artifact elements; Design should weigh the final artifact shape.
- The proposed presentation depends on earlier vocabulary cleanup, referenced as F-22 in the source issue, because wave nesting should use canonical terminology.
- Test debt includes updating the Plan-reviewer template that lints Branch Map shape and the Parallelize worked examples for good and bad artifacts.
- The change is primarily presentation, but it touches reviewer expectations and examples, so it should be handled as a bounded artifact-contract update rather than a prose-only edit.

#### v0.7 deferral reason
Per v0.7 Design (round-14 disposition gate, user-approved): the current flat `parallelization.md` shape is readable enough and is not causing incorrect dispatch. Nesting tasks under waves would be a presentation refactor that also requires reviewer and example updates. Not worth the v0.7 cost.

## Ideas

(none captured yet)
