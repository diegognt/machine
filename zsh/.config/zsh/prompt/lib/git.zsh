# git.zsh — synchronous git status helpers for the prompt
# Pure zsh, no external async library required.
# Worktree-aware: works with plain repos, `git worktree add` linked worktrees,
# and bare-repo + worktrees layouts (e.g. ~/.machine/.bare + linked worktrees).

# Single git call that resolves toplevel, git-dir, common-dir and branch at
# once (cheaper than separate `git rev-parse`/`symbolic-ref` invocations).
# Populates prompt_data[git_toplevel|git_dir|git_common_dir|git_worktree|
# git_branch]. Returns 1 (and leaves git_toplevel empty) when not inside a
# git repo.
git_fetch_info() {
  local raw
  raw="$(command git rev-parse --show-toplevel --git-dir --git-common-dir --abbrev-ref HEAD 2>/dev/null)"
  if [[ -z "$raw" ]]; then
    prompt_data[git_toplevel]=
    prompt_data[git_dir]=
    prompt_data[git_common_dir]=
    prompt_data[git_worktree]=
    prompt_data[git_branch]=
    return 1
  fi

  local -a lines
  lines=("${(@f)raw}")

  local toplevel="$lines[1]"
  local git_dir="${lines[2]:A}"
  local common_dir="${lines[3]:A}"
  local branch="$lines[4]"

  prompt_data[git_toplevel]="$toplevel"
  prompt_data[git_dir]="$git_dir"
  prompt_data[git_common_dir]="$common_dir"

  # Repo/project name, derived from the git-dir's parent: for a plain repo
  # this is "<repo>/.git" -> "<repo>", for a bare-repo-hub layout (e.g.
  # ~/.machine/.bare + sibling worktrees) this is ".bare" -> "~/.machine",
  # giving the actual project name in both popular worktree layouts.
  prompt_data[git_repo_name]="${${common_dir:h}:t}"

  # Linked worktree detection: git stores each worktree's git-dir at
  # <common-dir>/worktrees/<name>. This <name> is git's own worktree id,
  # not necessarily the directory name you're standing in.
  local worktree=""
  if [[ "$git_dir" != "$common_dir" && "$git_dir" == "$common_dir"/worktrees/* ]]; then
    worktree="${git_dir#$common_dir/worktrees/}"
  fi
  prompt_data[git_worktree]="$worktree"

  if [[ "$branch" == "HEAD" ]]; then
    # Detached HEAD (common right after `git worktree add <path> <sha>`).
    local sha
    sha="$(command git rev-parse --short HEAD 2>/dev/null)"
    prompt_data[git_branch]="➦ ${sha}"
  else
    prompt_data[git_branch]="$branch"
  fi
}

# Compares a worktree directory name against the checked-out branch name,
# tolerant of the common directory-naming conventions used across the
# popular worktree layouts (bare-repo hub, sibling clones, .worktrees/):
#   - exact match                          foo        == foo
#   - slash -> dash slug                   feature-foo == feature/foo
#   - leaf segment only                    foo        == feature/foo
# Returns 0 (match) if any of these apply, 1 otherwise.
worktree_matches_branch() {
  local worktree="$1"
  local branch="$2"

  [[ -z "$worktree" || -z "$branch" ]] && return 1
  [[ "$worktree" == "$branch" ]] && return 0

  local slug="${branch//\//-}"
  [[ "$worktree" == "$slug" ]] && return 0

  local leaf="${branch##*/}"
  [[ "$worktree" == "$leaf" ]] && return 0

  return 1
}

git_home() {
  local current_directory="$1"
  local git_toplevel="$2"
  local home=""

  if [[ -n "$git_toplevel" && "$git_toplevel" != "$current_directory" ]]; then
    local repo_name="${git_toplevel:t}"
    home="$repo_name"
  fi

  if [[ -n "$home" ]]; then
    local current_nesting="${current_directory//[^\/]}"
    local repo_nesting="${git_toplevel//[^\/]}"
    local diff=$(( ${#current_nesting} - ${#repo_nesting} ))
    if [[ $diff -eq 1 ]]; then
      echo "$home/"
    else
      echo "$home/.../"
    fi
  else
    echo ""
  fi
}

# Real rebase/merge/cherry-pick/bisect detection via git-dir state files —
# accurate per-worktree (each linked worktree has its own git-dir, so its
# own independent rebase-merge/rebase-apply/MERGE_HEAD state), unlike the
# `## HEAD (no branch)` string-sniffing which also fires on plain detached
# HEAD (the normal case for a worktree pinned to a commit/tag).
git_in_progress_state() {
  local git_dir="$1"
  [[ -z "$git_dir" ]] && return

  if [[ -d "$git_dir/rebase-merge" || -d "$git_dir/rebase-apply" ]]; then
    echo "rebasing"
  elif [[ -f "$git_dir/MERGE_HEAD" ]]; then
    echo "merging"
  elif [[ -f "$git_dir/CHERRY_PICK_HEAD" ]]; then
    echo "cherry-picking"
  elif [[ -f "$git_dir/BISECT_LOG" ]]; then
    echo "bisecting"
  fi
}

git_status_summary() {
  local git_dir="$1"
  local status_response
  status_response=$(command git status --porcelain -b 2>/dev/null)

  local status_display=""
  local in_progress
  in_progress="$(git_in_progress_state "$git_dir")"

  if [[ -n "$in_progress" ]]; then
    status_display=" %F{$colors[git_rebasing]}$in_progress"
  else
    if grep -qE "^(A|M|D). " <<< "$status_response" 2>/dev/null; then
      status_display+=" %F{$colors[git_status_staged]}+"
    fi

    if grep -q "^?? " <<< "$status_response" 2>/dev/null; then
      status_display+=" %F{$colors[git_status_new]}?"
    fi

    if grep -q "^.M " <<< "$status_response" 2>/dev/null; then
      status_display+=" %F{$colors[git_status_modified]}!"
    fi

    if grep -q "^R. " <<< "$status_response" 2>/dev/null; then
      status_display+=" %F{$colors[git_status_renamed]}»"
    fi

    if grep -q "^.D " <<< "$status_response" 2>/dev/null; then
      status_display+=" %F{$colors[git_status_deleted]}—"
    fi

    if grep -q "^UU " <<< "$status_response" 2>/dev/null; then
      status_display+=" %F{$colors[git_status_unmerged]}#"
    fi

    local is_ahead=false is_behind=false
    grep -q "^## .*ahead" <<< "$status_response" 2>/dev/null && is_ahead=true
    grep -q "^## .*behind" <<< "$status_response" 2>/dev/null && is_behind=true

    if [[ "$is_ahead" == true && "$is_behind" == true ]]; then
      status_display+=" %F{$colors[git_status_diverged]}~"
    elif [[ "$is_ahead" == true ]]; then
      status_display+=" %F{$colors[git_status_ahead]}|•"
    elif [[ "$is_behind" == true ]]; then
      status_display+=" %F{$colors[git_status_behind]}•|"
    fi

    local stash_count
    stash_count=$(command git rev-list --walk-reflogs --count refs/stash 2>/dev/null)
    if [[ -n "$stash_count" && "$stash_count" -gt 0 ]]; then
      status_display+=" %F{$colors[git_status_stash]}\$"
    fi
  fi

  echo "$status_display"
}
