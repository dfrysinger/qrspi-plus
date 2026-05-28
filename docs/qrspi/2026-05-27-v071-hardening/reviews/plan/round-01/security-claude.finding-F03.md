---
id: F03
reviewer: security-claude
round: 1
severity: medium
category: fail-closed
task: Task 1 (G1)
status: open
---

# F03: `codex-broker` transport path bypasses the control-char pre-flight check; plan does not acknowledge the scope boundary

## What the plan says

Task 1 description:

> The control-char detection routine inside the `openai-chat-completions` security pre-flight block is replaced by a dedicated internal helper function…

G1 goal motivation (goals.md):

> Silent failure of its control-character detection **allows prompt-injection vectors (CR/LF/NUL in user-supplied content) to reach downstream providers undetected**.

## The gap

Research Q01 establishes:

> **Gating condition 1 — transport type:** The entire check (lines 530–571) only executes when `TRANSPORT_TYPE = "openai-chat-completions"`; the **`codex-broker` path skips this block entirely**.

Task 1 rewrites the detection logic that lives *inside* this gated block. It does not extend the check to the `codex-broker` path, and the plan contains no task, no test expectation, and no scope-boundary statement that addresses the `codex-broker` transport.

Under the design as described in DKR7, Claude Code Codex dispatches continue to use the shell pipeline (`scripts/run-codex-review.sh` → `scripts/run-third-party-llm.sh`) with `TRANSPORT_TYPE=codex-broker`. Provider `default_headers` passed on the `codex-broker` path are **never inspected** by any control-char check — before or after Task 1 lands.

## Why this matters

G1's security motivation is about prompt-injection vectors in *user-supplied content* reaching *downstream providers*. The `codex-broker` path dispatches to a downstream provider (Codex via OpenAI). If that provider's `default_headers` configuration can contain user-supplied values (the same threat model G1 is fixing for the `openai-chat-completions` path), then:

- The `openai-chat-completions` path: **protected after Task 1**
- The `codex-broker` path on Claude Code: **still unprotected after Task 1**

The plan closes the *observed* bug (BSD grep silent fallback on macOS) but does not document whether `codex-broker` headers are operator-configured or fixed — which is the load-bearing question for whether the injection risk exists on that path.

## Required fix (choose one)

**Option A — Extend coverage (preferred if codex-broker accepts configurable headers):**
Add a test expectation to Task 1 or a new sub-task requiring that `_control_char_check` is also called for any configurable header on the `codex-broker` path, and add a test expectation pinning that behavior.

**Option B — Document the scope boundary explicitly (acceptable if codex-broker headers are fixed at build time):**
Add a sentence to the Task 1 description stating: "The `codex-broker` transport path has no configurable `default_headers` surface and is therefore out of scope for this check." This makes the scope decision explicit and reviewable rather than implicit.

Without one of these, a reader of G1 post-implementation cannot determine whether the full injection-vector surface is closed or only the `openai-chat-completions` portion of it.
