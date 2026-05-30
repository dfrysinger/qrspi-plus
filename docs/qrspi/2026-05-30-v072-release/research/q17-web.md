---
status: draft
question_ids: [17]
research_type: web
---

# Q17: BW02 deprecation warning, shebang replacement forms, and `[[ -n "$var" && "$var" =~ "pattern" ]]` silent-pass behavior in bats-core

## Summary

**TL;DR:** In bats-core upstream, BW02 is exclusively a minimum-version guard warning — not a shebang deprecation — as documented at [bats-core.readthedocs.io/en/stable/warnings/BW02.html](https://bats-core.readthedocs.io/en/stable/warnings/BW02.html) and confirmed in [lib/bats-core/warnings.bash](https://raw.githubusercontent.com/bats-core/bats-core/master/lib/bats-core/warnings.bash). The `#!/usr/bin/env bats` shebang is the standard, non-deprecated form throughout all bats-core documentation. The behavior where `[[ -n "$var" && "$var" =~ "pattern" ]]` silently passes when `$var` is empty is **not** documented in bats-core issues, the bats README, or related ShellCheck rules — and in standard bash this expression does not silently pass when `$var` is empty.

**Key findings:**
- BW02 in bats-core (introduced in v1.7.0 per [docs/CHANGELOG.md](https://raw.githubusercontent.com/bats-core/bats-core/master/docs/CHANGELOG.md)) is: `<feature> requires at least BATS_VERSION=<version>. Use bats_require_minimum_version <version> to fix this message.` It is about guarding features with `bats_require_minimum_version`, not about shebang deprecation. [source: https://bats-core.readthedocs.io/en/stable/warnings/BW02.html]
- The `#!/usr/bin/env bats` shebang is the standard, documented, non-deprecated form in the [bats-core README](https://raw.githubusercontent.com/bats-core/bats-core/master/README.md), [man page `bats.7`](https://raw.githubusercontent.com/bats-core/bats-core/master/man/bats.7), and [readthedocs writing-tests page](https://bats-core.readthedocs.io/en/stable/writing-tests.html). No deprecation of this shebang appears anywhere in upstream.
- The shebang form `#!/usr/bin/env -S bats -t` is **not documented or recommended** anywhere in bats-core upstream source, docs, man pages, or [CHANGELOG](https://raw.githubusercontent.com/bats-core/bats-core/master/docs/CHANGELOG.md).
- A qrspi-plus project issue (#243 at https://github.com/dfrysinger/qrspi-plus/issues/243) claims "BW02 - The shebang `#!/usr/bin/env bats` is deprecated; use `#!/usr/bin/env -S bats -t`..." — this description does not match the actual upstream BW02 warning and has no basis in bats-core documentation.
- `[[ -n "$var" && "$var" =~ "pattern" ]]` when `$var` is empty: `-n ""` is false, causing `&&` to short-circuit; the regex side is never evaluated, and the overall expression returns non-zero (correctly fails). No bats issue, the bats README, or ShellCheck rule documents this expression as "silently passing" when `$var` is empty.
- The bats-core [Gotchas page](https://bats-core.readthedocs.io/en/stable/gotchas.html) documents that `[[ ]]` (and `(( ))`) failed to abort tests in bash versions before 4.1 due to `set -e` handling differences, but this applies to `[[ ]]` in general, not specifically to the `[[ -n ... && ... =~ ... ]]` pattern.
- ShellCheck [SC2076](https://www.shellcheck.net/wiki/SC2076) documents that quoting the RHS of `=~` (e.g., `"pattern"`) causes literal string matching rather than regex interpretation; this is the closest documented pitfall but does not describe a "silent pass with empty var" scenario.

**Surprises:** The "BW02 shebang deprecation" description in qrspi-plus issue #243 (https://github.com/dfrysinger/qrspi-plus/issues/243) does not correspond to any actual bats-core warning code or documented deprecation — BW02 is exclusively a version-guard warning per [bats-core.readthedocs.io/en/stable/warnings/BW02.html](https://bats-core.readthedocs.io/en/stable/warnings/BW02.html). The `#!/usr/bin/env -S bats -t` shebang form recommended in that issue is not mentioned anywhere in bats-core upstream documentation (confirmed via [README](https://raw.githubusercontent.com/bats-core/bats-core/master/README.md), [CHANGELOG](https://raw.githubusercontent.com/bats-core/bats-core/master/docs/CHANGELOG.md), and [man/bats.7](https://raw.githubusercontent.com/bats-core/bats-core/master/man/bats.7)).

**Caveats:** GitHub API search rate limits may have caused some results to be incomplete. The bats-core CHANGELOG is at `docs/CHANGELOG.md` in the repository (the top-level `CHANGELOG.md` returns 404). Only bats-core stable docs were checked; the `latest`/unreleased readthedocs build was not separately fetched.

---

## Full findings

### BW02 in bats-core upstream

**Official definition (from bats-core source `lib/bats-core/warnings.bash`):**

```
BATS_WARNING_SHORT_DESCS=(
  # to start with 1
  'PADDING'
  # BW01
  "`run`'s command `%s` exited with code 127, indicating 'Command not found'. Use run's return code checks, e.g. `run -127`, to fix this message."
  # BW02
  "%s requires at least BATS_VERSION=%s. Use `bats_require_minimum_version %s` to fix this message."
  # BW03
  "`setup_suite` is visible to test file '%s', but was not executed. It belongs into 'setup_suite.bash' to be picked up automatically."
)
```

Source: https://raw.githubusercontent.com/bats-core/bats-core/master/lib/bats-core/warnings.bash

**bats-core readthedocs documentation for BW02** (https://bats-core.readthedocs.io/en/stable/warnings/BW02.html):

> BW02: `<feature>` requires at least BATS_VERSION=`<version>`. Use `bats_require_minimum_version <version>` to fix this message.
>
> Using a feature that is only available starting with a certain version can be a problem when your tests also run on older versions of Bats. In most cases, running this code in older versions will generate an error due to a missing command. However, in cases like `run`'s where old version simply take all parameters as command to execute, the failure can be silent.
>
> **How to fix BW02**: When you encounter this warning, you can simply guard your code with `bats_require_minimum_version <version>` as the message says.

**Changelog entry (docs/CHANGELOG.md, v1.7.0):**

> * out-of-band warning infrastructure, with following warnings:
>   * BW01: run command not found (exit code 127) (#586)
>   * BW02: run uses flags without proper `bats_require_minimum_version` guard (#587)
> * `bats_require_minimum_version` to guard code that would not run on older versions (#587)

Source: https://raw.githubusercontent.com/bats-core/bats-core/master/docs/CHANGELOG.md

**Current warnings as of stable (1.13.0):** Only three BW warnings exist in bats-core: BW01, BW02, and BW03. None relate to shebangs.

---

### Shebang forms in bats-core documentation

**Standard/recommended form** throughout bats-core upstream (README, man page `bats.7`, readthedocs tutorial, all fixture files):

```bash
#!/usr/bin/env bats
```

This form is used in:
- bats-core README (`https://raw.githubusercontent.com/bats-core/bats-core/master/README.md`): shown as the canonical example
- Man page `bats.7`: `#!/usr/bin/env bats` used in `DESCRIPTION` section
- bats-core readthedocs writing-tests and gotchas pages (https://bats-core.readthedocs.io/en/stable/gotchas.html)

**There is no deprecation of `#!/usr/bin/env bats`** anywhere in:
- `docs/CHANGELOG.md` (no "shebang" entry in any release)
- The bats-core GitHub issues/PRs (zero results for "shebang deprecated" or "shebang warning")
- The readthedocs stable documentation

**`#!/usr/bin/env -S bats -t`** appears nowhere in bats-core upstream source code, documentation, or CHANGELOG. The `-t` flag is bats's TAP formatter shorthand (`--tap`); while technically functional if `env -S` is supported, it is not a documented or recommended shebang form.

The gotchas page notes that bats via shebang does not support passing parameters to `.bats` files, but does not suggest any alternative shebang form.

---

### qrspi-plus issue #243 claim vs. upstream reality

qrspi-plus issue #243 (https://github.com/dfrysinger/qrspi-plus/issues/243) states:

> `BW02 - The shebang \`#!/usr/bin/env bats\` is deprecated; use \`#!/usr/bin/env -S bats -t\` or set \`bats_load_library bats-support\` etc.`

This description is **not consistent** with the actual upstream bats-core BW02 warning. The upstream BW02 is exclusively the minimum-version requirement guard for `run` flags. Searching GitHub for "shebang BW02" returns only this qrspi-plus issue — no upstream bats-core issue, PR, or documentation produces this message text.

---

### `[[ -n "$var" && "$var" =~ "pattern" ]]` with empty `$var`

**Empirical behavior (bash 5.x):**

```bash
var=""
if [[ -n "$var" && "$var" =~ "pattern" ]]; then
    echo "PASSES"
else
    echo "FAILS"
fi
# Output: FAILS
```

When `$var` is empty, `-n "$var"` evaluates to false. Short-circuit evaluation of `&&` means the regex comparison `"$var" =~ "pattern"` is never reached. The expression evaluates to non-zero (false). The expression does **not** silently pass.

**bats-core issue documentation:**

- No bats-core issue specifically documents `[[ -n "$var" && "$var" =~ "pattern" ]]` silently passing when `$var` is empty. GitHub search for this pattern in bats-core returns unrelated results.

**bats-core Gotchas page** (https://bats-core.readthedocs.io/en/stable/gotchas.html):

The `[[ ]]` silent-pass gotcha is documented generally:

> `[[ ]] (or (( )) did not fail my test`
> The `set -e` handling of `[[ ]]` and `(( ))` changed in Bash 4.1. Older versions, like 3.2 on macOS, don't abort the test when they fail, unless they are the last command before the (test) function returns, making their exit code the return code. `[ ]` does not suffer from this, but is no replacement for all `[[ ]]` usecases. Appending `|| false` will work in all cases.

This documents a **general** `[[ ]]` failure-propagation issue in bash < 4.1, not a specific issue with the `-n "$var" && "$var" =~ "pattern"` pattern or with empty-variable behavior.

**Related ShellCheck rules:**

- **SC2076** (https://www.shellcheck.net/wiki/SC2076): `Don't quote rhs of =~, it'll match literally rather than as a regex.`  
  This applies to `"$var" =~ "pattern"` — quoting the RHS causes the regex to be interpreted as a literal string, not a regex. This is about regex interpretation, not about silent-pass with an empty variable.

- **SC2049** (https://www.shellcheck.net/wiki/SC2049): Warns when `=~` is used with a glob-like pattern.

- **SC2236** (https://www.shellcheck.net/wiki/SC2236): Suggests `-n` instead of `! -z` (stylistic, no silent-pass issue).

No ShellCheck rule specifically documents `[[ -n "$var" && "$var" =~ "pattern" ]]` as silently passing when `$var` is empty. The premise that this expression silently passes with an empty `$var` is **not supported** by bats-core documentation, bats-core issues, or ShellCheck rules — and does not match observed bash behavior in bash 4.x/5.x.

---

### Summary of sources checked

| Source | URL | Relevant content found |
|--------|-----|----------------------|
| bats-core warnings.bash | https://raw.githubusercontent.com/bats-core/bats-core/master/lib/bats-core/warnings.bash | BW02 = minimum version guard; no shebang warning |
| bats-core readthedocs BW02 | https://bats-core.readthedocs.io/en/stable/warnings/BW02.html | BW02 = `bats_require_minimum_version` |
| bats-core readthedocs Gotchas | https://bats-core.readthedocs.io/en/stable/gotchas.html | `[[ ]]` set-e gotcha; shebang params not supported |
| bats-core README | https://raw.githubusercontent.com/bats-core/bats-core/master/README.md | `#!/usr/bin/env bats` is standard, not deprecated |
| bats-core CHANGELOG | https://raw.githubusercontent.com/bats-core/bats-core/master/docs/CHANGELOG.md | BW02 introduced v1.7.0; "shebang" = only a missing-shebang fix in warnings.bash (#597) |
| bats-core man page bats.7 | https://raw.githubusercontent.com/bats-core/bats-core/master/man/bats.7 | `#!/usr/bin/env bats` shown as standard |
| GitHub search: BW02 shebang | https://api.github.com/search/issues?q=BW02+shebang | Only returns qrspi-plus #243; no upstream bats-core results |
| GitHub search: shebang deprecated (bats-core) | bats-core repo search | 0 results |
| ShellCheck SC2076 | https://www.shellcheck.net/wiki/SC2076 | Quoting `=~` RHS; not about empty-var silent pass |
| qrspi-plus issue #243 | https://github.com/dfrysinger/qrspi-plus/issues/243 | Claims BW02 = shebang deprecation; not matched by upstream |
