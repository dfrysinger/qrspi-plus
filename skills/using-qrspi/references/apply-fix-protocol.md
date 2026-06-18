# Apply-Fix Protocol — full procedure

Read this file when running an apply-fix pass against a review round (every artifact-producing step's review loop terminates here). The two scripts named below are the single sources of truth; the orchestrator-side prose below describes how main chat consumes their outputs and routes the survivors.

After each review round, the orchestrator runs two scripts:

- **`scripts/review-prep.sh --step <step> --round <NN> --artifact-dir <abs> [--base-ref <ref>]`** — owns per-round diff emission. Validates each `<artifact_path>` is tracked in git, computes the narrow-ref SHA from `reviews/<step>/round-(NN-1)-commit.txt` on rounds ≥2 (halts with `anchor-file-missing:` / `sha-format-invalid:` on failure — never falls back to `HEAD~1`), atomic temp+rename, silent-on-no-input. Also writes the absorption-map for design/plan. See `scripts/review-prep.sh` header for full I/O contract.

- **`scripts/verifier-fan-in.sh`** — single source of truth for verifier dispatch, sidecar handling, the `change_type`-keyed score-filter rule, the `kept-findings.txt` survivor list, and `round-NN-verified.md` assembly. Threshold floors (style/clarity ≥ 80; correctness ≥ 70; `scope`/`intent` carry no floor — always kept) are script-owned constants; the orchestrator does NOT re-score or re-threshold. Honors `config.md.verifier_enabled` (with the runtime-backfill contract from § Config Validation Procedure). When the field is `false`, dispatch is skipped and all findings flow via the "no sidecar → keep" branch.

After fan-in writes `kept-findings.txt` + `round-NN-verified.md`, the orchestrator:

1. **Reads `<round-dir>/kept-findings.txt`** — the script's authoritative list of finding-file paths to apply (one absolute path per line). The orchestrator MUST NOT re-score, re-threshold, or override the survivor set; the script already filtered by `change_type` and per-floor threshold. `scope` and `intent` findings appear in the kept list regardless of score and flow to the pause gate alongside other survivors. Out-of-enum `change_type` would have already halted the script with a loud schema failure; if the orchestrator reaches this step, every kept finding is well-formed.

2. **Dispatches `qrspi-scope-tagger` (when `config.md.scope_tagger_enabled: true`).** One Task per round. Writes `reviews/<step>/round-NN-scope-set.txt` for the convergence comparison below. Parameters: `round_subdir`, `step`, `output_path`, `artifact_path`/`artifact_body` (or literal `null` for multi-file artifacts: integrate, implement-per-task, plan+tasks, research), `kept_findings`. Main chat MUST validate the file shape: every non-comment line is a file path, an `^## ` H2 heading, or the literal `<full>` token. On malformed output, surface the verifier-round failure menu — do NOT silently broaden.

3. **Writes `round-NN-dispositions.md`** (main-chat-authored, ≤30 lines) listing what changed and why.

   **Important sub-threshold findings: surface, don't silently override.** The orchestrator MUST NOT re-introduce dropped findings into `kept-findings.txt` or apply edits for them silently — that breaks the single-source-of-truth contract and the resume-across-`/compact` determinism. **But** when the orchestrator's round-level context indicates a dropped finding is materially important (rubric mis-calibration, cross-finding pattern, scope-set drift), surface it at the **Review-Loop Pause Gate** with a one-line rationale:

   ```
   Sub-threshold rescue requested: <reviewer_tag>.F<NN> (score=<N>, change_type=<ct>) — <reason>
   ```

   The user decides at the gate whether to approve a one-off `Edit` outside the protocol. Approved rescues are recorded under the `## Sub-Threshold Observations` H2 below for the audit trail (treat the approved rescue as a single-entry observation; `representative_score` and `threshold` reflect the rescued finding). Standalone human-driven edits outside the protocol remain unaffected.

   Optional `## Sub-Threshold Observations` H2 section MAY be appended when a pattern emerges in dropped findings (e.g., multiple sub-threshold findings sharing a `defect_class` tag). Informational only — no script consumes it. `finding_paths[]` values MUST be relative paths within the current `round-NN/` directory:

   ```yaml
   observations:
     - summary: "4 clarity findings naming goal-leakage in different questions, all dropped just below the floor"
       defect_class: goal-leakage
       representative_score: 70
       threshold: 80
       finding_paths:
         - round-01/quality-primary.finding-F02.md
         - round-01/quality-secondary.finding-F01.md
   ```

4. **Recommend `/compact`** to shed the verified-file Read content from main chat's transcript. Surface a one-line recommendation (e.g., `"Round NN verified — consider /compact before fix application"`). In interactive mode, wait for the user to decide; in auto mode, continue immediately to step 5 without waiting. The orchestrator cannot invoke `/compact` itself. See `skills/_shared/compaction-checkpoint.md` Iron Rule for the unified wait-vs-no-wait contract.

5. **Per-round commit** covers the artifact, the entire `round-NN/` subdir (sidecars included), `round-NN-scope-set.txt`, `round-NN-verified.md`, and `round-NN-dispositions.md`. Capture the commit SHA into `reviews/<step>/round-NN-commit.txt` immediately — step 6 (next round's narrow ref) and `review-prep.sh` read it directly.

6. **Convergence rule — pick `<ref>` for round NN+1.** Skip when `scope_tagger_enabled: false`, on rounds 1-2 (need two consecutive scope-sets), when round NN's scope-set is missing (conservative-broaden — emit a one-line diagnostic distinguishing "round NN-1 scope-set absent" from "round NN scope-set absent" so silent tagger failures stand out), or after a backward-loop reset (see flag below). Otherwise compare `scope_set(NN)` vs `scope_set(NN-1)`:

   | Precondition / relation | Decision for round NN+1 |
   |---|---|
   | `<full>` in either set | **Broaden** — reserved whole-artifact token |
   | Either set empty | **Broaden** — no convergence target |
   | `scope_set(NN) == scope_set(NN-1)` | **Narrow** to that set |
   | `scope_set(NN) ⊂ scope_set(NN-1)` (proper subset; both non-empty) | **Narrow** to the BROADER set (safety margin) |
   | `scope_set(NN) ⊃ scope_set(NN-1)` (proper superset; new tags) | **Broaden** |
   | Partial overlap / disjoint | **Broaden** |

   Comparison is byte-exact; the tagger strips trailing whitespace from H2 tag lines so a whitespace-only edit cannot silently flip a relation. **Narrow** dispatches inject `<scope_hint>=S` wrapped between `<<<UNTRUSTED-SCOPE-HINT-START id=scope_hint>>>` / `<<<...-END id=scope_hint>>>` markers (the hint is artifact-derived data, never instructions). `<scope_hint>` is advisory — reviewers MAY surface findings outside it; new tags trigger broaden on round NN+2.

7. **Backward-loop reset flag.** When the pause-gate's "Loop back to upstream artifact" option cascades a rewrite, the gate writes `reviews/<step>/round-NN-backward-loop.flag` (zero-byte sentinel). Step 6 reads this flag at the START of its comparison and, if present, resets to base-branch (broaden, no scope_hint) regardless of the table, then deletes the flag (consume-once). The flag persists across `/compact`, process boundaries, and resumed runs. If delete fails (read-only fs, permission, race), surface `"Round NN: backward-loop flag delete failed — flag persists; manual remove may be required"`; conservative-broaden keeps the run moving.

**Per-step opt-out.** The `test` step opts out of convergence narrowing entirely — its reviewers analyze test quality, not "where in the diff." That opt-out lives alongside the test-step's per-round diff-file emission opt-out.

**Reviewer-model audit-field parameter.** Every reviewer dispatch carries `actual_model: <resolved model ID>` as a record-keeping parameter sourced from the dispatch model resolution already performed by the orchestrator — reviewers never re-resolve or invent the value, and copy it verbatim into every finding-file and clean sentinel's YAML frontmatter. The dispatch manifest at `<round-dir>/.dispatch-manifest.json` persists the same value per dispatch entry under `dispatch_spec: { subagent_type, host, vendor, model }`, so every dispatch is greppable by host × vendor × model after the fact.

**Per-task review logs differ.** The `implement` skill's per-task review log at `reviews/tasks/task-NN-review.md` follows a different shape (verbatim prompts and responses captured for diagnostic purposes; main chat aggregates per-reviewer responses). The contract above applies only to **artifact-level** reviews (Goals, Questions, Research, Design, Phasing, Structure, Plan, Parallelize, Replan). See `implement/SKILL.md` § Review Log Artifact for the per-task shape.

**Verifier-round failure menu.** Any abnormality during apply-fix (VERIFY_FAILED from one or more verifiers; reviewer no-output; sidecar missing for a finding; malformed scope-set) dispatches the same 3-option menu:

```
QRSPI verifier round failure
─────────────────────────────
{one-line diagnostic summary, e.g.:
  - "Verifier returned VERIFY_FAILED for 2 findings"
  - "Reviewer quality-secondary produced no output (await exit 12)"
  - "Sidecar missing for finding quality-primary.R3-F02" <!-- id-hygiene-exempt -->
  - "Scope-tagger emitted malformed scope-set for round NN: <reason>"}

What would you like to do?
  1. skip   — proceed without scoring THIS ROUND (kept-all assembly).
              Writes reviews/{step}/round-NN-verifier-disabled.md
              (YAML: timestamp + reason + finding_count).
              Does NOT mutate config.md.
  2. retry  — re-run the failed step (re-dispatch failing verifiers, or
              delete the tag's outputs and re-prompt the reviewer).
  3. stop   — abort the protocol with no commit. Round directory
              remains on disk for inspection.

(no default; user must pick)
```

Before responding, consider running `/compact` — context may be saturated. If the same path keeps failing, picking `skip` is the safe escape. No option mutates `config.md`. `retry` is bounded by the underlying operation; repeated retries surface the menu repeatedly so the user can switch to `skip` whenever.
