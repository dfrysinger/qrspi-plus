---
status: draft
question_ids: [6]
research_type: web
---

# Q6: Patterns for Encoding Absorbed or Superseded Scope Items in Structured Planning Documents

## Summary

**TL;DR:** Five primary encoding patterns exist for marking absorbed or superseded scope items in structured planning documents: (1) lifecycle-status header fields (RFC `Obsoletes`/`Superseded-By`, PEP `Superseded-By`, MADR frontmatter `status`), (2) inline visual-deletion markup (`~~strikethrough~~` / HTML `<del>`), (3) enumerated resolution/state values in issue trackers (GitHub `state_reason`, Jira resolution types, Azure DevOps `Removed` state category), (4) versioned deprecation notices in documentation toolchains (Sphinx `.. deprecated::`, Docusaurus `banner: "unmaintained"`), and (5) schema-level boolean annotations (`deprecated: true` in OpenAPI/JSON Schema). Interactions with downstream processors vary sharply by pattern: status-field and resolution-enum patterns are machine-readable and drive filtering/visibility logic in trackers and build tools, while inline strikethrough is rendered visually but carries no semantic payload that processors can act on, and schema `deprecated` annotations are advisory only and do not cause validation failure.

**Key findings:**

- **RFC/PEP bidirectional cross-reference headers**: The IETF RFC format defines `Obsoletes:` and `Updates:` header fields; the RFC 2026 process assigns `Historic` status to superseded specs (RFC 2026 §4.2.4). Python PEPs use `Status: Superseded` plus a `Superseded-By: NNN` field in the RFC 2822-style preamble, with the replacement PEP carrying a `Replaces: NNN` field — bidirectional pointers in the document itself. Source: `peps.python.org/pep-0001/`, `raw.githubusercontent.com/python/peps/main/peps/pep-0005.rst`.

- **Architecture Decision Records (ADR) — free-text `## Status` section with cross-links**: The Michael Nygard ADR template specifies a free-text `## Status` section accepting values such as `proposed`, `accepted`, `rejected`, `deprecated`, `superseded`. The `adr-tools` CLI (`github.com/npryce/adr-tools`) implements a `adr new -s N` command that: (a) removes `Accepted` from the superseded ADR's `## Status` section via `awk`, (b) inserts a `Superceded by [title](file)` link into that section, and (c) inserts a `Supercedes [title](file)` link into the new ADR. MADR (Markdown ADR format) encodes the same information as YAML frontmatter: `status: "superseded by ADR-0123"`. Source: `adr-tools` `src/adr-new`, `src/_adr_add_link`, `src/_adr_remove_status`; `raw.githubusercontent.com/adr/madr/main/template/adr-template.md`.

- **Inline strikethrough (`~~text~~` → `<del>`)**: GitHub Flavored Markdown (GFM) defines a strikethrough extension (§6.5) rendering `~~text~~` as `<del>text</del>`. Pandoc implements this as the `strikeout` extension; in LaTeX output it becomes `\sout{text}`, in HTML `<del>`, and in DOCX format, strikethrough character formatting. The HTML `<del>` element is semantically a "range of text deleted from a document" per the HTML Living Standard (§4.7.2) and optionally carries `datetime` and `cite` attributes. Pandoc's `--track-changes=all` for DOCX input wraps `w:del` content in `<span class="deletion">` with author/time. **Importantly**, GFM strikethrough is not part of CommonMark; parsers without the extension pass through `~~text~~` as literal characters. Source: `github.github.com/gfm/#strikethrough-extension-`; `pandoc.org/MANUAL.html`; `html.spec.whatwg.org/multipage/edits.html`.

- **Keep a Changelog / SemVer two-stage deprecation**: Keep a Changelog 1.1.0 defines two distinct sections: `### Deprecated` (for soon-to-be-removed features) and `### Removed` (for now-removed features). SemVer specifies that marking a feature deprecated triggers a MINOR version bump; actual removal requires a MAJOR version bump, with at least one minor release containing the deprecation in place before removal. Source: `keepachangelog.com/en/1.1.0/`; `semver.org/`.

- **Schema and API `deprecated: true` annotation**: JSON Schema 2020-12 defines a `deprecated` annotation keyword (§9.3). OpenAPI 3.1 applies `deprecated: true` to operation objects, parameter objects, and schema objects. Both are boolean annotations — they do not cause validation failure and are described as advisory: "Consumers SHOULD refrain from usage." Linters (e.g., Spectral) can be configured to issue warnings or errors for deprecated usage. Source: `raw.githubusercontent.com/OAI/OpenAPI-Specification/main/versions/3.1.0.md`.

- **Issue tracker enumerated resolution/state values**: (a) **GitHub Issues**: `state_reason` API field values are `completed`, `not_planned`, and `reopened` (confirmed via GitHub REST API). GitHub also uses `"Duplicate of #N"` in issue comments to create a cross-reference timeline event. The `wontfix` label is a conventional (non-automated) signal. (b) **Jira**: Default resolution types include `Won't Fix`, `Duplicate`, `Obsolete`, `Won't Do`, `Tracked Elsewhere`, `Invalid`, `Low Engagement`; confirmed from `jira.atlassian.com/rest/api/2/resolution`. (c) **Azure DevOps**: Defines a `Removed` state category that hides work items from all backlog and board experiences while preserving them; confirmed from `learn.microsoft.com`. Source: `api.github.com`; `jira.atlassian.com/rest/api/2/resolution`; Azure DevOps docs.

- **Documentation toolchain deprecated directives**: Sphinx/RST defines `.. deprecated:: version [brief explanation]` (renamed to `.. version-deprecated::` in version 9.0) which renders as a styled warning box noting the version and appears in a "Deprecated since version X" index. Docusaurus uses `banner: "unmaintained"` in `versions.json` to display a persistent banner across all pages of that doc version; archived versions can be published as immutable external URLs. Hugo provides `draft: bool` and `expiryDate: string` frontmatter — the latter causes the page to be entirely excluded from builds after the expiry date (content removal, not archival). Source: `sphinx-doc.org`; `docusaurus.io/docs/versioning`.

- **DITA `<draft-comment>` with `@disposition` attribute**: DITA 1.3 defines `<draft-comment>` with a `@disposition` attribute accepting values: `issue`, `open`, `accepted`, `rejected`, `deferred`, `duplicate`, `reopened`, `unassigned`, `completed`. Processors SHOULD strip draft comments from non-draft output. This is the most semantically rich inline lifecycle encoding found — it distinguishes reason categories. Source: `docs.oasis-open.org/dita/dita/v1.3/os/part2-tech-content/langRef/base/draft-comment.html`.

- **todo.txt plain-text format**: Marks completed items with a leading `x ` (lowercase x followed by space). No dedicated superseded/absorbed encoding — only completion. Source: `raw.githubusercontent.com/todotxt/todo.txt/master/README.md`.

**Surprises:**
- GitHub Issues has no built-in "superseded by" or "absorbed into" relationship — only `"Duplicate of #N"` comment convention and the `wontfix` label. The `state_reason: "not_planned"` is the closest machine-readable signal for intent-not-to-implement, but it conflates several distinct causes (scope change, deprioritization, external absorption).
- `adr-tools` manipulates the ADR Markdown files using plain `awk` text manipulation — it removes the literal string `Accepted` from the `## Status` section and inserts link text. There is no schema or structured field; parsing requires understanding the freeform convention.
- The HTML `<del>` element predates GFM strikethrough by decades and carries richer semantics (`datetime`, `cite`), but Markdown `~~text~~` discards both attributes entirely — the visual result is identical but the machine-readable provenance is lost.
- JSON Schema `deprecated: true` is defined as a pure annotation keyword — schema validators collect and report it but it never causes a validation assertion to fail. This means automated document processors cannot use it for gating purposes without external linter configuration.

**Caveats:**
- Jira Cloud REST API at `jira.atlassian.com/rest/api/2/resolution` reflects that instance's configuration; actual Jira Cloud instances can have custom resolution types beyond the default set.
- GitHub `state_reason` field was introduced in late 2022; older issues and tools that predate that feature may not populate or consume it.
- The W3C supersedence process page was inaccessible during this research (returned empty body); W3C supersedence detail is absent from this report.
- The IETF "Historic" category applies to entire RFC documents, not sub-items within them; there is no sub-document scope supersession mechanism in the RFC format.
- Obsidian/Logseq/Roam frontmatter conventions for deprecated/superseded status are user-defined and not standardized; this research did not find an official schema.
- OpenAPI Spectral linter configuration for `deprecated: true` enforcement was not verified in detail.

## Full Findings

### 1. Standards and Proposal Document Header Fields

#### IETF RFC Format
RFC documents use structured header fields at the top of the document to encode supersession relationships. Per RFC 2026 §4.2.4:
- `Obsoletes: XXXX` — this document makes the listed RFC(s) obsolete
- `Updates: XXXX` — this document partially updates the listed RFC(s)
- `Obsoleted by: XXXX` — listed on the info page (not in the document text) once superseded
- `Historic` status — assigned to "a specification that has been superseded by a more recent specification or is for any other reason considered to be obsolete" (RFC 2026 §4.2.4, `rfc-editor.org/rfc/rfc2026.txt`)

Example: RFC 7231 header reads `Obsoletes: 2616` and is itself marked `Obsoleted by RFC 9110` on the RFC Editor info page. These fields are parsed by the RFC Editor's toolchain to cross-link entries in the RFC index.

#### Python PEP Format
PEPs use RFC 2822-style header preambles in RST format. The PEP 1 specification (`raw.githubusercontent.com/python/peps/main/peps/pep-0001.rst`) defines:
- `Status: Superseded` — one of the enumerated lifecycle states (Active, Accepted, Deferred, Draft, Final, Provisional, Rejected, Superseded, Withdrawn)
- `Superseded-By: NNN` — reference to the superseding PEP number
- `Replaces: NNN` — present in the new PEP, pointing back to the old one

From the PEP 1 spec: "PEPs may also have a Superseded-By header indicating that a PEP has been rendered obsolete by a later document... The newer PEP must have a Replaces header containing the number of the PEP that it rendered obsolete."

Example (PEP 5, `raw.githubusercontent.com/python/peps/main/peps/pep-0005.rst`):
```
PEP: 5
Title: Guidelines for Language Evolution
Status: Superseded
Superseded-By: 387
```

The PEP JSON API (`peps.python.org/api/peps.json`) exposes `status`, `superseded_by`, and `replaces` as machine-readable fields. As of the research date, confirmed superseded PEPs include PEP 5, 102, 215, 241.

**Interaction with downstream tools**: The PEP index page (`peps.python.org/pep-0000/`) groups superseded PEPs under a "Rejected, Superseded, and Withdrawn PEPs" section. The JSON API enables programmatic queries. The RST renderer (used to build `peps.python.org`) renders the preamble fields as a definition list in the published HTML.

### 2. Architecture Decision Records (ADRs)

#### Michael Nygard Template
The original ADR template (`github.com/joelparkerhenderson/architecture-decision-record`) defines a free-text `## Status` section accepting values including `proposed`, `accepted`, `rejected`, `deprecated`, `superseded`. The section is pure prose — no schema enforcement.

#### MADR Template (Markdown Architectural Decision Records)
MADR (`github.com/adr/madr`) encodes status in YAML frontmatter:
```yaml
status: "{proposed | rejected | accepted | deprecated | … | superseded by ADR-0123}"
```
Source: `raw.githubusercontent.com/adr/madr/main/template/adr-template.md`

#### adr-tools CLI Automation
The `adr-tools` CLI (`github.com/npryce/adr-tools`) provides `adr new -s N` to create a superseding ADR. The tool modifies files using `awk` scripts:

- `_adr_remove_status`: Removes the literal string `Accepted` from the `## Status` section of the superseded ADR.
- `_adr_add_link`: Inserts a Markdown link after the `## Status` heading: `Superceded by [Title](file.md)` in the old ADR, and `Supercedes [Title](file.md)` in the new ADR.

This is entirely text-based manipulation — no schema, no frontmatter field. The pattern results in prose like:
```markdown
## Status

Superceded by [Use PostgreSQL Database](0025-use-postgresql.md)
```

**Interaction with downstream tools**: Because there is no machine-readable field, downstream tools that wish to parse supersession relationships must pattern-match the prose. Some ADR management tools (e.g., `adr-manager`) do this via regex against the `## Status` section content.

### 3. Inline Visual-Deletion Markup

#### GFM Strikethrough (`~~text~~` → `<del>`)
GitHub Flavored Markdown Spec §6.5 (`github.github.com/gfm/#strikethrough-extension-`) defines the strikethrough extension: text wrapped in `~~` renders as `<del>text</del>` in HTML output. This is a GFM extension not present in base CommonMark — parsers without the extension (or with it disabled) pass through `~~text~~` as literal characters.

Usage for scope items: a common convention is to mark superseded checklist items as `- [x] ~~old item~~` or just `~~old item~~` in planning docs.

#### Pandoc `strikeout` Extension
Pandoc implements `~~text~~` as the `strikeout` extension (enabled by default for Markdown). Output mapping:
- HTML: `<del>text</del>`
- LaTeX: `\sout{text}` (requires `\usepackage{soul}`)
- DOCX: strikethrough character formatting
- Plain text/CommonMark without `raw_html`: falls back to plain text (strikethrough lost)

Source: `pandoc.org/MANUAL.html` (§ Extension: strikeout).

#### HTML `<del>` and `<ins>` Elements
The HTML Living Standard (§4.7, `html.spec.whatwg.org/multipage/edits.html`) defines:
- `<del>`: "represents a range of text that has been deleted from a document"
- `<ins>`: counterpart for added text
- Both accept optional `datetime` (ISO 8601 timestamp) and `cite` (URL to source of change) attributes

The `datetime` and `cite` attributes allow machine-readable provenance. However, GFM `~~strikethrough~~` and Pandoc `strikeout` do not support these attributes — the rendered `<del>` element has neither `datetime` nor `cite`.

#### OOXML Track Changes (`w:del`)
In Word/DOCX format, deleted content is wrapped in `w:del` elements containing `w:delText` children, with `w:author` and `w:date` attributes on the `w:del` element. Pandoc with `--track-changes=all` converts this to `<span class="deletion">` with inline metadata. This is a fundamentally different encoding than Markdown strikethrough — it preserves author identity and timestamp.

### 4. Issue Tracker Resolution and State Patterns

#### GitHub Issues
GitHub encodes superseded/out-of-scope decisions through multiple mechanisms:

1. **`state_reason` API field** (added late 2022): When an issue is closed, `state_reason` is set to one of:
   - `completed` — work done
   - `not_planned` — will not be implemented (covers scope decisions, absorption, won't-fix)
   - `reopened` — transitional state
   Confirmed by `api.github.com` responses and GitHub REST API docs.

2. **`"Duplicate of #N"` comment convention**: Typing `"Duplicate of"` followed by an issue/PR number in a comment body creates a "marked as duplicate" timeline event (requires write access). Source: GitHub Docs, marking duplicates page.

3. **`wontfix` label**: A purely conventional label with no automated behavior — used by humans and some bots for filtering/reporting.

4. **GitHub Projects archiving**: Items in GitHub Projects can be archived (removed from view in board/table while preserved in archive). This is a Projects-level action distinct from closing the issue.

5. **Closing keywords in PR descriptions**: `Closes #N`, `Fixes #N`, `Resolves #N` (and variants) in PRs close the linked issue on merge with `state_reason: completed`. There is no built-in "Supersedes #N" or "Absorbed into #N" keyword.

#### Jira Issue Resolutions
From `jira.atlassian.com/rest/api/2/resolution` (public Atlassian Jira instance), the default resolution types include:
- `Fixed` — issue resolved
- `Won't Fix` — problem will never be fixed
- `Duplicate` — duplicate of an existing issue
- `Incomplete` — not completely described
- `Cannot Reproduce` — reproduction failed
- `Invalid` — invalid issue
- `Obsolete` — "Issue was valid at some stage, but has become redundant due to other developments"
- `Won't Do` — issue won't be actioned
- `Tracked Elsewhere` — tracked on another Jira instance or third-party system
- `Low Engagement` — limited demand

The resolution is set as a required field when transitioning to the `Done` or `Closed` workflow state. Resolutions are searchable via JQL.

#### Azure DevOps Work Item States
Azure DevOps defines a `Removed` state category (`learn.microsoft.com`): "Assign this category to the Removed state to hide items from backlog and board experiences." When a work item is set to the `Removed` state:
- It disappears from backlog views
- It disappears from board columns
- It is preserved in the database and can be queried/restored
- Applies to Epic, Feature, User Story work item types in Agile process

This is a soft-delete/archive pattern at the state-category level, distinct from permanently deleting the item.

### 5. Documentation Toolchain Deprecated Directives

#### Sphinx (reStructuredText)
Sphinx defines versioned deprecation directives (`sphinx-doc.org/en/master/usage/restructuredtext/directives.html`):
- `.. deprecated:: version` (renamed to `.. version-deprecated::` in Sphinx 9.0): Renders as a styled callout box "Deprecated since version X." and adds entries to a deprecation index.
- `.. version-removed:: version`: For items slated for removal.

**Interaction with downstream tools**: Sphinx generates a "Deprecated since version X" notice inline in the rendered HTML and can generate a separate deprecation index page. The version metadata is machine-readable in Sphinx's doctree/pickle format, enabling downstream extensions to aggregate all deprecated items.

#### Docusaurus Versioning
Docusaurus (`docusaurus.io/docs/versioning`) uses `versions.json` to configure doc version banners:
- `banner: "none"` — no banner
- `banner: "unreleased"` — shows "unreleased version" banner
- `banner: "unmaintained"` — shows "unmaintained version" banner across all pages

Archived versions can be published as external static URLs (immutable) while being removed from the active build, keeping build times low. The `versions.json` file is the structured encoding; downstream rendering reads this to inject banners automatically.

#### Hugo Frontmatter
Hugo (`gohugo.io/content-management/front-matter/`) provides:
- `draft: bool` — page excluded from build unless `--buildDrafts` passed
- `expiryDate: string` — page excluded from build on/after this date unless `--buildExpired` passed

`expiryDate` is a hard removal from the output site — there is no "superseded by" cross-reference mechanism. The scope item simply stops appearing.

### 6. Schema and API `deprecated` Annotations

#### JSON Schema 2020-12
JSON Schema 2020-12 defines `deprecated` as an annotation keyword (§9.3). It is a pure annotation: validators collect and surface it but it does not affect validation outcomes. A `true` value signals that the annotated instance value should be transitioned away from.

#### OpenAPI 3.1
OpenAPI 3.1 (`raw.githubusercontent.com/OAI/OpenAPI-Specification/main/versions/3.1.0.md`) applies `deprecated: true` to:
- Operation objects: "Declares this operation to be deprecated. Consumers SHOULD refrain from usage."
- Parameter objects: "Specifies that a parameter is deprecated and SHOULD be transitioned out of usage."
- Schema objects: same semantics.

**Interaction with downstream tools**: OpenAPI linters such as Spectral can be configured to issue `warn` or `error` severity on use of deprecated operations/parameters. API documentation generators (Redoc, Swagger UI) render deprecated endpoints with a visual strikethrough or badge. The `example` property in OpenAPI 3.1 is itself marked deprecated in favor of the JSON Schema `examples` keyword.

#### TypeScript / JSDoc `@deprecated`
TypeScript and JSDoc support `/** @deprecated [message] */` annotations. Effects:
- IDEs (VS Code, IntelliJ) show strikethrough in autocomplete and display the deprecation message on hover
- TypeScript compiler does not by default fail on usage of `@deprecated` symbols, but `@typescript-eslint/no-deprecated` rule can be configured to error/warn
- No runtime effect

### 7. Keep a Changelog and SemVer Two-Stage Pattern

Keep a Changelog 1.1.0 (`keepachangelog.com/en/1.1.0/`) defines a two-stage encoding for scope items being phased out:

1. **`### Deprecated` section** — "for soon-to-be removed features" — the item is still present but announced for removal
2. **`### Removed` section** — "for now removed features" — the item is gone

SemVer (`semver.org/`) specifies the version semantics: a MINOR version bump is required when features are marked deprecated; a MAJOR version bump is required when deprecated features are actually removed. This creates a mandatory two-version window for consumers to adapt.

**Interaction with downstream tools**: Changelog parsers (e.g., `cliff`, `towncrier`, `auto-changelog`) can extract and categorize these sections. The Vandamme Ruby gem was designed specifically to parse Keep-a-Changelog-style changelogs programmatically, though it handles the format with varying reliability across changelog variants.

### 8. DITA `<draft-comment>` with `@disposition`

DITA 1.3 (`docs.oasis-open.org/dita/...`) defines `<draft-comment>` with a `@disposition` attribute for lifecycle state of the comment/item:
- Values: `issue`, `open`, `accepted`, `rejected`, `deferred`, `duplicate`, `reopened`, `unassigned`, `completed`
- `@author` and `@time` attributes provide provenance

**Interaction with downstream tools**: DITA processors SHOULD strip `<draft-comment>` elements from non-draft output by default (they are hidden in production builds). The disposition values map to issue-tracker concepts but within the document structure itself.

### 9. todo.txt Plain-Text Format

The todo.txt format (`raw.githubusercontent.com/todotxt/todo.txt/master/README.md`) marks completed tasks with a leading `x ` (lowercase x followed by space):
```
x 2011-03-03 Call Mom
```

There is no dedicated encoding for "absorbed into another item", "superseded by", or "won't do" — only completion. Applications built on todo.txt (e.g., `todo.txt-cli`) typically filter completed items to a `done.txt` archive file.

### Cross-Cutting Interaction Observations

| Pattern | Machine-readable? | Bidirectional cross-reference? | Downstream tool automation | Visibility preservation |
|---|---|---|---|---|
| RFC `Obsoletes:` header | Yes | Yes (via `Obsoleted by` on info page) | RFC Editor index cross-links | Preserved as Historic |
| PEP `Superseded-By:` + `Replaces:` | Yes | Yes (in both doc headers) | PEP index grouping, JSON API | Preserved, grouped separately |
| ADR `## Status` free text + adr-tools | No (prose) | Yes (linked prose) | Regex-based parsers only | Preserved, linked |
| MADR `status:` frontmatter | Semi (freeform string) | Only by convention in text | YAML parsers can extract | Preserved |
| `~~strikethrough~~` GFM | No | No | Visual only; `<del>` in HTML | Content visible in rendered HTML |
| HTML `<del datetime cite>` | Yes (with attributes) | Via `cite` URL | Semantic web, diff tools | Visible with strikethrough |
| Jira `Obsolete`/`Won't Do` resolution | Yes | No (unidirectional only) | JQL queries, dashboard filters | Issue remains searchable |
| GitHub `state_reason: not_planned` | Yes | No | Projects board filtering | Issue preserved, filterable |
| GitHub `"Duplicate of #N"` comment | Semi (text pattern) | No | Timeline event only | Both issues preserved |
| Azure DevOps `Removed` state | Yes | No | Hidden from backlog/board widgets | Preserved in DB |
| JSON Schema / OpenAPI `deprecated: true` | Yes | No | Linter warnings, UI badges | Endpoint/field remains in schema |
| Sphinx `.. deprecated::` | Yes (version) | No | Deprecation index, callout | Docs preserved with notice |
| Docusaurus `banner: "unmaintained"` | Yes | No | Banner on all pages of version | All pages preserved |
| Hugo `expiryDate` | Yes | No | Page excluded from build | **Not preserved in build output** |
| Keep a Changelog `### Deprecated` → `### Removed` | Yes (section) | No | Changelog parsers (Vandamme, cliff) | Removed items logged in CHANGELOG |
| DITA `<draft-comment @disposition>` | Yes | No | Stripped from non-draft output | Stripped from production |
| todo.txt `x ` prefix | Yes | No | Moved to done.txt | Preserved in archive file |
