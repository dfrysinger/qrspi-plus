---
artifact: design
reviewer_tag: scope-claude
round: 4
status: clean
---

# scope-claude — round 4 — clean

No scope/boundary-drift findings.

## Procedure applied

Read goals.md G34 first per operator's CRITICAL CONTEXT directive. G34 amends
the Design scope-reviewer's effective OWNS/DEFERS contract for v0.7.2:

- **OWNS additions (G34 D2):** detailed solution descriptions with full edge
  cases, end-to-end flows specifying actor sequence + per-step inputs/outputs,
  prompt-writing specifics (verbatim or paraphrased SKILL/agent prose when
  load-bearing), acceptance criteria including concrete examples and rough
  test-pairing shapes, per-solution diagrams per goal/CD block, naming and
  renames establishing cross-skill vocabulary, dependency-justified
  release-assignment phrases.
- **DEFERS retained (G34 D3):** function bodies with executable logic, full
  unit-test code, executable shell beyond a few illustrative lines (UNLESS the
  body IS the dispatch contract downstream consumers must read), file
  architecture (Structure's), unified system-wide architecture diagrams
  (Structure's), unified Test Strategy/Architecture (Structure's), task
  carving (Plan's).

Applied the 3-check procedure against the G34-amended contract over the full
3021-line base-branch diff (round 4 broadened to base-branch per
`scope_hint: (none)`).

## Boundary-drift detection

Scanned for the GENUINE scope concerns the operator named:

1. **Literal test assertions (`assert_equal "expected" "$actual"`-style code)**
   — not found. Acceptance criteria use shape language throughout (e.g.,
   "assert exit 10 AND stderr matches the orchestrator-bug diagnostic regex",
   "asserts non-zero exit and a diagnostic written to stderr naming the
   unconfigured tier", "fixture asserts both scope variants"). All
   acceptance-criteria-altitude per G34 OWNS.

2. **Full bash scripts inlined without dispatch-contract justification** —
   closest candidates:
   - G4 `round-prepare.sh` step 1 (~25 lines) — exit codes 10/11/12 are
     consumed by main chat's between-rounds recovery branch per CD-1 #3.
     Script body IS the dispatch contract. PI-HKP-005 R3 user-override
     precedent applies; G34-blessed per "script-body shapes when the script
     body IS the dispatch contract."
   - G16 `assert_path_under_repo_root` (~22 lines) — function body shape +
     stderr format is the security contract consumed by the bats fixtures in
     G16 deliverable 3 (which assert `"resolves outside repository"` stderr
     substring). Same dispatch-contract bless applies.
   - CD-4 §C 5-step `verifier-fan-in.sh` algorithm — prose enumeration of
     script behavior (halt conditions, audit JSON shape), not bash code; this
     IS the dispatch contract downstream consumers (using-qrspi, implement)
     read.
   None cross the G34 line under the dispatch-contract carve-out + R3
   user-override disposition.

3. **File paths to implementation modules Structure should own** — G16/G17
   cite specific line numbers in existing files as edit-site anchors
   (modification of existing files, not authoring of new file layouts). G22
   enumerates the 41-agent tier rubric (the rubric IS the design decision per
   CD-1's tier schema, not Structure's file map). G27/G31/G32 name new files
   by purpose and identity per G34 OWNS "naming and renames that establish
   cross-skill vocabulary." No Structure-altitude file-architecture leakage.

## Phasing-altitude scan

Many "v0.7.3+ follow-up" deferrals appear across G14/G15/G18/G19/G20/G21/G22/
G23/G24/G25/G26/G27/G28/G29/G31/G32/G34/G35, but each carries either
dependency-edge framing (e.g., "G27 lands AFTER CD-1 and AFTER G22 — both
upstreams must settle before G27's cross-link anchors are stable", "G34/G35
hard-depend on G32") or explicit operator-scope-decision framing (e.g.,
"investigation-first scope per goals dialogue"). No intra-v0.7.2 "Phase 1
ships X / Phase 2 ships Y" carving was found — that's `qrspi:phasing`'s
territory and is correctly absent from design.md per the existing
DEFERS pointer.

## Goals-altitude scan

Per-goal "Plain-language problem" / "Why we care" blocks (G10, G15, G16, G17,
G18, G19, G20, G21, G22, G23, G24, G25, G26, G27, G28, G31, G32, G34, G35)
ground each design decision with minimal context anchor; they do not
re-litigate goals.md problem framing wholesale. This pattern was present in
R1-R3 and is operator-blessed per the R1 decisions file's "phasing-leakage
phrases throughout — all kept per operator decision" disposition, which
extends naturally to problem-framing prose under PI-HKP-005's broader
user-override stance.

## Scope compliance per OWNS

Every goal in goals.md (G1-G35) and every cross-cutting decision (CD-1, CD-2,
CD-3, CD-4) has a per-goal/per-CD solution block present. G1's per-goal
template (Outcome / Solution / Why this approach / Dependencies + edge cases
/ Acceptance) is followed throughout. Per-solution Mermaid diagrams present
where load-bearing (CD-4). Rename inventories present (CD-1, G3). Sub-Rule C
end-to-end flow elements (actor inventory, sequence, per-step I/O, consumers,
loud-failure paths, context-cost callouts) specified for multi-actor
decisions (CD-1, CD-4, G4, G9). No OWNS gap detected.

## PI-HKP-005 directive applied

Per the operator's R4 directive, the three recurring categories — G4
round-prepare.sh body, CD-1 dispatch-agent.sh flag enumeration, assertion-
text examples in acceptance criteria — are G34-blessed and declined as
findings this round. No new round-4 surfaces were found that cross the G34
amended boundary and aren't already absorbed by the PI-HKP-005 disposition.
