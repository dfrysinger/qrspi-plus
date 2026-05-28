---
finding_id: R1-F06
severity: medium
change_type: correctness
referenced_files: [docs/qrspi/2026-05-17-v07-release/research/summary.md:L343-L356]
artifact: research
round: 1
reviewer: quality-claude
---

The Q25 section is a `[web]` research question about lint/CI patterns for detecting version strings and dated language in markdown-driven prompt/skill libraries. None of its five Key findings bullets carry a URL or source-attribution citation. The bullets make specific factual assertions about named external repositories and rule files — "GitLab uses Vale in documentation pipelines; error-level Vale rules fail CI", "GitLab's `OutdatedVersions.yml` is a concrete dated-version detector: it flags unsupported GitLab version references using a regex token and emits the message 'If possible, remove the reference to "%s".'", "GitLab's `CurrentStatus.yml` flags `currently` with the message 'Remove "%s". The documentation reflects the current state of the product,'", "Strapi's documentation repo exposes a YAML style-validation config with `docs/**/*.md` and `docs/**/*.mdx` targets, forbidden phrase lists, severity levels, and PR-blocking critical violations", "Anthropic's public `skills` repository and Microsoft's `promptflow` repository did not visibly expose CI or lint rules specifically for temporal language".

The Caveats note that "GitHub top-level pages can hide workflow contents" and that the investigation used "fetched public pages and targeted GitHub code search/API lookups", but no URLs to the cited Vale rule files, Strapi config, Anthropic skills repo, or Microsoft promptflow repo are present. The quoted message strings from `OutdatedVersions.yml` and `CurrentStatus.yml` are direct quotations from external files that require source-URL citations under the reviewer-protocol `[web]` research check — quoted text without a quoted source URL is exactly the citation gap the check exists to catch.
