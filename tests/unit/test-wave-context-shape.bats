#!/usr/bin/env bats
bats_require_minimum_version 1.5.0

# T30 (pin 3 of 5) — G11: Slice 5 wave-context-shape contract pin.
#
# Asserts T27's wave_context: companion shape in skills/implement/SKILL.md:
#   - Per-task companion entries carry task ID, task name, allowed_files
#     glob, and earlier-wave sibling findings.
#   - Body is wrapped between canonical untrusted-artifact sentinels:
#     <<<UNTRUSTED-ARTIFACT-START id=wave_context>>>
#     <<<UNTRUSTED-ARTIFACT-END id=wave_context>>>
#   - Sentinel-collision sanitize-or-exclude path is documented (a sibling
#     finding body containing a literal sentinel token is stripped or
#     excluded — never embedded as a nested sentinel).
#   - When at least one finding is stripped or excluded, the assembled
#     companion body MUST carry a REDACTION-NOTICE entry naming the source
#     task ID, the action, and the count of redacted findings.
#   - wave_number: companion parameter is required on every visual-fidelity
#     reviewer dispatch (so missing wave_context on wave_number>1 +
#     multi-UI-task plans fails loud rather than degrading silently).
#
# Bash 3.2 portable.

load '../helpers/skill-markdown'

setup_file() {
  require_repo_root
  IMPLEMENT_SKILL="$REPO_ROOT/skills/implement/SKILL.md"
  export IMPLEMENT_SKILL
}

# =============================================================================
# Per-task companion entry shape (task ID, name, allowed_files, findings)
# =============================================================================

@test "[T30-wave-ctx] wave_context entries carry task ID and task name" {
  extract_and_grep "$IMPLEMENT_SKILL" H2 "Dispatch parameters" \
    "Task ID, task name"
}

@test "[T30-wave-ctx] wave_context entries carry allowed_files glob" {
  extract_and_grep "$IMPLEMENT_SKILL" H2 "Dispatch parameters" \
    "allowed_files"
}

@test "[T30-wave-ctx] wave_context entries carry per-finding category/severity/summary" {
  extract_and_grep "$IMPLEMENT_SKILL" H2 "Dispatch parameters" \
    "(change_type|category)"
}

# =============================================================================
# Canonical untrusted-artifact sentinel wrapping
# =============================================================================

@test "[T30-wave-ctx] wave_context body wrapped in canonical START sentinel" {
  extract_and_grep "$IMPLEMENT_SKILL" H2 "Dispatch parameters" \
    "<<<UNTRUSTED-ARTIFACT-START id=wave_context>>>"
}

@test "[T30-wave-ctx] wave_context body wrapped in canonical END sentinel" {
  extract_and_grep "$IMPLEMENT_SKILL" H2 "Dispatch parameters" \
    "<<<UNTRUSTED-ARTIFACT-END id=wave_context>>>"
}

# =============================================================================
# Sentinel injection guard (sanitize-or-exclude on collision)
# =============================================================================

@test "[T30-wave-ctx] Sentinel injection guard checks sibling finding bodies" {
  extract_and_grep "$IMPLEMENT_SKILL" H2 "Dispatch parameters" \
    "[Ss]entinel injection guard"
}

@test "[T30-wave-ctx] Sentinel-collision path documents strip OR exclude action" {
  extract_and_grep "$IMPLEMENT_SKILL" H2 "Dispatch parameters" \
    "[Ss]trip"
}

@test "[T30-wave-ctx] Sentinel-collision path documents exclude action" {
  extract_and_grep "$IMPLEMENT_SKILL" H2 "Dispatch parameters" \
    "[Ee]xclude"
}

# =============================================================================
# REDACTION-NOTICE entry when sibling findings were stripped or excluded
# =============================================================================

@test "[T30-wave-ctx] Redaction path emits REDACTION-NOTICE entry on companion body" {
  extract_and_grep "$IMPLEMENT_SKILL" H2 "Dispatch parameters" \
    "REDACTION-NOTICE"
}

@test "[T30-wave-ctx] REDACTION-NOTICE names source task ID" {
  extract_and_grep "$IMPLEMENT_SKILL" H2 "Dispatch parameters" \
    "source task ID"
}

@test "[T30-wave-ctx] REDACTION-NOTICE names redaction action (strip or exclude)" {
  extract_and_grep "$IMPLEMENT_SKILL" H2 "Dispatch parameters" \
    "redaction action"
}

@test "[T30-wave-ctx] REDACTION-NOTICE names count of redacted findings" {
  extract_and_grep "$IMPLEMENT_SKILL" H2 "Dispatch parameters" \
    "count of redacted findings"
}

# =============================================================================
# Absence-of-companion contract (first-wave / single-UI-task)
# =============================================================================

@test "[T30-wave-ctx] First-wave or single-UI-task dispatches omit wave_context legally" {
  extract_and_grep "$IMPLEMENT_SKILL" H2 "Dispatch parameters" \
    "absence is legal"
}

# =============================================================================
# wave_number: companion parameter — load-bearing on every dispatch
# =============================================================================

@test "[T30-wave-ctx] wave_number companion parameter required on every dispatch" {
  extract_and_grep "$IMPLEMENT_SKILL" H2 "Dispatch parameters" \
    "wave_number:"
}

@test "[T30-wave-ctx] wave_number>1 + multi-UI plan treats missing wave_context as load-bearing diagnostic" {
  extract_and_grep "$IMPLEMENT_SKILL" H2 "Dispatch parameters" \
    "load-bearing diagnostic"
}
