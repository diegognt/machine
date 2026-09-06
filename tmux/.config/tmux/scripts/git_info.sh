#!/usr/bin/env bash
# Print a status-bar label for the current git context.
#
# - If the current directory is inside a linked git worktree, print the
#   worktree directory name (basename of the worktree's toplevel).
# - Otherwise, if it's inside a regular git repo, print the current branch.
# - If not inside a git repo at all, print nothing.

dir="${1:-$PWD}"

if ! git -C "$dir" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  exit 0
fi

git_dir="$(git -C "$dir" rev-parse --git-dir 2>/dev/null)"
common_dir="$(git -C "$dir" rev-parse --git-common-dir 2>/dev/null)"

if [[ -n "$git_dir" && -n "$common_dir" && "$git_dir" != "$common_dir" ]]; then
  # Linked worktree: git-dir differs from the common (main) git-dir.
  toplevel="$(git -C "$dir" rev-parse --show-toplevel 2>/dev/null)"
  basename "$toplevel"
else
  # Regular repo (or the main worktree): show the branch name.
  git -C "$dir" branch --show-current 2>/dev/null
fi
