# git-worktree-auto-prune

Remove worktrees whose PR was merged, delete their branch, then `git worktree prune`.

## Decisions
- Bash, same layout as `claude-resume-session` (script + `install.sh` into `~/bin`).
- Merge check: `gh pr list --head <branch> --state merged` (works for squash merges).
- Unsafe by default. `--safe` asks before each removal. `--dry-run` only reports.
- Scope: current repo only. Main worktree is never touched.
- Skip (with a warning): dirty worktrees, locked, detached HEAD, the worktree you run it from,
  and worktrees whose HEAD has commits not in the merged PR.
- Delete branch with `git branch -D` (squash merges look unmerged to git).

## Tasks
- [x] Tests with a stubbed `gh` (`tests/test_auto_prune.sh`)
- [x] Script `git_worktree_auto_prune.sh`
- [x] `install.sh`
- [x] `justfile` (lint, test, install)
- [x] All tests pass, shellcheck clean if available

## Review
- 18/18 tests pass with a stubbed `gh`. `bash -n` clean. shellcheck not installed, so not run.
- Self-review found 2 bugs before the first run: the current worktree was detected after `cd`
  (always the main worktree), and the `--safe` prompt read from the worktree-list pipe. Both are fixed and covered by tests.
- Real-repo dry run worked, but the real `gh` call was not exercised (the only worktree was locked).

## Step 2: `-d` for dry run, `-f/--force`
- [x] `-n` renamed to `-d` (user choice). `-n` is now rejected as unknown.
- [x] `--force` overrides: locked, uncommitted changes, commits not in the merged PR.
  It never overrides: not merged, detached, the worktree you are in.
- [x] `--safe --force` still asks, and the prompt names the reason.
  The prompt is printed with `printf`, because `read -p` hides it when stdin is not a terminal.
- [x] 32/32 tests pass (14 new, written first and seen failing).

## Notes
- Known limit: `gh pr list --head` matches by branch name only. A fork PR with the same name
  could match, but the SHA ancestry check prevents removing unrelated work.
