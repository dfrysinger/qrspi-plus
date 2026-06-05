spec-claude: clean — Task 04 round 01

All five DoD items verified against the implementation:

1. skills/reviewer-protocol/SKILL.md L57 documents `change_type:` as the
   required reviewer frontmatter field name under the `## Finding Schema`
   section, with the bold lead-in "**Required reviewer frontmatter field
   name.**" The classifier MUST be emitted under that exact key.

2. Same paragraph (L57) explicitly states `category:` is NOT recognized as
   a synonym or alias. The test at bats L125-135 enforces no softening
   "synonym/alias/accepted/equivalent" wording links category↔change_type.

3. SKILL.md L59 documents loud-failure on missing `change_type:` with
   named-cause halt and explicitly forbids silent-accept, silent-drop, and
   default-routing.

4. tests/unit/test-change-type-partition.bats L73-94 pins the missing-
   field / legacy-`category:` diagnostic: fixture
   tests/fixtures/change-type-required/round-01/legacy-category-claude.finding-F01.md
   carries `category: correctness` with no `change_type:`; test asserts
   non-zero exit, empty stdout (no routing), AND stderr matches
   "missing required field 'change_type:'".

5. Same bats file L96-104 pins the well-formed acceptance path: fixture
   well-formed-claude.finding-F02.md carries `change_type: scope`; test
   asserts rc=0 and routed value == "scope" (routed by field name, not
   by position).

6. Audit test L137-161 scans SKILL.md, the three reviewer-protocol
   emission siblings, the bats file, and the well-formed fixture for
   any `^category:` frontmatter line. Legacy fixture is explicitly
   excluded as the negative-test input. Implementer reports green.

Scope/target-files deviation (advisory): the two fixture files under
tests/fixtures/change-type-required/round-01/ are not enumerated in the
task's Target files list but are necessary auxiliary inputs for the
new bats tests. This is the "small number of necessary auxiliary
files" case from the checklist — PASS, not flag.

No scope creep into scripts/verifier-fan-in.sh (T05 owns); the bats
file uses a local `_partition_finding` helper that mirrors the
documented schema-guard contract, which is the correct in/out
interpretation.

Two additional SKILL.md-wording assertions (bats L106-135) beyond the
bare DoD pin the protocol edits the task explicitly required —
appropriate regression coverage, not over-engineering.

No findings.
