# Goals — `goals.md` template (conformance contract)

The subagent invoked by the Goals skill's Artifact Synthesis step produces `goals.md` per the template below. The template is the **conformance contract**: required sections and per-goal subsections are enumerated; claim-before-evidence ordering is mandated; scannable bullets are required; "be concise" instructions are forbidden (synthesize the substance, do not truncate it).

```markdown
---
status: draft
---

# Goals: {Project/Feature Name}

## Purpose

{1-2 sentences leading with the claim — what is being built and the problem space it addresses. First sentence ≤250 chars, ends with a period.}

## Constraints

- {Environmental constraint 1 — tech stack, compatibility, performance budget, deployment, timeline}
- {Environmental constraint 2}
- ...

## Goals

### G1 — {Short goal name}

- **type:** `known-fix` | `exploratory`

#### Problem

{The problem this goal addresses, framed as a problem (not a solution). One paragraph; lead with the claim. ≤150 words, ≤8 rendered lines per paragraph.}

#### Why we care

{Why this problem matters now — impact, blast radius, who is affected, what breaks if it stays. One paragraph.}

#### What we know so far

{Prior attempts, partial diagnoses, observed signals, and any solution **candidates Design should weigh** (framed as possibilities, not commitments). Use bullets when enumerating candidates so Design can see them at a glance.}

- {Candidate A — Design should weigh}
- {Candidate B — Design should weigh}
- ...

{Repeat the `### GN — ...` block per goal. Each goal has exactly the three subsections — Problem / Why we care / What we know so far — no others. No per-goal `Acceptance Criteria`, `Out of Scope`, or solution-definition subsection.}

## Cross-Cutting Notes

{OPTIONAL — include only when relationships between goals genuinely cross-cut. Omit the entire section otherwise. Do NOT use this section as a back door for acceptance criteria, file maps, or phasing.}
```
