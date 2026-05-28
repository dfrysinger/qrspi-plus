---
finding_id: R1-F05
severity: medium
change_type: correctness
referenced_files: [docs/qrspi/2026-05-17-v07-release/research/summary.md:L295-L308]
artifact: research
round: 1
reviewer: quality-claude
---

The Q22 section is a `[web]` research question about current GitHub Actions patterns (2025–2026) for running BATS test suites and shell linting on `ubuntu-latest`. None of its five Key findings bullets carry a URL or source-attribution citation. The bullets make specific factual assertions about external action versions and runner-image package versions — "`sgerrand/setup-bats-action@v1`, which installs BATS itself, and `bats-core/bats-action@4.0.0`, which installs BATS plus `bats-support`, `bats-assert`, `bats-detik`, and `bats-file`", "Ubuntu 24.04 runner image documentation lists `shellcheck 0.9.0-1` as an installed apt package", "`actions/cache@v5` with explicit `path`, `key`, and optional `restore-keys`", and the Surprises bullet asserts that "default Linux helper-library paths under `/usr/lib/bats-*` are not cache-supported because of a known sudo/cache-action limitation".

The Caveats note that "WebFetch succeeded for BATS and ShellCheck action pages but was rate-limited on GitHub's matrix/cache documentation pages" and that GitHub content was retrieved through "GitHub's public API" — but no URLs are quoted in the summary. The reviewer-protocol research check requires `[web]` research to include URLs and source attribution for every factual claim; pinned action versions (`@v1`, `@4.0.0`, `@v5`) and package-version assertions (`shellcheck 0.9.0-1`) are exactly the kind of claim that requires a citation to the README/release note/runner-image manifest that established the version.
