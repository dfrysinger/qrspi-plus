# Resolver acceptance fixture — legacy ${CLAUDE_SKILL_DIR} rejection.
#
# This fixture deliberately embeds the legacy `${CLAUDE_SKILL_DIR}` token
# in a shipped `.md` body. Running the build pipeline against this fixture
# MUST fail non-zero with a `<file>:<line>: ${CLAUDE_SKILL_DIR} occurrence
# in shipped file` diagnostic on stderr — proving that the v0.7.2 cleanup
# of legacy `!`cat ${CLAUDE_SKILL_DIR}/...`` directives is enforced at
# build time and cannot regress silently.
#
# Mirrors task-39 §"Definition of done" bullet on `${CLAUDE_SKILL_DIR}`
# rejection and §"Test expectations" "Acceptance fixtures cover a legacy
# ${CLAUDE_SKILL_DIR} directive failure".
The forbidden token follows on the next line:
embedded ${CLAUDE_SKILL_DIR}/some/path/in/body.md
