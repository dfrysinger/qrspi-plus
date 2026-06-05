# Task 10 — Round 2 Fan-in

**HEAD before fix:** `5a8f1cb…` (R1 fix commit)
**Round-02 diff:** `round-02.diff` (264 lines, base `7aa0ecc` = T09 terminal)
**Reviewers run:** spec (claude + codex), cq (claude + codex), sf (claude + codex), sec (claude + codex) — 8 dispatches; cq-claude/cq-codex/sf-claude/sf-codex/sec-claude returned with findings; spec-claude/sec-codex CLEAN; spec-codex 1 procedural.

## Convergence map

| # | Issue | Convergent reviewers | Combined severity | Disposition |
|---|---|---|---|---|
| A | Score-precision: prose says "each finding's score" but template shows single scalar | cq-claude F01 (LOW) + sf-claude F01 (MED) | **MED** | KEEP — rename `score:` to `representative_score:` + update prose |
| B | `[G28 ACN]` prefix in 5 @test names (QRSPI-internal ID leak in code surface) | cq-claude F02 (LOW) + cq-codex F01 (HIGH) | **MED** | KEEP — strip prefix from 5 @test names |
| C | mktemp -d not cleaned on early-return paths in AC4 | cq-claude F03 (LOW) + cq-codex F02 (LOW) | **LOW** | KEEP — `trap 'rm -rf "$tmp"' EXIT` |
| D | grep -q exits 2 on missing file → silent test pass; AC4 reintroduces anti-pattern already documented at L1880 + adds `2>/dev/null` | sf-claude F02 (HIGH) + sf-codex F01 (MED) | **HIGH** | KEEP — add `[ -f "$tmp/kept-findings.txt" ]` precondition + remove `2>/dev/null` |

## Novel findings (single-reviewer)

| # | Reviewer | Finding | Severity | Disposition |
|---|---|---|---|---|
| E | sec-claude F01 | defect_class regex constraint instruction-only; no post-write validation; future YAML duplicate-key injection vector | MED | **KEEP (partial)** — document field-ordering invariant in fan-in script header; defer script-level regex enforcement to v0.7.3 backlog |
| F | sec-claude F02 | finding_paths[] has no path-traversal constraint | LOW | KEEP — add prose constraint + AC5 sub-assertion |
| G | sec-claude F03 | summary: no mandatory-quoting rule; YAML-structural chars in reviewer prose can corrupt block | LOW | KEEP — add prose requirement (MUST quote, MUST escape `"` as `\"`) |
| H | sf-claude F03 | `defect_class: unspecified` unconditionally valid for failure sidecars → crash-type cluster collapse | LOW | KEEP — tighten failure-sidecar template guidance: require best-effort failure class |
| I | sf-claude F04 | Verifier procedure has no on-error branch; early-step crash → no failure sidecar → fan-in falls back to keep-all → no `verifier-crash` record | MED | KEEP — add explicit on-error instruction before step 1 |
| J | spec-codex R2 F01 | Procedural: no explicit RED-transcript evidence beyond implementer self-report | MED (procedural) | DEFER — already-disposed in R2 spec-gate (procedural-evidence-satisfied; R1 fix DONE report documents RED→GREEN per finding) |

## R2 fix instructions (for implementer)

Total: **9 fixes**, all surgical, all to existing modified files (no new files). Test-first discipline applies — write/update failing tests, then fix.

### Fix A — score semantics (skills/using-qrspi/SKILL.md L995-L1008)
Rename single-scalar `score:` field to `representative_score:` in the observations template (L1003 area). Update prose at L995 from "each finding's `score`" to "the representative `score` (typically the minimum score in the cluster) and the `threshold` that dropped them". Note that per-finding scores are NOT preserved in this template by design; if per-finding precision is needed downstream, the individual sidecar files at `finding_paths[]` carry them.

### Fix B — G28 ID hygiene (tests/acceptance/v07-phase1/test-phase1-acceptance.bats)
Strip `[G28 ACN]` prefix from 5 `@test` names. Replace with `[ACN]` only. AC1/AC2/AC3/AC4/AC5 lines.

### Fix C — temp-dir cleanup (tests/acceptance/v07-phase1/test-phase1-acceptance.bats AC4 ~L2010-L2032)
Replace bare `tmp="$(mktemp -d)"` with `tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT`. Remove the existing `rm -rf "$tmp"` line on success path (now redundant). Cleanup will fire on every exit path.

### Fix D — grep -q exit-2 (tests/acceptance/v07-phase1/test-phase1-acceptance.bats AC4 ~L2023-L2030)
Immediately after the `run` assertion (before the two `if grep -q ... 2>/dev/null` blocks), add:
```bash
[ -f "$tmp/kept-findings.txt" ] \
  || { echo "kept-findings.txt was not written by fan-in script"; return 1; }
```
Then remove `2>/dev/null` from both `grep -q` calls.

### Fix E — defect_class field-ordering invariant (scripts/verifier-fan-in.sh header + agents/qrspi-finding-verifier.md)
In the failure-sidecar template at agents/qrspi-finding-verifier.md L114-L122, reorder fields so `score:` appears BEFORE `defect_class:` (matches success template). Add a one-line note in the agent prose: "Field ordering is load-bearing: `score:` MUST precede `defect_class:` in all sidecars to protect against duplicate-key YAML parser drift." Add equivalent note to `scripts/verifier-fan-in.sh` header. Add unit test pinning field order.

### Fix F — finding_paths traversal (skills/using-qrspi/SKILL.md + AC5)
Add to SKILL.md observations-block prose: "`finding_paths[]` values MUST be relative paths within the current `round-NN/` directory and MUST NOT contain `../` components or absolute paths." Add AC5 sub-assertion: `! printf '%s\n' "$yaml" | grep -qE '(\.\./|^\s*-\s*/)'`.

### Fix G — summary quoting (skills/using-qrspi/SKILL.md)
Add to SKILL.md observations-block prose: "The `summary:` value MUST be enclosed in double quotes; any `\"` characters in the value MUST be escaped as `\\\"`. Orchestrators MUST NOT copy reviewer finding text verbatim into the summary without stripping or escaping YAML-unsafe characters (`:`, `&`, `*`, `!`, `|`, `>`, etc.)."

### Fix H — unspecified failure-class tightening (agents/qrspi-finding-verifier.md L96, L119)
Update L96 prose: replace "whose evaluation never produced a defect signal — emit literal `defect_class: unspecified`" with "whose verdict reached a conclusion but did not identify a classifiable defect — emit literal `defect_class: unspecified`. For failure-path sidecars (verifier_status: failed), make best-effort classification from `verifier-crash`, `infrastructure-failure`, `tool-error`, `file-missing`, `rate-limited`; reserve `unspecified` for the genuine no-signal case."

### Fix I — on-error branch (agents/qrspi-finding-verifier.md procedure)
Add as a new top-level paragraph immediately BEFORE step 1 of the procedure:
> **On any unrecoverable error during steps 1–5** (tool failure, file missing, rate-limit, parse error): stop the normal path and go directly to step 6 using the "On failure" sidecar template at L114-L122, populating `defect_class:` with the best-fit failure class per the H taxonomy and `failure_reason:` with a one-sentence diagnosis. **Never return without writing a sidecar** — silent return causes fan-in to fall back to keep-all and produces no verifier-crash record for observability.

### Acceptance criteria for this fix-cycle

1. All 9 fixes land in the cumulative diff.
2. All existing tests still GREEN (83/83 baseline).
3. New AC5 path-traversal sub-assertion GREEN.
4. New unit test pinning sidecar field-order GREEN.
5. Diff stays within 4 files (no new files); fan-in script header gets a one-line invariant note (file count = 4 or 5 if SKILL.md hardening forces new sub-section).

## Plugin-issue backlog adds (for v0.7.3)

- **PI-V072-T10-001:** Verifier procedure should fall-through to failure-sidecar template on early-step crash. Currently no on-error instruction → no sidecar written → fan-in keep-all fallback → silent loss of crash telemetry. (Codified as Fix I in this round; backlog tracks deeper "validate sidecar was written" check in fan-in script.)
- **PI-V072-T10-002:** `verifier-fan-in.sh` should validate `defect_class:` regex against the documented pattern and emit a non-halting warning on violation. Currently the constraint is instruction-only.
- **PI-V072-T10-003:** Future cluster-analysis tooling that parses sidecar YAML should use a parser that rejects duplicate keys (not pyyaml default last-value-wins). Document as required.
