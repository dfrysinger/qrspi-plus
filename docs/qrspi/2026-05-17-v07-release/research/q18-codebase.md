---
status: draft
question_ids: [18,19]
research_type: codebase
---

# Q18, Q19: Unit BATS path scanning and SKILL-body extraction patterns

## Summary

**TL;DR:** `tests/unit/test-u14-lint.bats` does not dynamically scan all skills; it hardcodes a five-file `IN_SCOPE_FILES` array and applies each lint by iterating that array. Its excluded-skill check is a negative substring assertion over each path, while other unit tests that derive skill identity from paths use `basename "$(dirname "$path")"` after grepping `skills/*/SKILL.md`. Across SKILL-body assertion tests, the dominant convention is to extract a heading-bounded block with `awk`, then grep only the extracted slice to avoid whole-file false positives.

**Key findings:**
- Q18: `test-u14-lint.bats` builds scope from five explicit absolute paths rooted at `REPO_ROOT`, not from `find`, globbed all-skill discovery, or `grep -l` output.
- Q18: The U14 excluded-skill check loops over `IN_SCOPE_FILES` and asserts each file path does not contain excluded directory substrings such as `"/implement/"`, `"/research/"`, or `"/parallelize/"`.
- Q18: `test-using-qrspi.bats` is the clearest adjacent pattern for deriving skill identity from file paths: after `grep -l... "$skills_root"/*/SKILL.md`, it uses `basename "$(dirname "$path")"` to convert a `skills/<slug>/SKILL.md` path into `<slug>`.
- Q19: Repeated extraction helpers use exact heading-line matches (`$0 == h`) to enter a block and `^## ` / `^### ` boundaries to stop or reset the block.
- Q19: Several tests handle nested H3 blocks either by piping an extracted H2 section into a second `awk`, or by directly extracting H3 blocks from `owns-defers.md` files that begin at H3 level.
- Q19: Recurrent conventions include comments stating why section-scoped extraction is used, `[ -n "$block" ]` guards after extraction, `grep -q`/`grep -Eqi` assertions on slices, and sentence/paragraph splitting with `awk` record separators for co-occurrence checks.

**Surprises:** `test-cross-skill-contracts.bats` does not use section extraction despite being named in the question; it uses deliberately broad file-level `grep` checks, and its header explicitly calls this a loose-grep style.

**Caveats:** Investigation sampled the named files plus adjacent `tests/unit/` SKILL-body assertion tests found by searching for `extract_h2`, `extract_h3`, `awk -v`, and markdown heading boundary patterns. It did not exhaustively read every BATS file in `tests/unit/`.

## Full findings

### Query Planning

Planned searches before inspection:
- Read the two named target files plus `test-u14-lint.bats`.
- Search `tests/unit/` for path-derived skill identity patterns: `basename`, `dirname`, `/skills/`, `SKILL.md`, `skill_slug`, and similar terms.
- Search `tests/unit/` for SKILL-body extraction helpers and heading-boundary idioms: `extract_h2`, `extract_h3`, `extract_`, `awk -v`, `^## `, `^### `, and `RS =`.
- Compare the named files with similar tests that assert prompt/SKILL markdown content, especially phasing, artifact-gating, scope-reviewer, replan, and reviewer-protocol tests.

### Q18: U14 file-path scan, excluded-skill substring check, and path-derived skill identity in other BATS tests

#### `test-u14-lint.bats` scope construction

`tests/unit/test-u14-lint.bats` documents its lint scope as five SKILL files only: `skills/goals/SKILL.md`, `skills/design/SKILL.md`, `skills/phasing/SKILL.md`, `skills/structure/SKILL.md`, and `skills/plan/SKILL.md` (`tests/unit/test-u14-lint.bats:39-45`). The header states this list is hardcoded as a BATS array and is not all `skills/**/*.md` (`tests/unit/test-u14-lint.bats:8-10`).

The actual setup matches the header: `setup()` computes `REPO_ROOT` from `$BATS_TEST_DIRNAME/../..`, sets `FIXTURE_DIR`, and defines `IN_SCOPE_FILES` with the five absolute paths (`tests/unit/test-u14-lint.bats:52-65`). The array entries are direct path literals rooted at `$REPO_ROOT` (`tests/unit/test-u14-lint.bats:58-64`). No dynamic `find`, `rg`, or `grep -l` discovery is used to build this scope.

Each lint runs over the same array by looping `for f in "${IN_SCOPE_FILES[@]}"; do ... done`. Examples:
- Claim-line clean-state loop: `tests/unit/test-u14-lint.bats:326-337`.
- Paragraph-density clean-state loop: `tests/unit/test-u14-lint.bats:362-372`.
- Scannability clean-state loop: `tests/unit/test-u14-lint.bats:386-397`.
- No-brevity clean-state loop: `tests/unit/test-u14-lint.bats:451-462`.

The file includes one explicit scope-shape test that asserts the array length is exactly five and that every array entry exists as a file (`tests/unit/test-u14-lint.bats:468-474`).

#### `test-u14-lint.bats` excluded-skill substring check

The excluded-skill assertion is the test named `[U14-scope] in-scope set excludes implement/integrate/test/replan/using-qrspi/research/questions/parallelize` (`tests/unit/test-u14-lint.bats:476`). Its comment calls it a counter-assertion: “no in-scope path should match these out-of-scope skill slugs” (`tests/unit/test-u14-lint.bats:477`).

Implementation details:
- It iterates `for f in "${IN_SCOPE_FILES[@]}"` (`tests/unit/test-u14-lint.bats:479`).
- It uses Bash pattern assertions against the full file path: `[[ "$f" != *"/implement/"* ]]`, and similarly for each excluded skill directory (`tests/unit/test-u14-lint.bats:480-487`).
- The excluded substrings include directory separators around the slug: `/implement/`, `/integrate/`, `/test/`, `/replan/`, `/using-qrspi/`, `/research/`, `/questions/`, and `/parallelize/` (`tests/unit/test-u14-lint.bats:480-487`).

This means the U14 exclusion check is path-substring based and directory-segment-aware. It does not parse the skill slug with `basename` and does not compare against an exclusion array; it uses direct negative glob assertions for each excluded directory substring.

#### Other BATS tests deriving skill identity from file paths

The clearest `tests/unit/` examples are in `tests/unit/test-using-qrspi.bats`, where tests discover skill files by grepping `skills/*/SKILL.md` and then derive the skill name from the parent directory:

- In the validator-table completeness test, the code reads each matching `path`, sets `name=$(basename "$(dirname "$path")")`, and appends that value to `invokers` (`tests/unit/test-using-qrspi.bats:207-214`). The source paths come from `grep -lF "Apply the **Config Validation Procedure**" "$skills_root"/*/SKILL.md 2>/dev/null | sort -u` (`tests/unit/test-using-qrspi.bats:214`). The derived `name` is then compared against a lowercased table blob, with `using-qrspi` skipped because it defines the procedure rather than validating its own config (`tests/unit/test-using-qrspi.bats:216-225`).
- In the codex_reviews parity test, the same identity derivation appears: `name=$(basename "$(dirname "$path")")` while reading paths produced by `grep -lE "validates.*\`?codex_reviews\`?" "$skills_root"/*/SKILL.md 2>/dev/null | sort -u` (`tests/unit/test-using-qrspi.bats:244-250`). Derived names are again compared against the relevant documentation row, with `using-qrspi` skipped (`tests/unit/test-using-qrspi.bats:252-260`).

Observed pattern: when tests need dynamic skill identity from a `skills/<skill>/SKILL.md` path, they derive it from the parent directory using `basename "$(dirname "$path")"`; when tests only need a fixed skill set, they typically assign named variables directly to canonical paths, e.g. `PLAN_FILE="$BATS_TEST_DIRNAME/../../skills/plan/SKILL.md"` in `test-artifact-gating.bats` (`tests/unit/test-artifact-gating.bats:20-25`) and similar setup variables in `test-skill-md-content-patterns.bats` (`tests/unit/test-skill-md-content-patterns.bats:32-41`).

### Q19: Recurring awk/grep section-extraction patterns and shared conventions

#### Named file: `test-skill-md-content-patterns.bats`

`tests/unit/test-skill-md-content-patterns.bats` states its central testing convention in the header: assertions extract a target heading’s section text first, stopping at the next `^## ` or `^### ` heading, so strings under other headings cannot satisfy a check accidentally (`tests/unit/test-skill-md-content-patterns.bats:27-30`).

It defines three reusable extraction helpers:

1. `extract_h2_section <file> <h2-heading>`:
   - Exact heading match: `$0 == h { in_b = 1; print; next }` (`tests/unit/test-skill-md-content-patterns.bats:50-51`).
   - Stop at the next H2: `in_b && /^## / { exit }` (`tests/unit/test-skill-md-content-patterns.bats:52`).
   - Print lines while in the block (`tests/unit/test-skill-md-content-patterns.bats:53`).

2. `extract_h3_subsection <file> <h2-heading> <h3-heading>`:
   - First pipes through `extract_h2_section "$file" "$h2"` (`tests/unit/test-skill-md-content-patterns.bats:64`).
   - Then exact-matches the requested H3 and exits on the next H3 or H2 (`tests/unit/test-skill-md-content-patterns.bats:65-70`).

3. `extract_h3_direct <file> <h3-heading>`:
   - Exact-matches an H3 directly in a file and stops on next H3 or H2 (`tests/unit/test-skill-md-content-patterns.bats:76-84`).
   - Its comment says this is for `owns-defers.md` files that start at H3 level (`tests/unit/test-skill-md-content-patterns.bats:73-75`).

A special-case `extract_review_round` helper tracks fenced code blocks while extracting `### Review Round`, because fenced template content contains headings like `## Approach` and `## Key Decisions` that would confuse simple heading-boundary extraction (`tests/unit/test-skill-md-content-patterns.bats:196-201`). Its `awk` toggles `fence` on lines matching `^````, enters only on an out-of-fence `### Review Round`, and stops only on out-of-fence `### ` or `## ` headings (`tests/unit/test-skill-md-content-patterns.bats:202-210`).

Assertions then follow a repeated shape:
- Assign an extracted slice to `block` or `section`, e.g. `block="$(extract_h3_direct "$GOALS_OWNS_FILE" "### Goals OWNS")"` (`tests/unit/test-skill-md-content-patterns.bats:100-103`).
- Assert the slice is non-empty with `[ -n "$block" ]` (`tests/unit/test-skill-md-content-patterns.bats:102`, `tests/unit/test-skill-md-content-patterns.bats:111`, `tests/unit/test-skill-md-content-patterns.bats:121`).
- Run `grep` checks against the slice using `echo "$block" | grep ...` (`tests/unit/test-skill-md-content-patterns.bats:103-105`, `tests/unit/test-skill-md-content-patterns.bats:112-116`, `tests/unit/test-skill-md-content-patterns.bats:137`).
- For forbidden content, negate `grep` against the extracted slice, especially OWNS/DEFERS blocks (`tests/unit/test-skill-md-content-patterns.bats:320-324`, `tests/unit/test-skill-md-content-patterns.bats:355-357`).

The file also uses whole-file greps for simpler existence or global absence claims: `grep -c` for exact heading count (`tests/unit/test-skill-md-content-patterns.bats:93-97`, `tests/unit/test-skill-md-content-patterns.bats:146-150`), `grep -Eq` for length markers (`tests/unit/test-skill-md-content-patterns.bats:152-154`, `tests/unit/test-skill-md-content-patterns.bats:296-298`), and negated whole-file heading checks when standalone headings must not exist (`tests/unit/test-skill-md-content-patterns.bats:165-180`).

#### Named file: `test-cross-skill-contracts.bats`

`tests/unit/test-cross-skill-contracts.bats` is different from the section-extraction style. Its header says every test is a “loose-grep” and the goal is to verify that a contract appears in both skills, not byte-for-byte prose stability (`tests/unit/test-cross-skill-contracts.bats:16-19`).

Observed pattern:
- Setup computes `REPO_ROOT` from `BATS_TEST_FILENAME` and exports it (`tests/unit/test-cross-skill-contracts.bats:21-24`).
- Tests use `run grep -F` and `run grep -E` directly against full file paths under `skills/` and `agents/` (`tests/unit/test-cross-skill-contracts.bats:33-41`, `tests/unit/test-cross-skill-contracts.bats:51-66`, `tests/unit/test-cross-skill-contracts.bats:75-86`).
- Assertions check `$status` after `run grep`, usually `[ "$status" -eq 0 ]` (`tests/unit/test-cross-skill-contracts.bats:35-41`, `tests/unit/test-cross-skill-contracts.bats:53-61`).
- Where discovery is needed, it counts matching files with `grep -lF ... "$REPO_ROOT/skills/"*/SKILL.md | wc -l | tr -d ' '` and asserts the count is at least a threshold (`tests/unit/test-cross-skill-contracts.bats:236-241`).

So, for the specific question wording, `test-cross-skill-contracts.bats` shares grep-based prompt assertions with SKILL-body tests, but it does not share the heading-scoped extraction helper style. Its convention is explicitly broader: full-file loose grep across both sides of a cross-skill contract.

#### Similar SKILL-body assertion tests

Several adjacent tests repeat the same heading-bounded `awk` idioms.

`tests/unit/test-artifact-gating.bats`:
- Header says assertions extract `## Artifact Gating` first to avoid a `phasing.md` mention elsewhere satisfying the gating-input check (`tests/unit/test-artifact-gating.bats:15-18`).
- Defines `extract_h2_section` using exact heading match, `in_b`, and stop on next `^## ` (`tests/unit/test-artifact-gating.bats:28-39`).
- Defines `assert_phasing_in_artifact_gating` that extracts the block, checks `[ -n "$block" ]`, then greps a list-item regex requiring `phasing.md` and `status: approved` on the same list entry (`tests/unit/test-artifact-gating.bats:41-50`).

`tests/unit/test-scope-reviewer-rules-loading.bats`:
- Header explicitly says section extraction uses `awk` to scope assertions to H2 OWNS/DEFERS sections and H3 children so unrelated content cannot satisfy checks (`tests/unit/test-scope-reviewer-rules-loading.bats:24-26`).
- Defines `extract_h2_section`, `extract_h3_subsection`, and `extract_h3_direct` in almost the same shapes as `test-skill-md-content-patterns.bats` (`tests/unit/test-scope-reviewer-rules-loading.bats:49-88`).
- Adds `count_enumerated_items`, an `awk` helper that counts bullet and numbered-list lines in a piped block (`tests/unit/test-scope-reviewer-rules-loading.bats:90-98`).
- Uses extracted H3 blocks plus `printf '%s\n' "$owns" | count_enumerated_items` to assert each block has at least one enumerated item (`tests/unit/test-scope-reviewer-rules-loading.bats:161-169`, `tests/unit/test-scope-reviewer-rules-loading.bats:176-184`).

`tests/unit/test-phasing-goal-id-consistency.bats`:
- Defines `extract_subsection` for a `### child` inside a `## parent`, using `awk -v p` and `-v c`, exact heading matches, and exits on next `### ` or `## ` (`tests/unit/test-phasing-goal-id-consistency.bats:27-41`).
- Repeatedly extracts a procedure block by accepting either `## Goal-ID Consistency Validation` or `### Goal-ID Consistency Validation`, setting `in_section`, and resetting it on the next H2/H3 heading that is not the target (`tests/unit/test-phasing-goal-id-consistency.bats:60-69`, `tests/unit/test-phasing-goal-id-consistency.bats:91-99`, `tests/unit/test-phasing-goal-id-consistency.bats:117-125`).
- For co-occurrence checks, it normalizes multi-line text and splits into logical units: `tr '\n' ' ' | awk 'BEGIN { RS = "[.!?]" } { print }' | grep ... | grep ...` for sentence-like checks (`tests/unit/test-phasing-goal-id-consistency.bats:106-113`, `tests/unit/test-phasing-goal-id-consistency.bats:134-140`, `tests/unit/test-phasing-goal-id-consistency.bats:188-194`). It also uses paragraph splitting with `awk 'BEGIN { RS = ""; ORS = "\n---\n" } { gsub(/\n/, " "); print }'` when filenames containing periods would corrupt sentence splitting (`tests/unit/test-phasing-goal-id-consistency.bats:232-242`).

`tests/unit/test-phasing-roadmap-generation.bats`:
- Its file-level comment says section-scoped extraction mirrors `test-reviewer-boilerplate-embed` (`tests/unit/test-phasing-roadmap-generation.bats:13`).
- Defines `extract_section` for exact heading-to-next-H2 extraction, `extract_subsection` by piping the parent section to an H3 extractor, and `extract_h3_direct` for `owns-defers.md` (`tests/unit/test-phasing-roadmap-generation.bats:23-62`).
- Includes a fallback extraction for `### Outputs` nested under Process, again using heading-boundary resets (`tests/unit/test-phasing-roadmap-generation.bats:77-87`).

`tests/unit/test-phasing-four-artifact-pruning.bats`:
- Defines a simpler `extract_section` that sets `in_section` on exact match and resets on next H2 rather than `exit`ing (`tests/unit/test-phasing-four-artifact-pruning.bats:24-33`).
- Defines `extract_subsection` using direct parent/child exact matches and stop conditions (`tests/unit/test-phasing-four-artifact-pruning.bats:35-48`).
- Defines `extract_h3_direct` for H3-only files (`tests/unit/test-phasing-four-artifact-pruning.bats:51-62`).
- Repeats an “accept H2 or H3 target heading” block-extraction pattern for `Four-Artifact Pruning Procedure`, entering on either heading level and resetting on subsequent H2/H3 boundaries that are not the target (`tests/unit/test-phasing-four-artifact-pruning.bats:79-87`, `tests/unit/test-phasing-four-artifact-pruning.bats:101-109`, `tests/unit/test-phasing-four-artifact-pruning.bats:123-131`).

`tests/unit/test-replan-archive-and-populate.bats`:
- Header repeats the convention: extract target heading text until next `^## ` and assert on the extracted slice, never the whole file, to avoid false positives (`tests/unit/test-replan-archive-and-populate.bats:12-16`).
- Defines `extract_section`, `extract_subsection`, and `extract_h3_direct` with the same exact-heading / heading-boundary style (`tests/unit/test-replan-archive-and-populate.bats:24-62`).
- Adds procedural helpers such as `extract_archive_block` and `extract_step`, which extract a named section and then a numbered step from that section using `awk` (`tests/unit/test-replan-archive-and-populate.bats:211-225`).
- Uses these slices for assertions on individual steps and sections (`tests/unit/test-replan-archive-and-populate.bats:233-304`, `tests/unit/test-replan-archive-and-populate.bats:312-390`).

`tests/unit/test-reviewer-boilerplate-embed.bats`:
- Uses `extract_section <file> <heading-line>` with exact heading match and next-H2 reset (`tests/unit/test-reviewer-boilerplate-embed.bats:23-38` from grep output; same pattern is referenced by other tests).
- Builds additional sub-extractors by piping a section into `awk -v h=...`, such as `extract_rule_block` for bold-rule blocks and `extract_subblock` for `###` classifier examples (`tests/unit/test-reviewer-boilerplate-embed.bats:211-238`, `tests/unit/test-reviewer-boilerplate-embed.bats:283-297` from grep output).
- Uses `awk 'BEGIN { RS = "[.!?]" } { print }'` for sentence-level co-occurrence checks in at least two tests (`tests/unit/test-reviewer-boilerplate-embed.bats:365`, `tests/unit/test-reviewer-boilerplate-embed.bats:552` from grep output).

#### Shared conventions across these tests

The recurring conventions are:

1. **Exact heading entry:** Helpers usually enter a block only when the line exactly equals the requested heading (`$0 == h`, or `$0 == p` / `$0 == c`). This avoids substring or partial-heading matches (`tests/unit/test-skill-md-content-patterns.bats:50-53`, `tests/unit/test-artifact-gating.bats:34-38`, `tests/unit/test-scope-reviewer-rules-loading.bats:54-58`).

2. **Markdown boundary stop/reset:** H2 section extractors stop or reset at the next `^## ` heading; H3 extractors stop at either `^### ` or `^## ` (`tests/unit/test-skill-md-content-patterns.bats:52`, `tests/unit/test-skill-md-content-patterns.bats:67-69`, `tests/unit/test-scope-reviewer-rules-loading.bats:69-72`). Some helpers use `exit`; others reset `in_section = 0` and continue scanning (`tests/unit/test-phasing-four-artifact-pruning.bats:29-32`).

3. **Two-stage nested extraction:** For nested H3 assertions, tests often extract the H2 parent first, then pipe that slice into a second `awk` looking for the H3 child (`tests/unit/test-skill-md-content-patterns.bats:64-70`, `tests/unit/test-artifact-gating.bats:47-50` for the single H2 variant, `tests/unit/test-replan-archive-and-populate.bats:37-48` from grep output).

4. **Direct H3 extraction for `owns-defers.md`:** Multiple tests define `extract_h3_direct` because `owns-defers.md` files start at H3 level or are treated as H3-first rule files (`tests/unit/test-skill-md-content-patterns.bats:73-84`, `tests/unit/test-scope-reviewer-rules-loading.bats:76-88`, `tests/unit/test-phasing-roadmap-generation.bats:51-62`).

5. **Scope-first, grep-second assertions:** Tests typically save the extracted slice to `block`, `section`, `proc_block`, or similar; assert non-empty; then run greps on that variable. This pattern appears throughout `test-skill-md-content-patterns.bats` (`tests/unit/test-skill-md-content-patterns.bats:219-231`, `tests/unit/test-skill-md-content-patterns.bats:253-281`) and adjacent files (`tests/unit/test-artifact-gating.bats:44-50`, `tests/unit/test-phasing-goal-id-consistency.bats:60-84`).

6. **Co-occurrence via record splitting:** When a requirement is about concepts appearing in the same sentence, statement, or paragraph, tests flatten or split extracted blocks with `tr` and `awk` record separators before chaining greps (`tests/unit/test-phasing-goal-id-consistency.bats:106-113`, `tests/unit/test-phasing-goal-id-consistency.bats:134-140`, `tests/unit/test-phasing-goal-id-consistency.bats:232-242`). This prevents a file-level or section-level match from being satisfied by unrelated distant mentions.

7. **Fenced-code awareness only where needed:** Most extractors are simple heading-boundary scanners. `test-skill-md-content-patterns.bats` adds a fence-aware `extract_review_round` because fenced code/template blocks can contain markdown headings that would otherwise terminate extraction incorrectly (`tests/unit/test-skill-md-content-patterns.bats:196-210`).

8. **Whole-file greps remain common for global contracts:** For existence of canonical headings, global absence of forbidden standalone headings, or cross-skill contract presence, tests still use direct `grep` against full files. `test-cross-skill-contracts.bats` is explicitly built around this loose-grep convention (`tests/unit/test-cross-skill-contracts.bats:16-19`, `tests/unit/test-cross-skill-contracts.bats:33-41`).
