---
name: questions
description: Use when goals.md is approved and the QRSPI pipeline needs research questions generated — produces tagged questions that guide the Research step without leaking goals
---

# Questions (QRSPI Step 2)

**PRECONDITION:** Invoke `qrspi:using-qrspi` skill to ensure global pipeline rules are in context. (Idempotent on session re-entry. Subagents are exempt — SUBAGENT-STOP in using-qrspi handles that.)

**Announce at start:** "I'm using the QRSPI Questions skill to generate research questions."

## Overview

Generate targeted research questions — query planning before any code is read. Separates "what we need to know" from "finding the answers," preventing unfocused research tangents. Questions are tagged by research type to dispatch the right specialist agents.

**Critical constraint:** Questions MUST NOT leak goals or intent. They should be neutral inquiries about how things work, not what we want to change.

## Artifact Gating

**Required inputs:**
- `goals.md` with `status: approved`

If `goals.md` doesn't exist or isn't approved, refuse to run and tell the user to complete the Goals step first.

Read `config.md` from the artifact directory to determine whether Codex reviews are enabled. If `config.md` doesn't exist, default to `codex_reviews: false`.

<HARD-GATE>
Do NOT generate questions without an approved goals.md.
Do NOT pass goals.md to any research subagent — research isolation is structural.
</HARD-GATE>

## Execution Model

**Subagent** (clean context). The subagent receives only `goals.md`.

## Process

### Question Generation Subagent

**Inputs:** `goals.md`

**Task:** Analyze goals to identify which codebase zones and external knowledge domains are relevant. Generate specific, objective research questions.

**Research type tags:**
- `[codebase]` — requires reading local code, tracing logic flows, understanding existing architecture
- `[web]` — requires web searches for competitors, existing tools, libraries, best practices, documentation
- `[hybrid]` — needs both local code reading and external research. Use ONLY when the question literally cannot be answered without both (e.g., "how does our auth token format compare to the JWT spec?"). Default to splitting into separate `codebase` and `web` questions instead.

**Goal leakage rules:**
- BAD: "We want to add real-time notifications — how do competitors handle this?" (leaks the goal)
- GOOD: "How do existing tools in this space handle real-time event delivery to clients?" (neutral inquiry)
- BAD: "How should we refactor the auth module?" (prescriptive)
- GOOD: "How does the auth module work? What are its dependencies and data flows?" (objective)

**Greenfield detection:** Run at the start of the question-generation subagent. Use the Glob tool with pattern `**/*.{ts,tsx,js,jsx,py,go,java,rs,rb,swift,kt,cs,cpp,c,h}`. If all results are inside `node_modules/`, `vendor/`, or `.git/` directories (or if there are zero results), treat this as a greenfield project — replace all `[codebase]` questions with `[web]` questions about existing solutions, frameworks, and best practices. If source files exist outside those directories, proceed normally.

**Output format for `questions.md`:**

```markdown
---
status: draft
---

# Research Questions

1. [codebase] How does the auth module work? What are its dependencies and data flows?
2. [web] What are the most common OAuth 2.0 libraries for Node.js? How do they compare?
3. [codebase] How are API endpoints registered and routed? Trace the request lifecycle.
4. [hybrid] How does our session token format compare to the JWT specification?
5. [web] What are current best practices for rate limiting in REST APIs?
```

### Review Round

**Compaction checkpoint: pre-fanout.** Reviewer dispatch reads `questions.md` + `goals.md` + the agent-embedded reviewer protocol; saturated context produces shallow findings. See using-qrspi `## Compaction Checkpoints` for the iron-rule contract.

Call `TaskCreate({ subject: "Recommend /compact (pre-fanout) — questions", description: "pre-fanout: reviewer dispatch reads questions.md + goals.md. User decides whether to /compact." })`.

Apply the **Standard Review Loop** from `using-qrspi/SKILL.md`. Questions has no scope-reviewer (canonical artifact-tree contract — Questions is not in the scope-reviewer topology). Only the quality reviewer runs.

**Pre-dispatch diff-file emission (#112 PR-1 Mechanism A).** Before dispatching the round's reviewers, the orchestrator runs `git -C "<repo>" diff "<base-branch>" -- "<ABS_ARTIFACT_DIR>/questions.md" > "<ABS_ARTIFACT_DIR>/reviews/questions/round-NN.diff"` as a Bash redirect (the diff content never enters main-chat context). The reviewer dispatch carries `diff_file_path: <ABS_ARTIFACT_DIR>/reviews/questions/round-NN.diff` so the reviewer Reads the diff file directly per the `## Reviewer Dispatch Contract` in the reviewer-protocol skill. Omit the diff redirect and the parameter when the artifact directory is not inside a git repository. The orchestrator follows the fail-loud diff-emission contract in `using-qrspi/SKILL.md` § Standard Review Loop step 1 (preconditions: artifact tracked in git, mkdir-p, rm-f, quoted placeholders, exit-code check).

- **Claude quality-reviewer subagent** — dispatch `Agent({ subagent_type: "qrspi-questions-reviewer", model: "sonnet" })` with a prompt containing only:
  - `artifact_body`: `questions.md` content wrapped between `<<<UNTRUSTED-ARTIFACT-START id=questions.md>>>` and `<<<UNTRUSTED-ARTIFACT-END id=questions.md>>>` markers
  - `companion_goals`: `goals.md` content wrapped between `<<<UNTRUSTED-ARTIFACT-START id=goals.md>>>` and `<<<UNTRUSTED-ARTIFACT-END id=goals.md>>>` markers
  - `round_subdir`: `<ABS_ARTIFACT_DIR>/reviews/questions/round-NN/` (interpolate absolute path and round number)
  - `round`: NN
  - `reviewer_tag`: `quality-claude`
  - `diff_file_path`: `<ABS_ARTIFACT_DIR>/reviews/questions/round-NN.diff` (omit when the artifact directory is not in a git repo)

  The reviewer protocol (5-field schema, change-type classifier, disk-write contract, untrusted-data handling per `skills/reviewer-protocol/SKILL.md`) arrives via the agent file's `skills:` preload — do NOT embed reviewer-protocol content in the dispatch prompt. The Questions-specific checks (goal leakage, comprehensiveness, objectivity, research type tags, hybrid scrutiny) arrive via the agent body auto-loaded by the runtime. Zero rules content in main chat for this dispatch.

- **Codex review** (if `codex_reviews: true`) — dispatch a non-blocking Codex review via a shell pipeline, in parallel with the Claude reviewer:

  **Output format (per-finding emission, #109).** Emit ONLY finding blocks (each preceded by exactly the literal line `<<<FINDING-BOUNDARY>>>`) or the literal sentinel `NO_FINDINGS` on its own line. No prose outside finding bodies. No preamble, no summary, no commentary between findings. The orchestrator's splitter (`scripts/codex-finding-splitter.sh`) treats anything before the first boundary as discardable preamble; anything that is neither boundary-prefixed nor the `NO_FINDINGS` sentinel is malformed and produces zero finding files for this tag (caught at apply-fix step 2 as "expected tag produced no output").

  **Worked one-finding example** (the example uses concrete `design` / `quality-codex` values to keep the prompt template fully literal — the implementer should NOT swap these to other artifact names; only the per-skill `artifact:` field of REAL findings emitted at runtime varies. Substitution-tokens like `<round>` and `<NN>` are placeholders Codex itself fills in at emission time):

  ```
  <<<FINDING-BOUNDARY>>>
  ---
  finding_id: R3-F01
  severity: high
  change_type: correctness
  referenced_files: [skills/design/SKILL.md]
  artifact: design
  round: 3
  reviewer: quality-codex
  ---

  The artifact's "Default action" sentence contradicts the change-type classifier in skills/reviewer-protocol/SKILL.md (which lists `style|clarity|correctness` as auto-apply and `scope|intent` as pause). Fix: rewrite the sentence to cite the classifier verbatim.
  ```

  **Worked zero-findings example.** When the analysis surfaces no findings, the entire output is exactly one line:

  ```
  NO_FINDINGS
  ```

  Nothing else — no boundary, no frontmatter, no commentary.

  **Constraint reminder.** Emit only finding blocks (each preceded by `<<<FINDING-BOUNDARY>>>`) or the literal `NO_FINDINGS` sentinel; no prose outside finding bodies.

  ```sh
  # Quality reviewer (Codex)
  { awk '/^---$/{n++; next} n>=2{print}' skills/reviewer-protocol/SKILL.md;
    printf '\n\n---\n\n';
    awk '/^---$/{n++; next} n>=2{print}' agents/qrspi-questions-reviewer.md;
    printf '\n\n## Dispatch parameters\n\nartifact_body: %s\ncompanion_goals: %s\nround_subdir: <ABS_ARTIFACT_DIR>/reviews/questions/round-%s/\nround: %s\nreviewer_tag: quality-codex\ndiff_file_path: <ABS_ARTIFACT_DIR>/reviews/questions/round-%s.diff\n' \
      "<untrusted-data-wrapped questions.md body>" "<untrusted-data-wrapped goals.md body>" "$ROUND" "$ROUND" "$ROUND";
  } | scripts/codex-companion-bg.sh launch
  ```

  The awk strips YAML frontmatter (everything up through the second `---` line). Main chat sees only the jobId Codex prints.

  After `await` returns, on exit 0 run the splitter to split Codex output into per-finding files:

  ```sh
  scripts/codex-companion-bg.sh await <jobId> > /tmp/codex-stdout-<jobId>.txt
  if [[ $? -eq 0 ]]; then
    scripts/codex-finding-splitter.sh /tmp/codex-stdout-<jobId>.txt reviews/questions/round-NN/ quality-codex
  fi
  # On either failure path (await non-zero OR splitter non-zero), the round
  # directory has zero output for the tag — step 2's schema guard catches it.
  ```

### Human Gate

Present the **full content of `questions.md` inline** — every question, every tag, verbatim. Do not summarize, show only headers, or present a condensed table. The user must see the complete artifact to give meaningful approval.

**Always state the review status** when presenting: either "Reviews passed clean in round N" or "Reviews found issues in round N which were fixed but not re-verified."

On approval, if reviews have not passed clean, note this and ask if they'd like a review loop before finalizing. Then write `status: approved` in frontmatter.

On rejection, write the user's feedback to `feedback/questions-round-{NN}.md` (see using-qrspi Feedback File Format), then launch a new subagent with `goals.md` + rejected `questions.md` + **all** prior feedback files (not just the latest round). After re-generation, the review cycle restarts.

### Terminal State

If the artifact directory is inside a git repository, commit the approved `questions.md` and the `reviews/questions/` directory (per-round per-reviewer files; see `using-qrspi` → "Commit after approval (when applicable)").

**Compaction checkpoint: pre-handoff.** Questions approved; the next skill (typically Research) reads `questions.md` + every prior approved artifact + reviewer findings on a fresh context. See using-qrspi `## Compaction Checkpoints` for the iron-rule contract.

Call `TaskCreate({ subject: "Recommend /compact (pre-handoff) — questions", description: "pre-handoff: next skill reads questions.md + prior artifacts + reviewer findings. User decides whether to /compact." })`.

**REQUIRED:** Invoke the next skill in the `config.md` route after `questions`.

## Red Flags — STOP

- A question reveals the user's intended solution ("how do competitors implement feature X that we want to add?")
- A question is prescriptive rather than exploratory ("how should we refactor X?" vs "how does X work?")
- A `[hybrid]` tag that could easily be split into `[codebase]` + `[web]`
- Questions only cover one research type (all codebase, no web, or vice versa) when the goals imply both
- Questions are too broad ("how does the app work?") or too narrow ("what's on line 42 of auth.ts?")
- Duplicate questions asking the same thing with different wording

## Common Rationalizations — STOP

| Rationalization | Reality |
|----------------|---------|
| "The questions are good enough" | Run the review. Goal leakage is subtle — you may not notice it yourself. |
| "This question needs to be hybrid" | Default to splitting. Only use hybrid when splitting loses essential cross-referencing. |
| "We don't need web research for this" | Even existing-codebase changes benefit from knowing current best practices. |
| "The goals don't imply any codebase questions" | If you're modifying code, you need to understand the existing code. Check again. |
| "I can combine these into fewer questions" | More specific questions get better research. Don't over-consolidate. |

## Worked Example

**Goal:** "Add per-client rate limiting to the public REST API"

**Good questions (no goal leakage):**

```markdown
1. [codebase] How does the Express middleware chain work? What middleware is currently registered and in what order?
2. [codebase] How are client identities resolved in the API? Is there an auth middleware that extracts client IDs?
3. [codebase] How does the application currently connect to and use Redis? What patterns are used for Redis operations?
4. [web] What are the current best practices for distributed rate limiting in Node.js applications?
5. [web] What Redis-based rate limiting algorithms exist (token bucket, sliding window, fixed window)? What are their trade-offs?
```

**Bad questions (goal leakage):**

```markdown
1. [codebase] Where should we add the rate limiting middleware?
2. [hybrid] How can we use our existing Redis connection to implement rate limiting?
3. [web] What's the best rate limiting library for Express that uses Redis?
```

The bad questions reveal intent ("add rate limiting middleware"), assume decisions ("use existing Redis"), and seek recommendations ("best library").

## Iron Laws — Final Reminder

The two override-critical rules for Questions, restated at end:

1. **Questions must NOT leak goals or intent.** A researcher reading only `questions.md` should not be able to infer what we're trying to build or change. Goal leakage produces confirmation-biased research downstream.

2. **Questions are exploratory, not prescriptive.** "How does X work?" is allowed; "How should we change X?" is not. Prescriptive questions presuppose conclusions that Design — not Research — should determine.

Behavioral directives D1-D4 apply — see `using-qrspi/SKILL.md` → "BEHAVIORAL-DIRECTIVES".
