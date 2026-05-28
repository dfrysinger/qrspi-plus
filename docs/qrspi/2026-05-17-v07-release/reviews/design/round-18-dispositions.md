---
round: 18
artifact: design
status: targeted-fix-then-approve
---

# Round 18 dispositions (targeted-fix path, user-approved)

## Findings inventory

- quality-claude: 4 findings (medium=2, low=2)
- scope-claude: 0 (clean — 16th consecutive)
- quality-codex: 3 findings (high=1, medium=2)
- scope-codex: 0 (clean — 14th consecutive)

Total: 7 findings, 1 HIGH. User selected targeted-fix path (B) at round-18 gate: fix the HIGH + 2 load-bearing mediums; defer the other 4 to `future-design.md` for Phasing.

## FIX (3 findings)

### R18-F01 quality-codex (HIGH, correctness) — accept. G2 universal dispatcher contract incompatibility

The supplementary R17-USER-01 fix said the dispatcher always populates `--output-file` AND that the Codex transport "returns the jobId for separate await." These contracts contradict — an async launch cannot also satisfy the smoke test that expects `--output-file` populated on exit 0.

**Fix:** Choose ONE universal contract. The dispatcher always BLOCKS until `--output-file` is populated, hiding the launch/await asymmetry internally. For Codex transport: the script internally invokes `codex-companion-bg.sh launch` to get a jobId, then immediately blocks on `codex-companion-bg.sh await` against that jobId, and writes the awaited result to `--output-file`. Callers see one symmetric contract: prompt in on stdin → result in `--output-file` on exit 0.

Update G2 in three places:
- Recommendation: state explicitly "the dispatcher always blocks until `--output-file` is populated; for `codex-broker` transport, the script internally invokes launch+await; for `openai-chat-completions` transport, the script blocks on the HTTPS response. Callers see one symmetric blocking contract."
- Remove any mention of "returns the jobId for separate await" from the transport-type vocabulary block.
- Update transport-type test bullet to: "Both transport types block until --output-file is populated; codex-broker transport internally chains launch+await; openai-chat-completions transport blocks on the HTTPS response. Smoke test confirms output-file populated on exit 0 for every provider in `config.md`."

Note: callers that want async behavior can run the script under Bash `run_in_background:true` — the symmetric blocking contract composes naturally with shell backgrounding, no special async API needed.

### R18-F01 quality-claude (medium, scope) — accept. G1 condition: schema slot YAGNI

Earlier rounds dropped the predicate keys (`citation_density_floor`, `input_volume_max`, `task_type`) but the `condition:` schema slot itself remained. No v0.7 consumer.

**Fix:** Remove the `condition:` schema example block from G1 entirely. Replace with a prose note: "Conditional routing is an extensibility point reserved for future goals. The v0.7 routing schema is unconditional (no `condition:` clauses, no predicate vocabulary). Future goals that need conditional routing will add the schema slot alongside concrete predicates and dispatch-site consumers."

Drop the G1 conditional-routing test bullet. Update Decision 1's G1/G2/G5 framing to drop the "conditional routing" mention.

### R18-F02 quality-claude (medium, correctness) — accept. G5 citation-density floor underspecified

Citation-density post-output validator needs: config key name, default, computational definition.

**Fix:** Add a "Citation-density validator specification" subsection to G5:
- **Config key:** `validators.citation_density_floor:` (under `config.md`'s `validators:` block; new section).
- **Default value:** `0.05` (one citation per 20 lines of research output — round-number conservative default; Plan can tune).
- **Computational definition:** citation count divided by total non-blank line count of the specialist's `q*.md` output. A citation is any `Q\d+` reference OR any external URL OR any `file:line` reference. Below-floor output triggers trusted-model re-run; the re-run is recorded once per specialist invocation (no infinite loops).
- **Test bullet:** specialist output with citation density 0.03 (below default 0.05) triggers exactly one trusted-model re-run; specialist output with density 0.06 proceeds.

## DEFER to future-design.md (4 findings)

These 4 findings are captured in `docs/qrspi/2026-05-17-v07-release/future-design.md` for Phasing to absorb into a future phase or release. They are not load-bearing for v0.7's design contract:

- R18-F02 quality-codex (medium): G1 cross-cutting test uses `model_routing.research-collator: cheap` but schema requires `{provider, model}` — `cheap` is not a legal value. **Test wording error, not design contract gap.**
- R18-F03 quality-codex (medium): G17 Option-A'-load-bearing test uses `${!array[@]}` as bash-4-only example, but it's valid in bash 3.2+. **Test fixture choice error, not design contract gap.**
- R18-F03 quality-claude (low): G3 cross-cutting test omits N=2 boundary case (covers ≥3 and 1, not 2). **Test enumeration gap, clarity.**
- R18-F04 quality-claude (low): G3 "~150-200 lines" estimate still attributed to Q6/Q7 — same class as R17-F05. **Citation attribution polish.**

## Fix dispatch plan

Single fix subagent. 3 accepts. After fix, create `future-design.md` with the 4 deferrals.

## Status

draft → fixing (targeted) → human gate → approved (pending user confirmation).
