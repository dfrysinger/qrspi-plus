---
status: draft
question_ids: [14, 20]
research_type: web
---

# Q14 + Q20: Style-guide prescriptions (IDs + comments)

## Summary

**TL;DR:** Mainstream style guides converge on one rule for issue IDs in source: they belong in TODO comments, commit footers, and PR descriptions, with the canonical Google form being `TODO: crbug.com/12345 - explanation`; embedding tracker IDs in identifiers, runtime-consumed string literals, or test names is not endorsed by any major guide and is treated as a smell ("magic string", "stringly typed"). For comments, every major source (McConnell, Martin, Kernighan/Pike, Linux kernel, PEP 8, Go) prescribes the same direction: explain why/intent, not what; remove redundant or out-of-date comments; prefer rewriting unclear code over commenting it.

**Key findings:**
- Google's Python and Java style guides explicitly mandate `TODO: <link> - explanation`, deprecating the older `TODO(crbug/123): ...` form, and explicitly forbid TODOs that "refer to an individual or team as the context."
- Conventional Commits places issue references in footers (`Refs: #123`, `Fixes: #123`) one blank line after the body, not in the subject line; only `BREAKING CHANGE` is an officially defined token.
- GitHub recognizes `fix/fixes/fixed/close/closes/closed/resolve/resolves/resolved #N` keywords in commit and PR bodies as auto-close triggers (a platform behavior, not a style mandate).
- McConnell categorizes comments into six kinds: repeat, explanation, marker (TODO/XXX/HACK), summary, intent, and information not expressible in code; the first two are bad, the last three are good, and markers are the conventional location for tracker IDs.
- Martin's Clean Code Chapter 4 enumerates ~8 good-comment categories (legal, informative, intent, clarification, warning of consequences, TODO, amplification, public-API Javadocs) and ~10+ bad categories (mumbling, redundant, misleading, mandated, journal, noise, scary noise, position markers, closing-brace, attributions/bylines, commented-out code, HTML, nonlocal info, too much info, inobvious connection, function headers).
- Kernighan & Pike compress the rules to: don't belabor the obvious, don't comment bad code (rewrite it), don't contradict the code, comment functions and global data, clarify don't confuse.
- Linux kernel coding style (Ch. 8): "NEVER try to explain HOW your code works in a comment: it's much better to write the code so that the working is obvious"; comment what/why, not how; kernel-doc `/**` for API surfaces.
- Branch names commonly embed tracker IDs (`feature/JIRA-456-...`); PR descriptions universally allow/encourage them; runtime string literals containing tracker IDs are a recognized "magic string" / "stringly typed" smell and never prescribed.

**Surprises:** Google has actively migrated *away* from the historical `TODO(username):` and `TODO(crbug/123):` parenthesized form to a colon-then-link form. Many third-party style guides still cite the old form.

**Caveats:** Code Complete and Clean Code are paywalled books; chapter content was confirmed via O'Reilly chapter index pages and multiple independent summaries that cross-corroborate. No mainstream style guide was found that explicitly addresses tracker IDs in test names or in user-facing string literals — this is "silence" rather than affirmative permission.

## Full findings

### Q14: Issue-tracker / internal-ID prescriptions

#### Code identifiers

No mainstream style guide reviewed prescribes embedding issue/ticket IDs in identifiers (variable, function, class, file names). Closest related guidance is general naming-convention advice (Google, PEP 8, Go) emphasizing semantic descriptive names. The "magic string / magic number" anti-pattern literature (e.g., SonarSource, JetBrains) treats embedded literal IDs as a smell when used in code rather than configuration.

> "In software development, a 'Magic String' is a sequence of characters enclosed in double or single quotes that is used directly in code to represent a value... The main problem with hardcoded strings throughout the codebase is making it difficult to update or change the string values consistently."
— https://zeeshan01.medium.com/problem-with-the-magic-string-1abbf7712414 (paraphrasing common Sonar/JetBrains rules)

> SonarSource Java rule S1075: "URIs should not be hardcoded... a URI should never be hardcoded and should instead be replaced by a customizable parameter."
— https://rules.sonarsource.com/java/rspec-1075/

Status: **no guide endorses; tooling-level consensus treats as smell.**

#### String literals at runtime

No mainstream style guide reviewed prescribes embedding tracker IDs in runtime-consumed string literals (log messages, user-facing strings, etc.). The "stringly typed" / "magic string" anti-pattern literature applies. Internationalization (i18n) guides (e.g., Google developer documentation style guide) treat user-facing strings as translatable assets, which structurally discourages embedded internal references.

Status: **silence (none endorse); generally treated as a smell when used as a logic value.**

#### Comments

This is the canonical home for tracker IDs. Most prescriptive sources are TODO-comment standards.

**Google Python Style Guide** (https://google.github.io/styleguide/pyguide.html, §3.12 TODO Comments):
> "A TODO comment begins with the word TODO in all caps, a following colon, and a link to a resource that contains the context, ideally a bug reference."
> Recommended: `# TODO: crbug.com/192795 - Investigate cpufreq optimizations.`
> Discouraged (legacy): `# TODO(crbug.com/192795): Investigate cpufreq optimizations.`
> "Avoid adding TODOs that refer to an individual or team as the context."

**Google Java Style Guide** (https://google.github.io/styleguide/javaguide.html):
> "A TODO comment begins with the word TODO in all caps, a following colon, and a link to a resource that contains the context, ideally a bug reference."
> Example: `// TODO: crbug.com/12345678 - Remove this after the 2047q4 compatibility window expires.`
> "Avoid adding TODOs that refer to an individual or team as the context."

**Chromium C++/Java/Python style guides** (https://chromium.googlesource.com/chromium/src/+/HEAD/styleguide/c++/c++.md, .../java/java.md, .../python/): bug references in parentheses or modern colon-link form, both seen in the wild; modern Chromium docs match Google's colon-link form, e.g., `// TODO(crbug.com/40192027):` (Java guide) and `TODO(b/123456789):` for internal Buganizer.
— https://chromium.googlesource.com/chromium/src/+/HEAD/styleguide/java/java.md
— https://www.chromium.org/chromium-os/developer-library/reference/style-guides/python/

**Linux kernel coding style** (https://docs.kernel.org/process/coding-style.html): no explicit guidance on tracker IDs in comments. The kernel project largely uses Lore mailing-list message-IDs and `Fixes: <abbrev-sha> ("subject")` trailers in commit messages rather than tracker URLs in comments.

**PEP 8** (https://peps.python.org/pep-0008/): no guidance on TODO format or tracker references; only generic block/inline comment formatting.

Status: **conventionally allowed (and prescribed by Google/Chromium); format is contested between `TODO:` colon-link and `TODO(...)` parenthesized forms.**

#### Test names

No mainstream style guide reviewed (Google, Microsoft, Linux, Go, Rust, PEP 8) prescribes embedding issue/ticket IDs in test names. Industry practice (Atlassian/Jira ecosystem articles) discusses traceability between test cases and Jira issues but operates at the test-case-management layer (Xray, Zephyr), not at the source-code test-name level.

> "Traceability refers to tracing the test case from start to go-live... you can establish clear traceability between test cases, test runs, test plans and issues within JIRA."
— https://www.adaptavist.com/blog/five-best-practices-for-managing-test-cases-in-jira

Status: **silence in mainstream style guides; tracker-IDs-in-test-names is neither forbidden nor prescribed.**

#### Commit messages

**Conventional Commits v1.0.0** (https://www.conventionalcommits.org/en/v1.0.0/):
> "One or more footers MAY be provided one blank line after the body. Each footer MUST consist of a word token, followed by either a `:<space>` or `<space>#` separator, followed by a string value."
> "A footer's token MUST use `-` in place of whitespace characters, e.g., `Acked-by` (this helps differentiate the footer section from a multi-paragraph body)."
Specification example:
```
fix: prevent racing of requests
...
Reviewed-by: Z
Refs: #123
```
Only `BREAKING CHANGE` is an officially defined token. `Fixes:`, `Closes:`, `Refs:` are conventional but not specified.

**GitHub auto-close keywords** (https://github.blog/news-insights/product-news/closing-issues-via-commit-messages/): `fix/fixes/fixed/close/closes/closed/resolve/resolves/resolved #N` (case-insensitive) in commit message body or PR body trigger auto-close on merge to default branch. This is platform behavior, not a style prescription.

**Linux kernel** (Documentation/process/submitting-patches.rst, observable convention): uses `Fixes: <12-char-sha> ("subject line")` trailer to point at the offending commit, and `Link:` trailers to lore.kernel.org messages or bug trackers. Tracker-ID-in-subject-line is not the convention.

**tpope's "A Note About Git Commit Messages"** (canonical seven rules — https://cbea.ms/git-commit/) and Linus Torvalds' commit-message guidance: subject line ≤ 50 chars in imperative mood; references and metadata in trailers/body, not subject.

Status: **issue references universally allowed in footers/trailers; placement in subject lines (e.g., `[JIRA-123] add X`) is contested — common in Jira-integrated shops, discouraged by Conventional Commits and tpope-style guides.**

#### PR descriptions

GitHub, GitLab, Atlassian, and most engineering culture sources treat PR descriptions as the proper home for cross-references: `Closes #123`, `Fixes JIRA-456`, etc.
> "The footer should contain any information about breaking changes and is also the place to reference GitHub issues that the commit closes. Add 'Fixes #123' or 'Closes #456' in the footer, and GitHub will automatically close the issue when the commit merges."
— https://github.blog/news-insights/product-news/closing-issues-via-commit-messages/

Branch names commonly embed tracker IDs (e.g., `feature/JIRA-456-add-dark-mode`):
> "It's common to include the ticket number from a project management tool like Jira in the branch name, which makes it easy to track the work done on a specific ticket."
— https://medium.com/@regondaakhil/best-practices-for-git-branch-naming-conventions-and-pr-creation-on-github-14a451d345dc
— https://namingconvention.org/git/branch-naming

Status: **universally allowed and conventionally encouraged.**

#### Cross-source consensus / divergence

| Surface | Universally forbidden | Conventionally allowed | Contested |
|---|---|---|---|
| Code identifiers | (none explicit) — but treated as "magic string" smell by Sonar/JetBrains | — | embedding tracker IDs at all |
| Runtime string literals | (none explicit) — flagged as "stringly typed" smell | — | embedding tracker IDs |
| Comments (TODO) | name-only TODOs without bug link (Google) | `TODO: <bug-link> - explanation` (Google modern), `TODO(crbug/...)` (legacy/Chromium) | colon-link vs. parenthesized form |
| Test names | (silence) | (silence) | embedding IDs |
| Commit subject | per Conventional Commits / tpope: metadata in trailers, not subject | `Fixes:` / `Refs:` / `Closes:` trailers in footer | `[JIRA-123] subject` prefix style |
| Commit body/footer | — | issue refs in footer trailers (Conv. Commits §; GitHub auto-close keywords) | exact token (`Fixes` vs `Closes` vs `Resolves` vs `Refs`) |
| PR descriptions | (none) | issue refs anywhere; auto-close keywords in body | — |
| Branch names | (none) | `type/TICKET-NN-slug` patterns | slash vs hyphen separator |

### Q20: Comment-purpose guidance

#### Per-source taxonomy of comment categories

**Steve McConnell, *Code Complete, 2nd ed.*, Ch. 32.5 "Commenting Techniques"**
URL: https://www.oreilly.com/library/view/code-complete-2nd/0735619670/ch32s05.html
Six "kinds of comments":
1. **Repeat of the code** — bad; just restates what code says.
2. **Explanation of the code** — bad; signal that the code is too complex; rewrite instead.
3. **Marker in the code** — acceptable transient: `// TODO`, `// HACK`, `// XXX`, etc.
4. **Summary of the code** — good; one or two lines distilling several lines.
5. **Description of the code's intent** — good; explains the *why*/problem-domain purpose, not the how.
6. **Information that cannot possibly be expressed by the code itself** — good; copyright, references to external algorithms or specifications, optimization notes, design rationale.
McConnell's general principle: "in good code, the need to comment individual lines of code is rare"; "Your code should say HOW it works; your comments should say WHY."
— https://www.oreilly.com/library/view/code-complete-2nd/0735619670/ch32.html

**Robert C. Martin, *Clean Code*, Ch. 4 "Comments"**
URL (book index): https://www.amazon.com/Clean-Code-Handbook-Software-Craftsmanship/dp/0132350882
Summary: https://gist.github.com/wojteklu/73c6914cc446146b8b533c0988cf8d29
Opening thesis: "Don't comment bad code—rewrite it" (citing Kernighan & Plaugher); "the proper use of comments is to compensate for our failure to express ourselves in code."

*Good comments:*
- Legal comments (copyright/authorship headers)
- Informative comments (e.g., explaining a regex pattern)
- Explanation of intent (why a decision was made)
- Clarification (translating obscure args/return values)
- Warning of consequences (e.g., "// SimpleDateFormat is not thread safe")
- TODO comments (work the programmer thinks should be done)
- Amplification (highlighting importance of an otherwise-overlookable detail)
- Javadocs in public APIs

*Bad comments:*
- Mumbling (vague comments only the author understands)
- Redundant comments (repeat what the code clearly states)
- Misleading comments (subtly inaccurate)
- Mandated comments (every-function-must-have-Javadoc rules that produce noise)
- Journal comments (changelog at top of file — "we have source control for this")
- Noise comments (e.g., `// Default constructor.`)
- Scary noise (Javadoc that says nothing useful)
- Don't use a comment when you can use a function or variable
- Position markers (`// Actions //////////////`)
- Closing brace comments
- Attributions and bylines (`/* Added by Rick */`)
- Commented-out code
- HTML comments
- Nonlocal information (commenting a function with system-wide info)
- Too much information
- Inobvious connection (comment whose subject isn't clear from context)
- Function headers (when the function is small and well-named)

Cited good example: a comment explaining a regex; cited bad examples include redundant getter/setter comments and journal/changelog comments at file top.

**Brian Kernighan & Rob Pike, *The Practice of Programming*, Ch. 1.6 "Comments"**
URL: https://www.amazon.com/Practice-Programming-Addison-Wesley-Professional-Computing/dp/020161586X
PDF (academic): https://kremlin.cc/rob.pdf
Five rules:
1. **Don't belabor the obvious** — comments restating self-evident code are clutter; delete them.
2. **Comment functions and global data** — function headers and global declarations need explanatory comments.
3. **Don't comment bad code—rewrite it** — when the comment outweighs the code, the code probably needs fixing.
4. **Don't contradict the code** — keep comments in sync; bad comments are worse than no comments.
5. **Clarify, don't confuse** — comments must add information not immediately evident from the code.

**Linux kernel coding style, Ch. 8 "Commenting"**
URL: https://docs.kernel.org/process/coding-style.html
> "Comments are good, but there is also a danger of over-commenting. NEVER try to explain HOW your code works in a comment: it's much better to write the code so that the working is obvious, and it's a waste of time to explain badly written code."
> "Generally, you want your comments to tell WHAT your code does, not HOW."
> "When commenting the kernel API functions, please use the kernel-doc format."
Categories implicit: function-header (kernel-doc `/**`), file-header license/SPDX, in-line "what/why" only.

Multi-line format prescribed verbatim:
```
/*
 * This is the preferred style for multi-line
 * comments in the Linux kernel source code.
 * Please use it consistently.
 */
```

**PEP 8** (https://peps.python.org/pep-0008/)
Categories:
- **Block comments** — `# ` prefix, indented to the code level; paragraphs separated by `#`.
- **Inline comments** — same line as statement, ≥2 spaces from code, sparing use; explicitly mark "inline comments are unnecessary and in fact distracting if they state the obvious."
- **Documentation strings** — defer to PEP 257; required for all public modules, classes, functions, methods.

Bad example (verbatim from PEP 8): `x = x + 1                 # Increment x`
Good example (verbatim): `x = x + 1                 # Compensate for border`
General rule: "Comments that contradict the code are worse than no comments."

**Go Code Review Comments** (https://go.dev/wiki/CodeReviewComments)
Categories:
- **Doc comments** — required on all top-level exported names and non-trivial unexported ones; full sentences; begin with the name of the thing described and end in a period.
  > Example: `// Request represents a request to run a command.`
- **Package comments** — adjacent to package clause, no blank line; start with capitalized first word.
- **Ordinary comments** — `//`-style for permanent comments; `/* */` only temporarily/test.

Effective Go (https://go.dev/doc/effective_go#commentary) splits comments into:
- Doc comments (consumed by godoc — for users of the package)
- Internal comments (notes/warnings for developers of the package)

**Rust API Guidelines / rustdoc** (https://rust-lang.github.io/api-guidelines/documentation.html, https://doc.rust-lang.org/rustdoc/how-to-write-documentation.html)
Categories:
- **Outer doc comments (`///`)** — on items.
- **Inner doc comments (`//!`)** — for crate/module-level docs only.
- **Standard sections** within doc comments: Examples, Panics, Errors, Safety. Each is mandated when applicable (errors must be in an Errors section; panics in a Panics section; unsafe invariants in a Safety section).
- First-line summary requirement; full-sentence form.
- "An example is often intended to show why someone would want to use the item" — examples-as-motivation.

**Microsoft / .NET XML doc comments** (https://learn.microsoft.com/en-us/dotnet/csharp/language-reference/language-specification/documentation-comments, https://learn.microsoft.com/en-us/dotnet/csharp/fundamentals/coding-style/coding-conventions)
Categories defined by tag taxonomy: `<summary>`, `<remarks>`, `<param>`, `<returns>`, `<exception>`, `<example>`, `<seealso>`, `<value>`, `<typeparam>`, `<inheritdoc>`. The compiler verifies tag/parameter consistency.
Internal coding guidelines (https://learn.microsoft.com/en-us/archive/blogs/brada/internal-coding-guidelines): "Comments should be used to describe intention, algorithmic overview, and/or logical flow."

#### Cross-source consensus

- **Why, not how**: McConnell, Martin, Kernighan/Pike, Linux kernel, and Microsoft all state explicitly that comments explain *intent/why*; code itself should make *how* obvious.
- **Don't repeat the code**: McConnell ("repeat" is bad), Martin ("redundant comments"), PEP 8 ("state the obvious"), Kernighan/Pike ("don't belabor the obvious") — verbatim or near-verbatim agreement.
- **Don't comment bad code; rewrite**: Kernighan/Plaugher (the original aphorism), Kernighan/Pike, Martin, Linux kernel all repeat this.
- **Out-of-date comments are worse than none**: PEP 8 verbatim; Kernighan/Pike ("don't contradict the code"); Martin ("misleading comments").
- **Doc comments on public surface**: Google (Java/Python), Go, Rust, Microsoft .NET all mandate doc-comments on exported/public API. Linux kernel mandates kernel-doc on API. PEP 8 defers to PEP 257 for the same effect.
- **Markers (TODO/FIXME/XXX/HACK) acceptable but should reference tickets**: McConnell (markers), Martin (TODO category), Google/Chromium (canonical TODO format), Linux kernel implicit.
- **Commented-out code: remove**: Martin explicit; Kernighan/Pike implicit; Linux kernel implicit. Universal.

## Sources

- Google Python Style Guide: https://google.github.io/styleguide/pyguide.html
- Google Java Style Guide: https://google.github.io/styleguide/javaguide.html
- Google C++ Style Guide: https://google.github.io/styleguide/cppguide.html
- Google Style Guides index: https://google.github.io/styleguide/
- Chromium C++ style guide: https://chromium.googlesource.com/chromium/src/+/HEAD/styleguide/c++/c++.md
- Chromium Java style guide: https://chromium.googlesource.com/chromium/src/+/HEAD/styleguide/java/java.md
- Chromium iOS / Objective-C style guide: https://chromium.googlesource.com/chromium/src/+/HEAD/docs/ios/style.md
- Chromium Python style guide: https://www.chromium.org/chromium-os/developer-library/reference/style-guides/python/
- Chromium C++ Modern Use (TODO with crbug refs): https://chromium.googlesource.com/chromium/src/+/HEAD/styleguide/c++/c++-features.md
- Conventional Commits v1.0.0: https://www.conventionalcommits.org/en/v1.0.0/
- GitHub closing issues via commit messages: https://github.blog/news-insights/product-news/closing-issues-via-commit-messages/
- tpope/cbea — A Note About Git Commit Messages: https://cbea.ms/git-commit/
- Linux kernel coding style: https://docs.kernel.org/process/coding-style.html
- Kernel-doc comments: https://docs.kernel.org/doc-guide/kernel-doc.html
- PEP 8 — Style Guide for Python Code: https://peps.python.org/pep-0008/
- PEP 257 — Docstring Conventions: https://peps.python.org/pep-0257/
- Go Code Review Comments: https://go.dev/wiki/CodeReviewComments
- Effective Go — Commentary: https://go.dev/doc/effective_go#commentary
- Rust API Guidelines — Documentation: https://rust-lang.github.io/api-guidelines/documentation.html
- Rust API Comment Conventions (RFC 0505): https://rust-lang.github.io/rfcs/0505-api-comment-conventions.html
- Rustdoc — How to write documentation: https://doc.rust-lang.org/rustdoc/how-to-write-documentation.html
- Microsoft .NET Coding Conventions: https://learn.microsoft.com/en-us/dotnet/csharp/fundamentals/coding-style/coding-conventions
- C# Documentation comments specification: https://learn.microsoft.com/en-us/dotnet/csharp/language-reference/language-specification/documentation-comments
- Microsoft Internal Coding Guidelines (Brad Abrams): https://learn.microsoft.com/en-us/archive/blogs/brada/internal-coding-guidelines
- Code Complete 2e, Ch. 32 (O'Reilly): https://www.oreilly.com/library/view/code-complete-2nd/0735619670/ch32.html
- Code Complete 2e, §32.5 Commenting Techniques: https://www.oreilly.com/library/view/code-complete-2nd/0735619670/ch32s05.html
- Clean Code (Robert C. Martin) book: https://www.amazon.com/Clean-Code-Handbook-Software-Craftsmanship/dp/0132350882
- Clean Code summary (Wojtek Lukaszuk gist, widely cited): https://gist.github.com/wojteklu/73c6914cc446146b8b533c0988cf8d29
- The Practice of Programming (Kernighan & Pike): https://www.amazon.com/Practice-Programming-Addison-Wesley-Professional-Computing/dp/020161586X
- The Practice of Programming (PDF, academic mirror): https://kremlin.cc/rob.pdf
- SonarSource Java rule S1075 (URIs not hardcoded): https://rules.sonarsource.com/java/rspec-1075/
- JetBrains hard-coded string literals inspection: https://www.jetbrains.com/help/idea/hard-coded-string-literals.html
- Magic String anti-pattern: https://zeeshan01.medium.com/problem-with-the-magic-string-1abbf7712414
- Git branch naming conventions (Naming Convention site): https://namingconvention.org/git/branch-naming
- Branch naming with Jira tickets: https://medium.com/@regondaakhil/best-practices-for-git-branch-naming-conventions-and-pr-creation-on-github-14a451d345dc
- RFC: Adding TODO(crbug.com/#####) to the Chromium style guide: https://groups.google.com/a/chromium.org/g/chromium-dev/c/whBCkcY8xtA
- Sourcery — Dissecting the Google Style Guide: https://www.sourcery.ai/blog/dissecting-the-google-style-guide
