---
status: draft
question_ids: [4]
research_type: codebase
---

# Q4: Task-tool transport branch for reviewer dispatch in `using-qrspi/SKILL.md` and `implement/SKILL.md`

## Summary

**TL;DR:** The task-tool transport branch for Codex reviewer dispatch is documented exclusively in `skills/using-qrspi/SKILL.md` (line 413). It applies only when the host is detected as Copilot CLI (`COPILOT_CLI=1`); the Claude Code host uses the shell-pipeline transport instead. When a reviewer returns findings inline in chat rather than writing to disk, the orchestrator's protocol — the "Verifier-round failure menu" at `using-qrspi/SKILL.md` lines 1041–1082 — classifies this as "Claude reviewer no-output" and presents a three-option menu (skip / retry / stop) to the user; it does not silently discard the inline text. `implement/SKILL.md` contains no task-tool transport documentation; its per-task reviewer section cross-references the disk-write contract defined in `using-qrspi`.

**Key findings:**
- The task-tool transport branch is documented only in `skills/using-qrspi/SKILL.md` § "Per-host Codex dispatch transport routing" (lines 411–416). `skills/implement/SKILL.md` has no task-tool transport text.
- The task-tool branch fires when `detect_host` returns `COPILOT_CLI=1`. The dispatcher invokes the task tool with `agent_type: code-review` and `model: gpt-5.3-codex`. A `[transport: task-tool]` trace marker is emitted to stderr exactly once at the call site.
- The shell-pipeline branch fires when `COPILOT_CLI` is unset (Claude Code host); it uses `scripts/run-codex-review.sh` → `scripts/run-third-party-llm.sh` and emits `[transport: shell-pipeline]` to stderr.
- The disk-write contract is stated at `using-qrspi/SKILL.md` lines 719–742: each reviewer writes findings to disk and returns only a brief ~30-token summary to main chat. Main chat **never receives finding text in subagent return values** by design.
- When a reviewer writes no per-finding files (returns findings inline), the per-expected-tag schema-violation guard at `using-qrspi/SKILL.md` line 759 fires, and the Verifier-round failure menu (lines 1041–1078) is presented. The diagnostic template is: `"Reviewer quality-claude wrote no per-finding files (subagent return: '<verbatim brief-return text>')"`. The three menu options are: (1) skip the round, (2) retry by re-prompting the reviewer after deleting any partial output, (3) stop and abort.
- `implement/SKILL.md` line 929 states that per-task Claude reviewers "return `✅ Approved` or `❌ Issues: [file:line references]` to main chat and write findings to `output` per the reviewer-protocol disk-write contract." No separate failure-handling prose for the inline-return case appears in `implement/SKILL.md`; it defers to the shared failure menu defined in `using-qrspi`.

**Surprises:** The task-tool transport branch is scoped exclusively to the Codex reviewer (not to Claude reviewers), and only applies to the Copilot CLI host. Claude reviewer dispatches always use the Agent tool and are not subject to host-based transport switching. The "inline findings" failure case is treated as a no-output failure rather than as an alternative data channel — the inline text is cited verbatim in the failure diagnostic but is not parsed or used.

**Caveats:** Only `using-qrspi/SKILL.md` and `implement/SKILL.md` were examined per the question. The `reviewer-protocol/SKILL.md` and `_shared/codex/launch-await-pattern.md` were checked only via grep for corroborating references, not read in full.

## Full findings

### Task-tool transport branch: where it is documented

The per-host Codex dispatch transport routing is documented in `skills/using-qrspi/SKILL.md` lines 411–416, under the heading **"Per-host Codex dispatch transport routing"**. The complete text:

> **Copilot CLI host (`COPILOT_CLI=1`):** Codex review dispatch uses the native task tool transport. The dispatcher invokes the task tool with `agent_type: code-review` and `model: gpt-5.3-codex` (the Codex model identifier named in `design.md` and goal G6). No shell pipeline is involved — the task tool is the in-process transport. The dispatch surface emits the `[transport: task-tool]` trace marker to stderr exactly once at the call site that selects this branch.
>
> **Claude Code host (`COPILOT_CLI` unset):** Codex review dispatch uses the shell-pipeline transport via `scripts/run-codex-review.sh`. The wrapper composes the reviewer prompt and pipes it through `scripts/run-third-party-llm.sh` to reach the Codex endpoint. The dispatch surface emits the `[transport: shell-pipeline]` trace marker to stderr exactly once at the call site that selects this branch.

`skills/implement/SKILL.md` contains **no task-tool transport documentation**. A grep of `implement/SKILL.md` for "task.tool", "task-tool", and "COPILOT_CLI" returns zero matches in transport context. The only transport-related text in `implement/SKILL.md` is at line 546, which describes third-party dispatches piping to `scripts/run-third-party-llm.sh` — the shell-pipeline path, not the task-tool path.

### Mismatch policy and availability short-circuit

`using-qrspi/SKILL.md` lines 416–417 document two runtime guards for the task-tool vs shell-pipeline selection:

- **Mismatch warning** (warning-only, non-blocking): when detected host availability disagrees with the `codex_reviews` config value, the dispatch surface emits a single-line `[mismatch]` diagnostic to stderr and continues with the configured policy. Does not block dispatch or override transport exit code.
- **Unavailability short-circuit** (blocks dispatch): when `check_codex_available` reports Codex unavailable for the detected host AND `codex_reviews: true`, the dispatch surface emits a single-line stderr diagnostic and propagates the non-zero availability-check exit code. The two guards are independent.

### Disk-write contract (the baseline before the failure case)

`using-qrspi/SKILL.md` lines 719–742, § **"Review Output Handling"**:

- Each artifact-level reviewer subagent writes findings **directly to disk** and returns only a brief structured summary (~30 tokens) to main chat.
- Main chat **never receives finding text in subagent return values**.
- The required return form is (lines 734–740):
  ```
  Round NN {reviewer-tag} review complete.
  Findings: N (high=X, medium=Y, low=Z)
  Auto-apply: A | Paused: P
  Written to: reviews/{step}/round-NN/
  ```
- Brevity is described as "load-bearing for the optimization" — the savings in cache-read accumulation across subsequent main-chat turns depend on the subagent returning ~30 tokens, not 3K–30K.

For per-task (Implement) Claude reviewers, `implement/SKILL.md` line 929 states: "Each reviewer returns `✅ Approved` or `❌ Issues: [file:line references]` to main chat and writes findings to `output` per the reviewer-protocol disk-write contract." The disk-write contract is the same, but the brief return summary has a different form.

### When a reviewer returns findings inline in chat instead of writing to disk

The protocol that handles this case is the **"Verifier-round failure menu"** at `using-qrspi/SKILL.md` lines 1041–1082.

Trigger condition: "Any abnormality during Apply-fix (VERIFY_FAILED from one or more verifiers; Codex reviewer no-output — cite `await` exit + wrapper `--artifact-dir`; **Claude reviewer no-output** — cite verbatim subagent return; sidecar missing for a finding)" (line 1041, emphasis added).

The "no-output" condition fires when the per-expected-tag schema-violation guard (line 759) finds that an expected tag produced zero `*.finding-*.md` or `*.clean.md` files — which is exactly the state that results when a reviewer returns its findings inline in chat instead of writing them to disk.

The diagnostic template for a Claude reviewer returning inline is (lines 1050–1051):
```
"Reviewer quality-claude wrote no per-finding files
 (subagent return: '<verbatim brief-return text>')"
```

The verbatim inline text appears in the failure diagnostic but is not parsed, applied, or treated as a valid findings source. The protocol presents a 3-option user menu:

1. **skip** — proceed without scoring this round (kept-all assembly). Writes a `round-NN-verifier-disabled.md` sentinel with timestamp, reason (identical to the diagnostic line), and finding_count. Does NOT mutate `config.md`; next round resumes verifier-enabled.
2. **retry** — for "reviewer produced no output": delete the tag's `*.finding-*.md`, `*.score.yml`, and `*.clean.md` for the round (if any), then re-prompt the reviewer.
3. **stop** — abort the protocol with no commit; round directory remains on disk for inspection.

No default option; user must pick. The menu also notes: "If the same path keeps failing, picking `skip` is the safe escape." (line 1082)

### Coverage: what is and is not documented

| Transport branch | Documentation location | Coverage |
|---|---|---|
| Task-tool (Copilot CLI host) | `using-qrspi/SKILL.md` lines 413–414 | Documented: invocation shape, trace marker, no-shell-pipeline note |
| Shell-pipeline (Claude Code host) | `using-qrspi/SKILL.md` lines 414–415 | Documented: wrapper script, pipes to run-third-party-llm.sh, trace marker |
| Task-tool in `implement/SKILL.md` | — | **Not present**; `implement/SKILL.md` has no task-tool transport text |
| Inline-return failure protocol | `using-qrspi/SKILL.md` lines 1041–1082 | Documented: "Verifier-round failure menu" covers Claude reviewer no-output case |
| Inline-return failure in `implement/SKILL.md` | — | Not separately documented in implement; per-task reviews reference disk-write contract but do not duplicate failure menu |

The task-tool transport branch is therefore documented in `using-qrspi/SKILL.md` only. The shell-pipeline transport branch is also documented in `using-qrspi/SKILL.md` and additionally referenced in `implement/SKILL.md` via the `scripts/run-codex-review.sh` dispatch shape at lines 1060–1161.
