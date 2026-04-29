---
name: malformed-empty-body
description: Synthetic SKILL.md fixture with both subsections present but bodies empty (no enumerated bullets/numbered items). Prose-only bodies do NOT satisfy the contract. Used to test the scope-reviewer rules-loading fail-closed case 4.
---

# Malformed SKILL — Empty Bodies

## Overview

This skill fixture has both H3 subsections present but their bodies contain no enumerated items — only prose paragraphs. The scope-reviewer must fail closed because prose-only bodies do not satisfy the rules-loading contract.

## Malformed OWNS / Malformed DEFERS

### Malformed OWNS

This subsection contains prose only — no bulleted or numbered enumerated rule items. The scope-reviewer's rules-loading procedure treats this as semantically empty.

### Malformed DEFERS

This subsection also contains prose only — no enumerated rule items. Running the checks would produce vacuous results, so the reviewer must fail closed.

## Process

Unrelated content.
