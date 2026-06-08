---
status: draft
question_ids: [16]
research_type: codebase
---

# Q16: What is the on-disk architecture of the universal dispatch chain, and how do scripts and SKILL.md bodies relate to each other in defining orchestration behavior?

## Summary

**TL;DR:** The universal dispatch chain is a four-script pipeline (`dispatch-agent.sh` → `dispatch-companion.sh` → `codex-companion-bg.sh` → `await-round.sh` / `third-party-finding-splitter.sh`) that assembles reviewer prompts by concatenating SKILL.md bodies (stripped of frontmatter) with agent bodies at runtime. SKILL.md files define the cross-cutting behavioral contracts (finding schema, emission protocol, isolation rules), while scripts enforce prompt structure, routing decisions, and I/O safety; neither is self-sufficient without the other. The assembly chain uses a single structural boundary marker (`<<<AGENT-BODY-END>>>`) to separate the trusted protocol/agent region from the untrusted orchestrator-supplied dispatch parameters.

**Key findings:**
- `scripts/dispatch-agent.sh` (1,426 lines) is the universal entry point supporting two modes: **batched** (`--step`/`--agents`) and **single-reviewer**; it assembles prompts, writes `.dispatch/<tag>.prompt` files, and records every dispatch into `<round-dir>/.dispatch-manifest.json`.
- Prompt assembly is performed by the `compose_prompt()` function: `skills/reviewer-protocol/SKILL.md` body → any additional `skills:[]`-declared SKILL.md bodies → agent body (all frontmatter-stripped) → `skills/reviewer-protocol/codex-emission-override.md` verbatim → `<<<AGENT-BODY-END>>>` marker → dispatch parameters block.
- The `skills:` YAML frontmatter field on each `agents/qrspi-*.md` file names the SKILL.md bodies that get injected; 34 of 37 agents declare `skills: [reviewer-protocol]`, while others declare `research-isolation`, `implementer-protocol`, or `prompt-prose-writer`.
- `dispatch-companion.sh` (954 lines) reads from stdin only (no `--prompt-file`), resolves the named provider from `<artifact-dir>/config.md`, branches on `transport_type:` (`openai-chat-completions` or `codex-broker`), and contains both the vendor-neutral `launch`/`await` subcommands and the legacy stdin form.
- The host × vendor routing matrix (`scripts/_resolve-lib.sh`: `lookup_host_vendor_path`) determines `first-party` vs `third-party` dispatch: Claude Code + claude = first-party; Claude Code + codex = third-party; Copilot CLI + either = first-party.
- `await-round.sh` drains background manifest entries using an inline Python block that validates `await_cmd`/`split_cmd` from `.dispatch-manifest.json` via `shlex.split` + exec-root allowlisting (never `shell=True`), then passes raw output to `third-party-finding-splitter.sh`.
- First-party reviewers use the Write tool to emit `<reviewer_tag>.finding-F<NN>.md` files; third-party reviewers emit `<<<FINDING-BOUNDARY>>>` blocks to stdout, which the splitter materializes. Both paths produce identical on-disk schemas, defined entirely in SKILL.md prose.
- `verifier-fan-in.sh` (331 lines) is the single source of truth for the `change_type` enum (`style|clarity|correctness|scope|intent`) and per-type threshold floors (style/clarity=80, correctness=70).

**Surprises:** The `<<<AGENT-BODY-END>>>` marker appears in `FORBIDDEN_MARKERS` (dispatch-agent.sh:544) — any orchestrator-supplied input containing this marker is rejected pre-assembly, making the trust boundary enforced by input rejection rather than parser logic alone. Also notable: `dispatch-companion.sh` has an entirely separate `launch`/`await` subcommand interface (lines 512–733) in addition to its legacy stdin dispatcher form — the two code paths share the same file but are detected by argument shape before any flag parsing.

**Caveats:** The `skills/using-qrspi/SKILL.md` (the main orchestrator skill) and `skills/design/SKILL.md`, `skills/plan/SKILL.md`, etc. (step-level orchestrator skills) were not read in full; they define the broader pipeline behavior but are not part of the dispatch chain itself. The `codex-companion-bg.sh` launch/await internals (its JavaScript companion at `~/.claude/plugins/cache/openai-codex/codex/*/scripts/codex-companion.mjs`) are an external plugin not in this repo. The `scripts/round-prepare.sh`, `scripts/detect-interaction-mode.sh`, and `scripts/second-reviewer-available.sh` were not read — these are supporting scripts that feed into the dispatch chain but are not the chain itself.

## Full findings

### On-Disk Layout

```
scripts/
  dispatch-agent.sh           # Universal entry point (1,426 lines)
  dispatch-companion.sh       # Stdin-only prompt dispatcher (954 lines)
  codex-companion-bg.sh       # Codex broker background wrapper (1,022 lines)
  await-round.sh              # Manifest-driven async drain (408 lines)
  third-party-finding-splitter.sh  # Raw output → per-finding files (133 lines)
  verifier-fan-in.sh          # Verifier score filter (331 lines)
  _resolve-lib.sh             # Tier/model/host×vendor routing library
  lib/
    path-guard.sh             # Repo-boundary guard (assert_path_under_repo_root)
    llm-prompt-utils.sh       # strip_frontmatter, guard_marker_injection helpers

skills/
  reviewer-protocol/
    SKILL.md                  # Cross-cutting reviewer contract (finding schema, change-type classifier, dispatch contract)
    first-party-emission.md   # Write-tool emission contract (host env)
    third-party-emission.md   # Stdout boundary contract (sandbox env)
    codex-emission-override.md  # Override injected at end of every third-party prompt
    SKILL.anchors.json
  research-isolation/
    SKILL.md                  # Pre-Flight isolation check (research agents)
  implementer-protocol/
    SKILL.md                  # Implementer behavioral contract
  research/
    SKILL.md                  # Orchestrator skill for Research step
  using-qrspi/
    SKILL.md                  # Global pipeline orchestrator skill
  design/, goals/, plan/, ...  # Per-step orchestrator skills (SKILL.md each)
  _shared/
    evergreen-output-rule.md
    ...                       # Shared prose snippets (not SKILL.md files)

agents/
  qrspi-spec-reviewer.md      # Example: skills: [reviewer-protocol]
  qrspi-research-specialist.md  # skills: [research-isolation]
  qrspi-implementer.md        # skills: [implementer-protocol]
  qrspi-research-collator.md  # skills: [research-isolation]
  ... (37 agent files total)
```

### The Dispatch Chain: Script Roles

#### 1. `scripts/dispatch-agent.sh` — Universal Entry Point

**File:** `scripts/dispatch-agent.sh:1–1426`

This is the universal reviewer/agent dispatch entry point, renamed from the legacy review wrapper under the CD-1 vendor-neutral dispatch rename. Two modes share this script, detected early at line 591–596:

- **Batched mode** (when `--step` or `--agents` flag is present, lines 598–866): resolves N reviewers in one call. For each `tag=agent-file` pair, resolves tier → vendor → model via `_resolve-lib.sh`, assembles the prompt to `<output-dir>/.dispatch/<tag>.prompt`, and emits `MODE=first_party TAG=<tag> SUBAGENT_TYPE=<name> MODEL=<model> PROMPT_FILE=<path>` to stdout for first-party dispatches, or launches `dispatch-companion.sh --vendor ... --model ... --prompt-file ... --round-dir ... --tag ...` for third-party dispatches.

- **Single-reviewer mode** (lines 868–1426): assembles one reviewer prompt and either writes a first-party `DISPATCH_FILE=<path>` to stdout (copilot-cli path) or pipes the assembled prompt to `dispatch-companion.sh` (shell-pipeline path).

**Prompt assembly** is performed by `compose_prompt()` (lines 1202–1216):
```
strip_frontmatter "$REVIEWER_PROTOCOL_ABS"   # skills/reviewer-protocol/SKILL.md
--- separator
[for each additional skill in skills:[]:
  strip_frontmatter "$skill_path"
  --- separator]
strip_frontmatter "$AGENT_FILE_ABS"           # agents/qrspi-*.md body
---
cat "$EMISSION_OVERRIDE_ABS"                  # codex-emission-override.md (verbatim, NOT frontmatter-stripped)
<<<AGENT-BODY-END>>>
emit_dispatch_parameters                      # round_subdir, round, reviewer_tag, artifact_body, etc.
```

The `strip_frontmatter()` function (line 1143) uses `awk` to drop the leading `---` ... `---` YAML block, emitting only the markdown body. This means agent files and SKILL.md files carry behavioral prose in their bodies; the frontmatter is metadata for the script layer.

**Skill loading from `skills:` frontmatter** (lines 1028–1064): `extract_skill_names()` parses the inline-list form `skills: [name1, name2]` from the agent file's frontmatter. For each name that is not `reviewer-protocol` (already handled by `REVIEWER_PROTOCOL_ABS`), the script resolves `$REPO_ROOT/skills/<name>/SKILL.md`, validates existence and repo boundary, then adds to `ADDITIONAL_SKILL_PATHS`. The `reviewer-protocol` skill is excluded because it is always loaded first unconditionally.

**Transport selection** (lines 1243–1356): `detect_host()` (lines 154–171) probes `COPILOT_CLI=1` + verified `gh` binary path under `/usr/*`, `/opt/*`, or `/Applications/*` to determine `copilot-cli` vs `claude-code`. The host × vendor matrix then determines the dispatch path:
- `copilot-cli` → first-party path: writes prompt to `<round-dir>/.dispatch/<tag>.prompt`, prints `DISPATCH_FILE=<path>` to stdout, records first-party manifest entry, exits 0.
- `claude-code` → third-party path: pipes prompt to `dispatch-companion.sh`, captures `JOB_ID=<id>` from stdout, records manifest entry.

**Dispatch manifest** (lines 429–494): every dispatch records a JSON entry in `<output-dir>/.dispatch-manifest.json` via `_append_manifest_entry()`. First-party entries carry `mode=first_party, status=dispatched`; third-party carry `mode=background, status=pending, job_id, await_cmd, split_cmd`. The manifest is written atomically using `mkdir`-as-mutex + mktemp + `mv -f` (lines 312–427).

**Security:** `FORBIDDEN_MARKERS` (lines 543–549) lists the private structural markers; `reject_if_contains_marker_file()` and `reject_if_value_unsafe_for_emission()` check every input path and value before prompt assembly. Embedded newlines in any emitted scalar are rejected (line 563–578).

#### 2. `scripts/dispatch-companion.sh` — Universal Stdin-Only Dispatcher

**File:** `scripts/dispatch-companion.sh:1–954`

Three distinct code paths share this single entry point, detected by argument shape:

- **`await <job-id>` subcommand** (lines 512–598): looks up `<round-dir>/.dispatch/.jobs/<job-id>` job record, reads `vendor=`, `tag=`, `round_dir=`, `codex_job_id=` fields, delegates to `codex-companion-bg.sh await <codex_job_id>`, captures raw output to `<round-dir>/.dispatch/<tag>.raw` (payload-silently — never echoed to stdout/stderr).

- **`--vendor` launch subcommand** (lines 601–732): writes a job record to `<round-dir>/.dispatch/.jobs/<job-id>` containing vendor/model/prompt_file/round_dir/tag, for codex vendor also launches `codex-companion-bg.sh launch < "$L_PROMPT_FILE"` to get the broker job-id, emits `JOB_ID=<id>` to stdout (only).

- **Legacy stdin form** (lines 734–954): reads the assembled prompt from `STDIN_TEMP`, resolves provider config from `<artifact-dir>/config.md`, branches on `transport_type:`:
  - `openai-chat-completions` → `_dispatch_openai_chat()`: curl POST to `<base_url>/chat/completions`, extracts `choices[0].message.content` via Node.js, writes atomically to `--output-file`.
  - `codex-broker` → `_dispatch_codex_broker()`: chains `codex-companion-bg.sh launch` + `await`, writes result to `--output-file`.

**Security hardening:** URL scheme must be `https://`; host is validated against rejected ranges (loopback/link-local/private/CGNAT) by `_is_rejected_host()` (lines 158–188); `default_headers` values are scanned for C0+DEL control bytes by `_control_char_check()` (lines 239–265); `--prompt-file` is explicitly rejected with `exit 1` (lines 764–766) to enforce stdin-only contract.

#### 3. `scripts/codex-companion-bg.sh` — Codex Broker Background Wrapper

**File:** `scripts/codex-companion-bg.sh:1–1022`

Not part of the prompt-assembly layer. Provides `launch` (reads prompt from stdin, forks `codex task --background`, captures broker `jobId`, verifies via status call, emits jobId to stdout) and `await <jobId>` (polls status every 5s/30s with backoff at 120s, ceiling at 1200s, writes reviewer markdown to stdout). Resolves the `codex-companion.mjs` script from the Claude plugin cache glob `~/.claude/plugins/cache/openai-codex/codex/*/scripts/codex-companion.mjs`.

#### 4. `scripts/await-round.sh` — Manifest-Driven Async Drain

**File:** `scripts/await-round.sh:1–408`

Reads `<round-dir>/.dispatch-manifest.json`. For each entry with `mode=background, status=pending`:
1. Runs `await_cmd` from the manifest entry (executes `dispatch-companion.sh await <job-id>`) to populate `<round-dir>/.dispatch/<tag>.raw`.
2. Runs `split_cmd` (executes `third-party-finding-splitter.sh --round-dir <dir> --tag <tag>`) to materialize per-finding files.
3. Updates manifest entry status to `succeeded` or `failed`.

An inline Python block (lines 99–300+) handles steps 1–3 via `shlex.split` + `subprocess.run(..., shell=False)`. Security: `await_cmd`/`split_cmd` strings from the manifest are NEVER passed to a shell. `argv[0]` is validated: bare names must appear in `BARE_NAME_ALLOWLIST = {"codex"}`; path-shaped names must resolve via `os.path.realpath` under `EXEC_ROOTS` = `<repo-root>/scripts/` ∪ `$QRSPI_AWAIT_EXEC_ROOTS`. Shell interpreters (`/bin/sh`, `/bin/bash`), `..`-traversals, and `./`-relative CWD masquerades are all rejected.

#### 5. `scripts/third-party-finding-splitter.sh` — Raw Output Materializer

**File:** `scripts/third-party-finding-splitter.sh:1–133`

Input: `<round-dir>/.dispatch/<tag>.raw`. Splits on `<<<FINDING-BOUNDARY>>>` lines. For `NO_FINDINGS` sentinel (exact byte comparison via `cmp`), writes `<round-dir>/<tag>.clean.md` with `findings: 0` frontmatter. For each boundary-delimited block, writes `<round-dir>/<tag>.finding-F<NN>.md` with zero-padded encounter ordering. Output-bound: stdout is empty on success (payload never echoed to orchestrator).

#### 6. `scripts/verifier-fan-in.sh` — Score Filter

**File:** `scripts/verifier-fan-in.sh:1–331`

Single source of truth for the `change_type` enum `(style|clarity|correctness|scope|intent)` (line 58) and threshold floors: `THRESHOLD_STYLE=80`, `THRESHOLD_CLARITY=80`, `THRESHOLD_CORRECTNESS=70` (lines 63–65). Reads `<round-dir>/*.finding-F*.md` + paired `.score.md` sidecars, applies thresholds keyed on `change_type`, writes `<round-dir>/kept-findings.txt` and `<round-dir>/.verifier-fan-in-audit.json`. Scope/intent findings carry no threshold — kept regardless of score. Halt causes (e.g. `missing_change_type`, `change_type_out_of_enum`) trigger exit 1 with named cause to stderr.

#### 7. `scripts/_resolve-lib.sh` — Routing Resolution Library

**File:** `scripts/_resolve-lib.sh:1–250+`

Sourced (not executed) by dispatch-agent.sh. Implements:
- `resolve_tier <agent-file> [<tier-override>]`: precedence chain — `--tier-override` flag (1) → agent `tier:` frontmatter (2) → `config.md default_tier:` (3) → hardcoded `medium` with LOUD warning (4). `none`-tier halts loudly (non-zero).
- `resolve_model <tier>`: looks up `model_routing:` YAML block in `config.md` for the tier; halts loudly if unconfigured or `none`.
- `lookup_host_vendor_path <host> <vendor>`: returns `first-party` or `third-party` per the matrix (lines 192–198).
- `lookup_default_second_reviewer <host>`: returns `openai-codex` (claude-code/copilot-cli) or `anthropic-claude` (codex-cli).

### SKILL.md Files: Role in Orchestration Behavior

SKILL.md files are the behavioral specification layer. Scripts are the mechanical enforcement layer. They divide responsibility as follows:

| SKILL.md file | What it defines | How scripts consume it |
|---|---|---|
| `skills/reviewer-protocol/SKILL.md` | Finding schema (5 required fields), change-type enum, audit fields, `finding_id` uniqueness rule, untrusted-data handling contract, Expected-Reviewer Matrix, dispatch contract parameters | Concatenated (frontmatter-stripped) as the first block of every third-party reviewer prompt by `compose_prompt()` in dispatch-agent.sh:1203. Also loaded by the host runtime for first-party reviewers via `skills: [reviewer-protocol]` frontmatter — NOT injected into the prompt text |
| `skills/reviewer-protocol/codex-emission-override.md` | Overrides any "use Write tool" instruction for Codex (sandbox) reviewers; defines `<<<FINDING-BOUNDARY>>>` stdout protocol | Concatenated verbatim (NOT frontmatter-stripped) at the end of every reviewer prompt body, AFTER the agent body, BEFORE `<<<AGENT-BODY-END>>>` (dispatch-agent.sh:795, 1213) |
| `skills/reviewer-protocol/first-party-emission.md` | Write-tool emission rules, path rules, per-finding file format for host-env reviewers | Not injected by scripts; loaded by the host runtime for first-party reviewers via `skills:` frontmatter. Referenced by agents directly |
| `skills/reviewer-protocol/third-party-emission.md` | `<<<FINDING-BOUNDARY>>>` stdout protocol for sandbox reviewers | Not injected by scripts; its functional content is duplicated in `codex-emission-override.md` which IS script-injected |
| `skills/research-isolation/SKILL.md` | Pre-Flight isolation check patterns (goals content leak detection, cross-question leakage), refusal procedure | Injected into research agent prompts via `skills: [research-isolation]` frontmatter → `ADDITIONAL_SKILL_PATHS` → `compose_prompt()` at dispatch-agent.sh:1206–1210 |
| `skills/implementer-protocol/SKILL.md` | Implementer behavioral contract | Same injection mechanism; used by `qrspi-implementer.md` and `qrspi-implementer-lightweight.md` |
| `skills/research/SKILL.md` | Orchestrator procedure for the Research step (subagent dispatch rules, isolation gates) | Read directly by the orchestrator at runtime via `qrspi:research` skill invocation. NOT injected into reviewer/agent prompts |
| `skills/using-qrspi/SKILL.md` | Global pipeline rules (precondition gating, step sequencing) | Read directly by the orchestrator. NOT script-injected |
| `skills/design/`, `skills/plan/`, etc. | Per-step orchestrator procedures | Same: orchestrator-loaded skills, not injected into dispatched agent prompts |

### How Scripts and SKILL.md Bodies Divide Orchestration Behavior

**Scripts are responsible for:**
- Routing decisions: host detection, host × vendor matrix lookup, tier resolution, model selection
- Prompt assembly: frontmatter stripping, concatenation order, `<<<AGENT-BODY-END>>>` structural boundary
- I/O safety: repo-boundary guards, marker-injection rejection, newline rejection in scalars, NUL-byte detection in config.md
- Transport mechanics: stdin piping, atomic file writes, manifest JSON construction, job record persistence
- Behavioral enforcement: `change_type` enum validation and threshold floors (verifier-fan-in.sh is the single source of truth)
- Security hardening: URL scheme + host-range validation, control-character scanning, `shell=False` exec in await-round.sh

**SKILL.md bodies are responsible for:**
- The schema of reviewer findings (field names, types, uniqueness rules)
- The behavioral contracts that agents follow (what to look for, how to classify findings)
- The emission format (stdout boundary protocol for third-party; Write-tool contract for first-party)
- The trust model (untrusted-data handling, `<<<UNTRUSTED-ARTIFACT-START/END>>>` wrapper semantics)
- The isolation invariants (research-isolation Pre-Flight checks)
- The convergence and pause-gate routing logic (scope/intent → pause; style/clarity/correctness → auto-apply)

**The structural coupling point** is the `<<<AGENT-BODY-END>>>` marker (dispatch-agent.sh:796, 1214). This single line is the only on-disk boundary between the trusted SKILL.md + agent body region and the orchestrator-supplied dispatch parameters. The research-isolation SKILL.md (skills/research-isolation/SKILL.md:40–47) formally defines that the Pre-Flight check applies ONLY to text AFTER this marker.

### Prompt Assembly Order (Summarized)

For a single-reviewer third-party dispatch, the assembled prompt written to `<round-dir>/.dispatch/<tag>.prompt` has this structure:

```
[body of skills/reviewer-protocol/SKILL.md — frontmatter stripped]

---

[body of skills/<additional-skill>/SKILL.md — frontmatter stripped, if any]

---

[body of agents/qrspi-*.md — frontmatter stripped]

---

[verbatim content of skills/reviewer-protocol/codex-emission-override.md]

<<<AGENT-BODY-END>>>

## Dispatch parameters

artifact_body:
<<<UNTRUSTED-ARTIFACT-START id=<artifact>>>>
...artifact content...
<<<UNTRUSTED-ARTIFACT-END id=<artifact>>>>>

round_subdir: <abs-path>
round: <N>
reviewer_tag: <tag>
[diff_file_path: ...]
[scope_hint: <<<UNTRUSTED-SCOPE-HINT-START id=scope_hint>>>...<<<UNTRUSTED-SCOPE-HINT-END>>>]
```

For first-party reviewers under Claude Code/Copilot CLI, the same `compose_prompt()` function assembles the same prompt body but writes it to `<round-dir>/.dispatch/<tag>.prompt`; the agent runtime loads SKILL.md bodies separately via `skills:` frontmatter preloading (not via the assembled prompt text), so SKILL.md bodies reach the first-party reviewer twice: once via preload and once via the script-assembled prompt. The `codex-emission-override.md` is appended to the assembled prompt in all modes, including first-party, making the override always present regardless of transport path.
