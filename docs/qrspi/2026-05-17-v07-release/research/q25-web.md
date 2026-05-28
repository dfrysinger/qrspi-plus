---
status: draft
question_ids: [25]
research_type: web
---

# Q25: What lint or CI patterns do other markdown-driven prompt or skill libraries use to detect or prevent version strings, milestone references, or other dated language from accumulating in files intended to be stable across releases?

## Summary

**TL;DR:** The clearest public pattern is not from prompt/skill libraries specifically, but from documentation repositories that treat Markdown as stable product content: GitLab uses Vale rules in CI to flag future tense, temporary-status wording, and outdated version references. Vale and markdownlint both provide mechanisms for repository-specific Markdown checks, but Vale is the more directly documented fit for prose-level banned terms, regexes, substitutions, and severity levels. Public prompt/skill repositories checked here did not visibly document rules that specifically block version strings, milestone references, or dated language in prompt/skill Markdown.

**Key findings:**
- GitLab uses Vale in documentation pipelines; error-level Vale rules fail CI, warnings appear in merge request diffs, and suggestions are advisory. Its custom rules include `FutureTense.yml`, `CurrentStatus.yml`, and `OutdatedVersions.yml`.
- GitLab's `OutdatedVersions.yml` is a concrete dated-version detector: it flags unsupported GitLab version references using a regex token and emits the message "If possible, remove the reference to '%s'."
- GitLab's `CurrentStatus.yml` flags `currently` with the message "Remove '%s'. The documentation reflects the current state of the product," which is directly aligned with preventing stable docs from implying transience.
- Strapi's documentation repo exposes a YAML style-validation config with `docs/**/*.md` and `docs/**/*.mdx` targets, forbidden phrase lists, severity levels, and PR-blocking critical violations; the fetched config did not show date/version-specific rules.
- Anthropic's public `skills` repository and Microsoft's `promptflow` repository did not visibly expose CI or lint rules specifically for temporal language, release strings, or milestone references in Markdown/prompt files in the fetched top-level pages.

**Surprises:** Public prompt/skill libraries checked here did not provide obvious examples of stable-prompt Markdown checks for versions or dates; the strongest evidence came from general documentation systems, especially GitLab's Vale rule set.

**Caveats:** This was web research using fetched public pages and targeted GitHub code search/API lookups. It was not an exhaustive crawl of all prompt libraries, private CI configurations, or every workflow file in the repositories sampled. GitHub top-level pages can hide workflow contents, so absence of visible evidence in a fetched page is not proof that a repository has no such checks.

## Full findings

### Query planning

The search plan was to look for three categories of evidence:

1. Prose/Markdown lint tools that support repository-specific checks for text patterns such as versions, dates, milestones, or temporal language.
2. Public documentation repositories with concrete CI or lint rules that detect stale release/version wording in Markdown.
3. Public prompt or skill repositories to see whether they publish comparable rules for prompt/skill Markdown.

Searches and fetches focused on Vale, markdownlint, GitLab documentation, Strapi documentation style validation, Anthropic skills, Anthropic cookbook, and Microsoft promptflow.

### Tool pattern: Vale custom prose rules for Markdown

Vale is the strongest general-purpose pattern found for this class of check.

Sources:
- https://vale.sh/docs/topics/styles/
- https://github.com/errata-ai/vale
- https://docs.gitlab.com/development/documentation/testing/vale/

Findings:

- Vale styles are collections of YAML rule files stored under a configured `StylesPath`.
- Vale rules can target Markdown and other markup-aware prose formats.
- The fetched Vale styles documentation identifies `existence` rules as checks for the presence of a regex pattern and `substitution` rules as replacements or preferred wording rules.
- This makes Vale directly applicable to stable Markdown files because a repository can define regex tokens for release names, semantic versions, milestone strings, month/year strings, or words such as `currently` and assign severity levels.
- The fetched Vale repository page describes Vale as a command-line tool that brings "code-like linting to prose" and shows automation-adjacent files/integrations, including GitHub Actions, GitLab CI, AppVeyor, pre-commit hooks, and Docker.

Observed pattern:

- Define a YAML rule per policy.
- Use `extends: existence` for banned terms or regex patterns.
- Use `extends: substitution` for preferred wording.
- Use rule `level` to distinguish CI-blocking errors from warnings or suggestions.
- Run Vale in local hooks and CI using the same config.

### Concrete implementation: GitLab documentation Vale rules

Sources:
- https://docs.gitlab.com/development/documentation/testing/vale/
- https://gitlab.com/gitlab-org/gitlab/-/raw/master/doc/.vale/gitlab_base/FutureTense.yml
- https://gitlab.com/gitlab-org/gitlab/-/raw/master/doc/.vale/gitlab_base/CurrentStatus.yml
- https://gitlab.com/gitlab-org/gitlab/-/raw/master/doc/.vale/gitlab_base/OutdatedVersions.yml
- https://docs.gitlab.com/development/documentation/styleguide/availability_details/#removing-versions
- https://docs.gitlab.com/development/documentation/styleguide/#promising-features-in-future-versions

GitLab's documentation testing page describes Vale as "a grammar, style, and word usage linter for the English language." It states that the same configuration is used in pipelines and that error-level rules are enforced in CI.

The fetched GitLab docs page describes result types as follows:

- `error`: fails CI, appears in merge request diffs, and appears in CI output.
- `warning`: does not fail CI, appears in merge request diffs, and does not appear in CI output.
- `suggestion`: does not fail CI and does not appear in merge request diffs or CI output.

The GitLab rule directory listing obtained through GitHub/GitLab repository access included these relevant custom Vale rule files under `doc/.vale/gitlab_base`:

- `FutureTense.yml`
- `CurrentStatus.yml`
- `OutdatedVersions.yml`
- Other style/stability rules such as `Substitutions.yml`, `ToDo.yml`, `Offerings.yml`, `DefaultBranch.yml`, and `SelfReferential.yml`

#### GitLab `FutureTense.yml`

Source: https://gitlab.com/gitlab-org/gitlab/-/raw/master/doc/.vale/gitlab_base/FutureTense.yml

Fetched rule characteristics:

- `name: gitlab_base.FutureTense`
- `extends: existence`
- `level: warning`
- Message: `Instead of future tense '%s', use present tense.`
- Link: https://docs.gitlab.com/development/documentation/styleguide/word_list/#future-tense
- Tokens include patterns for `going to`, `will`, `won't`, and contracted forms such as `we'll`, `you'll`, and `they'll` followed by another word.

This is a concrete lint pattern for preventing stable docs from accumulating future-tense commitments or planned-release phrasing.

#### GitLab `CurrentStatus.yml`

Source: https://gitlab.com/gitlab-org/gitlab/-/raw/master/doc/.vale/gitlab_base/CurrentStatus.yml

Fetched rule characteristics:

- `name: gitlab_base.CurrentStatus`
- Description: checks for words that indicate a product or feature may change in the future.
- `extends: existence`
- `level: warning`
- Token: `currently`
- Message: `Remove '%s'. The documentation reflects the current state of the product.`
- Link: https://docs.gitlab.com/development/documentation/styleguide/#promising-features-in-future-versions

This is the closest direct example found for a stable-across-releases wording rule: it treats `currently` as stale-prone because current-state documentation should not imply that the text is temporary.

#### GitLab `OutdatedVersions.yml`

Source: https://gitlab.com/gitlab-org/gitlab/-/raw/master/doc/.vale/gitlab_base/OutdatedVersions.yml

Fetched rule characteristics:

- `name: gitlab_base.OutdatedVersions`
- Description: checks for references to GitLab versions that are no longer supported.
- `extends: existence`
- `level: suggestion`
- Message: `If possible, remove the reference to '%s'.`
- Link: https://docs.gitlab.com/development/documentation/styleguide/availability_details/#removing-versions
- Regex token: `GitLab v?(2[^0-9]|[4-9]|1[0-5])`

This is a concrete version-string detector. It flags references to older GitLab versions using a regular expression rather than a generic date detector. Its severity is `suggestion`, so it is advisory rather than CI-blocking in the fetched rule.

GitLab's availability-details style guide states that history items and inline text should be removed when they reference unsupported versions. It describes support as the current major version and two previous major versions. It also describes timing for removing references around major releases. The fetched style-guide page did not itself name the `OutdatedVersions` Vale rule, but the Vale rule links to that page.

#### GitLab future-feature guidance

Source: https://docs.gitlab.com/development/documentation/styleguide/#promising-features-in-future-versions

The fetched style-guide guidance says not to state that GitLab will ship future functionality and to avoid wording such as "Support for this feature is planned." It prefers issue-based wording that says an issue proposes a change instead of implying commitment or timing. It allows planned removals of existing features and says forward-looking disclaimers may be used when future functionality must be documented.

Pattern extracted:

- Style guide defines stale-prone language policy.
- Vale rules encode high-signal terms or regexes from the policy.
- CI/MR integration surfaces violations at severity levels appropriate to confidence.

### Concrete implementation: Strapi documentation style-validation config

Source:
- https://github.com/strapi/documentation/blob/main/docusaurus/scripts/style-validation/style-rules.yml

Fetched findings:

- Strapi's documentation repository has a YAML style-validation configuration named around "Strapi 12 Rules of Technical Writing."
- The fetched config groups rules under categories including `content_rules`, `structure_rules`, `formatting_rules`, `media_rules`, `strapi_specific_rules`, `critical_violations`, `validation_settings`, `reporting`, and `quick_rules`.
- It targets Markdown/MDX paths including `docs/**/*.md` and `docs/**/*.mdx`.
- It excludes paths including `docs/legacy/**` and `**/README.md`.
- It defines forbidden-word and forbidden-phrase lists, such as casual terms and phrases including `funny`, `hilarious`, `awesome`, `amazing`, `cool`, `super`, `lol`, `piece of cake`, `child's play`, `rocket science`, and `no-brainer`.
- It defines severity behavior: `error` blocks PRs with exit code `1`, `warning` reports but exits `0`, and `suggestion` recommends improvement while exiting `0`.
- It has critical violations with `block_pr: true`.

The fetched Strapi config did not show an explicit future-tense, version-string, milestone, or date detector. Its relevant pattern is the schema: a repo-owned YAML file with path targeting, exclusions, forbidden phrase lists, severities, and PR-blocking critical rules. That schema could host release/date/milestone terms, but the fetched evidence shows style and terminology enforcement rather than version-staleness enforcement.

### Tool pattern: markdownlint custom rules

Source:
- https://github.com/DavidAnson/markdownlint

Fetched findings:

- markdownlint's built-in rules cover Markdown structure/style issues such as headings, lists, whitespace, links, images, tables, code blocks, line length, HTML, and accessibility.
- The fetched repository page states that custom rules can address project-specific requirements.
- Custom rules can be supplied through `options.customRules`.
- Community rules can be found on npm using the `markdownlint-rule` keyword.
- Auto-fixing is available for rules that provide fix information.

The fetched markdownlint evidence did not identify a built-in rule for version strings, dates, milestone names, or temporal language. The relevant pattern is that custom JavaScript rules can inspect Markdown tokens or raw lines for repository-specific patterns. Compared with Vale, markdownlint is more Markdown-structure oriented; implementing stale-language checks usually requires custom rule code rather than a simple YAML prose rule.

### Prompt and skill repositories checked

#### Anthropic `skills`

Source:
- https://github.com/anthropics/skills

Fetched findings:

- The top-level repository page showed directories and files including `.claude-plugin/`, `skills/`, `spec/`, `template/`, `.gitignore`, `README.md`, and `THIRD_PARTY_NOTICES.md`.
- The fetched README content documents skill structure: a skill is a folder with a `SKILL.md` file containing YAML frontmatter and instructions.
- The fetched page did not show a `.github/workflows/` directory, pre-commit config, markdown linter config, Vale config, or CI rule for stable-language checks.
- No visible evidence was found on the fetched page for detecting version strings, milestone references, dates, or temporal language in skill Markdown.

#### Anthropic cookbook

Source:
- https://github.com/anthropics/anthropic-cookbook

Fetched findings:

- The fetched top-level page showed CI/config-related files such as `.github/`, `.pre-commit-config.yaml`, `tox.ini`, `pyproject.toml`, and `lychee.toml`.
- The fetched page did not show the contents of those files.
- The README excerpt did not mention Markdown linting, dated-language checks, or version-string detection.
- No visible evidence was found on the fetched page for checks specific to stale temporal language in Markdown prompt/cookbook content.

#### Microsoft `promptflow`

Source:
- https://github.com/microsoft/promptflow

Fetched findings:

- The fetched top-level page showed `.github`, `.pre-commit-config.yaml`, `.cspell.json`, `pylintrc`, and `setup.cfg`, indicating that lint/spellcheck infrastructure may exist.
- The fetched README mentions integrating testing and evaluation into CI/CD generally.
- The fetched page did not visibly document linting rules or CI checks for version strings, dates, milestone references, or stale temporal language in prompt YAML or Markdown.

### Patterns observed across sources

1. **Regex-backed prose rules in Vale**
   - GitLab's `OutdatedVersions.yml` demonstrates regex matching of release/version text.
   - GitLab's `FutureTense.yml` demonstrates regex matching of future-tense constructions.
   - GitLab's `CurrentStatus.yml` demonstrates a single-token rule for stale-prone temporal wording.

2. **Severity mapping to CI behavior**
   - GitLab distinguishes `error`, `warning`, and `suggestion`, with errors failing CI.
   - Strapi's fetched config similarly maps `error` to PR-blocking behavior and `warning`/`suggestion` to non-blocking output.

3. **Policy page plus machine rule**
   - GitLab links Vale rules to style-guide pages, such as availability details and future-tense guidance.
   - The rule messages are short and point the author to the reason or source policy.

4. **Path scoping and exclusions**
   - Strapi's style-validation config targets `docs/**/*.md` and `docs/**/*.mdx`, while excluding legacy docs and README files.
   - This pattern is relevant when only some Markdown is intended to be stable across releases.

5. **Prompt/skill-specific public evidence was thin**
   - Public prompt/skill repositories checked here did not visibly publish stale-version or dated-language checks for prompt/skill Markdown.
   - The available evidence suggests that markdown-driven prompt/skill projects can borrow patterns from documentation repositories, but this research did not find a prompt/skill repository with a public, purpose-built stale-release lint rule comparable to GitLab's Vale rules.
