# Prompt scenarios

This document describes how `prompt.zsh` renders in the different situations
it's designed to handle, especially around `git worktree`. All examples use
the `singleline` layout (`PROMPT_LAYOUT=singleline`, the default in this
repo's `.zshrc`): `PROMPT` on the left, `RPROMPT` on the right, in the form

```
<symbol> <RPROMPT: dir -> branch [tags] status>
```

Placeholders used below:

- `<repo>`      — the repository/project name (derived from git's common-dir)
- `<dir>`       — the actual current directory name (`%c`)
- `<branch>`    — the checked-out branch (or `➦ <sha>` when detached)
- `<worktree>`  — git's internal worktree identifier (from `.git/worktrees/<name>`)

---

## 1. Not inside a git repository

No git segment at all — just the directory.

```
❯ /tmp
```

## 2. Plain repo, no worktrees

Standard case, single clone, no `git worktree` involved. Directory name and
branch are shown as usual; no worktree tag is possible since there's only one
checkout.

```
❯ my-project -> main
```

With changes:

```
❯ my-project -> main ? !
```
(`?` untracked, `!` modified — see [Status markers](#5-status-markers))

## 3. Worktree root, directory name matches the branch (common case)

This is the typical result of a "bare repo + one worktree per branch" layout
(e.g. `git worktree add ../feature-x feature-x`), or any layout where the
worktree folder is simply named after its branch. At the **root** of the
worktree, repeating the branch as the directory name would be redundant
(`main -> main`), so the directory side shows the **repo name** instead:

```
❯ <repo> -> <branch>
```

Example, standing in `~/.machine/main` (branch `main`, part of the
`~/.machine/.bare` hub):

```
❯ .machine -> main
```

Example, standing in `~/.machine/zsh-prompt` (branch `zsh-prompt`):

```
❯ .machine -> zsh-prompt
```

No worktree tag is shown — the directory name and branch already agree, so
there's nothing extra to flag.

This substitution only fires at the worktree's top-level directory. Moving
into a subdirectory reveals the real directory name again (see scenario 4).

## 4. Inside a subdirectory of a worktree

Once you're below the worktree root, the directory side goes back to showing
the real, current directory name — the repo-name substitution from scenario 3
only applies exactly at the worktree root.

```
❯ <dir> -> <branch>
```

Example, inside `~/.machine/zsh-prompt/zsh`:

```
❯ zsh -> zsh-prompt
```

## 5. Worktree checked out to a different branch than its name

You can always `git checkout <other-branch>` inside an existing worktree.
When that happens, the directory name no longer matches the branch, so:

- the directory side shows the **real directory name** again (no repo-name
  substitution — it's no longer redundant)
- a bracketed tag `[<worktree>]` appears next to the branch, telling you which
  worktree slot you're physically standing in

```
❯ <dir>[<worktree>] -> <branch>
```

Example: inside the `zsh-prompt` worktree, after `git checkout other-branch`:

```
❯ zsh-prompt[zsh-prompt]-> other-branch
```

This is the important safety net: without the tag, seeing `other-branch`
alone gives no hint that the folder is normally associated with a different
branch.

## 6. Worktree directory manually renamed (`mv`, not `git worktree move`)

Git's own worktree identifier (stored at creation time under
`.git/worktrees/<name>`) doesn't follow a plain `mv`/`rename` of the folder.
Both the current directory name and the branch stay accurate; the bracket tag
now shows git's *original* worktree id, which may no longer match anything
visible on disk — a useful hint that `git worktree repair`/`git worktree
move` might be worth running.

```
❯ <dir>[<original-worktree-id>] -> <branch>
```

Example: worktree created as `wt-abc` (branch `feature-x`), later renamed on
disk to `wt-renamed`:

```
❯ wt-renamed[wt-abc] -> feature-x
```

## 7. Worktree name is a slug/leaf variant of the branch (no tag shown)

Because branch names can contain `/`, which isn't valid in a single path
segment, worktree directories are often named using either a slash → dash
slug, or just the branch's leaf segment. Both are recognized as "matching"
and suppress the tag, same as an exact match:

| Branch          | Worktree dir      | Tag shown? |
|-----------------|--------------------|------------|
| `feature/foo`   | `feature-foo`      | No         |
| `feature/foo`   | `foo`              | No         |
| `feature/foo`   | `something-else`   | Yes: `[something-else]` |

Example (slug):

```
❯ .machine -> feature/foo
```

Example (genuine mismatch):

```
❯ .machine -> feature/foo [something-else]
```

## 8. Detached HEAD

Common right after `git worktree add <path> <commit-or-tag>`, or any manual
`git checkout <sha>`. Shown as an arrow + short SHA instead of a branch name.

```
❯ <dir> -> ➦ <short-sha>
```

Example:

```
❯ .machine -> ➦ bfa014d
```

If the worktree name doesn't match this synthetic "branch", the bracket tag
still applies:

```
❯ zsh-prompt -> ➦ bfa014d [zsh-prompt]
```

## 9. Rebase / merge / cherry-pick / bisect in progress

Detected from real state files inside the worktree's own git-dir (not from
detached-HEAD guessing), so it's accurate per-worktree — two worktrees can be
in different states at the same time.

```
❯ <dir> -> <branch> rebasing
❯ <dir> -> <branch> merging
❯ <dir> -> <branch> cherry-picking
❯ <dir> -> <branch> bisecting
```

Example:

```
❯ rebase-test -> ➦ 3132295 rebasing
```

## 10. Status markers

Appended after the branch/tag segment, space-separated, each in its own
color:

| Marker | Meaning              |
|--------|----------------------|
| `+`    | staged changes       |
| `?`    | untracked files      |
| `!`    | modified files       |
| `»`    | renamed files        |
| `—`    | deleted files        |
| `#`    | unmerged (conflicts) |
| `~`    | diverged from upstream |
| <code>&#124;•</code> | ahead of upstream |
| <code>•&#124;</code> | behind upstream |
| `$`    | stash present        |

Example, several at once:

```
❯ .machine -> zsh-prompt ? ! $
```

## 11. Hiding the worktree tag entirely

Set `PROMPT_HIDE_WORKTREE=true` to always suppress the bracketed tag, even
when directory and branch diverge:

```
❯ zsh-prompt -> other-branch
```

## Configuration quick reference

See the header of `prompt.zsh` for the full list. Worktree-related knobs:

- `PROMPT_HIDE_WORKTREE` — `true` to never show the `[<worktree>]` tag
- `PROMPT_WORKTREE_BRACKET_OPEN` / `PROMPT_WORKTREE_BRACKET_CLOSE` — characters
  wrapping the worktree name, default `[` and `]`
