---
finding_id: F04
severity: medium
change_type: scope
referenced_files:
  - docs/qrspi/2026-05-30-v072-release/questions.md
  - docs/qrspi/2026-05-30-v072-release/goals.md
artifact: questions
---

# Missing Area — G13 (Out-of-Enum `change_type` Values) Is Not Covered by Q2

## Goal Not Covered

**G13** — `change_type` enum drift: reviewer subagents occasionally emit `change_type` values that are free-text strings outside the documented enum (`security | correctness | clarity | style`) — e.g., "Test comment inaccuracy / overstated mutation-resistance claim", "Defense-in-depth / multi-condition mutation testing." The verifier-fan-in threshold logic looks up the threshold by enum value; an out-of-enum lookup returns no match and the orchestrator implicitly keeps the finding regardless of confidence score.

## Why Q2 Does Not Cover This

Q2 asks: "Do the per-reviewer agent files… explicitly require `change_type:` in per-finding frontmatter **by that name**, and do they enumerate the **allowed values**?"

Q2's focus is on **field-name correctness** (`change_type:` vs. `category:`), which is the G8 question. G13 is a distinct problem: the field is correctly named `change_type:`, but the **value** is a free-text string rather than an enum member. These are orthogonal defects:

- G8 (Q2): reviewer writes `category: correctness` → field name wrong, value happens to be valid.
- G13 (not asked): reviewer writes `change_type: Test comment inaccuracy / overstated mutation-resistance claim` → field name correct, value is out-of-enum.

Research needs to characterize how the verifier-fan-in threshold logic currently behaves on out-of-enum input — does it silently keep, silently drop, error, or have no case at all? It also needs to find where (if anywhere) the allowed enum is declared in SKILL prose and whether the allowed values match across `reviewer-protocol/SKILL.md`, `using-qrspi/SKILL.md`, and the agent files.

## Suggested Addition

`[codebase]`:
> "When a reviewer writes a `change_type:` value that is not a member of the documented enum (e.g., a free-text phrase like 'Test comment inaccuracy'), how does the verifier filter logic in `skills/using-qrspi/SKILL.md` currently handle the lookup? Does the threshold table have an else/default branch, or does an unknown value result in a silent keep, silent drop, or parse error? Where is the canonical allowed-values enum declared across `reviewer-protocol/SKILL.md`, `using-qrspi/SKILL.md`, and `implement/SKILL.md` — and are all three declarations consistent?"
