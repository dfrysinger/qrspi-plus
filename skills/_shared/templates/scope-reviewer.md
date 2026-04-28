# Scope-Reviewer Template (parameterized)

This template is consumed at dispatch time by the Goals, Design, Phasing, Structure, Plan, and Parallelize skills. Each consumer instantiates the template with a single `{ARTIFACT_TYPE}` value and the dispatched reviewer subagent runs against the corresponding artifact under the rules locked in that skill's `SKILL.md`.

This template defines the schema/contract only. The reviewer-runtime logic that physically loads files, runs greps, and emits findings lives in the consuming skill prompts; this file declares the parameters those prompts must respect.

## Parameters

- **`{ARTIFACT_TYPE}`** — required. One of:
  - `goals`
  - `design`
  - `phasing`
  - `structure`
  - `plan`
  - `parallelize`

No other values are permitted. A dispatch that supplies any other token (or omits the parameter) is malformed and the reviewer must fail closed with a structured-error finding before performing any checks.

## Rules-Loading Procedure

1. Resolve the rules file path: `skills/{ARTIFACT_TYPE}/SKILL.md`.
2. Read the file and locate the heading `## {Skill} OWNS / {Skill} DEFERS` where `{Skill}` is the title-case form of `{ARTIFACT_TYPE}` (e.g. for `goals` the heading is `## Goals OWNS / Goals DEFERS`).
3. Within that H2 section, parse two H3 subsections: the OWNS rules are under `### {Skill} OWNS` (H3, rules the artifact is responsible for); the DEFERS rules are under `### {Skill} DEFERS` (H3, concerns explicitly punted to a later artifact). The literal subheading shapes (parameterized by `{Skill}`) are:

```
### {Skill} OWNS
### {Skill} DEFERS
```
4. Treat the parsed `OWNS` and `DEFERS` lists as the locked rule set for this dispatch. All Checks below run against this rule set.

**Fail-closed malformed cases.** If any of the following is detected, the reviewer MUST abort the checks and emit a single structured-error finding conforming to the M48 5-field schema (see `## Output Contract`). The finding's `change_type` is `correctness`, `severity` is `high`, and `message` names the malformed case in plain language so the user can repair the SKILL.md.

1. **Heading missing entirely.** The file `skills/{ARTIFACT_TYPE}/SKILL.md` does not contain the `## {Skill} OWNS / {Skill} DEFERS` heading at all. The reviewer cannot locate any rule set and must not silently fall back to a default.
2. **`OWNS` subsection missing.** The H2 heading is present but no H3 subsection `### {Skill} OWNS` is present underneath it. The reviewer has no positive-rule set to check the artifact against.
3. **`DEFERS` subsection missing.** The H2 heading is present but no H3 subsection `### {Skill} DEFERS` is present underneath it. The reviewer has no boundary-drift exclusions and cannot run boundary-drift detection.
4. **Both subsections empty.** Both subsections are present but their bodies are empty — no bulleted or numbered enumerated items (prose-only bodies do NOT satisfy this requirement and trigger fail-closed). The rule set is structurally present but semantically empty; running the checks would produce vacuous results.

In all four cases the reviewer reports the malformed condition once, exits, and does NOT attempt partial checks.

## Checks

When the rules-loading procedure succeeds, the reviewer performs three checks against the artifact under review:

1. **Boundary-drift detection.** Scan the artifact for content that matches a `DEFERS` entry from the locked rules. Any paragraph asserting a concern the artifact has explicitly deferred is a finding. (Example: a `goals` artifact prescribing a file layout — file layout is owned by `structure`, deferred by `goals`.)
2. **Scope-compliance per locked rules.** Every paragraph (or list item carrying a load-bearing claim) in the artifact must trace to an `OWNS` rule. Paragraphs that do not trace to any `OWNS` entry are findings — the artifact is making a commitment outside its declared scope.
3. **U14 boundary-drift signal.** Apply the U14 lint pattern: flag artifacts that contain skill-implementation jargon (e.g. specific tool names, hook syntax, subagent dispatch verbs) when the artifact's `{ARTIFACT_TYPE}` does not own implementation detail at that layer. The U14 signal is a boundary-drift sub-check focused on lexical leakage from later pipeline stages into earlier-stage artifacts.

## Output Contract

Every finding emitted by this reviewer — including the fail-closed structured-error findings from the rules-loading procedure — MUST conform to the M48 reviewer-finding schema as defined in `skills/_shared/reviewer-boilerplate.md` `## Finding Schema`. The five required fields are:

- `finding_id`
- `severity`
- `change_type` — required tag, one of `style`, `clarity`, `correctness`, `scope`, `intent` per the change-type classifier.
- `message`
- `referenced_files`

A finding that omits `change_type` (or any other field) is malformed and will not be accepted by the review-loop pause gate.

## Embedded Boilerplate

This template embeds `skills/_shared/reviewer-boilerplate.md` verbatim at dispatch time. The consuming skill's dispatch logic (wired by Task 12) concatenates the boilerplate file into the rendered reviewer prompt so the dispatched subagent sees the finding schema, change-type classifier, and disagreement-valid framing inline. This file references the boilerplate by path; it does NOT copy its contents.

## Per-`{ARTIFACT_TYPE}` Gated Sections

The block matching the dispatched `{ARTIFACT_TYPE}` value renders into the reviewer prompt; the others are omitted.

### When `{ARTIFACT_TYPE} == goals`

Load the rule input from `skills/goals/SKILL.md` `## Goals OWNS / Goals DEFERS`. The reviewer checks `goals.md` against those rules.

### When `{ARTIFACT_TYPE} == design`

Load the rule input from `skills/design/SKILL.md` `## Design OWNS / Design DEFERS`. The reviewer checks `design.md` against those rules.

### When `{ARTIFACT_TYPE} == phasing`

Load the rule input from `skills/phasing/SKILL.md` `## Phasing OWNS / Phasing DEFERS`. The reviewer checks the phasing artifact against those rules.

### When `{ARTIFACT_TYPE} == structure`

Load the rule input from `skills/structure/SKILL.md` `## Structure OWNS / Structure DEFERS`. The reviewer checks `structure.md` against those rules.

### When `{ARTIFACT_TYPE} == plan`

Load the rule input from `skills/plan/SKILL.md` `## Plan OWNS / Plan DEFERS`. The reviewer checks `plan.md` against those rules.

### When `{ARTIFACT_TYPE} == parallelize`

Load the rule input from `skills/parallelize/SKILL.md` `## Parallelize OWNS / Parallelize DEFERS`. The reviewer checks `parallelization.md` against those rules.
