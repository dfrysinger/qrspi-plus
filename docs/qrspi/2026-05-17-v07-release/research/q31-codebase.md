---
status: draft
question_ids: [31]
research_type: codebase
---

# Q31: How does the QRSPI pipeline currently parse `config.md`, apply defaults for fields that did not exist when an older resumed run was created, and warn or migrate older configurations?

## Summary

**TL;DR:** `config.md` is specified as a YAML-frontmatter file in each artifact directory, but the current repository implements parsing mostly through prose contracts and shell snippets rather than a centralized production parser. The canonical contract is strict: skills must validate required behavior-affecting fields and must not silently infer missing `pipeline`, `route`, or `codex_reviews`; older-run compatibility exists only through explicit runtime-backfill carve-outs for `verifier_enabled`, `scope_tagger_enabled`, `visual_fidelity_required`, and Implement's `phase`. There are current inconsistencies: Research and Questions still document a missing-`config.md` fallback to `codex_reviews: false`, and the test fixture validator only implements some fields named by the canonical validation table.

**Key findings:**
- The canonical schema and validation rules live in `skills/using-qrspi/SKILL.md`, where `config.md` is defined as the artifact-directory source of truth with YAML frontmatter fields including `pipeline`, `codex_reviews`, `route`, `review_depth`, `review_mode`, `verifier_enabled`, `scope_tagger_enabled`, `visual_fidelity_required`, and quick-only `question_budget`.
- Parsing is described in two concrete forms: frontmatter extraction between the first two `---` markers in `tests/fixtures/validate-config-field.sh`, and direct line-based `awk -F': *' '/^field:/ {print $2; exit}'` snippets in the Apply-fix protocol for verifier/scope-tagger gates.
- The no-silent-defaults rule forbids assuming `pipeline: full`, assuming `codex_reviews: false`, deriving `route` from `pipeline`, or proceeding with guessed field values.
- Runtime backfill is explicitly documented for missing legacy fields: `verifier_enabled` defaults to `true`, `scope_tagger_enabled` defaults to `true`, `visual_fidelity_required` defaults to `false`, and Implement backfills `phase: NN` by deriving the next phase ordinal from phase-bearing artifacts.
- Missing/invalid non-backfilled fields stop and present a field-specific menu; `question_budget` has no runtime-backfill carve-out and must be present only for quick runs, absent for full runs, and in range 1–50.

**Surprises:** Research and Questions still document `config.md` missing → `codex_reviews: false`, which conflicts with the canonical no-silent-defaults rule. The validation fixture implements `route`, `pipeline`, `codex_reviews`, `visual_fidelity_required`, and `question_budget`, but not all fields in the canonical table such as `verifier_enabled` or `scope_tagger_enabled`.

**Caveats:** This investigation examined the skill markdown, hook references, and config-validation fixtures in the repository. QRSPI is largely prompt/prose-driven here; I did not find a centralized runtime library that parses `config.md` for all skills, so findings distinguish documented contracts, shell snippets embedded in skill docs, and test fixtures.

## Full findings

### Query Planning

I searched for where `config.md` is referenced and validated across the QRSPI codebase, then inspected:
- the canonical user-facing pipeline contract in `skills/using-qrspi/SKILL.md`;
- per-skill artifact gating and validation references in `skills/{goals,questions,research,design,plan,phasing,implement}/SKILL.md`;
- concrete validation/test fixtures under `tests/fixtures` and `tests/unit`;
- hook references to confirm whether the legacy hook layer participates in runtime config parsing.

### Canonical `config.md` format and source of truth

`skills/using-qrspi/SKILL.md` defines `config.md` as living in the artifact directory and being written during Goals after the artifact directory is created; it calls the file the single source of truth for pipeline configuration (`skills/using-qrspi/SKILL.md:349-351`). The same section shows the canonical YAML-frontmatter format (`skills/using-qrspi/SKILL.md:353-379`):

- `created`
- `pipeline`
- `codex_reviews`
- `route`
- `review_depth`
- `review_mode`
- `verifier_enabled`
- `scope_tagger_enabled`
- `visual_fidelity_required`
- `question_budget`

The field definitions immediately below state which fields are informational vs behavioral. `pipeline` is a human-readable label, while `route` is authoritative (`skills/using-qrspi/SKILL.md:381-385`). `review_depth` and `review_mode` are written later by Implement (`skills/using-qrspi/SKILL.md:386-387`). `question_budget` is quick-pipeline-only, defaults to `5`, and must be 1–50 (`skills/using-qrspi/SKILL.md:391`).

Fresh-run writing is documented as atomic from Goals for `created`, `pipeline`, `codex_reviews`, and `route`; Goals also writes `verifier_enabled: true`, `scope_tagger_enabled: true`, and `visual_fidelity_required: false` or `true`, and writes `question_budget: 5` only for `pipeline: quick` (`skills/using-qrspi/SKILL.md:393`).

### How `config.md` is parsed today

There is no single production parser found for all QRSPI skills. The current repository contains three parsing patterns.

1. **Frontmatter parser in test fixture.** `tests/fixtures/validate-config-field.sh` reads `config.md` from an artifact directory (`tests/fixtures/validate-config-field.sh:17-25`). Its `extract_field` function reads only between the first two `---` markers and extracts a scalar field by matching `^[[:space:]]*key:[[:space:]]*(.*)` (`tests/fixtures/validate-config-field.sh:27-51`). Its `field_present` helper similarly checks key presence only inside the frontmatter block (`tests/fixtures/validate-config-field.sh:53-73`). For `route`, it checks that the line after `route:` begins with a YAML list item (`tests/fixtures/validate-config-field.sh:75-102`).

2. **Line-based `awk` snippets in the canonical Apply-fix protocol.** The verifier gate reads `verifier_enabled` from a resolved absolute config path using `awk -F': *' '/^verifier_enabled:/ {print $2; exit}'` (`skills/using-qrspi/SKILL.md:656-667`). The scope-tagger gate uses the same shape for `scope_tagger_enabled` (`skills/using-qrspi/SKILL.md:778-789`). The verified-file assembly also mirrors `verifier_enabled` by reading `config.md` with an `awk` scalar extraction and defaulting the output header expression to true if blank (`skills/using-qrspi/SKILL.md:725-774`, especially `skills/using-qrspi/SKILL.md:745-752`).

3. **Per-skill prose validation hooks.** Skills mostly instruct the orchestrator to apply the shared validation procedure rather than calling a shared library. Goals validates `route`, `pipeline`, `codex_reviews`, `verifier_enabled`, `scope_tagger_enabled`, `visual_fidelity_required`, and quick-run `question_budget` when resuming (`skills/goals/SKILL.md:80-82`). Design validates `codex_reviews` (`skills/design/SKILL.md:36`). Plan validates `pipeline`, `route`, `codex_reviews`, and quick-run `question_budget` (`skills/plan/SKILL.md:41-43`). Implement has a phase-entry smoke check that reads and strictly parses `verifier_enabled` (`skills/implement/SKILL.md:140-159`). Phasing's visual-fidelity approval assertion reads `visual_fidelity_required` and treats absent or false as inactive in that specific assertion (`skills/phasing/SKILL.md:221-232`).

The repository also has hooks referencing `config.md`, but the found references are protection/artifact bookkeeping rather than pipeline config parsing: `hooks/lib/artifact.sh` names `config.md` as an artifact path class, and `hooks/lib/protected.sh` treats `config.md` as protected.

### Validation behavior for missing or invalid configuration

The canonical rule says all subsequent skills must read `config.md` for route and Codex config, apply the Config Validation Procedure when `config.md` is missing or invalid, avoid silently defaulting behavior-affecting fields, and avoid automatic route derivation (`skills/using-qrspi/SKILL.md:405-411`).

The Config Validation Procedure starts at `skills/using-qrspi/SKILL.md:413`. It says every skill that reads `config.md` applies the procedure before using any field (`skills/using-qrspi/SKILL.md:413-415`). If `config.md` is missing entirely, the user-facing stop menu is:

- re-run Goals to create `config.md` and set pipeline mode;
- abort (`skills/using-qrspi/SKILL.md:417-425`).

For missing/invalid required fields, the skill stops and presents field-specific menus (`skills/using-qrspi/SKILL.md:426-428`). The canonical menu coverage includes:

- missing `route`: manually add a `route:` list or abort (`skills/using-qrspi/SKILL.md:430-432`);
- missing/invalid `pipeline`: set `pipeline: full` or `pipeline: quick`, or abort (`skills/using-qrspi/SKILL.md:434-436`);
- missing/invalid `codex_reviews`: set `true` or `false`, or abort (`skills/using-qrspi/SKILL.md:438-440`);
- missing/invalid `visual_fidelity_required`: set `true`/`false`, re-run Goals, or abort (`skills/using-qrspi/SKILL.md:442-445`);
- missing/invalid `verifier_enabled`: set `true`/`false` or abort (`skills/using-qrspi/SKILL.md:447-449`);
- missing/invalid `scope_tagger_enabled`: set `true`/`false` or abort (`skills/using-qrspi/SKILL.md:451-453`);
- `question_budget` missing when quick, present when full, non-positive, non-integer, or out of range: field-specific menus to add/remove/fix it or re-run Goals (`skills/using-qrspi/SKILL.md:455-475`).

The no-silent-defaults subsection explicitly forbids assuming `pipeline: full`, assuming `codex_reviews: false`, deriving `route` from `pipeline`, or proceeding with guessed/inferred field values (`skills/using-qrspi/SKILL.md:479-485`).

### Runtime defaults/backfills for older resumed runs

The only explicitly allowed exceptions to no-silent-defaults in the canonical config section are three missing-field backfills for older resumed runs:

- `verifier_enabled`: if missing on the first verifier-aware Apply-fix invocation in a resumed run created before the verifier landed, runtime treats it as `true`, emits stderr warning `verifier_enabled missing from config.md — backfilling default 'true' for this run`, and writes the field back to `config.md` (`skills/using-qrspi/SKILL.md:487-490`).
- `scope_tagger_enabled`: same shape; missing field defaults to `true`, emits `scope_tagger_enabled missing from config.md — backfilling default 'true' for this run`, and writes it back (`skills/using-qrspi/SKILL.md:491`).
- `visual_fidelity_required`: same shape; missing field defaults to `false`, emits `visual_fidelity_required missing from config.md — backfilling default 'false' for this run`, and writes it back (`skills/using-qrspi/SKILL.md:493`).

The contract states those three fields are the only carve-outs from the no-silent-defaults rule in that section (`skills/using-qrspi/SKILL.md:493`). It also says write-back is not best-effort: if writing back to `config.md` fails, runtime must stop issuing tool calls and present a resolve/abort menu (`skills/using-qrspi/SKILL.md:495-504`). The reason given is that in-memory defaults diverging from disk would re-fire the backfill repeatedly and could produce inconsistent cross-invocation behavior (`skills/using-qrspi/SKILL.md:504`).

The concrete Apply-fix verifier snippet implements the `verifier_enabled` missing-field path by appending `verifier_enabled: true`, setting the in-memory variable to true, and writing the stderr warning (`skills/using-qrspi/SKILL.md:656-667`). The concrete scope-tagger snippet similarly appends `scope_tagger_enabled: true`, sets the in-memory variable, and writes the stderr warning (`skills/using-qrspi/SKILL.md:778-789`). The snippet comments rely on a trailing-newline invariant and state that YAML still tolerates a missing newline if the invariant breaks (`skills/using-qrspi/SKILL.md:661-665`, `skills/using-qrspi/SKILL.md:783-787`).

Implement has an additional runtime-backfill carve-out for the `phase:` field in its one-shot per-phase smoke check. If `phase:` is absent, Implement computes the next phase ordinal by scanning phase-bearing artifact state such as `reviews/tasks/.smoke-probe-NN` and `reviews/integration/round-NN-commit.txt`, writes `phase: NN` back to `config.md`, re-reads to confirm it round-trips, and logs `Implement smoke check: backfilled phase: <NN> to config.md (was absent).` (`skills/implement/SKILL.md:140-151`). Malformed present `phase` values are not eligible for backfill and halt immediately (`skills/implement/SKILL.md:151`). Write failure or read-back mismatch halts with a diagnostic (`skills/implement/SKILL.md:150`).

### Field-specific behavior in the validation fixture

`tests/fixtures/validate-config-field.sh` is a concrete shell validator, but it does not cover every field listed in the canonical table. It implements cases for:

- `route`, including field presence and list shape (`tests/fixtures/validate-config-field.sh:104-122`);
- `pipeline`, accepting only `full` or `quick` (`tests/fixtures/validate-config-field.sh:124-143`);
- `codex_reviews`, accepting only `true` or `false` (`tests/fixtures/validate-config-field.sh:145-165`);
- `visual_fidelity_required`, accepting only `true` or `false` and treating present-but-empty extraction as a structural anomaly (`tests/fixtures/validate-config-field.sh:167-201`);
- `question_budget`, requiring presence for the invoked validation, requiring a positive decimal integer, rejecting leading-zero shapes such as `01`, guarding against arithmetic overflow by rejecting values longer than three digits before numeric comparison, and enforcing an upper bound of 50 (`tests/fixtures/validate-config-field.sh:203-273`).

The same fixture's `*)` branch reports unknown fields (`tests/fixtures/validate-config-field.sh:275-278`). A direct search found no `verifier_enabled` or `scope_tagger_enabled` cases in this fixture, even though the canonical table names them as behavior-affecting fields that Goals and Implement validate (`skills/using-qrspi/SKILL.md:506-518`).

### Migration/warning surfaces

The repository currently documents migration primarily as manual repair plus runtime write-back for the explicit carve-outs.

Manual migration is named in the no-legacy-fallback paragraph: existing runs can be migrated by manually adding `pipeline` and `route` fields to `config.md` (`skills/using-qrspi/SKILL.md:411`). Missing `config.md` or missing/invalid required fields stop and present menus rather than auto-migrating (`skills/using-qrspi/SKILL.md:417-475`).

Automatic migration/backfill warning surfaces are narrow:

- stderr one-line warnings for `verifier_enabled`, `scope_tagger_enabled`, and `visual_fidelity_required` missing on eligible resumed runs (`skills/using-qrspi/SKILL.md:489-493`);
- append-write plus in-memory default in the concrete verifier and scope-tagger snippets (`skills/using-qrspi/SKILL.md:656-667`, `skills/using-qrspi/SKILL.md:778-789`);
- Implement in-session output for `phase:` backfill (`skills/implement/SKILL.md:150`).

`question_budget` explicitly has no runtime-backfill carve-out; missing/invalid cases always route to the menu, including missing when quick and present when full (`skills/using-qrspi/SKILL.md:455-477`).

### Current inconsistencies and edge cases found

1. **Research and Questions still document a missing-`config.md` fallback for Codex.** Research says to read `config.md` to determine Codex reviews and, if `config.md` does not exist, default to `codex_reviews: false` (`skills/research/SKILL.md:23`). Questions says the same (`skills/questions/SKILL.md:25`). This conflicts with the canonical no-silent-defaults rule forbidding `codex_reviews: false` when missing (`skills/using-qrspi/SKILL.md:479-485`) and with the missing-config stop menu (`skills/using-qrspi/SKILL.md:417-425`).

2. **Phasing has an absent-or-false skip for visual fidelity in one approval assertion.** The visual-fidelity precondition assertion says it fires only when `config.md` carries `visual_fidelity_required: true`, and if the flag is absent or false the assertion is inert (`skills/phasing/SKILL.md:221-232`). The canonical validation text separately says missing-on-read for older resumed runs is covered by the runtime-backfill carve-out, while invalid or fresh-run absence uses the menu (`skills/using-qrspi/SKILL.md:477-493`).

3. **The validator fixture is partial relative to the canonical table.** The canonical table lists behavior-affecting validation ownership for `route`, `pipeline`, `codex_reviews`, `review_depth`, `review_mode`, `verifier_enabled`, `scope_tagger_enabled`, `visual_fidelity_required`, and `question_budget` (`skills/using-qrspi/SKILL.md:506-518`). The concrete `validate-config-field.sh` fixture implements only five cases and otherwise reports unknown fields (`tests/fixtures/validate-config-field.sh:104-278`).

4. **Runtime backfill snippets append scalar fields directly.** The verifier and scope-tagger snippets append `field: true` to `config.md` rather than performing a structured frontmatter rewrite (`skills/using-qrspi/SKILL.md:656-667`, `skills/using-qrspi/SKILL.md:778-789`). The comments explicitly rely on a trailing-newline invariant and state YAML tolerates the missing-newline edge (`skills/using-qrspi/SKILL.md:661-665`, `skills/using-qrspi/SKILL.md:783-787`).
