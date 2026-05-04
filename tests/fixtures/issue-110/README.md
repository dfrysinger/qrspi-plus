# Issue #110 smoke-test fixture

This fixture exercises the new agent files added in commit `733926d`
(`feat(agents): #110 add 37 agent files + structural CI tests`).
It contains a deliberate boundary violation that is detectable **only** by a
scope-reviewer with access to the OWNS/DEFERS rules.

## Fixture artifact: `goals.md`

`goals.md` contains a goal (G2) whose "What we know so far" body smuggles
implementation language: it prescribes a concrete algorithm (`token-bucket`)
with exact TypeScript type signatures
(`Map<clientId, TokenBucket>`, `TokenBucket = { tokens: number; lastRefill: number }`)
and a concrete arithmetic formula for refilling.

**Violated clause** (`skills/goals/owns-defers.md`, Goals DEFERS section):

> "Implementation logic, function signatures, assertion text"
> → Structure / Plan / Implement

Goals may present solution IDEAS framed as candidates for Design to weigh
(Goals OWNS: "Solution candidates as possibilities — never as commitments").
G2 crosses that line by prescribing a complete implementation recipe, not a
candidate: it specifies the data structure, field names, and refill formula —
decisions that belong in Plan or Implement.

A well-formed G2 "What we know so far" would say something like:
"A sliding-window or token-bucket counter is a common approach; Design should
weigh tradeoffs between in-process maps and a shared cache."

## Expected smoke results

### `qrspi-goals-reviewer` (quality, no scope)

Expected: **ZERO scope findings** on G2's implementation language.

The quality reviewer has no access to `skills/goals/owns-defers.md`. It
evaluates artifact quality (solutions-as-possibilities framing, goal-type
field, required subsections, etc.) and may emit **quality** findings (e.g.
that G2's "What we know so far" reads as a commitment rather than a
candidate — a clarity or correctness finding). It must NOT emit a `scope`
finding citing the DEFERS clause, because it never reads that file.

### `qrspi-goals-scope-reviewer` (scope, Step-1 Read of owns-defers.md)

Expected: **ONE scope finding** on G2 citing the violated DEFERS clause.

The finding must:
- Have `change_type: scope` (or `intent` if the reviewer escalates).
- Quote or directly reference the violated clause:
  `"Implementation logic, function signatures, assertion text → Structure / Plan / Implement"`
- Identify G2's "What we know so far" as the locus of the violation.
- NOT flag G1 (G1 is clean: its "What we know so far" frames a 429 response
  as a candidate for Design to weigh).

## How to run the smoke test live

From a real QRSPI session with the new agents installed
(branch `qrspi-echo/issue-110-subagents-in-agent-files`, agents wired into
the Claude Code runtime via `.claude/agents/` or user-level agents):

```
Agent({
  subagent_type: "qrspi-goals-reviewer",
  prompt: "<wrapped fixture body + output path + round + reviewer_tag>",
  model: "sonnet"
})

Agent({
  subagent_type: "qrspi-goals-scope-reviewer",
  prompt: "<wrapped fixture body + output path + round + reviewer_tag>",
  model: "sonnet"
})
```

Output paths (create `reviews/goals/` if absent):
- `tests/fixtures/issue-110/reviews/goals/round-01-claude.md` — quality reviewer output
- `tests/fixtures/issue-110/reviews/goals/round-01-scope-claude.md` — scope reviewer output

The `artifact_body` passed to each agent is the full text of
`tests/fixtures/issue-110/goals.md`. Wrap it with the standard
`<<<UNTRUSTED-ARTIFACT-START id=goals>>>` / `<<<UNTRUSTED-ARTIFACT-END id=goals>>>`
markers per the reviewer-protocol skill.

## Pass / fail criteria

**PASS:** Scope reviewer emits exactly one scope finding on G2 citing the
DEFERS clause `"Implementation logic, function signatures, assertion text"`.
Quality reviewer emits zero scope findings.

**FAIL:** Scope reviewer emits no OWNS/DEFERS-shaped finding (i.e. the
Step-1 Read of `skills/goals/owns-defers.md` did not produce usable context).

## If the smoke test FAILS

Execute the mode-switch contingency per plan Task 5 step 6b:
rewrite the 7 scope-reviewer bodies to **inline** OWNS/DEFERS verbatim (no
Step-1 Read), swap the bats test
(`test-scope-reviewer-step1-read.bats` → `test-scope-reviewer-inline-owns-defers.bats`
asserting byte-parity between each scope-reviewer body's inlined block and
the corresponding `skills/{name}/owns-defers.md`), and update the spec
Reliability section's mode marker.

The mode switch lands as a **separate commit** between commit 6 and commit 7,
renumbering the downstream sequence from 22 commits to 23 commits.

## Read-mode default rationale (spec § Reliability)

Read mode is selected as the design default because:
- Scope-reviewer bodies are single-purpose (~30 lines), so there is nothing
  competing for attention or memory alongside the Step-1 Read instruction.
- The path is hard-coded (no template substitution), making it a single Read
  call to a known file.
- Fallback to inline mode is available at the smoke-test gate; no downstream
  commit is blocked by deferring this decision.

See `docs/superpowers/specs/2026-05-04-110-subagents-in-agent-files-design.md`
§ Reliability for the full rationale.
