#!/usr/bin/env bash
set -euo pipefail

bash_detect_file_writes() {
    local cmd="$1"
    local paths=()

    # Split on compound operators (&&, ||, ;) to handle multiple commands
    local parts=()
    local current=""
    local i=0

    while [[ $i -lt ${#cmd} ]]; do
        local char="${cmd:$i:1}"
        local next_two="${cmd:$i:2}"

        # Check for compound operators
        if [[ "$next_two" == "&&" ]] || [[ "$next_two" == "||" ]]; then
            if [[ -n "$current" ]]; then
                parts+=("$current")
            fi
            current=""
            i=$((i+2))
        elif [[ "$char" == ";" ]]; then
            if [[ -n "$current" ]]; then
                parts+=("$current")
            fi
            current=""
            i=$((i+1))
        else
            current+="$char"
            i=$((i+1))
        fi
    done
    [[ -n "$current" ]] && parts+=("$current")

    # Process each part of the compound command
    for part in "${parts[@]}"; do
        part="${part## }"  # Trim leading whitespace
        part="${part%% }"  # Trim trailing whitespace

        # Pattern 1: Output redirect (> or >>)
        if [[ "$part" =~ \>\>?[[:space:]]+\"?([^\"]+)\"? ]]; then
            local path="${BASH_REMATCH[1]}"
            # Remove quotes if present
            path="${path%\"}"
            path="${path#\"}"
            path="${path%\'}"
            path="${path#\'}"
            [[ -n "$path" ]] && paths+=("$path")
        fi

        # Pattern 2: sed -i or sed -i.bak
        if [[ "$part" =~ sed[[:space:]]+-i ]]; then
            # Extract the filename (last argument after the sed pattern)
            local sed_match=""
            if [[ "$part" =~ sed[[:space:]]+-i\.[a-zA-Z0-9]+[[:space:]]+\'[^\']*\'[[:space:]]+([^ ]+) ]]; then
                sed_match="${BASH_REMATCH[1]}"
            elif [[ "$part" =~ sed[[:space:]]+-i\.[a-zA-Z0-9]+[[:space:]]+\"[^\"]*\"[[:space:]]+([^ ]+) ]]; then
                sed_match="${BASH_REMATCH[1]}"
            elif [[ "$part" =~ sed[[:space:]]+-i\.[a-zA-Z0-9]+[[:space:]]+[^[:space:]]+[[:space:]]+([^ ]+)$ ]]; then
                sed_match="${BASH_REMATCH[1]}"
            elif [[ "$part" =~ sed[[:space:]]+-i[[:space:]]+\'[^\']*\'[[:space:]]+([^ ]+) ]]; then
                sed_match="${BASH_REMATCH[1]}"
            elif [[ "$part" =~ sed[[:space:]]+-i[[:space:]]+\"[^\"]*\"[[:space:]]+([^ ]+) ]]; then
                sed_match="${BASH_REMATCH[1]}"
            elif [[ "$part" =~ sed[[:space:]]+-i[[:space:]]+[^[:space:]]+[[:space:]]+([^ ]+)$ ]]; then
                sed_match="${BASH_REMATCH[1]}"
            fi
            [[ -n "$sed_match" ]] && paths+=("$sed_match")
        fi

        # Pattern 3: cp source dest
        if [[ "$part" =~ ^cp[[:space:]]+ ]]; then
            local args_str="${part#cp}"
            args_str="${args_str## }"
            local last_arg=$(echo "$args_str" | awk '{print $NF}')
            if [[ ! "$last_arg" =~ ^- ]]; then
                last_arg="${last_arg%\"}"
                last_arg="${last_arg#\"}"
                last_arg="${last_arg%\'}"
                last_arg="${last_arg#\'}"
                [[ -n "$last_arg" ]] && paths+=("$last_arg")
            fi
        fi

        # Pattern 4: mv old new
        if [[ "$part" =~ ^mv[[:space:]]+ ]]; then
            local args_str="${part#mv}"
            args_str="${args_str## }"
            local last_arg=$(echo "$args_str" | awk '{print $NF}')
            if [[ ! "$last_arg" =~ ^- ]]; then
                last_arg="${last_arg%\"}"
                last_arg="${last_arg#\"}"
                last_arg="${last_arg%\'}"
                last_arg="${last_arg#\'}"
                [[ -n "$last_arg" ]] && paths+=("$last_arg")
            fi
        fi

        # Pattern 5: tee or tee -a
        if [[ "$part" =~ tee[[:space:]]+ ]]; then
            local tee_match=""
            if [[ "$part" =~ tee[[:space:]]+-a[[:space:]]+\"?([^\"]+)\"? ]]; then
                tee_match="${BASH_REMATCH[1]}"
            elif [[ "$part" =~ tee[[:space:]]+\"?([^\"]+)\"? ]]; then
                tee_match="${BASH_REMATCH[1]}"
            fi
            if [[ -n "$tee_match" ]]; then
                tee_match="${tee_match%\"}"
                tee_match="${tee_match#\"}"
                tee_match="${tee_match%\'}"
                tee_match="${tee_match#\'}"
                [[ -n "$tee_match" ]] && paths+=("$tee_match")
            fi
        fi
    done

    # Output results (one per line)
    for path in "${paths[@]}"; do
        echo "$path"
    done

    return 0
}

# bash_detect_destructive_universal <command>
#
# Returns 0 (and prints pattern name on stdout) if the command matches a
# destructive pattern that should be blocked for ALL agents, including main chat.
# Returns 1 otherwise.
#
# Patterns:
#   - rm -rf with target containing *, ~, leading /, or ..
#   - git push --force / -f
#   - git reset --hard <ref> where ref is anything other than HEAD or HEAD~/HEAD^ variants
#   - git clean -fd / -fdx / -fdX
#   - Redirect to /dev/sd*
#   - DROP DATABASE / DROP SCHEMA (case-insensitive)
bash_detect_destructive_universal() {
  local cmd="$1"
  local upper="${cmd^^}"

  # rm -rf with dangerous targets — tokenize the target portion so we catch
  # dangerous paths in ANY position (not just the first token after flags).
  # We use set -f / set +f to suppress glob expansion during `read -ra`.
  local rm_flags_re='rm[[:space:]]+(-[rRfF]+|-[rR][[:space:]]+-[fF]|-[fF][[:space:]]+-[rR])[[:space:]]+'
  if [[ "$cmd" =~ $rm_flags_re ]]; then
    # Extract everything after the matched flags portion.
    local after="${cmd#*${BASH_REMATCH[0]}}"
    # Truncate at compound operators so we only inspect rm's own arguments.
    local op
    for op in '&&' '||' ';' '|'; do
      if [[ "$after" == *"$op"* ]]; then
        after="${after%%$op*}"
      fi
    done
    # Tokenize safely — disable glob expansion so a literal * is not expanded.
    local -a tokens
    set -f
    read -ra tokens <<< "$after"
    set +f
    local tok
    for tok in "${tokens[@]}"; do
      if [[ "$tok" == *'*'* ]]; then
        echo "rm -rf with dangerous target: wildcard ($tok)"
        return 0
      fi
      if [[ "$tok" == '~'* ]]; then
        echo "rm -rf with dangerous target: home glob ($tok)"
        return 0
      fi
      if [[ "$tok" == /* ]]; then
        # F-3 minimal: allow project-internal absolute paths (under $PWD).
        # Catastrophic prefixes (/, /etc, /usr, /Users/other-user/...) still
        # blocked because they don't share the $PWD prefix.
        # NOTE: lexical comparison only — symlinked PWD (e.g. macOS
        # /tmp → /private/tmp) won't match canonical absolute targets and will
        # block. Errs toward safety; user can rerun with the matching form.
        local pwd_norm="${PWD%/}"
        if [[ -z "$pwd_norm" ]] || { [[ "$tok" != "$pwd_norm" ]] && [[ "$tok" != "$pwd_norm"/* ]]; }; then
          echo "rm -rf with dangerous target: absolute path ($tok)"
          return 0
        fi
        # project-internal absolute path — continue to ../parent-traversal check below
      fi
      if [[ "$tok" == *'..'* ]]; then
        echo "rm -rf with dangerous target: parent traversal ($tok)"
        return 0
      fi
    done
  fi

  # git push --force / -f
  if [[ "$cmd" =~ git[[:space:]]+push([[:space:]]|$) ]]; then
    if [[ "$cmd" =~ ([[:space:]]|^)--force([[:space:]]|$) ]] || \
       [[ "$cmd" =~ ([[:space:]]|^)-f([[:space:]]|$) ]]; then
      echo "git push --force"
      return 0
    fi
  fi

  # git reset --hard <non-HEAD>
  if [[ "$cmd" =~ git[[:space:]]+reset[[:space:]]+--hard[[:space:]]+([^[:space:]]+) ]]; then
    local ref="${BASH_REMATCH[1]}"
    case "$ref" in
      HEAD|HEAD~*|HEAD^*) ;;  # safe
      *) echo "git reset --hard non-HEAD ref: $ref"; return 0 ;;
    esac
  fi

  # git clean -fd / -fdx / -fdX
  # Anchor to end-of-token (whitespace or end-of-string) so -fdn (dry-run) is not matched.
  if [[ "$cmd" =~ git[[:space:]]+clean[[:space:]]+(-fd|-fdx|-fdX|-df|-dfx|-dfX)([[:space:]]|$) ]]; then
    echo "git clean -fd"
    return 0
  fi

  # Redirect to /dev/sd*
  if [[ "$cmd" =~ \>[[:space:]]*/dev/sd ]]; then
    echo "redirect to /dev/sd*"
    return 0
  fi

  # SQL DROP DATABASE / DROP SCHEMA
  if [[ "$upper" =~ DROP[[:space:]]+DATABASE ]] || [[ "$upper" =~ DROP[[:space:]]+SCHEMA ]]; then
    echo "DROP DATABASE/SCHEMA"
    return 0
  fi

  return 1
}

# bash_detect_destructive_subagent <command>
#
# Returns 0 (and prints pattern name on stdout) if the command matches a
# destructive pattern that should be blocked for SUBAGENTS only. Main chat is
# exempt — these patterns have legitimate manual-migration use cases.
# Returns 1 otherwise.
#
# Patterns:
#   - DROP TABLE (case-insensitive)
#   - TRUNCATE (case-insensitive, word-boundary)
bash_detect_destructive_subagent() {
  local cmd="$1"
  local upper="${cmd^^}"

  if [[ "$upper" =~ DROP[[:space:]]+TABLE ]]; then
    echo "DROP TABLE"
    return 0
  fi

  # Word-boundary TRUNCATE: not preceded or followed by [A-Z_]
  if [[ "$upper" =~ (^|[^A-Z_])TRUNCATE([^A-Z_]|$) ]]; then
    echo "TRUNCATE"
    return 0
  fi

  return 1
}
