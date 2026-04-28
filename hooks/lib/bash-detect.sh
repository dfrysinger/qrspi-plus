#!/usr/bin/env bash
set -euo pipefail

# bash_detect_file_writes <command>
#
# Emits one line per detected write target on stdout. Always returns 0.
#
# When the command contains a write-effect mechanism whose target cannot be
# reliably parsed (inline interpreters, awk redirect-from-program), the
# function emits a single sentinel line:
#
#     __OPAQUE_WRITE__
#
# pre-tool-use treats `__OPAQUE_WRITE__` as a write target that is *not* under
# `.worktrees/<slug>/(task-NN|baseline)/`, so the subagent worktree wall blocks
# the command. Main chat is exempt from the wall and is unaffected.
#
# Detection patterns (R2 S-N2 hardening — bypass coverage):
#
#   Redirect-style (target extractable):
#     - `> path`, `>> path`           — space-separated (existing)
#     - `>path`, `>>path`             — no-space (new)
#     - `>| path`, `>|path`           — clobber redirect (new)
#     - `>file cmd ...`               — leading-redirect form (new)
#     - `cat <<EOF >file`             — redirect after heredoc (new)
#
#   Command-style (target extractable from arguments):
#     - `sed -i ... file`             — in-place (existing)
#     - `cp ... dest`                 — last positional arg (existing)
#     - `mv ... dest`                 — last positional arg (existing)
#     - `tee [-a] file`               — existing
#     - `dd of=path`                  — write target via of= (new)
#     - `install ... dst`             — last positional arg (new)
#     - `rsync ... dst`               — last positional arg (new)
#
#   Opaque-write (cannot reliably parse target → sentinel emitted):
#     - `python -c ...`, `python3 -c ...`
#     - `node -e ...`, `node --eval ...`
#     - `perl -e ...`
#     - `ruby -e ...`
#     - `awk 'BEGIN{...}'` containing `>` or `>>`
#
bash_detect_file_writes() {
    local cmd="$1"
    local paths=()
    local opaque=0

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

    # `cd_escaped` tracks whether an earlier compound part has changed the
    # shell's effective CWD to a location outside the hook's PWD (the
    # worktree root for subagents). When set, any RELATIVE write target in a
    # subsequent part is opaque — pre-tool-use resolves relative paths
    # against the hook PWD, but the shell will resolve against the cd-into
    # target, so the apparent target and the actual target diverge. Treat as
    # opaque-write to fail closed.
    #
    # Round-2 task-43 (S-2 MAJOR — cd-before-relative-write subagent escape):
    # `cd /tmp && echo x > escaped.txt` would otherwise be classified as
    # writing to `<worktree>/escaped.txt` and allowed by the wall, while the
    # shell actually writes `/tmp/escaped.txt` outside the worktree.
    local cd_escaped=0

    # Helper: append a discovered path with surrounding quotes/whitespace stripped.
    # When `cd_escaped` is set and the path is RELATIVE (no leading /), the
    # path is opaque — emit the sentinel instead of the apparent target.
    _bd_add_path() {
        local p="$1"
        # Strip surrounding double quotes
        p="${p%\"}"
        p="${p#\"}"
        # Strip surrounding single quotes
        p="${p%\'}"
        p="${p#\'}"
        # Strip trailing whitespace/punctuation that may have leaked from regex
        # (kept conservative to avoid mangling real paths).
        p="${p%[[:space:]]}"
        if [[ -n "$p" ]]; then
            # task-43 S-2: relative-path writes after a cd-out are opaque.
            # Absolute paths are unaffected — the wall resolves them
            # directly without consulting CWD.
            if [[ "$cd_escaped" -eq 1 && "$p" != /* ]]; then
                opaque=1
                return 0
            fi
            paths+=("$p")
        fi
    }

    # Process each part of the compound command
    for part in "${parts[@]}"; do
        # Trim leading/trailing whitespace
        part="${part#"${part%%[![:space:]]*}"}"
        part="${part%"${part##*[![:space:]]}"}"

        # ── task-43 S-2: cd-before-relative-write subagent escape ─────────
        # Detect a leading `cd <target>` in this compound part. If the target
        # is absolute (`/...`), contains a `..` segment, or is `~` (home
        # expansion), the shell's effective CWD diverges from the hook PWD
        # for ALL subsequent parts in this compound. Mark cd_escaped=1 so
        # later relative-path writes are treated as opaque.
        #
        # Conservative posture (Codex round-3 recommendation): we do NOT try
        # to track exact post-cd CWD — we just refuse to trust the apparent
        # relative-path target after any cd-out. cd into a relative subdir
        # of the worktree (e.g., `cd src && ...`) keeps cd_escaped=0 because
        # the post-cd CWD is still inside the worktree, so relative writes
        # resolve to a path the wall regex still matches.
        local cd_re='^cd[[:space:]]+([^[:space:]]+|"[^"]*"|'\''[^'\'']*'\'')'
        if [[ "$part" =~ $cd_re ]]; then
            local cd_target="${BASH_REMATCH[1]}"
            # Strip surrounding quotes from the cd target.
            cd_target="${cd_target%\"}"
            cd_target="${cd_target#\"}"
            cd_target="${cd_target%\'}"
            cd_target="${cd_target#\'}"
            case "$cd_target" in
                /*|~*|*/../*|*/..|../*|..)
                    cd_escaped=1
                    ;;
                # `cd -` (return to OLDPWD) — opaque since we don't track it.
                -)
                    cd_escaped=1
                    ;;
            esac
        fi

        # ── Pattern: opaque-write — inline interpreters ──────────────────
        # python/python3/perl/ruby/bash/sh with -e or -c flag, node with -e
        # or --eval. The interpreter receives a script as a string argument;
        # the script may invoke arbitrary write APIs we cannot statically
        # parse. Treat as opaque-write — pre-tool-use wall blocks for
        # subagents.
        #
        # We accept the flag in any position (combined or separate):
        #   python -c CODE          → matches `-c`
        #   python -bc CODE         → matches `-bc` (combined)
        #   python -B -c CODE       → matches `-c` after other flag
        #   python3 -u -c CODE      → same
        #   bash -c CODE / sh -c CODE
        #   node -e CODE / node --eval CODE
        #   perl -e CODE / ruby -e CODE
        #
        # Match is "interpreter token, then anywhere later a flag containing
        # c (for python/perl/ruby/bash/sh) or e (for node/perl/ruby) or
        # --eval (for node)". We require the interpreter to be a recognized
        # name (not arbitrary command) to avoid over-blocking.
        local interp_re='(^|[[:space:]/])(python[0-9]*|perl|ruby|bash|sh|node)([[:space:]]+-+[A-Za-z]+)*[[:space:]]+-+[A-Za-z]*[ce][A-Za-z]*([[:space:]]|$)'
        local interp_eval_re='(^|[[:space:]/])node([[:space:]]+-+[A-Za-z]+)*[[:space:]]+--eval([[:space:]]|$)'
        if [[ "$part" =~ $interp_re ]] || [[ "$part" =~ $interp_eval_re ]]; then
            opaque=1
        fi

        # ── Pattern: opaque-write — awk program containing redirect ──────
        # `awk 'BEGIN{print > "..."}'` writes from inside the awk program;
        # we cannot reliably parse the target out of the awk script.
        if [[ "$part" =~ (^|[[:space:]/])awk([[:space:]]+-[A-Za-z]+)*[[:space:]]+[\'\"][^\'\"]*\>[^\'\"]*[\'\"] ]]; then
            opaque=1
        fi

        # ── Pattern: leading-redirect — `>file cmd ...` or `>>file cmd ...`
        # POSIX allows redirections anywhere on the command line. When `>`
        # appears at the very start (after stripping whitespace), capture
        # the next token as the target. Skip process substitution `>(`.
        if [[ "$part" =~ ^\>\>?\|?[[:space:]]*\"?\'?([^[:space:]\"\'\;\&\|\(]+) ]]; then
            local lead_target="${BASH_REMATCH[1]}"
            # Skip if it looks like the start of process substitution — already
            # excluded `(` from the character class, so an empty match means
            # the operand was `(...)` and we drop it.
            [[ -n "$lead_target" ]] && _bd_add_path "$lead_target"
        fi

        # ── Pattern: redirect (>, >>, >|) — space OR no-space, anywhere ──
        # We scan all occurrences using a hand-rolled walker because bash
        # `=~` only returns the first match. The walker tokenizes the
        # command into bytes, finds each `>` (skipping `>(` process subs
        # and `>&N` fd-dups), then reads the target token.
        local idx=0
        local plen=${#part}
        while [[ $idx -lt $plen ]]; do
            local c="${part:$idx:1}"
            if [[ "$c" != ">" ]]; then
                idx=$((idx+1))
                continue
            fi
            # Look back: is this preceded by `<<` (heredoc) or `<<<`
            # (herestring)? In those cases the `<<...` is the operator and
            # the `>` here is NOT a redirect — skip. But `<>file` (RW open)
            # IS a write because it creates the file when missing.
            if [[ $idx -gt 1 ]]; then
                local prev="${part:$((idx-1)):1}"
                local prev2="${part:$((idx-2)):1}"
                if [[ "$prev" == "<" && "$prev2" == "<" ]]; then
                    idx=$((idx+1))
                    continue
                fi
                # `<>file` — the `<` is bash's RW open which CREATES the
                # file if it doesn't exist. Treat the following token as a
                # write target. Fall through to normal target extraction.
            fi
            # Walk past the redirect operator (>, >>, >|, >&)
            local op_end=$((idx+1))
            if [[ $op_end -lt $plen && "${part:$op_end:1}" == ">" ]]; then
                op_end=$((op_end+1))
            fi
            if [[ $op_end -lt $plen && "${part:$op_end:1}" == "|" ]]; then
                op_end=$((op_end+1))
            fi
            # Process substitution `>(...)` — skip; it's a read endpoint.
            if [[ $op_end -lt $plen && "${part:$op_end:1}" == "(" ]]; then
                idx=$((op_end+1))
                continue
            fi
            # FD duplication `>&N` — not a file write. Skip.
            if [[ $op_end -lt $plen && "${part:$op_end:1}" == "&" ]]; then
                idx=$((op_end+1))
                continue
            fi
            # Skip optional whitespace between operator and target.
            while [[ $op_end -lt $plen ]]; do
                local sc="${part:$op_end:1}"
                [[ "$sc" == " " || "$sc" == $'\t' ]] || break
                op_end=$((op_end+1))
            done
            # Read the target. May be quoted (single or double) or a bareword.
            if [[ $op_end -lt $plen ]]; then
                local q="${part:$op_end:1}"
                if [[ "$q" == "\"" ]]; then
                    local end=$((op_end+1))
                    while [[ $end -lt $plen && "${part:$end:1}" != "\"" ]]; do
                        end=$((end+1))
                    done
                    local target="${part:$((op_end+1)):$((end-op_end-1))}"
                    _bd_add_path "$target"
                    idx=$((end+1))
                    continue
                elif [[ "$q" == "'" ]]; then
                    local end=$((op_end+1))
                    while [[ $end -lt $plen && "${part:$end:1}" != "'" ]]; do
                        end=$((end+1))
                    done
                    local target="${part:$((op_end+1)):$((end-op_end-1))}"
                    _bd_add_path "$target"
                    idx=$((end+1))
                    continue
                else
                    # Bareword: read until whitespace or terminator.
                    local end=$op_end
                    while [[ $end -lt $plen ]]; do
                        local tc="${part:$end:1}"
                        case "$tc" in
                            ' '|$'\t'|';'|'&'|'|'|'<'|'>') break ;;
                            *) end=$((end+1)) ;;
                        esac
                    done
                    if [[ $end -gt $op_end ]]; then
                        local target="${part:$op_end:$((end-op_end))}"
                        _bd_add_path "$target"
                    fi
                    idx=$end
                    continue
                fi
            fi
            idx=$((idx+1))
        done

        # ── Pattern: sed -i / sed -i.ext ─────────────────────────────────
        if [[ "$part" =~ sed[[:space:]]+-i ]]; then
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
            [[ -n "$sed_match" ]] && _bd_add_path "$sed_match"
        fi

        # ── Pattern: cp source dest ──────────────────────────────────────
        if [[ "$part" =~ ^cp[[:space:]]+ ]]; then
            local args_str="${part#cp}"
            args_str="${args_str## }"
            local last_arg=$(echo "$args_str" | awk '{print $NF}')
            if [[ ! "$last_arg" =~ ^- ]]; then
                _bd_add_path "$last_arg"
            fi
        fi

        # ── Pattern: mv old new ──────────────────────────────────────────
        if [[ "$part" =~ ^mv[[:space:]]+ ]]; then
            local args_str="${part#mv}"
            args_str="${args_str## }"
            local last_arg=$(echo "$args_str" | awk '{print $NF}')
            if [[ ! "$last_arg" =~ ^- ]]; then
                _bd_add_path "$last_arg"
            fi
        fi

        # ── Pattern: tee or tee -a ───────────────────────────────────────
        if [[ "$part" =~ tee[[:space:]]+ ]]; then
            local tee_match=""
            if [[ "$part" =~ tee[[:space:]]+-a[[:space:]]+\"?([^\"]+)\"? ]]; then
                tee_match="${BASH_REMATCH[1]}"
            elif [[ "$part" =~ tee[[:space:]]+\"?([^\"]+)\"? ]]; then
                tee_match="${BASH_REMATCH[1]}"
            fi
            [[ -n "$tee_match" ]] && _bd_add_path "$tee_match"
        fi

        # ── Pattern: dd of=path or dd of="path" ──────────────────────────
        # `dd` is special: write target appears as `of=` keyword arg, NOT
        # as the last positional argument.
        if [[ "$part" =~ (^|[^A-Za-z0-9_])dd([[:space:]]+|$) ]]; then
            local dd_match=""
            if [[ "$part" =~ (^|[^A-Za-z0-9_])of=\"([^\"]+)\" ]]; then
                dd_match="${BASH_REMATCH[2]}"
            elif [[ "$part" =~ (^|[^A-Za-z0-9_])of=\'([^\']+)\' ]]; then
                dd_match="${BASH_REMATCH[2]}"
            elif [[ "$part" =~ (^|[^A-Za-z0-9_])of=([^[:space:]\;\&\|\)]+) ]]; then
                dd_match="${BASH_REMATCH[2]}"
            fi
            [[ -n "$dd_match" ]] && _bd_add_path "$dd_match"
        fi

        # ── Pattern: install ... dst ─────────────────────────────────────
        # GNU/BSD `install` copies files; the LAST non-flag positional arg
        # is the destination. We use the same shape as cp/mv: last token
        # that is not a flag.
        if [[ "$part" =~ (^|[^A-Za-z0-9_])install([[:space:]]+|$) ]]; then
            local args_str="${part#*install}"
            args_str="${args_str## }"
            # Strip flag-with-arg pairs we know: -m MODE, -o OWNER, -g GROUP.
            # (We don't fully parse getopt; we just take the last token.)
            local last_arg
            last_arg=$(echo "$args_str" | awk '{print $NF}')
            if [[ -n "$last_arg" && ! "$last_arg" =~ ^- ]]; then
                _bd_add_path "$last_arg"
            fi
        fi

        # ── Pattern: rsync ... dst ───────────────────────────────────────
        # `rsync` last positional arg is the destination (local or remote).
        if [[ "$part" =~ (^|[^A-Za-z0-9_])rsync([[:space:]]+|$) ]]; then
            local args_str="${part#*rsync}"
            args_str="${args_str## }"
            local last_arg
            last_arg=$(echo "$args_str" | awk '{print $NF}')
            if [[ -n "$last_arg" && ! "$last_arg" =~ ^- ]]; then
                _bd_add_path "$last_arg"
            fi
        fi
    done

    # Output results (one per line). Deduplicate trivially by tracking seen.
    local seen_opaque=0
    local p
    for p in "${paths[@]}"; do
        echo "$p"
    done
    if [[ "$opaque" -eq 1 ]]; then
        echo "__OPAQUE_WRITE__"
    fi

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
        echo "rm -rf with dangerous target: absolute path ($tok)"
        return 0
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
