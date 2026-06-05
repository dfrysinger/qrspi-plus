---
status: draft
question_ids: [1]
research_type: codebase
---

# Q1: Verifier sidecar pipeline end-to-end

## Summary

**TL;DR:** The `qrspi-finding-verifier` is dispatched once per finding file in parallel by the orchestrator (main chat). Each verifier reads the finding + artifact + diff from disk, then writes a `.score.yml` sidecar as a sibling of the finding file in `reviews/{step}/round-NN/`. The orchestrator reads sidecars from disk — not from the verifier's chat-side return text — by assembling them into `round-NN-verified.md`, then applies score-based thresholds to decide which findings reach the apply-fix step.

**Key findings:**
- **Extension**: `agents/qrspi-finding-verifier.md` specifies `.score.yml` (line 36). The transform is `<finding_file_path>` with `.md` → `.score.yml` (e.g., `quality-claude.finding-F01.md` → `quality-claude.finding-F01.score.yml`). The `.yml` extension is chosen explicitly to prevent sidecars from matching `*.finding-*.md` globs and to enable YAML syntax highlighting.
- **Sidecar landing path**: `<abs_run_dir>/reviews/{step}/round-NN/<reviewer_tag>.finding-F<NN>.score.yml` — a sibling of the finding file in the round directory. The orchestrator constructs `sidecar_path` as `finding_file_path` with `.md` replaced by `.score.yml` and passes it to the verifier as an explicit dispatch parameter.
- **How the orchestrator consumes verifier results**: Primarily via the sidecar on disk, not the chat-side return. The verifier's brief return line (`<reviewer_tag>.<finding_id>: <score>`) is inspected only for the `VERIFY_FAILED:` prefix to route to the §3 failure menu. All scoring decisions are made by reading `*.score.yml` files off disk.
- **Assembly step**: A Bash script (using-qrspi SKILL.md §Apply-fix protocol step 5) enumerates `*.finding-*.md` files, derives each sidecar path via `${f%.md}.score.yml`, reads scores, and emits `round-NN-verified.md` with interleaved `<!-- @@FINDING: ... @@>` / `<!-- @@SCORE: ... @@ -->` delimiters and a YAML frontmatter header (`scored`, `kept`, `dropped`, `failed`, `clean`).
- **Apply-fix step**: After reading `round-NN-verified.md` once (step 7), the orchestrator partitions findings by `change_type`: `style`/`clarity` require sidecar score ≥ 80; `correctness` requires score ≥ 70. Findings with `scope`/`intent` change_type bypass score filtering entirely. Kept findings are applied via `Edit` on the artifact.
- **Legacy `.score.md` files** exist in the v0.7.1 hardening run disk (`reviews/tasks/task-10/round-01/quality-claude.finding-F01.score.md`, etc.) but the current agent spec mandates `.score.yml`.

**Surprises:** The orchestrator explicitly ignores the verifier's chat-side return value for scoring — it is treated only as a failure-detection signal (checking for the `VERIFY_FAILED:` prefix). The sidecar on disk is the sole source of truth for score values. Also, sidecars are intentionally excluded from the step-1 nullglob enumeration (`*.score.yml` not in the glob) and are discovered per-finding via a derived path transformation inside the assembly loop.

**Caveats:** The `round-NN-verified.md` assembly Bash script in using-qrspi SKILL.md is prescriptive spec prose, not executed code — actual orchestrator behavior may vary. No executed Apply-fix logs or session traces were available for runtime verification. Legacy `.score.md` sidecars found in the v0.7.1 run predate or diverge from the current `.score.yml` spec; the transition point was not precisely dated.

## Full findings

### Q1: Verifier sidecar pipeline end-to-end

#### 1. Agent specification: `agents/qrspi-finding-verifier.md`

File: `agents/qrspi-finding-verifier.md`

The agent descriptor is a 65-line Markdown file. Its relevant structures:

**Input contract (lines 33–38):**
Five prompt parameters are passed to the verifier:
- `<finding_file_path>` — absolute path to the per-finding file under `reviews/{step}/round-NN/`
- `<sidecar_path>` — absolute path the verifier writes its score to; always constructed as `<finding_file_path>` with `.md` → `.score.yml`. The agent description states: *"The `.yml` extension is deliberate: it keeps the sidecar from matching `*.finding-*.md` globs in the round directory and lets editors syntax-highlight the YAML body."* Example from line 36: `quality-claude.finding-F01.md` → `quality-claude.finding-F01.score.yml`.
- `<artifact_path>` — absolute path to the artifact under review
- `<diff_file_path>` — absolute path to `reviews/{step}/round-NN.diff`
- `<upstream_paths>` — newline-separated upstream artifact and SKILL paths

**Procedure (lines 42–64):**
1. Read finding file (YAML frontmatter: `finding_id`, `severity`, `change_type`, `referenced_files` + prose `message`).
2. Read artifact + diff file eagerly.
3. Read each `referenced_files` entry.
4. Lazy-read `<upstream_paths>` entries if cited or load-bearing.
5. Score 0–100 using rubric.
6. Write `<sidecar_path>` with YAML body:
   - Success: `score: <int 0..100>` + `reason: <≤1-sentence>`
   - Failure: `score: VERIFY_FAILED` + `reason: <one-sentence diagnosis>`
7. Return exactly one line: `<reviewer_tag>.<finding_id>: <score>` on success, or `<reviewer_tag>.<finding_id>: VERIFY_FAILED:<reason>` on failure.

The verifier never edits the finding file — only writes the sidecar (`agents/qrspi-finding-verifier.md`, line 64).

#### 2. Sidecar landing path

Sidecars land as siblings of their finding files, in the round directory:

```
<abs_run_dir>/reviews/{step}/round-NN/<reviewer_tag>.finding-F<NN>.score.yml
```

For example (`skills/using-qrspi/SKILL.md`, lines 824–825):
```
reviews/{step}/round-NN/quality-claude.finding-F01.score.yml
reviews/{step}/round-NN/quality-claude.finding-F02.score.yml
```

The orchestrator derives `sidecar_path` from `finding_file_path` by replacing `.md` with `.score.yml` and passes it to the verifier as an explicit parameter in the dispatch prompt.

**On-disk examples (from test fixtures and v0.7.1 hardening run):**
- `tests/fixtures/issue-109/round-enabled-clean/round-03/quality-claude.finding-F01.score.yml`: `score: 87` / `reason: real defect`
- `docs/qrspi/2026-05-27-v071-hardening/reviews/tasks/task-10/round-02/silent-failure-claude.finding-F01.score.yml`: `score: 72` + multi-sentence reason
- Legacy `.score.md` files exist for the v0.7.1 run (e.g., `reviews/tasks/task-10/round-01/quality-claude.finding-F01.score.md`; same YAML body, `.md` extension instead of `.yml`).

#### 3. End-to-end data path: verifier dispatch through apply-fix

The Apply-fix protocol is specified in `skills/using-qrspi/SKILL.md` lines 748–993.

**Step 1 (line 750–757): Enumerate per-reviewer outputs**
```bash
shopt -s nullglob
D="reviews/{step}/round-NN"
findings=( "$D"/*.finding-*.md )
cleans=( "$D"/*.clean.md )
```
Sidecars (`*.score.yml`) are intentionally NOT enumerated here; they are discovered per-finding inside the assembly loop.

**Step 2 (line 759): Schema-violation guard**
Per-expected-tag check: each expected reviewer tag must have produced at least one finding or clean sentinel. Malformed YAML, missing required fields, or out-of-enum `change_type` values route to the §3 failure menu.

**Step 3 (lines 797–811): Verifier-enabled gate**
Read `verifier_enabled` from `config.md`. If missing, backfill as `true` (runtime-backfill carve-out). If `false`, skip to step 5 with no sidecars on disk — all findings kept (keep-all path).

**Step 4 (lines 814–864): Parallel verifier dispatch**
For each finding file, dispatch one `qrspi-finding-verifier` Task subagent with:
```
subagent_type: qrspi-finding-verifier
description:   verify <reviewer_tag>.<finding_id>
prompt:
  finding_file_path: <abs_path>/reviews/{step}/round-NN/<reviewer_tag>.finding-F<NN>.md
  sidecar_path:      <abs_path>/reviews/{step}/round-NN/<reviewer_tag>.finding-F<NN>.score.yml
  artifact_path:     <abs_path>/<step>.md
  diff_file_path:    <abs_path>/reviews/{step}/round-NN.diff
  upstream_paths:    <newline-separated list>
```
All dispatches fire in parallel (one Task per finding file). Each verifier writes its `.score.yml` sidecar directly to disk.

**Chat-side return vs disk:** The verifier's brief return line (`<reviewer_tag>.<finding_id>: <score>`) is inspected **only** for the `VERIFY_FAILED:` prefix. If any return is `VERIFY_FAILED:` OR any expected sidecar is missing on disk after dispatch, route to the §3 failure menu (`skills/using-qrspi/SKILL.md` line 864). The sidecar on disk is the source of truth — main chat ignores the numeric score in the return text.

**Step 5 (lines 866–921): Round assembly into `round-NN-verified.md`**
A Bash assembly block:
```bash
# Pre-pass: compute totals over findings + sidecars.
scored=0; failed=0; dropped=0
for f in "${findings[@]}"; do
  sc="${f%.md}.score.yml"          # derive sidecar path
  [[ -f $sc ]] || continue
  if grep -q '^score: VERIFY_FAILED' "$sc"; then
    failed=$((failed + 1)); continue
  fi
  score=$(awk -F': *' '/^score:/ {print $2; exit}' "$sc")
  scored=$((scored + 1))
  ct=$(awk -F': *' '/^change_type:/ {print $2; exit}' "$f")
  threshold=80
  [[ $ct == "correctness" ]] && threshold=70
  if (( score < threshold )) && [[ $ct =~ ^(style|clarity|correctness)$ ]]; then
    dropped=$((dropped + 1))
  fi
done
kept=$(( ${#findings[@]} - dropped ))
```

Then emits `round-NN-verified.md` with:
- YAML frontmatter (`verifier_enabled`, `scored`, `kept`, `dropped`, `failed`, `clean`)
- For each finding: `<!-- @@FINDING: <basename> @@ -->` + finding file content + optional `<!-- @@SCORE: <basename> @@ -->` + sidecar content
- For each clean sentinel: `<!-- @@CLEAN: <basename> @@ -->` + clean file content

**Step 7 (line 980): Orchestrator reads `round-NN-verified.md` exactly once.**
```
reviews/{step}/round-NN-verified.md
```
This file is the single source from which the orchestrator makes all filtering decisions.

**Step 8 (lines 982–987): Filter and dispatch findings by `change_type`**
- `scope` / `intent`: bypass score filter entirely → existing pause gate
- `style` / `clarity`: require sidecar score ≥ 80 → kept → `Edit` on artifact
- `correctness`: require sidecar score ≥ 70 → kept → `Edit` on artifact
- Missing sidecar, `VERIFY_FAILED` sidecar, or verifier-disabled round: keep-all (favor surfacing)

**Step 9 (line 989): Write `round-NN-dispositions.md`**
Main-chat-authored ≤30-line summary of what was changed and why.

**Step 11 (line 993): Per-round commit**
Covers the artifact, the entire `round-NN/` subdir **including sidecars** (`.score.yml` files), `round-NN-scope-set.txt`, `round-NN-verified.md`, and `round-NN-dispositions.md`.

#### 4. Summary: source-of-truth authority

| Data path | Authority |
|---|---|
| Sidecar score value | `.score.yml` file on disk (read in step 5 assembly Bash) |
| Verifier failure detection | Chat-side return text (inspected for `VERIFY_FAILED:` prefix, step 4) |
| Filtering thresholds | Applied in step 5 pre-pass (Bash) + step 8 partition (orchestrator in-session) |
| Final kept-findings count | Orchestrator in-session tally (step 5 `kept` variable / `round-NN-verified.md` frontmatter) |
| Apply-fix decisions | Orchestrator reads `round-NN-verified.md` once (step 7), then partitions in step 8 |

The verifier's chat-side output is explicitly described as advisory/signal-only; the sidecar file is the canonical record. (`skills/using-qrspi/SKILL.md` line 864: *"main chat ignores the return text (the sidecar on disk is the source of truth)"*)

#### 5. File extension history note

The current agent spec (`agents/qrspi-finding-verifier.md`, line 36) mandates `.score.yml`. The CHANGELOG entry for issue #109 (2026-05-05) also specifies `.score.yml`. However, the v0.7.1 hardening run on disk contains `.score.md` sidecars in some task round directories (e.g., `reviews/tasks/task-03/round-09/gt-claude.finding-F03.score.md`, `reviews/tasks/task-10/round-01/quality-claude.finding-F01.score.md`). The `.score.md` files have identical YAML body content to `.score.yml` files — only the extension differs. The test fixture suite (`tests/fixtures/issue-109/`) exclusively uses `.score.yml`. The precise transition point within the v0.7.1 run is not determinable from the files examined.
