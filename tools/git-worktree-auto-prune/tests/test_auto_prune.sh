#!/usr/bin/env bash
#
# Tests for git_worktree_auto_prune.sh.
# Builds throwaway repos and stubs `gh` so no network is used.

set -uo pipefail

TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT="${TEST_DIR}/../git_worktree_auto_prune.sh"

PASSED=0
FAILED=0

# --- helpers ---------------------------------------------------------------

# Creates a repo with worktrees and a fake gh. Sets REPO, WT_ROOT, FAKE_GH_DIR.
setup() {
    SANDBOX="$(mktemp -d)"
    SANDBOX="$(cd "$SANDBOX" && pwd -P)"
    REPO="${SANDBOX}/repo"
    WT_ROOT="${SANDBOX}/wts"
    FAKE_GH_DIR="${SANDBOX}/gh-data"
    mkdir -p "$REPO" "$WT_ROOT" "$FAKE_GH_DIR" "${SANDBOX}/bin"

    git -C "$REPO" init -q -b main
    git -C "$REPO" config user.email t@t
    git -C "$REPO" config user.name t
    git -C "$REPO" commit -q --allow-empty -m init

    # Fake gh: prints the merged PR head SHA stored in $FAKE_GH_DIR/<branch>.
    cat > "${SANDBOX}/bin/gh" <<'EOF'
#!/usr/bin/env bash
head=""
while [[ $# -gt 0 ]]; do
    if [[ "$1" == "--head" ]]; then head="$2"; shift; fi
    shift
done
cat "${FAKE_GH_DIR}/${head//\//_}" 2>/dev/null || true
EOF
    chmod +x "${SANDBOX}/bin/gh"
    export FAKE_GH_DIR
    export PATH="${SANDBOX}/bin:${PATH}"
}

teardown() {
    rm -rf "$SANDBOX"
}

# Adds a worktree on a new branch with one commit.
add_wt() {
    local branch="$1"
    git -C "$REPO" worktree add -q -b "$branch" "${WT_ROOT}/${branch//\//_}"
    git -C "${WT_ROOT}/${branch//\//_}" commit -q --allow-empty -m "work on ${branch}"
}

wt_path() {
    echo "${WT_ROOT}/${1//\//_}"
}

# Marks the branch's PR as merged at its current HEAD.
mark_merged() {
    local branch="$1"
    git -C "$(wt_path "$branch")" rev-parse HEAD > "${FAKE_GH_DIR}/${branch//\//_}"
}

run() {
    (cd "$REPO" && bash "$SCRIPT" "$@") 2>&1
}

assert() {
    local name="$1"
    shift
    if "$@"; then
        PASSED=$((PASSED + 1))
        echo "ok   - ${name}"
    else
        FAILED=$((FAILED + 1))
        echo "FAIL - ${name}"
    fi
}

branch_exists() {
    git -C "$REPO" show-ref --verify --quiet "refs/heads/$1"
}

# --- tests -----------------------------------------------------------------

test_removes_merged_worktree_and_branch() {
    setup
    add_wt feat/merged
    add_wt open
    mark_merged feat/merged
    run >/dev/null
    assert "merged worktree removed" test ! -d "$(wt_path feat/merged)"
    assert "merged branch deleted" bash -c "! git -C '$REPO' show-ref --quiet refs/heads/feat/merged"
    assert "open worktree kept" test -d "$(wt_path open)"
    assert "open branch kept" branch_exists open
    teardown
}

test_skips_dirty_worktree() {
    setup
    add_wt dirty
    mark_merged dirty
    touch "$(wt_path dirty)/untracked.txt"
    local out
    out="$(run)"
    assert "dirty worktree kept" test -d "$(wt_path dirty)"
    assert "dirty branch kept" branch_exists dirty
    assert "dirty warning shown" grep -q "uncommitted" <<<"$out"
    teardown
}

test_skips_commits_after_merge() {
    setup
    add_wt extra
    mark_merged extra
    git -C "$(wt_path extra)" commit -q --allow-empty -m "after merge"
    local out
    out="$(run)"
    assert "worktree with new commits kept" test -d "$(wt_path extra)"
    assert "new commits warning shown" grep -q "not in the merged PR" <<<"$out"
    teardown
}

test_allows_head_behind_merged_pr() {
    setup
    add_wt behind
    git -C "$(wt_path behind)" commit -q --allow-empty -m "pushed later"
    mark_merged behind
    git -C "$(wt_path behind)" reset -q --hard HEAD~1
    run >/dev/null
    assert "worktree behind merged PR removed" test ! -d "$(wt_path behind)"
    teardown
}

test_safe_mode_declined() {
    setup
    add_wt asked
    mark_merged asked
    (cd "$REPO" && echo n | bash "$SCRIPT" --safe) >/dev/null 2>&1
    assert "safe mode 'n' keeps worktree" test -d "$(wt_path asked)"
    teardown
}

test_safe_mode_accepted() {
    setup
    add_wt asked
    mark_merged asked
    (cd "$REPO" && echo y | bash "$SCRIPT" --safe) >/dev/null 2>&1
    assert "safe mode 'y' removes worktree" test ! -d "$(wt_path asked)"
    teardown
}

test_dry_run() {
    setup
    add_wt dry
    mark_merged dry
    local out
    out="$(run --dry-run)"
    assert "dry run keeps worktree" test -d "$(wt_path dry)"
    assert "dry run reports" grep -q "would remove" <<<"$out"
    teardown
}

test_dry_run_short_flag() {
    setup
    add_wt dry
    mark_merged dry
    local out
    out="$(run -d)"
    assert "-d keeps worktree" test -d "$(wt_path dry)"
    assert "-d reports" grep -q "would remove" <<<"$out"
    teardown
}

test_force_removes_dirty() {
    setup
    add_wt dirty
    mark_merged dirty
    touch "$(wt_path dirty)/untracked.txt"
    run --force >/dev/null
    assert "force removes dirty worktree" test ! -d "$(wt_path dirty)"
    assert "force deletes dirty branch" bash -c "! git -C '$REPO' show-ref --quiet refs/heads/dirty"
    teardown
}

test_force_removes_extra_commits() {
    setup
    add_wt extra
    mark_merged extra
    git -C "$(wt_path extra)" commit -q --allow-empty -m "after merge"
    run -f >/dev/null
    assert "force removes worktree with new commits" test ! -d "$(wt_path extra)"
    teardown
}

test_force_removes_locked() {
    setup
    add_wt locked
    mark_merged locked
    git -C "$REPO" worktree lock "$(wt_path locked)"
    run -f >/dev/null
    assert "force removes locked worktree" test ! -d "$(wt_path locked)"
    teardown
}

test_force_keeps_hard_skips() {
    setup
    add_wt open
    add_wt here
    mark_merged here
    git -C "$REPO" worktree add -q --detach "${WT_ROOT}/detached"
    (cd "$(wt_path here)" && bash "$SCRIPT" -f) >/dev/null 2>&1
    assert "force keeps unmerged worktree" test -d "$(wt_path open)"
    assert "force keeps current worktree" test -d "$(wt_path here)"
    assert "force keeps detached worktree" test -d "${WT_ROOT}/detached"
    teardown
}

test_force_dry_run() {
    setup
    add_wt dirty
    mark_merged dirty
    touch "$(wt_path dirty)/untracked.txt"
    local out
    out="$(run -f -d)"
    assert "force dry run keeps worktree" test -d "$(wt_path dirty)"
    assert "force dry run reports reason" grep -q "would remove.*uncommitted" <<<"$out"
    teardown
}

test_safe_force_declined() {
    setup
    add_wt dirty
    mark_merged dirty
    touch "$(wt_path dirty)/untracked.txt"
    local out
    out="$(cd "$REPO" && echo n | bash "$SCRIPT" -s -f 2>&1)"
    assert "safe+force 'n' keeps worktree" test -d "$(wt_path dirty)"
    assert "safe+force prompt names reason" grep -q "uncommitted" <<<"$out"
    teardown
}

test_safe_force_accepted() {
    setup
    add_wt dirty
    mark_merged dirty
    touch "$(wt_path dirty)/untracked.txt"
    (cd "$REPO" && echo y | bash "$SCRIPT" -s -f) >/dev/null 2>&1
    assert "safe+force 'y' removes worktree" test ! -d "$(wt_path dirty)"
    teardown
}

test_skips_current_worktree() {
    setup
    add_wt here
    mark_merged here
    (cd "$(wt_path here)" && bash "$SCRIPT") >/dev/null 2>&1
    assert "current worktree kept" test -d "$(wt_path here)"
    teardown
}

test_skips_locked_worktree() {
    setup
    add_wt locked
    mark_merged locked
    git -C "$REPO" worktree lock "$(wt_path locked)"
    run >/dev/null
    assert "locked worktree kept" test -d "$(wt_path locked)"
    teardown
}

test_prunes_stale_metadata() {
    setup
    add_wt gone
    rm -rf "$(wt_path gone)"
    run >/dev/null
    assert "stale entry pruned" bash -c "! git -C '$REPO' worktree list | grep -q gone"
    teardown
}

test_rejects_unknown_flag() {
    setup
    (cd "$REPO" && bash "$SCRIPT" --nope) >/dev/null 2>&1
    assert "unknown flag exits non-zero" test $? -ne 0
    teardown
}

# --- main ------------------------------------------------------------------

for t in $(declare -F | awk '{print $3}' | grep '^test_'); do
    "$t"
done

echo
echo "passed: ${PASSED}, failed: ${FAILED}"
[[ "$FAILED" -eq 0 ]]
