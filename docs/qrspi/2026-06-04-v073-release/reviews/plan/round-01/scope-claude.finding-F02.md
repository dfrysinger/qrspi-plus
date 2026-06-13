---
finding_id: R1-F02
severity: high
change_type: scope
referenced_files: [docs/qrspi/2026-06-04-v073-release/plan.md:L772, docs/qrspi/2026-06-04-v073-release/plan.md:L781, docs/qrspi/2026-06-04-v073-release/plan.md:L845-L850, docs/qrspi/2026-06-04-v073-release/plan.md:L930-L936, docs/qrspi/2026-06-04-v073-release/plan.md:L1030]
artifact: plan
round: 1
reviewer: scope-claude
---

The second `## Task Specs` section (L711+) carries content that `skills/plan/owns-defers.md` § Plan DEFERS routes to Implement (line-by-line logic / control-flow detail / algorithm pseudocode) and to Structure (interface contracts / file-internal coordinates). Four concrete instances, each load-bearing for the finding:

1. **T02 description (L772) — algorithmic flow.** "extracts the goal ID (e.g. `G3`) from each matched context and infers the absorbing ID from the heading-suffix form where present, emitting `\"no-task\"` for the three non-suffix forms" is per-input control-flow narration of the script's parser. The INVEST-Negotiable framing in owns-defers.md is explicit: "Plan says 'increment Redis counter on each allowed request'; Implement chooses `INCR` vs. `EVAL` with a Lua script." Plan should say "emit one map row per absorbed-goal occurrence, distinguishing the heading-suffix absorbing-ID form from the three no-task forms"; the per-matched-context extraction algorithm is Implement's.

2. **T02 test-expectations (L781) — implementation-detail leak.** "The script is executable (`chmod +x`) and has a `#!/usr/bin/env bash` shebang" specifies file-mode and shebang-line content — both Implement-layer choices that flow from Plan's "bash script" decision. Plan does not own the executable-bit or the interpreter directive.

3. **T04 description (L845-L850) — hard-coded literal value.** The literal email string `bot@qrspi.local` is named as part of T04's plan-level contract. Plan's actual requirement (G5: "subagent commits carry the marker the G5 boundary check filters on") is satisfied by any author-marker scheme the boundary-check filter recognises; the specific email-address string is an Implement choice. Pinning the literal in Plan forecloses Implement's negotiation room (Conversation-not-contract per owns-defers.md § INVEST Negotiable framing).

4. **T05 description (L930-L936) — regex pseudocode.** The structural-lint script is described by its exact grep grammar: "exits 0 when the diff contains only removal of lines matching `git( -C [^ ]*)? diff.*>.*round-NN\\.diff` and `mkdir -p\\|rm -f\\|exit.*check\\|Pre-dispatch diff-file emission` patterns plus addition of lines matching `dispatch-agent\\.sh --step [a-z]+ --round`". Regex grammar is the Implement-layer surface for a grep-based lint; Plan's job is the behavioral claim ("structural-lint script proves the diff is a mechanical T05 sweep — only the documented removal patterns and the dispatch-agent-line addition; any other hunk fails the lint"). The lexical-boundary-drift signal in owns-defers.md lists "line-numbered logic walkthroughs" as an Implement-layer leak; this is the same shape.

5. **T07 description (L1030) — file-internal-coordinate leak.** "immediately before the `---` separator that opens the cross-cutting principles section (currently after R7 at line 99)" carries a current-file line number. Line numbers are Structure-layer file-internal coordinates that drift the moment the upstream file is edited; the content-anchored half of the sentence ("immediately before the `---` separator that opens the cross-cutting principles section") is exactly the right Plan-layer phrasing — the parenthetical line number should be dropped.

Resolution shape: every Plan DEFERS leak above belongs in Implement's choice space. The fix is not to delete the test-expectations / acceptance behaviour each describes, but to restate the Plan-layer claim in behavioral terms (what observable property must hold) and let Implement choose the literal, the regex, the shebang, the file-mode, and the line position that satisfy it.
