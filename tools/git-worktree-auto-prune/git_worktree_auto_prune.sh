#!/usr/bin/env bash
#
# git_worktree_auto_prune.sh
# Removes worktrees whose GitHub PR was merged, deletes their local branch,
# then runs `git worktree prune`.
#
# A worktree is always skipped when it is the main worktree, the one you run
# this from, or detached. It is also skipped (with a warning) when it is
# locked, has uncommitted changes, or has commits not in the merged PR,
# unless --force is given.

set -euo pipefail

SAFE=false
DRY_RUN=false
FORCE=false

usage() {
    cat <<EOF
Usage: git-worktree-auto-prune [--safe] [--force] [--dry-run]

Removes worktrees (and their local branches) whose GitHub PR was merged,
then runs 'git worktree prune'. Acts without asking by default.

Options:
  -s, --safe      Ask before removing each worktree.
  -f, --force     Also remove worktrees that are locked, have uncommitted
                  changes, or have commits not in the merged PR.
                  That work is lost. Combine with --safe to be asked.
  -d, --dry-run   Only report what would be removed.
  -h, --help      Show this help.
EOF
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -s|--safe) SAFE=true ;;
            -f|--force) FORCE=true ;;
            -d|--dry-run) DRY_RUN=true ;;
            -h|--help) usage; exit 0 ;;
            *) echo "Unknown option: $1" >&2; usage >&2; exit 2 ;;
        esac
        shift
    done
}

check_requirements() {
    command -v gh >/dev/null 2>&1 || { echo "Error: gh CLI not found." >&2; exit 1; }
    git rev-parse --git-dir >/dev/null 2>&1 || { echo "Error: not in a git repository." >&2; exit 1; }
}

warn() {
    echo "skip: $1 ($2)" >&2
}

# Prints the head SHA of the merged PR for a branch, or nothing.
merged_pr_sha() {
    gh pr list --head "$1" --state merged --limit 1 \
        --json headRefOid --jq '.[].headRefOid'
}

# Asks about one worktree. $1 is its description, $2 the forced reason (may be empty).
confirm() {
    local answer
    if [[ -n "$2" ]]; then
        printf 'Remove %s anyway, it %s? (y/N) ' "$1" "$2" >&2
    else
        printf 'Remove %s? (y/N) ' "$1" >&2
    fi
    # fd 3 is the caller's stdin; fd 0 is the worktree list inside the loop.
    read -r answer <&3 || return 1
    [[ "$answer" =~ ^[Yy]$ ]]
}

# Joins arguments with ", ".
join_reasons() {
    local out="$1"
    shift
    for r in "$@"; do out+=", $r"; done
    echo "$out"
}

# Decides and acts on one worktree entry.
handle_worktree() {
    local path="$1" branch="$2" head="$3" locked="$4" prunable="$5" current="$6"
    local pr_sha desc reason="" reasons=()

    # Skips that --force never overrides.
    [[ "$prunable" == true ]] && return 0  # folder gone, prune handles it
    [[ -z "$branch" ]] && { warn "$path" "detached HEAD"; return 0; }

    pr_sha="$(merged_pr_sha "$branch")" || { warn "$path" "gh query failed"; return 0; }
    [[ -z "$pr_sha" ]] && return 0  # not merged, nothing to say

    if [[ "$path" == "$current" ]]; then
        warn "$path" "you are inside it"
        return 0
    fi

    # Skips that --force overrides. They only risk local work.
    [[ "$locked" == true ]] && reasons+=("is locked")
    [[ -n "$(git -C "$path" status --porcelain)" ]] && reasons+=("has uncommitted changes")
    # HEAD must be the merged commit or an ancestor of it, so no work is lost.
    if [[ "$head" != "$pr_sha" ]] && ! git merge-base --is-ancestor "$head" "$pr_sha" 2>/dev/null; then
        reasons+=("has commits not in the merged PR")
    fi
    if [[ ${#reasons[@]} -gt 0 ]]; then
        reason="$(join_reasons "${reasons[@]}")"
        if [[ "$FORCE" != true ]]; then
            warn "$path" "${reason}; --force removes it"
            return 0
        fi
    fi

    desc="$path (branch $branch)"
    if [[ "$DRY_RUN" == true ]]; then
        echo "would remove: ${desc}${reason:+ [forced: $reason]}"
        return 0
    fi
    if [[ "$SAFE" == true ]] && ! confirm "$desc" "$reason"; then
        return 0
    fi

    if [[ -n "$reason" ]]; then
        git worktree remove -f -f "$path"  # double -f also overrides a lock
    else
        git worktree remove "$path"
    fi
    git branch -D "$branch" >/dev/null
    echo "removed: ${desc}${reason:+ [forced: $reason]}"
}

# Walks `git worktree list --porcelain`, skipping the main worktree (first entry).
process_worktrees() {
    local current="$1"
    local line path="" branch="" head="" locked=false prunable=false first=true

    flush() {
        if [[ -n "$path" ]]; then
            if [[ "$first" == true ]]; then
                first=false
            else
                handle_worktree "$path" "$branch" "$head" "$locked" "$prunable" "$current"
            fi
        fi
        path="" branch="" head="" locked=false prunable=false
    }

    while IFS= read -r line; do
        case "$line" in
            "worktree "*) path="${line#worktree }" ;;
            "HEAD "*) head="${line#HEAD }" ;;
            "branch refs/heads/"*) branch="${line#branch refs/heads/}" ;;
            locked*) locked=true ;;
            prunable*) prunable=true ;;
            "") flush ;;
        esac
    done < <(git worktree list --porcelain; echo)
    flush
}

main() {
    parse_args "$@"
    check_requirements
    local current
    current="$(git rev-parse --show-toplevel)"
    exec 3<&0
    # Run from the main worktree so removals never pull the rug from under us.
    cd "$(dirname "$(git rev-parse --path-format=absolute --git-common-dir)")"
    process_worktrees "$current"
    if [[ "$DRY_RUN" == true ]]; then
        git worktree prune --dry-run --verbose
    else
        git worktree prune --verbose
    fi
}

main "$@"
