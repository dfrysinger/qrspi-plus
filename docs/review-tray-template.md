<!--
  REVIEW TRAY TEMPLATE

  Each agent maintains ONE sticky comment on its draft PR using this layout.
  Edit the same comment after every push (don't post new ones).

  Replace placeholders before posting:
    {ISSUE_NUMBER}   — the issue this PR fixes
    {PR_NUMBER}      — this PR's number
    {BRANCH_NAME}    — your branch (e.g. df-agent-alpha/issue-42-foo)
    {SLUG}           — the QRSPI artifact slug (e.g. issue-42-foo)

  Why a single sticky comment?
  - Phone-friendly: one bookmark, taps go straight to rendered Markdown
    + Mermaid.
  - Avoids notification spam.
  - Sibling agents and the human can see all artifact status at a glance.
-->

## 📋 Review Tray — issue #{ISSUE_NUMBER} / PR #{PR_NUMBER}

Branch: `{BRANCH_NAME}`
Last updated: <!-- yyyy-mm-dd hh:mm UTC -->

### 🟡 Ready for review
<!-- Tap a link below to read the rendered file (Mermaid included) on phone. -->
- [goals.md](https://github.com/dfrysinger/qrspi-plus/blob/{BRANCH_NAME}/docs/qrspi/{SLUG}/goals.md) — updated <!-- hh:mm -->

### ⚪ In progress (not ready yet)
- _(list artifacts being written)_

### ✅ Approved
- _(none yet)_

---

**How to use:**
1. After each push, edit *this* comment to move files between the three
   sections (🟡 / ⚪ / ✅) and refresh the timestamps.
2. When a file is newly ready, also post a separate short comment
   `@dfrysinger ready for {file}` so the notification reaches the
   reviewer.
3. When the reviewer signals approval (e.g. `approved goals.md`), move
   that file to the ✅ section.
