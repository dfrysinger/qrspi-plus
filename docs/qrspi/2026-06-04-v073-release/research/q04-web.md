---
status: draft
question_ids: [4]
research_type: web
---

# Q4: What are established practices for enforcing bats test-name conventions via automated lint or CI checks?

## Summary

**TL;DR:** No dedicated bats test-name linter tool exists as a first-class community artifact. Established practices fall into four categories: using shellcheck/shfmt via the alternative `function_name { #@test }` syntax, grep/awk-based custom CI scripts that extract and validate `@test` names against a regex, using `bats --filter`/`--negative-filter` with `-c` in CI to count non-conforming tests, and leveraging the built-in bats tag system (v1.8.0+) which enforces tag format automatically.

**Key findings:**
- **No dedicated bats test-name linter exists** as a standalone tool, pre-commit hook, or GitHub Action in the ecosystem.
- **shellcheck** (v0.7+) supports `.bats` files natively via `@test` syntax, and also via the bash-compatible alternative `function test_name { #@test }`. The function-name syntax forces test names to be valid bash identifiers (letters, digits, underscores; no spaces), effectively enforcing a `snake_case` or `verb_noun_...` convention. bats-core's own CI runs shellcheck on all `.bats` files via a custom `shellcheck.sh` script using this mechanism.
- **shfmt** (v3.2.0+) supports `.bats` files via `-ln bats` flag and is enforced in bats-core CI. shfmt formats code but does not validate test name strings.
- **grep/awk CI scripts** are the most flexible approach for enforcing arbitrary naming patterns: extract `@test "..."` lines from `.bats` files, match against a regex, and fail if violations are found. This pattern is used by projects with custom conventions but no single canonical script exists.
- **`bats --filter <regex>` / `--negative-filter <regex>` combined with `-c`** can be used in CI to count how many tests do or do not conform to a naming regex, enabling a "fail if non-conforming tests exist" gate.
- **bats:focus tag auto-enforcement**: bats itself returns exit code 1 when a `bats:focus` tag is present in any test, preventing accidentally committed focus-only test runs from silently passing in CI. This is the only built-in convention enforcement.
- **bats tag format enforcement** (v1.8.0+): `# bats test_tags=` tag values are validated by bats to match `[alphanumeric_:\-]`, no whitespace. This constrains tag naming but not test description strings.
- bats-core's CONTRIBUTING.md recommends `snake_case` for identifiers and mandates shfmt + shellcheck in CI, but specifies no naming convention for `@test` description strings.

**Surprises:** There is no first-party or widely-adopted third-party tool specifically for enforcing bats test-name conventions — the community relies entirely on general shell linting tools (shellcheck, shfmt) and custom grep/awk scripts. The `function_name { #@test }` alternative syntax is the closest thing to structural naming enforcement, as it restricts test names to valid bash identifier format.

**Caveats:** GitHub API search results were limited by rate limits; some niche community tools or pre-commit hook repos may have been missed. Stack Overflow and blog posts were not exhaustively surveyed. The research is based on bats-core documentation, the bats-core repository itself, and GitHub code/issue search results.

## Full findings

### Background: bats test name syntax

A bats test is declared with either:
1. `@test "description string" { ... }` — the standard syntax (not valid bash; shellcheck/shfmt cannot process it without bats-specific support)
2. `function test_description_as_identifier { #@test ... }` — the bash-compatible alternative syntax (bats-core docs: "Comment syntax"); when this form is used, the function name becomes the test title displayed in output and matched by `--filter`.

Source: https://bats-core.readthedocs.io/en/stable/writing-tests.html#comment-syntax

---

### 1. shellcheck — static analysis of `.bats` files

**shellcheck v0.7+** supports bats syntax natively. bats-core's own CI runs shellcheck on all `.bats` files using the script `shellcheck.sh`:

```bash
#!/usr/bin/env bash
set -e
targets=()
while IFS= read -r -d $'\0'; do
  targets+=("$REPLY")
done < <(
  find . -type f \( -name \*.bash -o -name \*.sh \) -print0
  find . -type f -name '*.bats' -not -name '*_no_shellcheck*' -print0
  find libexec -type f -print0
  find bin -type f -print0
)
LC_ALL=C.UTF-8 shellcheck -x "${targets[@]}"
```
Source: https://raw.githubusercontent.com/bats-core/bats-core/master/shellcheck.sh

This is enforced in the `.github/workflows/tests.yml` CI workflow.

**Naming implication**: When using the `function test_name { #@test }` syntax, shellcheck validates that function names are valid bash identifiers. This restricts test names to `[A-Za-z0-9_]` (no spaces, no special characters), effectively enforcing a `snake_case` or similar identifier-based naming scheme.

**Limitation**: shellcheck does not validate the content of `@test "..."` description strings against any naming convention. It only validates bash syntax.

---

### 2. shfmt — formatting `.bats` files

**shfmt v3.2.0+** supports `.bats` files via the `-ln bats` language dialect flag. The dialect is auto-detected from `.bats` file extensions. bats-core's CI workflow runs:

```yaml
- run: |
    curl https://github.com/mvdan/sh/releases/download/v3.5.1/shfmt_v3.5.1_linux_amd64 -o shfmt
    chmod a+x shfmt
- run: ./shfmt --diff .
```
Source: https://raw.githubusercontent.com/bats-core/bats-core/master/.github/workflows/tests.yml

shfmt with `-ln bats` auto-detects and processes `.bats` files. It enforces consistent code formatting but does **not** validate test name strings against any convention.

The bats-core FAQ confirms: "shfmt support since version 3.2.0 (using `-ln bats`)."  
Source: https://bats-core.readthedocs.io/en/stable/faq.html

---

### 3. grep/awk-based custom CI scripts

The most flexible approach for enforcing arbitrary naming conventions is to extract test names from `.bats` files using grep or awk and validate them against a project-specific regex. No canonical community script was found; this is a bespoke approach used per-project.

**Typical pattern**:
```bash
# Fail if any @test name does not start with an expected prefix
violations=$(grep -E '^@test "' tests/*.bats | grep -vE '"(should |given |when |then |it )' | wc -l)
if [ "$violations" -gt 0 ]; then
  echo "ERROR: Test names must start with 'should', 'given', 'when', 'then', or 'it'"
  grep -E '^@test "' tests/*.bats | grep -vE '"(should |given |when |then |it )'
  exit 1
fi
```

**Variant using awk**:
```bash
awk '/^@test "/ { 
  match($0, /^@test "([^"]+)"/, arr)
  name = arr[1]
  if (name !~ /^(should|given|when|then|it) /) {
    print "NAMING VIOLATION: " name; violations++
  }
} END { exit (violations > 0) }' tests/*.bats
```

GitHub code search returned 0 results for explicit bats test-name enforcement patterns using grep/awk in CI configs. This suggests teams either (a) don't enforce test naming in automated CI, (b) use internal/private repos, or (c) implement this via ad-hoc scripts not findable by keyword search.

---

### 4. `bats --filter` / `--negative-filter` + `-c` in CI

bats provides:
- `-c` / `--count`: Count test cases without running any tests.
- `--filter <regex>`: Only run tests matching the regex (matched against test name/description).
- `--negative-filter <regex>`: Only run tests NOT matching the regex.

Source: https://bats-core.readthedocs.io/en/stable/usage.html

These flags can be combined in CI to enforce naming conventions:

```bash
# Count total tests
total=$(bats -c tests/*.bats)
# Count tests matching the convention
conforming=$(bats --filter '^(should|given|when|then|it) ' -c tests/*.bats)
if [ "$total" -ne "$conforming" ]; then
  echo "Naming convention violation: $((total - conforming)) tests don't match convention"
  exit 1
fi
```

Alternatively:
```bash
# Fail if any tests don't match the convention
non_conforming=$(bats --negative-filter '^(should|given|when|then|it) ' -c tests/*.bats)
if [ "$non_conforming" -gt 0 ]; then
  echo "$non_conforming tests violate naming convention"
  exit 1
fi
```

**Limitation**: `--filter` uses extended regex but the `-c` flag may not combine with `--filter` in all bats versions (this combination should be tested against the target bats version).

---

### 5. bats tag system (v1.8.0+)

Since bats-core v1.8.0, the `# bats test_tags=` directive categorizes tests with structured tags. Tags must match the format `[alphanumeric_:\-]` (no whitespace); bats enforces this at parse time.

```bash
# bats test_tags=unit, component:auth
@test "login succeeds with valid credentials" { ... }
```

Tags support `--filter-tags` in CI runs, providing a complementary categorization mechanism. bats validates tag format automatically; invalid tags cause a test run error.

Source: https://bats-core.readthedocs.io/en/stable/writing-tests.html#tagging-tests

**`bats:focus` tag auto-enforcement**: If any test has the `bats:focus` tag and the test suite runs with it, bats returns exit code 1 even on success, causing CI to fail. This prevents accidentally committed focus tags.

---

### 6. `function name { #@test }` syntax as structural naming enforcement

The bash-compatible alternative syntax (bats-core "Comment syntax") forces test names to be valid bash identifiers:

```bash
function login_succeeds_with_valid_credentials { #@test
  run auth_login valid_user valid_pass
  [ "$status" -eq 0 ]
}
```

This syntax:
- Is processed by shellcheck (v0.7+), shfmt (v3.2.0+), and IDE tools without special configuration.
- Restricts test names to `[A-Za-z0-9_]` — no spaces, no special characters.
- When combined with a project convention like `snake_case`, the `#@test` comment pattern can itself serve as a naming constraint.

To lint that function names used as test identifiers follow a specific pattern, standard `grep` against function definitions suffices:
```bash
grep -E '^function [^{]+\{ #@test' tests/*.bats | grep -vE '^function (should|given|when|then|it)_'
```

Source: https://bats-core.readthedocs.io/en/stable/writing-tests.html#comment-syntax; https://bats-core.readthedocs.io/en/stable/gotchas.html

---

### 7. bats-core's own conventions (observed from codebase)

Inspecting bats-core's own test suite (`test/bats.bats`, `test/run.bats`, etc.):
- Tests use the `@test "description string" { }` syntax.
- Names use lowercase plain English descriptions: `@test "no arguments prints message and usage instructions"`.
- bats-core's CONTRIBUTING.md mandates `snake_case` for code identifiers and requires shfmt + shellcheck in CI, but specifies no naming convention for `@test` description strings.

Source: https://raw.githubusercontent.com/bats-core/bats-core/master/docs/CONTRIBUTING.md

---

### 8. No dedicated bats test-name linter found

A search of:
- GitHub repositories (query: `bats-lint`, `bats linter`, `bats pre-commit lint`, `bats test naming`)
- GitHub Actions Marketplace (query: `bats lint`, `bats test name`)
- pre-commit hooks registry
- bats-core issues and wiki

Found **no dedicated tool** for bats test-name convention linting. The closest related GitHub Actions are:
- `mig4/setup-bats` — installs bats, does not lint.
- `ffurrer2/bats-action` — runs bats tests, does not lint names.
- `brokenpip3/setup-bats-libs` — installs bats libraries.

None of these address naming convention enforcement.

---

### Summary table

| Approach | Tool / Mechanism | Enforces Naming Pattern | Notes |
|---|---|---|---|
| Shell linting | shellcheck v0.7+ | Only via `function { #@test }` syntax (bash identifier constraints) | Validates shell syntax, not description strings |
| Code formatting | shfmt v3.2.0+ (`-ln bats`) | No | Formatting only |
| Test name extraction + regex | Custom grep/awk CI script | Yes — arbitrary regex | Most flexible; no standard script exists |
| Test count comparison | `bats --filter regex -c` vs `bats -c` | Yes — arbitrary regex | Requires bats to run; combinability should be verified |
| Tag convention | `# bats test_tags=` (v1.8.0+) | Partial — tag format enforced, not description | Tags must match `[alphanumeric_:\-]` |
| Focus tag | `bats:focus` | Prevents accidental CI pass | Built-in bats behavior |
| Identifier syntax | `function name { #@test }` | Yes — bash identifier chars only | Enables tooling; names limited to `[A-Za-z0-9_]` |
