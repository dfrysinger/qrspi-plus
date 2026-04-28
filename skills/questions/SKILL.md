---
name: questions
description: Use when goals.md is approved and the QRSPI pipeline needs research questions generated — produces tagged questions that guide the Research step without leaking goals
---

# Questions (QRSPI Step 2)

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

> **IMPORTANT — Compaction recommended (M53; pre-review-loop).** The Question Generation subagent has just returned `questions.md`. Before dispatching the Claude reviewer (and Codex reviewer in parallel, if enabled), run `/compact` if context utilization may exceed ~50%. Reviewer prompts each load `questions.md` + `goals.md` + the embedded reviewer-boilerplate; running them on a saturated context produces shallow findings.

Apply the **Standard Review Loop** from `using-qrspi/SKILL.md`. Questions-specific reviewer instructions:

- **Claude review subagent** — inputs: `goals.md` + `questions.md`. Checks: **Goal leakage** (would a researcher reading only the questions be able to infer what we're trying to build? if yes, rewrite); comprehensiveness (covers all codebase zones implied by goals); objectivity ("how does X work?" not "how should we change X?"); appropriate research type tags; **Hybrid scrutiny** (can `[hybrid]` be split into `[codebase]` + `[web]`?); no redundant or missing areas. Findings written to `reviews/questions-review.md`. The reviewer subagent embeds `skills/_shared/reviewer-boilerplate.md` verbatim at dispatch time. Findings must conform to the M48 5-field schema defined there (`finding_id`, `severity`, `change_type`, `message`, `referenced_files`); `change_type` is required.
- **Codex review** (if `codex_reviews: true`) — dispatch a non-blocking Codex review via the wrapper:
  1. Write the review prompt (`questions.md` + `goals.md` + the same criteria) to a temporary file (e.g., `/tmp/codex-prompt-questions.md`).
  2. Launch the job early (in parallel with the Claude reviewer above) by running `scripts/codex-companion-bg.sh launch --prompt-file /tmp/codex-prompt-questions.md` as a foreground Bash-tool call. The wrapper prints the jobId to stdout as a single line and exits 0 within ~5 seconds. The orchestrator (this skill's caller — the Claude Code agent driving the Bash tool) records that printed jobId text from the Bash tool's stdout output and pastes it as the literal `<jobId>` argument in the matching await Bash call below; there is no shell variable assignment in this flow, and shell command substitution (`$()` / backticks) is forbidden per Daniel's CLAUDE.md. If launch exits non-zero, abort this Codex review and append a launch-failure note to `reviews/questions-review.md`.
  3. After the Claude reviewer returns, await the result: `scripts/codex-companion-bg.sh await <jobId>`. Exit codes: **0** = success, append the markdown stdout to `reviews/questions-review.md` under `#### Codex`; **10** = 20-min ceiling hit (no stdout produced) — append an explicit ceiling note (e.g., `Codex review: 20-min ceiling hit, no findings produced`), do NOT append empty stdout, do NOT silently retry; **11** = companion crash mid-job (job-not-found) — append a crash note and surface to the user before proceeding; **12** = audit-write fail (e.g., row > 4096 bytes) — append an infrastructure-failure note and surface to the user, do NOT retry blindly. **Only append stdout to the review log on exit 0.**

### Human Gate

Present the **full content of `questions.md` inline** — every question, every tag, verbatim. Do not summarize, show only headers, or present a condensed table. The user must see the complete artifact to give meaningful approval.

**Always state the review status** when presenting: either "Reviews passed clean in round N" or "Reviews found issues in round N which were fixed but not re-verified."

On approval, if reviews have not passed clean, note this and ask if they'd like a review loop before finalizing. Then write `status: approved` in frontmatter.

On rejection, write the user's feedback to `feedback/questions-round-{NN}.md` (see using-qrspi Feedback File Format), then launch a new subagent with `goals.md` + rejected `questions.md` + **all** prior feedback files (not just the latest round). After re-generation, the review cycle restarts.

### Terminal State

Commit the approved `questions.md` and `reviews/questions-review.md` to git.

> **IMPORTANT — Compaction recommended (M53; terminal state).** Questions approved. This is a good point to compact context before the next step. Recommend the user run `/compact` if context utilization may exceed ~50%.

**REQUIRED:** Invoke the next skill in the `config.md` route after `questions`.

> **IMPORTANT — Compaction recommended (M53; cross-skill transition).** Before invoking the next skill, run `/compact` if context utilization may exceed ~50%. The next skill (typically Research, per the Full route) reads `questions.md` + every prior approved artifact + reviewer findings; entering it on a saturated context degrades the synthesis quality of downstream research subagents.

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

Behavioral directives D1-D3 apply — see `using-qrspi/SKILL.md` → "BEHAVIORAL-DIRECTIVES".
