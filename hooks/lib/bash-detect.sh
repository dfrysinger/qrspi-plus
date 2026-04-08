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
