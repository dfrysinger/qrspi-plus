# Permission-Friction Notes

**Status:** Working notes. Not authoritative — open questions need verification before any of this becomes policy. To be expanded after Config Validation menu cleanup completes.

**Originated:** 2026-04-25 conversation about reducing approval-prompt interruptions during long agentic sessions.

---

## The four categories of approval friction

Approval prompts come from architecturally distinct layers. Conflating them led to bad recommendations on this conversation; keeping them separate is the prerequisite for solving each one correctly.

### Category 1 — Tool permission prompts ("Claude wants to run X")

**Source:** Claude Code's permission system, governed by `.claude/settings.json` `permissions.allow` / `deny` / `ask`.
**Behavior:** Prompts the user before each tool call that isn't pre-allowlisted.
**Permanently silenceable:** Yes — add the pattern to `.claude/settings.json` `permissions.allow`.
**Mitigation:** Run the `fewer-permission-prompts` skill periodically (after major sessions). It scans transcripts and auto-adds read-only patterns.

### Category 2 — Bash safety-heuristic prompts

**Source:** Claude Code's bash tool internal safety heuristics.
**Behavior:** Re-prompts on every invocation that matches a "dangerous-looking" bash pattern.
**Permanently silenceable:** No (per `~/.claude/CLAUDE.md` notes — these patterns cannot be allowlisted).
**Triggers (from `~/.claude/CLAUDE.md`):**
- Command substitution (`$()`, backticks)
- Newlines between commands
- Multi-step scripts (for / if-then / while loops)
- `cd path && git ...` — use `git -C /absolute/path ...` instead
- Heredocs (`<<EOF`) — use the Write tool instead
**Mitigation:** Don't write commands that trigger them. Discipline-based. Strict adherence eliminates this category entirely.

### Category 3 — QRSPI hook denials

**Source:** `qrspi-plus` PreToolUse hook (`hooks/pre-tool-use`), exit code 2 = block.
**Behavior:** Blocks tool calls that violate pipeline ordering, task allowlists, protected paths, worktree containment.
**Permanently silenceable:** Not by allowlist — these are the security model. Bypassing defeats the purpose. Adjustment is via task allowlists, runtime overrides (`task-NN-runtime.json`), or hook config refinement.
**Mitigation:** Improve hook ergonomics where genuinely over-strict; widen task allowlists where the planner under-specified; use the runtime-override mechanism for legitimate mid-task scope additions.

### Category 4 — Write/Edit prompts to specific paths

**Source:** Claude Code's permission system applied to file paths.
**Behavior:** Prompts before writing or editing paths not pre-approved.
**Permanently silenceable:** Yes — `permissions.allow` with path patterns.
**Mitigation:** Settings management; subagent isolation (subagents in worktrees have different permission surfaces).

---

## What `--dangerously-skip-permissions` actually does

**Important correction from the originating conversation:** Hooks and permissions are architecturally separate in Claude Code. The dangerous-skip flag bypasses the *permission prompt layer* — it does not disable the hook system.

| Layer | Skipped by `--dangerously-skip-permissions`? |
|---|---|
| Category 1 (tool permission prompts) | Yes |
| Category 2 (bash safety heuristics) | Likely yes — needs verification (open question below) |
| Category 3 (QRSPI hook denials) | **No** — hooks still fire and still fail-closed via exit 2 |
| Category 4 (write/edit path prompts) | Yes |

**Practical implication:** For QRSPI plugin work specifically, the dangerous-skip mode is much less risky than commonly assumed. The qrspi safety model is hook-enforced (not permission-prompt-enforced), so artifact gating, task boundary enforcement, protected-path checks, and audit logging all keep working. What you lose is generic safety prompts on tool calls *not* covered by a hook (e.g., `rm -rf` outside the project).

---

## Open questions (verify before policy)

1. **Do bash safety-heuristic prompts get skipped in dangerous mode?** I assume yes (they appear AS prompts so likely live in the permission layer) but I haven't verified. If they're NOT skipped, dangerous mode wouldn't help with category 2 friction at all.
2. **Are there any hook events that only fire when a permission would otherwise be requested?** I don't think so — hooks fire on tool lifecycle events independent of permission state — but worth confirming.
3. **What's the actual top-N source of prompts in real sessions?** We have transcripts; a scan would tell us whether prompts are mostly category 1 (allowlistable), category 2 (discipline), or category 3 (hook config).
4. **Does the `claude-code-guide` agent have authoritative answers on questions 1-2?** Worth dispatching it once.

---

## Mitigation queue (rough order of effort vs. payoff)

### A. Run `fewer-permission-prompts` after each big session

**Effort:** Low (one slash command).
**Payoff:** Cumulative reduction in category 1 prompts. Should be habit, possibly a session-end hook.

### B. Audit which prompts I trigger most often (transcript scan)

**Effort:** Medium (need a script that counts prompt patterns from transcripts).
**Payoff:** High — gives a prioritized list. Without this we're guessing where the friction is.
**Deliverable:** Top-N list with category and proposed mitigation per pattern.

### C. Fix bash discipline (category 2 elimination)

**Effort:** Low (it's just me following the rules in `~/.claude/CLAUDE.md`).
**Payoff:** Eliminates category 2 entirely if rigorous. I caught myself doing some of these in this session (multiple `&&` chains in earlier commits). Strict adherence: use Write tool for multi-line commits, `git -C /path` instead of `cd && git`, separate Bash calls instead of newlines or for-loops.

### D. QRSPI hook ergonomics review

**Effort:** Medium (audit hook config + task allowlist patterns).
**Payoff:** Reduces category 3 friction without weakening enforcement. Look for: per-task allowlists that should be slightly broader; common patterns where the runtime-override mechanism should pre-approve; hook denials that fire on actions the user has already approved in conversation.

### E. Push more work into Agent-tool subagents

**Effort:** Low (already do this for research).
**Payoff:** Subagents have their own permission surface and don't pin main-chat CWD. Could expand to codebase exploration and other read-heavy tasks.

### F. Use `--dangerously-skip-permissions` for QRSPI plugin sessions

**Effort:** Trivial (one flag).
**Payoff:** Eliminates categories 1, 2, and 4 entirely.
**Risk:** Lose generic safety prompts on non-hook-covered actions. For QRSPI plugin work specifically, the hook model still enforces the important things, so risk is lower than the name implies.
**Verify first:** Open questions 1 and 2 above.

---

## Recommended sequence (when we resume this)

1. Verify open questions 1-2 via `claude-code-guide` agent (5 minutes).
2. Run B (transcript scan) — get the actual top-N prompt sources.
3. Apply A immediately (run `fewer-permission-prompts` against this session's transcripts).
4. Fix C (bash discipline) — strict-mode adherence going forward.
5. Decide on F based on what 1-3 surfaced.
6. D as a longer-running improvement, scoped per recurring hook denial pattern.

---

## Notes for future expansion

- If we end up running with `--dangerously-skip-permissions` on QRSPI work, document a "what to watch for" list — the specific failure modes that the permission system was protecting against and that you now need to catch by other means.
- If `fewer-permission-prompts` becomes a recurring cleanup, consider whether it should run automatically at session end or as part of phase compaction.
- If hook ergonomics keeps surfacing as a friction source, consider a separate "hook UX" review pass distinct from the prompt-design audit.
