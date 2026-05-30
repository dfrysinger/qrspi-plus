---
finding_id: R1-F01
severity: medium
change_type: scope
referenced_files: [docs/qrspi/2026-05-27-v071-hardening/structure.md:L83-L155]
artifact: structure
round: 1
reviewer: scope-claude
---

The three function-doc blocks inside `## Interfaces` cross from
boundary-shape (Structure OWNS) into algorithm description
("line-by-line logic" — Structure DEFERS to Plan / Implement).

Per `skills/structure/owns-defers.md`, Structure OWNS "Function/script
exports and parameter shapes. Public function signatures, exported
types, script entry points, CLI argument shapes — **what the unit
exposes at its boundary**." It DEFERS "Per-task LOC, full assertion
text, per-task commit ranges, **line-by-line logic** → Plan /
Implement." The boundary is "what it exposes," not "how it does it
internally."

Three places in the artifact describe the internal algorithm rather
than the boundary:

1. **`_control_char_check` (L145-L154).** "Strips all POSIX [:cntrl:]
   bytes (0x00--0x1F and 0x7F, including LF) using `LC_ALL=C tr -d
   '[:cntrl:]'`, then compares byte count via `LC_ALL=C wc -c`. A
   non-zero difference means at least one control byte was present."
   That names the specific commands and the comparison strategy —
   that is the C-body, not the C-header. The boundary is `$1 str`
   in, rc 0/1 out, with a one-line semantic ("returns 1 iff input
   contains a control byte"). The `tr` / `wc -c` choice is Plan's
   implementation decision.

2. **`detect_host` (L116-L122).** "Probes `COPILOT_CLI=1` first;
   falls through to `claude-code` default. Codex CLI as a host is
   out of scope for v0.7.1 and falls through to the `claude-code`
   branch." Probe order and fallthrough order are control-flow
   logic. The boundary is "outputs one of `copilot-cli` /
   `claude-code` on stdout, always rc 0, no args."

3. **`check_codex_available` (L127-L135).** "Under `copilot-cli`:
   Codex is always available as gpt-5.3-codex via the native task
   tool; no filesystem probe; returns 0. Under `claude-code`: globs
   `~/.claude/plugins/cache/openai-codex/codex/*/scripts/codex-companion.mjs`;
   returns 0 on at least one match, 1 on no match." That specifies
   the per-host probe strategy and a literal glob path — both
   are implementation choices Plan owns. The boundary is `$1 host`
   in, rc 0/1 out, semantic "is Codex reachable on this host."

Resolution: trim each doc-block to signature + parameter shape +
return contract + one-line semantic. Move the "how" (tr/wc-c choice,
probe order, glob path, fallthrough rule) to Plan, where per-task
specs own implementation logic. Also drop the "Bash 3.2 portable;
no nameref, no associative arrays, no $'...'" implementation
constraint from L104 — that is a Plan-level coding-style constraint,
not part of the exported signature.

Note the Slice 1 row at L17 also encodes algorithm choice in a
Responsibility cell ("using `LC_ALL=C tr -d '[:cntrl:]'` + `LC_ALL=C
wc -c` byte comparison"); the same trim applies there for the same
reason.
