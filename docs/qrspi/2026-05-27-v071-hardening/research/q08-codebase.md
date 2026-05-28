---
status: draft
question_ids: [8, 15]
research_type: codebase
---

# Q8, Q15: Codex availability detection in `using-qrspi/SKILL.md` and `run-third-party-llm.sh` call sites

## Summary

**TL;DR:** `skills/using-qrspi/SKILL.md` detects Codex availability by globbing a single filesystem path under `~/.claude/plugins/` for `codex-companion.mjs`; on a hit the Goals skill asks the user a 2-option question and writes `codex_reviews: true/false` to `config.md`, which gates every subsequent reviewer dispatch. `scripts/run-third-party-llm.sh` is reached from exactly three call sites: `scripts/run-codex-review.sh` (the primary path invoked from 14 skill files), `scripts/g4-cache-probe.sh` (a Plan-time spike script), and the main-chat dispatch contract described in `skills/implement/SKILL.md`; none of these call sites are gated on a host-specific signal.

**Key findings:**

- **Filesystem path probed (Q8):** `~/.claude/plugins/cache/openai-codex/codex/*/scripts/codex-companion.mjs` (glob, wildcard version segment). `SKILL.md` line 405 and `scripts/codex-companion-bg.sh` lines 70–93 use the same pattern.
- **Config key inspected (Q8):** `codex_reviews` in `config.md`. The Goals skill writes `codex_reviews: true` or `codex_reviews: false` depending on detection result and user choice. All downstream review steps read this key before deciding whether to dispatch `run-codex-review.sh`.
- **Dispatch code path on positive detection (Q8):** Goals asks the user a 2-option prompt; user selecting option 2 causes `codex_reviews: true` to be written to `config.md`. All review rounds in every pipeline step then gate a `scripts/run-codex-review.sh` dispatch on `codex_reviews: true`.
- **Primary call site for `run-third-party-llm.sh` (Q15):** `scripts/run-codex-review.sh` line 454. Called from 14 distinct skill SKILL.md files (Goals, Research, Plan, Design, Phasing, Parallelize/Structure, Implement, Integrate, Test, Replan, Questions, Research-isolation, Reviewer-protocol — see full list below). All are gated on `codex_reviews: true`.
- **Secondary call site (Q15):** `scripts/g4-cache-probe.sh` line 159. Calls `run-third-party-llm.sh` directly with `--provider anthropic-probe`. No `codex_reviews` gate; this is an operator-run spike script.
- **Tertiary call site (Q15):** `skills/implement/SKILL.md` line 537 documents that main-chat dispatches for any provider with `transport_type: openai-chat-completions` or `transport_type: codex-broker` pipe to `run-third-party-llm.sh`. This is not a shell script invocation but an instruction to the orchestrating LLM.
- **Host-specific gating (Q15):** None. No call site checks for Copilot CLI vs. Claude Code or any other host-environment signal before invoking `run-third-party-llm.sh`. The only environment-specific carve-out in the script itself is the `QRSPI_ALLOW_LOCALHOST_BASE_URL=1` env-var override for test environments.
- **Stale doc:** `skills/reviewer-protocol/SKILL.md` line 13 describes `run-codex-review.sh` as piping to `scripts/codex-companion-bg.sh launch` on stdin — pre-T04 wording. Post-T04, `run-codex-review.sh` pipes to `run-third-party-llm.sh` instead.

**Surprises:** The `reviewer-protocol/SKILL.md` description of the Codex dispatch path (line 13) is stale relative to the actual shell script implementation — it still refers to the pre-T04 `codex-companion-bg.sh launch` chaining, while the script itself (post-T04) routes through `run-third-party-llm.sh`. Also, `g4-cache-probe.sh` invokes `run-third-party-llm.sh` directly for an Anthropic (not Codex) provider, making it a completely independent call site unrelated to the Codex review path.

**Caveats:** Only SKILL.md files and shell scripts were searched for call sites. Agent `.md` files and test BATS files were found to reference `run-third-party-llm.sh` only in test fixtures or in the context of this investigation's own `questions.md`. The `skills/implement/SKILL.md` mention (line 537) is a prose instruction to the LLM orchestrator, not a concrete shell invocation. The `reviewer-protocol/SKILL.md` stale description was noted but not further traced to verify whether the shell script behavior was updated in all places.

---

## Full findings

### Q8: How `skills/using-qrspi/SKILL.md` determines Codex availability

#### Filesystem path probed

`skills/using-qrspi/SKILL.md` line 405:

> **Codex detection:** Check if `codex:rescue` is available by globbing for `~/.claude/plugins/cache/openai-codex/codex/*/scripts/codex-companion.mjs`. If the file doesn't exist, skip the Codex question silently and write `codex_reviews: false`.

The exact glob pattern is:
```
~/.claude/plugins/cache/openai-codex/codex/*/scripts/codex-companion.mjs
```

The `*` segment matches any installed Codex version directory. The same pattern appears verbatim at runtime in `scripts/codex-companion-bg.sh` lines 79–93:

```bash
local pattern="${HOME}/.claude/plugins/cache/openai-codex/codex/*/scripts/codex-companion.mjs"
shopt -s nullglob
local matches=( $pattern )
```

The companion script picks the newest match via `sort -V | tail -n1`; the SKILL.md instruction does not specify this tie-breaking behavior — it simply checks for existence.

#### Config key inspected

The key written (and subsequently read by all skills) is `codex_reviews` in `config.md`. Its valid values are `true` or `false` (YAML boolean, case-sensitive per `using-qrspi/SKILL.md` line 533). 

The following fields are written atomically to `config.md` by the Goals skill after Codex detection and user response (`SKILL.md` line 393):

- `created` (timestamp)
- `pipeline` (quick/full)
- `codex_reviews` (true/false)
- `route` (list)
- `verifier_enabled`, `scope_tagger_enabled`, `visual_fidelity_required`
- `question_budget: 5` (if `pipeline: quick`)

The `codex_reviews` field is consumed by all downstream steps (`SKILL.md` line 607):

| Field | Steps consuming it |
|---|---|
| `codex_reviews` | Goals, Plan, Design, Phasing, Structure, Replan, Implement, Integrate, Test (and all others with review loops) |

#### Dispatch code path on positive detection

When the glob finds at least one match, the Goals skill asks (`SKILL.md` lines 407–409):

```
Codex reviews:
1) No Codex reviews
2) Use Codex for second reviews
```

- **User selects 1:** `codex_reviews: false` written; no Codex dispatches anywhere in the run.
- **User selects 2:** `codex_reviews: true` written; the following dispatch chain activates at every review round across all review-enabled steps:

  1. Main chat reads `codex_reviews: true` from `config.md`.
  2. Main chat launches `scripts/run-codex-review.sh` as a background bash job (non-blocking, in parallel with Claude reviewer subagents).
  3. `run-codex-review.sh` assembles the reviewer prompt (reviewer-protocol body + agent body + emission override + dispatch params).
  4. `run-codex-review.sh` calls `bash "$DISPATCHER" "${DISPATCHER_ARGS[@]}"` where `DISPATCHER=run-third-party-llm.sh` and the args are `--provider codex --model <id> --output-file <path> --artifact-dir <dir>` (`run-codex-review.sh` lines 434–456).
  5. `run-third-party-llm.sh` reads `config.md`, finds the `codex` provider entry with `transport_type: codex-broker`, and calls `_dispatch_codex_broker`.
  6. `_dispatch_codex_broker` calls `scripts/codex-companion-bg.sh launch` (piping stdin prompt), captures `job_id`, then calls `codex-companion-bg.sh await <job_id>` with optional `QRSPI_CODEX_CEILING_SECONDS` timeout.
  7. `codex-companion-bg.sh` resolves `codex-companion.mjs` from the same glob (`~/.claude/plugins/cache/openai-codex/codex/*/scripts/codex-companion.mjs`) or from `$CODEX_COMPANION` env override, launches it as a background task, polls for completion, and writes finding markdown to stdout.
  8. stdout from the `await` step is redirected into the per-round directory per the `## Per-Finding Disk-Write Contract` (`SKILL.md` line 679).

If the file glob finds no match at Goals time, `codex_reviews: false` is written silently and the question is never presented. The runtime dispatch chain (steps 2–8 above) is never activated.

---

### Q15: Call sites for `scripts/run-third-party-llm.sh`

#### Call site 1: `scripts/run-codex-review.sh` (primary Codex reviewer path)

**File:** `scripts/run-codex-review.sh` lines 434–456  
**How it reaches run-third-party-llm.sh:**

```bash
DISPATCHER="$REPO_ROOT/scripts/run-third-party-llm.sh"
...
compose_prompt | bash "$DISPATCHER" "${DISPATCHER_ARGS[@]}"
```

`DISPATCHER_ARGS` always includes `--provider codex`. This is the T04 migration result: `run-codex-review.sh` previously called `codex-companion-bg.sh` directly but was refactored to forward to `run-third-party-llm.sh`.

**Gated on host-specific signal?** No. The only gate before the `run-third-party-llm.sh` call is `DRY_RUN == "true"` (flag-controlled, not host-detected). The dispatcher call is unconditional when `--dry-run` is not set.

**Skill files that invoke `run-codex-review.sh`** (and thus transitively reach `run-third-party-llm.sh`):

All 14 skill files gate their `run-codex-review.sh` dispatch on `codex_reviews: true` in `config.md`. No skill conditions this on the host environment:

| Skill file | References to `run-codex-review.sh` | Gate |
|---|---|---|
| `skills/goals/SKILL.md` | lines 293, 303 | `codex_reviews: true` |
| `skills/questions/SKILL.md` | (ref present) | `codex_reviews: true` |
| `skills/research/SKILL.md` | line 201 | `codex_reviews: true` |
| `skills/plan/SKILL.md` | lines 322, 338, 344, 350, 356, 362, 368 | `codex_reviews: true` |
| `skills/design/SKILL.md` | lines 212, 224 | `codex_reviews: true` |
| `skills/phasing/SKILL.md` | (ref present) | `codex_reviews: true` |
| `skills/parallelize/SKILL.md` | lines 234, 247 | `codex_reviews: true` |
| `skills/structure/SKILL.md` | (ref present) | `codex_reviews: true` |
| `skills/implement/SKILL.md` | (ref present) | `codex_reviews: true` |
| `skills/integrate/SKILL.md` | lines 126, 141 | `codex_reviews: true` |
| `skills/test/SKILL.md` | lines 156, 167, 178 | `codex_reviews: true` |
| `skills/replan/SKILL.md` | (ref present) | `codex_reviews: true` |
| `skills/research-isolation/SKILL.md` | (ref present) | `codex_reviews: true` |
| `skills/reviewer-protocol/SKILL.md` | line 13 (description) | N/A (description only) |

#### Call site 2: `scripts/g4-cache-probe.sh` (spike script — direct call)

**File:** `scripts/g4-cache-probe.sh` lines 159–166  
**How it reaches run-third-party-llm.sh:**

```bash
DISPATCHER="$REPO_ROOT/scripts/run-third-party-llm.sh"
if [ ! -f "$DISPATCHER" ]; then
  echo "g4-cache-probe: missing-input: universal dispatcher not found at $DISPATCHER" >&2
  exit 1
fi
```

This script dispatches directly to `run-third-party-llm.sh` with `--provider anthropic-probe` (not `codex`). Its purpose is to measure Anthropic prompt-cache metadata across three successive dispatches. The script header (lines 1–11) identifies this as the G4 Mechanism A cache-probe intended to be run against "Claude Code's Agent({}) dispatch path."

**Gated on host-specific signal?** No. The script performs no host-environment detection. It is described as an operator-run probe script, not part of the automated pipeline, but no code in it checks for a particular host.

#### Call site 3: `skills/implement/SKILL.md` — prose contract for main-chat dispatch

**File:** `skills/implement/SKILL.md` line 537  
**Text:**

> **Third-party dispatches** (any provider with `transport_type: openai-chat-completions` OR `transport_type: codex-broker` in `config.md`) pipe their prompt to `scripts/run-third-party-llm.sh` with `--provider <resolved-provider> --model <resolved-model>`.

This is an instruction to the LLM acting as the Implement-phase orchestrator (main chat), not a shell invocation. It describes when any non-Claude provider is resolved through the four-layer model-routing chain, the resulting prompt should be piped to `run-third-party-llm.sh`.

**Gated on host-specific signal?** No. The gating condition is purely `transport_type` in `config.md`.

#### Host-environment analysis

`run-third-party-llm.sh` itself contains no host-detection logic. The only environment-conditional behavior in the script is:

- **`QRSPI_ALLOW_LOCALHOST_BASE_URL=1`** (lines 561–566): carve-out allowing `localhost` as `base_url` for the `openai-chat-completions` transport, explicitly documented as "Set ... to allow loopback-only hosts in tests." This is a test-infrastructure flag, not a host-type detection.

No call site passes or checks for Copilot CLI vs. Claude Code signals. The `AGENTS.md` line 8 notes "This pointer file auto-loads in Copilot CLI / Claude Code sessions" but this pertains to the pointer file mechanism, not to any conditional gating of `run-third-party-llm.sh`.

#### Stale description in `skills/reviewer-protocol/SKILL.md`

`skills/reviewer-protocol/SKILL.md` line 13 describes the Codex dispatch path as:

> The wrapper … pipes the result to `scripts/codex-companion-bg.sh launch` on stdin.

This is the pre-T04 description. The actual `run-codex-review.sh` implementation (post-T04) pipes to `run-third-party-llm.sh`, not `codex-companion-bg.sh` directly. The `codex-companion-bg.sh` is still invoked, but indirectly via `run-third-party-llm.sh`'s `_dispatch_codex_broker` function.
