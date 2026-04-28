#!/usr/bin/env bash
set -euo pipefail

# artifact_map_get <step_name>
# Maps pipeline step names to their artifact file paths.
# Returns the file path on stdout.
# Exit: 0 on success, 1 on unrecognized step name.
artifact_map_get() {
  local step="$1"
  case "$step" in
    goals)      echo "goals.md" ;;
    questions)  echo "questions.md" ;;
    research)   echo "research/summary.md" ;;
    design)     echo "design.md" ;;
    structure)  echo "structure.md" ;;
    plan)       echo "plan.md" ;;
    *)
      echo "artifact_map_get: unrecognized step '${step}'" >&2
      return 1
      ;;
  esac
}

# artifact_map_get_step <filename>
# Reverse lookup: maps a filename (or path suffix) to a pipeline step name.
# Returns the step name on stdout.
# Exit: 0 on success, 1 on unrecognized filename.
artifact_map_get_step() {
  local filename="$1"
  case "$filename" in
    */research/summary.md|research/summary.md) echo "research" ;;
    */goals.md|goals.md)                       echo "goals" ;;
    */questions.md|questions.md)               echo "questions" ;;
    */design.md|design.md)                     echo "design" ;;
    */structure.md|structure.md)               echo "structure" ;;
    */plan.md|plan.md)                         echo "plan" ;;
    *)                                         return 1 ;;
  esac
}
