#!/usr/bin/env bash
# scripts/upstream-paths.sh — emit the per-step upstream-artifact path list
# consumed by reviewer/verifier dispatches (CD-1, G1, G4).
#
# Contract (per design.md § CD-1, G1, G4 + structure.md):
#
#   scripts/upstream-paths.sh --step <step> [--artifact-dir <path>]
#
# Prints a newline-separated path list to stdout. The list is composed of two
# sections, in order:
#
#   1. Per-step upstream artifacts (step-relative basenames; the orchestrator
#      joins them against the run's <abs_path>):
#
#        Goals:        (none)
#        Questions:    goals.md
#        Research:     goals.md, questions.md
#        Design:       goals.md, questions.md, research/summary.md
#        Phasing:      goals.md, design.md
#        Structure:    goals.md, design.md, phasing.md
#        Parallelize:  goals.md, design.md, structure.md
#        Replan:       plan.md, replan-trigger-source
#        Plan:         pipeline-mode-aware (read from <artifact-dir>/config.md):
#                        full  → goals.md, research/summary.md, design.md,
#                                phasing.md, structure.md
#                        quick → goals.md, research/summary.md
#
#   2. Always-appended SKILL paths (repo-relative; G1 contributes the third
#      entry as the canonical ID-hygiene authority):
#
#        skills/<step>/SKILL.md
#        skills/using-qrspi/SKILL.md
#        skills/implementer-protocol/SKILL.md
#
# Unknown step (any --step value not in the table above): print only the
# always-appended SKILL paths (with skills/<step>/SKILL.md substituted using
# the literal --step value), exit 0, no diagnostic on stderr. Per design.md
# § CD-1 Acceptance bullet 2 + structure.md row 17, the fail-soft direction
# is contracted: orchestrator failure on an absent step would be a regression
# vs. today's prose behaviour.
#
# Plan step diagnostics (named, fail-loud — per G4 Acceptance bullet 3):
#   - <artifact-dir>/config.md missing (or --artifact-dir omitted) →
#     `config-missing:` on stderr, exit 3.
#   - config.md present but `pipeline:` value is absent or not in {full, quick}
#     → `config-malformed:` on stderr, exit 4.
#
# The script is context-free: it does not resolve <abs_path>, does not touch
# git, and writes nothing to disk. Same risk profile as a lookup table.
#
# Bash 3.2 compatible (macOS system /bin/bash).

set -eu

usage() {
  cat >&2 <<'EOF'
Usage: upstream-paths.sh --step <step> [--artifact-dir <path>]

  --step <step>           Required. One of {goals, questions, research, design,
                          phasing, structure, parallelize, replan, plan}, or any
                          unknown value (fail-soft: returns appended SKILLs only).
  --artifact-dir <path>   Required only for --step plan. Directory containing
                          config.md with a `pipeline: {full|quick}` line.
EOF
}

step=""
artifact_dir=""

while [ $# -gt 0 ]; do
  case "$1" in
    --step)
      [ $# -ge 2 ] || { echo "missing-arg-value: --step requires a value" >&2; usage; exit 2; }
      step="$2"; shift 2 ;;
    --artifact-dir)
      [ $# -ge 2 ] || { echo "missing-arg-value: --artifact-dir requires a value" >&2; usage; exit 2; }
      artifact_dir="$2"; shift 2 ;;
    -h|--help)
      usage; exit 0 ;;
    *)
      echo "unknown-arg: $1" >&2; usage; exit 2 ;;
  esac
done

if [ -z "$step" ]; then
  echo "missing-arg: --step is required" >&2
  usage
  exit 2
fi

# Per-step upstream artifact set. Empty string means "no upstream artifacts;
# emit only the always-appended SKILLs". Each entry on its own line.
upstream=""

case "$step" in
  goals)
    upstream=""
    ;;
  questions)
    upstream="goals.md"
    ;;
  research)
    upstream="goals.md
questions.md"
    ;;
  design)
    upstream="goals.md
questions.md
research/summary.md"
    ;;
  phasing)
    upstream="goals.md
design.md"
    ;;
  structure)
    upstream="goals.md
design.md
phasing.md"
    ;;
  parallelize)
    upstream="goals.md
design.md
structure.md"
    ;;
  replan)
    upstream="plan.md
replan-trigger-source"
    ;;
  plan)
    # Pipeline-mode-aware branch (G4). Read pipeline: from <artifact-dir>/config.md.
    if [ -z "$artifact_dir" ]; then
      echo "config-missing: --artifact-dir omitted; Plan step requires --artifact-dir <path> with a config.md" >&2
      exit 3
    fi
    cfg="${artifact_dir%/}/config.md"
    if [ ! -f "$cfg" ]; then
      echo "config-missing: $cfg not found (Plan step requires <artifact-dir>/config.md)" >&2
      exit 3
    fi
    # Match `pipeline:` followed by optional whitespace and a value; trim trailing whitespace.
    pipeline_value=$(awk -F': *' '/^pipeline:[[:space:]]*/ {sub(/[[:space:]]+$/, "", $2); print $2; exit}' "$cfg")
    case "$pipeline_value" in
      full)
        upstream="goals.md
research/summary.md
design.md
phasing.md
structure.md"
        ;;
      quick)
        upstream="goals.md
research/summary.md"
        ;;
      "")
        echo "config-malformed: no recognised 'pipeline:' line in $cfg (expected: pipeline: full | pipeline: quick)" >&2
        exit 4
        ;;
      *)
        echo "config-malformed: unrecognised pipeline value '$pipeline_value' in $cfg (expected: full | quick)" >&2
        exit 4
        ;;
    esac
    ;;
  *)
    # Unknown step: fail-soft. Emit only the always-appended SKILLs below.
    upstream=""
    ;;
esac

# Emit per-step upstream entries (if any), one per line.
if [ -n "$upstream" ]; then
  printf '%s\n' "$upstream"
fi

# Always-appended SKILL paths.
printf '%s\n' "skills/${step}/SKILL.md"
printf '%s\n' "skills/using-qrspi/SKILL.md"
printf '%s\n' "skills/implementer-protocol/SKILL.md"
