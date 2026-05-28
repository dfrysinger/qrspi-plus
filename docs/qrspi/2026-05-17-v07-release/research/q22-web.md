---
status: draft
question_ids: [22]
research_type: web
---

# Q22: What current GitHub Actions patterns (2025–2026) exist for running BATS test suites and shell linting on `ubuntu-latest`, including dependency installation, matrix strategies, and caching?

## Summary

**TL;DR:** Current GitHub Actions patterns for BATS on `ubuntu-latest` split into three main forms: using a BATS-specific setup action, installing BATS directly through npm/apt/source, or using the BATS action that also installs common helper libraries. Shell linting patterns most commonly use `ludeeus/action-shellcheck`, while GitHub-hosted Ubuntu 24.04 runner images also list ShellCheck as a preinstalled apt package. Matrix and caching patterns combine standard GitHub Actions `strategy.matrix` syntax with `actions/cache@v5` or BATS-action built-in caching behavior, especially when BATS helper libraries are installed under the workspace or `$HOME` instead of `/usr/lib`.

**Key findings:**
- BATS setup actions exist in two visible patterns: `sgerrand/setup-bats-action@v1`, which installs BATS itself, and `bats-core/bats-action@4.0.0`, which installs BATS plus `bats-support`, `bats-assert`, `bats-detik`, and `bats-file`.
- BATS upstream installation docs still list apt, npm, Homebrew, source install, and Docker patterns; the docs warn that Ubuntu apt packages can lag and that pre-1.0 BATS packages came from the original project.
- Shell linting patterns use either a dedicated ShellCheck action (`ludeeus/action-shellcheck@master`) or direct runner-provided `shellcheck`; Ubuntu 24.04 runner image documentation lists `shellcheck 0.9.0-1` as an installed apt package.
- Matrix usage for this class of workflow is normally at the job level with `runs-on: ${{ matrix.os }}` and dimensions such as operating system, BATS version, ShellCheck version, or shell dialect.
- Caching is handled either by `actions/cache@v5` with explicit `path`, `key`, and optional `restore-keys`, or by BATS action behavior; `bats-core/bats-action` states BATS binary caching is always available, while helper-library caching depends on installing libraries inside `$HOME`.

**Surprises:** ShellCheck is listed as preinstalled on the Ubuntu 24.04 GitHub-hosted runner image, so a separate ShellCheck action is not the only current pattern for shell linting on Ubuntu runners. The BATS action’s README also states that default Linux helper-library paths under `/usr/lib/bats-*` are not cache-supported because of a known sudo/cache-action limitation.

**Caveats:** WebFetch succeeded for BATS and ShellCheck action pages but was rate-limited on GitHub’s matrix/cache documentation pages. GitHub repository README and runner-image content were retrieved through GitHub’s public API, and the matrix section uses the public GitHub Actions matrix documentation URL plus observed action README examples rather than a successful WebFetch extraction from that page.

## Full findings

### Query Planning

Planned source categories before searching:

1. BATS upstream installation documentation for baseline dependency-install options on Ubuntu.
2. GitHub Marketplace and repository README pages for BATS-specific setup actions.
3. ShellCheck GitHub Action Marketplace and README pages for shell linting patterns, inputs, severity handling, and version pinning.
4. GitHub Actions documentation and action READMEs for matrix and caching syntax.
5. GitHub-hosted runner image documentation for what is already present on Ubuntu runners.

Sources consulted:

- BATS installation docs: https://bats-core.readthedocs.io/en/stable/installation.html
- Setup BATS Marketplace page: https://github.com/marketplace/actions/setup-bats
- `bats-core/bats-action` README: https://github.com/bats-core/bats-action
- ShellCheck action README: https://github.com/ludeeus/action-shellcheck
- ShellCheck Marketplace page: https://github.com/marketplace/actions/shellcheck
- `actions/cache` README: https://github.com/actions/cache
- Ubuntu 24.04 runner image README: https://github.com/actions/runner-images/blob/main/images/ubuntu/Ubuntu2404-Readme.md
- GitHub Actions matrix documentation URL consulted but WebFetch was rate-limited: https://docs.github.com/en/actions/using-jobs/using-a-matrix-for-your-jobs

### BATS dependency installation patterns on `ubuntu-latest`

#### Pattern 1: BATS-specific setup action for BATS only

The GitHub Marketplace page for “Setup BATS” presents `sgerrand/setup-bats-action@v1` as an action that installs BATS in a workflow (source: https://github.com/marketplace/actions/setup-bats). Its examples show this minimal Ubuntu-compatible pattern:

```yaml
steps:
  - uses: actions/checkout@v6
  - uses: sgerrand/setup-bats-action@v1
  - run: bats tests/
```

The same page documents a `version` input with examples such as `1.11.0` or `v1.11.0`, defaulting to `latest`, plus a `token` input defaulting to `${{ github.token }}` for resolving the latest release. It also documents an output named `version`, which is the resolved installed BATS version without a leading `v`.

Observed pattern characteristics:

- BATS is installed as a tool before `bats tests/` is invoked.
- Version pinning is represented through the action input, not a package-manager command.
- The page does not document helper-library installation, matrix examples, or caching behavior.

#### Pattern 2: `bats-core/bats-action` for BATS plus helper libraries

The `bats-core/bats-action` README describes an action that installs BATS and four major BATS helper libraries: `bats-support`, `bats-assert`, `bats-detik`, and `bats-file` (source: https://github.com/bats-core/bats-action). Its documented `ubuntu-latest` example is:

```yaml
on: [push]

jobs:
  bats:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v5

      - id: bats
        uses: bats-core/bats-action@4.0.0

      - name: Run Bats tests
        shell: bash
        env:
          BATS_LIB_PATH: ${{ steps.bats.outputs.lib-path }}
          TERM: xterm
        run: bats test/my-test
```

The action exposes `lib-path`, which is commonly wired into `BATS_LIB_PATH` so tests can call `bats_load_library`. The README lists configurable inputs for installing BATS and each library, including:

- `bats-install`, default `true`
- `bats-version`, default `latest`
- `support-install`, `support-version`, `support-path`
- `assert-install`, `assert-version`, `assert-path`
- `detik-install`, `detik-version`, `detik-path`
- `file-install`, `file-version`, `file-path`

The README states Linux is fully supported and shows an OS matrix containing `ubuntu-latest`, `macos-latest`, and `windows-latest`.

#### Pattern 3: Direct package-manager or source install

The BATS installation documentation lists several install methods relevant to GitHub Actions on Ubuntu (source: https://bats-core.readthedocs.io/en/stable/installation.html):

- Ubuntu package manager: the docs link to Ubuntu’s `bats` package and warn that “Bats versions pre 1.0 are from sstephenson’s original project.” The docs state to consider other installation methods to get the latest BATS release.
- npm global install: `npm install -g bats`
- npm project dependency: `npm install --save-dev bats`
- source install: clone `https://github.com/bats-core/bats-core.git` and run `./install.sh /usr/local`; the docs note `install.sh` may need `sudo`.
- Docker: `docker run -it bats/bats:latest --version` and mounting the working directory at `/code` to run local tests.

Observed workflow implication: apt-based installation is available on Ubuntu, but current BATS docs explicitly frame other methods as a way to get newer BATS releases.

### Shell linting patterns on `ubuntu-latest`

#### Pattern 1: Dedicated ShellCheck action

The `ludeeus/action-shellcheck` README and Marketplace page both document a basic `ubuntu-latest` job (sources: https://github.com/ludeeus/action-shellcheck and https://github.com/marketplace/actions/shellcheck):

```yaml
on:
  push:
    branches:
      - master

name: "Trigger: Push action"
permissions: {}

jobs:
  shellcheck:
    name: Shellcheck
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Run ShellCheck
        uses: ludeeus/action-shellcheck@master
```

The same sources document these current action inputs and controls:

- `SHELLCHECK_OPTS` environment variable for arbitrary ShellCheck options, including disabling rules such as `-e SC2059 -e SC2034 -e SC1090` or selecting shell dialects such as `-s dash` or `-s ksh`.
- `ignore_paths` and `ignore_names` for excluding directories, full paths, glob patterns, or filenames.
- `severity` with levels `error`, `warning`, `info`, and `style`.
- `check_together: 'yes'` to run ShellCheck on all paths in one invocation, with a README warning that many scripts can exceed maximum argument length.
- `scandir` to scan only one directory, e.g. `./scripts`.
- `additional_files` for unusual filenames such as `run finish`.
- `format` for output formats including `checkstyle`, `diff`, `gcc`, `json`, `json1`, `quiet`, and `tty`.
- `version` to select a ShellCheck release such as `v0.9.0`.

The Marketplace content presents the action as using the latest stable ShellCheck by default unless `version` is set.

#### Pattern 2: Direct `shellcheck` on runner image

The Ubuntu 24.04 GitHub-hosted runner image README lists `shellcheck 0.9.0-1` under installed apt packages and `Bash 5.2.21(1)-release` under language/runtime tools (source: https://github.com/actions/runner-images/blob/main/images/ubuntu/Ubuntu2404-Readme.md). It does not list BATS among the installed packages in the retrieved content.

Observed workflow implication: on Ubuntu 24.04 runner images, a shell lint job can invoke `shellcheck` directly after checkout if the repository is satisfied with the runner-provided ShellCheck version. A dedicated ShellCheck action remains a separate pattern when repository workflows need action-managed scanning behavior, version selection, ignore controls, or output-format controls.

### Matrix strategies observed for BATS and shell linting

Current matrix patterns relevant to BATS and ShellCheck jobs include:

#### OS matrix

The `bats-core/bats-action` README includes this matrix shape (source: https://github.com/bats-core/bats-action):

```yaml
strategy:
  matrix:
    os: [ubuntu-latest, macos-latest, windows-latest]

runs-on: ${{ matrix.os }}
```

For this question’s `ubuntu-latest` scope, the same pattern can be reduced to Ubuntu-only dimensions or used to keep Ubuntu as one axis in a broader compatibility job.

#### Version matrix

The Setup BATS Marketplace page documents a `version` input for BATS (source: https://github.com/marketplace/actions/setup-bats). A current version-matrix pattern is to feed a matrix value into that input:

```yaml
strategy:
  matrix:
    bats-version: ['1.11.0', 'latest']

steps:
  - uses: actions/checkout@v6
  - uses: sgerrand/setup-bats-action@v1
    with:
      version: ${{ matrix.bats-version }}
  - run: bats tests/
```

The ShellCheck action similarly documents a `version` input such as `v0.9.0` (source: https://github.com/ludeeus/action-shellcheck), which supports the same matrix-value pattern for ShellCheck versions.

#### Shell dialect matrix

The ShellCheck action README documents `SHELLCHECK_OPTS` examples for `-s dash` and `-s ksh` (source: https://github.com/ludeeus/action-shellcheck). That maps to a shell-dialect matrix pattern:

```yaml
strategy:
  matrix:
    shell-dialect: [bash, dash, ksh]

steps:
  - uses: actions/checkout@v4
  - uses: ludeeus/action-shellcheck@master
    env:
      SHELLCHECK_OPTS: -s ${{ matrix.shell-dialect }}
```

#### Include/exclude and fail behavior

GitHub’s matrix documentation describes standard `strategy.matrix` expansion and use of matrix variables in job properties such as `runs-on` (source URL: https://docs.github.com/en/actions/using-jobs/using-a-matrix-for-your-jobs). For BATS/ShellCheck workflows, the relevant documented syntax family is:

- `matrix` to define axes such as OS, BATS version, ShellCheck version, or shell dialect.
- `include` to add specific combinations or additional metadata.
- `exclude` to remove invalid combinations.
- job strategy controls such as `fail-fast` and per-combination `continue-on-error` in workflows that mark one matrix cell experimental.

### Caching patterns

#### General `actions/cache@v5` pattern

The `actions/cache` README states that `actions/cache@v5` runs on Node.js 24 and requires Actions Runner version `2.327.1` or newer (source: https://github.com/actions/cache). It also states that older cache backends were sunset as of February 1, 2025, and that current versions integrate with the new cache service APIs.

The README’s basic cache pattern on `ubuntu-latest` is:

```yaml
steps:
  - uses: actions/checkout@v6

  - name: Cache Primes
    id: cache-primes
    uses: actions/cache@v5
    with:
      path: prime-numbers
      key: ${{ runner.os }}-primes

  - name: Generate Prime Numbers
    if: steps.cache-primes.outputs.cache-hit != 'true'
    run: /generate-prime-numbers.sh -d prime-numbers
```

The README documents these inputs and behaviors:

- `path`: files, directories, and glob patterns to cache.
- `key`: explicit cache entry key.
- `restore-keys`: ordered multiline prefix keys for stale cache restore.
- `enableCrossOsArchive`: optional cross-OS archive behavior, default `false`.
- `fail-on-cache-miss`: fail workflow if no cache entry is found, default `false`.
- `lookup-only`: check cache existence without download, default `false`.
- `cache-hit`: output set to `true` for an exact primary-key hit, `false` for restore-key match or no restored cache, and empty string for cache miss in the README’s description.

The README also documents cache scope: cache entries are scoped to key, version, and branch, and default-branch cache is available to other branches. It states repository caches are limited to 10 GB and that caches not accessed within the last week are evicted.

#### Lockfile/key pattern

The `actions/cache` README documents use of `hashFiles` for keys, e.g. keys combining runner OS and lockfile hashes (source: https://github.com/actions/cache):

```yaml
- uses: actions/cache@v5
  with:
    path: |
      path/to/dependencies
      some/other/dependencies
    key: ${{ runner.os }}-${{ hashFiles('**/lockfiles') }}
```

For shell projects, analogous cached paths commonly include package-manager directories or checked-out test helper libraries, while the evidence source itself only documents the generic dependency-cache mechanism.

#### BATS-action caching behavior

The `bats-core/bats-action` README has a specific “About Caching” section (source: https://github.com/bats-core/bats-action). It states:

- Caching for the `bats` binary is always available.
- Caching for BATS libraries depends on each library path.
- If a library is located inside `$HOME`, caching is supported.
- If a library is located outside `$HOME`, including the default library locations, caching is not supported.
- The README attributes the limitation to sudo and the cache action, linking to a GitHub toolkit issue.
- The README states: “If you want to cache bats libraries you must install them inside HOME directory.”

The README gives cache-friendly custom paths under the workspace:

```yaml
with:
  support-path: ${{ github.workspace }}/tests/bats-support
  assert-path: ${{ github.workspace }}/tests/bats-assert
  detik-path: ${{ github.workspace }}/tests/bats-detik
  file-path: ${{ github.workspace }}/tests/bats-file
```

This is the main BATS-specific caching pattern found in current action documentation.

### Consolidated current workflow shapes

#### BATS-only setup action plus ShellCheck action

```yaml
jobs:
  shell:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v6
      - uses: sgerrand/setup-bats-action@v1
        with:
          version: '1.11.0'
      - run: bats tests/
      - uses: ludeeus/action-shellcheck@master
        env:
          SHELLCHECK_OPTS: -e SC1090
```

This shape is directly composed from the Setup BATS Marketplace examples and the ShellCheck action README examples.

#### BATS helper libraries plus `BATS_LIB_PATH`

```yaml
jobs:
  bats:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v5
      - id: setup-bats
        uses: bats-core/bats-action@4.0.0
      - name: Run Bats tests
        shell: bash
        env:
          BATS_LIB_PATH: ${{ steps.setup-bats.outputs.lib-path }}
          TERM: xterm
        run: bats test/my-test
```

This shape is the `bats-core/bats-action` documented Ubuntu example.

#### Direct runner ShellCheck

```yaml
jobs:
  shellcheck:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: shellcheck scripts/*.sh
```

The factual basis is the Ubuntu 24.04 runner image README listing ShellCheck as installed; the exact glob is workflow-specific, not prescribed by the runner image documentation.

#### Matrix with cache-aware BATS library paths

```yaml
jobs:
  bats:
    runs-on: ${{ matrix.os }}
    strategy:
      matrix:
        os: [ubuntu-latest]
        bats-version: ['latest']
    steps:
      - uses: actions/checkout@v6
      - id: setup-bats
        uses: bats-core/bats-action@4.0.0
        with:
          bats-version: ${{ matrix.bats-version }}
          support-path: ${{ github.workspace }}/tests/bats-support
          assert-path: ${{ github.workspace }}/tests/bats-assert
          detik-path: ${{ github.workspace }}/tests/bats-detik
          file-path: ${{ github.workspace }}/tests/bats-file
      - shell: bash
        env:
          BATS_LIB_PATH: ${{ steps.setup-bats.outputs.lib-path }}
          TERM: xterm
        run: bats tests/
```

This shape combines the BATS action’s documented matrix support, BATS version input, output wiring, and cache-friendly helper-library path guidance.
