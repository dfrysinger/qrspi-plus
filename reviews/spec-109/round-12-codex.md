**Assembly / Parsing**

1. `finding_id`: `R12-F01`

   `severity`: `high`
   `change_type`: `correctness`
   `message`: `The assembled verified file is not parseable with the contract as written. The spec says main chat assembles per-finding files, sidecars, clean markers, and crash files into one round-NN-verified.md and then reads that file exactly once (lines 9, 141-154). But a finding file is YAML frontmatter plus arbitrary free-form prose body (lines 74-87), while a sidecar is just two bare YAML-looking lines with no delimiter (lines 51-60). After cat, the reader no longer knows where a finding body ends and its sidecar or a following crash/clean file begins. A single-read consumer can only recover this with brittle heuristics, which is exactly the kind of hidden parsing dependency the simplification was supposed to remove. The assembly needs an explicit per-record boundary/manifest format (for example, assembler-inserted sentinels or a structured wrapper that preserves file identity) before this can be implemented safely.`
   `referenced_files`: `["docs/superpowers/specs/2026-05-04-109-sonnet-haiku-verifier-design.md"]`

2. `finding_id`: `R12-F02`

   `severity`: `high`
   `change_type`: `correctness`
   `message`: `The round file glob will misclassify score sidecars as finding files on any retry/resume path. Sidecars are named by replacing .md with .score.md on the finding path (lines 41-42), while step 1 enumerates findings with "$D"/*.finding-*.md (lines 129-145). A file like quality-claude.finding-F01.score.md matches that glob. Once any sidecar already exists on disk, step 1 will treat it as a finding, step 2 will try to schema-validate it as a finding object, and step 6 will derive a bogus .score.score.md path from it. Narrow the finding glob so it cannot match sidecars, or store sidecars under a disjoint naming scheme/directory.`
   `referenced_files`: `["docs/superpowers/specs/2026-05-04-109-sonnet-haiku-verifier-design.md"]`

**Crash / Retry Semantics**

3. `finding_id`: `R12-F03`

   `severity`: `high`
   `change_type`: `correctness`
   `message`: `Crash files are defined as frontmatter-free audit artifacts, but the schema guard does not exempt them. The splitter writes <reviewer_tag>.crash.md with raw stdout and explicitly says "NO synthetic frontmatter" (lines 117-121). Step 2 then says it "fails loud on: malformed YAML, missing required fields..." (line 137), and step 8 expects crash files to flow through the reviewer-failure path (line 154). As written, an expected-tag crash output is indistinguishable from malformed output to the guard, so the intended crash path can be rejected before it ever reaches the menu/pause handling. The spec needs either a minimal crash-file schema or an explicit rule that crash files bypass finding-schema validation.`
   `referenced_files`: `["docs/superpowers/specs/2026-05-04-109-sonnet-haiku-verifier-design.md"]`

4. `finding_id`: `R12-F04`

   `severity`: `high`
   `change_type`: `correctness`
   `message`: `The retry path does not define cleanup of stale crash/failure artifacts, so a successful retry can be discarded. Step 3 always stages a tag's finding files into .crash-skipped/ when that tag has both a crash file and finding files (line 138). The failure menu then says retry re-runs the splitter or re-prompts the reviewer against the same round (lines 225-228), but it never says to delete or replace the original <tag>.crash.md or stale sidecars first. That means a retried reviewer can successfully produce findings, and the next pass will immediately re-stage them as "crash-skipped" because the old crash marker is still present. The retry contract needs per-tag cleanup/replacement semantics before re-dispatch.`
   `referenced_files`: `["docs/superpowers/specs/2026-05-04-109-sonnet-haiku-verifier-design.md"]`

**Verifier State**

5. `finding_id`: `R12-F05`

   `severity`: `medium`
   `change_type`: `correctness`
   `message`: `skip is too strong a primitive for the failure it handles. The config field is run-global and durable (lines 165-168), and the failure menu says a single skip both keeps the current round unscored and flips verifier_enabled: false "for the rest of this run" (lines 221-237). On a transient verifier outage or one malformed Codex emission, every later round loses score-filtering too, even though those later rounds may be healthy. That is a behavioral regression introduced by the simplification, not just a UX choice. Make skip round-scoped by default, and if you want a persistent opt-out, expose it as a separate explicit action rather than coupling it to the transient-failure escape hatch.`
   `referenced_files`: `["docs/superpowers/specs/2026-05-04-109-sonnet-haiku-verifier-design.md"]`
