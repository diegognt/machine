# prompt.zsh — a minimal, informative zsh prompt written in pure zsh
# Based on the layout/feature-set of "typewritten" (https://github.com/reobin/typewritten)
# but reimplemented without the zsh-async dependency: git info is refreshed
# synchronously on precmd, which is fast enough for typical repos and keeps
# this prompt dependency-free (pure zsh builtins + git). No naming prefix is
# used; everything lives in its own sourced files to limit collision risk,
# but if you already have functions/vars named e.g. `colors`, `git_branch`,
# `redraw`, etc. in your zshrc, rename accordingly.
#
# Enable with:
#   source ~/.config/zsh/prompt/prompt.zsh
#
# Configuration (all optional), same spirit as typewritten:
#   PROMPT_LAYOUT             singleline | singleline_verbose | pure | pure_verbose | half_pure | multiline
#   PROMPT_SYMBOL             prompt symbol, default "❯"
#   PROMPT_ARROW_SYMBOL       arrow between wd and git info, default "->"
#   PROMPT_RELATIVE_PATH      "" | home | git | adaptive
#   PROMPT_DISABLE_RETURN_CODE  true to hide the last exit code
#   PROMPT_CURSOR             block | beam | terminal
#   PROMPT_LEFT_PREFIX / PROMPT_LEFT_PREFIX_FUNCTION
#   PROMPT_RIGHT_PREFIX / PROMPT_RIGHT_PREFIX_FUNCTION
#   PROMPT_COLORS / PROMPT_COLOR_MAPPINGS   see lib/colors.zsh
#   PROMPT_HIDE_WORKTREE      true to hide the linked-worktree tag
#   PROMPT_WORKTREE_BRACKET_OPEN / PROMPT_WORKTREE_BRACKET_CLOSE
#                             characters wrapping the worktree name, default "[" "]"

export PROMPT_ROOT=${0:A:h}

source "$PROMPT_ROOT/lib/colors.zsh"
source "$PROMPT_ROOT/lib/git.zsh"

typeset -g PROMPT_BREAK_LINE="
"

prompt_symbol="❯"
if [[ -n "$PROMPT_SYMBOL" ]]; then
  prompt_symbol="$PROMPT_SYMBOL"
fi

base_symbol_color="%F{$colors[symbol]}"
if [[ $(id -u) -eq 0 ]]; then
  base_symbol_color="%F{$colors[symbol_root]}"
fi

prompt_color="%(?,$base_symbol_color,%F{$colors[symbol_error]})"
return_code="%(?,,%F{$colors[error_code]}%? )"
if [[ "$PROMPT_DISABLE_RETURN_CODE" == true ]]; then
  prompt_color="$base_symbol_color"
  return_code=""
fi

user_host="%F{$colors[host]}%n%F{$colors[host_user_connector]}@%F{$colors[user]}%m"
prompt_line="$prompt_color$return_code$prompt_symbol %F{$colors[prompt]}"

current_directory_color="$colors[current_directory]"
git_branch_color="$colors[git_branch]"

arrow_symbol="->"
if [[ -n "$PROMPT_ARROW_SYMBOL" ]]; then
  arrow_symbol="$PROMPT_ARROW_SYMBOL"
fi
arrow="%F{$colors[arrow]}$arrow_symbol"

worktree_bracket_open="["
if [[ -n "$PROMPT_WORKTREE_BRACKET_OPEN" ]]; then
  worktree_bracket_open="$PROMPT_WORKTREE_BRACKET_OPEN"
fi

worktree_bracket_close="]"
if [[ -n "$PROMPT_WORKTREE_BRACKET_CLOSE" ]]; then
  worktree_bracket_close="$PROMPT_WORKTREE_BRACKET_CLOSE"
fi

get_virtual_env() {
  if [[ -z $VIRTUAL_ENV_DISABLE_PROMPT ]]; then
    local virtual_env=""
    if [[ -n $VIRTUAL_ENV ]]; then
      virtual_env="($(basename $VIRTUAL_ENV)) "
    elif [[ -n $CONDA_PROMPT_MODIFIER ]]; then
      virtual_env="$(basename $CONDA_PROMPT_MODIFIER)"
    fi

    if [[ -n $virtual_env ]]; then
      echo "%F{$colors[virtual_env]}$virtual_env"
    fi
  fi
}

get_displayed_wd() {
  local branch=$prompt_data[git_branch]
  local home=$prompt_data[git_home]
  local toplevel=$prompt_data[git_toplevel]
  local worktree=$prompt_data[git_worktree]

  local home_relative_wd="%~"
  local leaf="%c"

  # At the root of a worktree whose directory name just repeats the branch
  # already shown in the git segment (e.g. "main -> main", the common case
  # in worktree-per-branch layouts), show the repo/project name instead —
  # it actually adds information ("which repo am I in") rather than
  # repeating what's already displayed.
  if [[ -n "$toplevel" && "$PWD" == "$toplevel" ]]; then
    local dir_name="${PWD:t}"
    if worktree_matches_branch "$dir_name" "$branch" && [[ -n "$prompt_data[git_repo_name]" ]]; then
      leaf="$prompt_data[git_repo_name]"
    fi
  fi

  # Linked worktrees (plain `git worktree add`, or bare-repo layouts like
  # ~/.machine/.bare + worktrees) get a bracketed tag attached to the
  # directory segment, since the worktree directory name/id can differ from
  # the checked-out branch. When they effectively match (exact, slash->dash
  # slug, or leaf segment — the common worktree-naming conventions), the
  # tag is redundant and skipped.
  local worktree_tag=""
  if [[ -n "$worktree" && "$PROMPT_HIDE_WORKTREE" != true ]] \
     && ! worktree_matches_branch "$worktree" "$branch"; then
    worktree_tag="%F{$colors[git_worktree]}$worktree_bracket_open$worktree$worktree_bracket_close%F{$current_directory_color}"
  fi

  local git_relative_wd="$home$leaf$worktree_tag"

  local displayed_wd="$git_relative_wd"

  if [[ "$PROMPT_LAYOUT" == pure* && -z "$PROMPT_RELATIVE_PATH" ]]; then
    displayed_wd=$home_relative_wd
  fi

  if [[ "$PROMPT_RELATIVE_PATH" == "home" ]]; then
    displayed_wd=$home_relative_wd
  fi

  if [[ "$PROMPT_RELATIVE_PATH" == "adaptive" ]]; then
    if [[ -z "$branch" ]]; then
      displayed_wd=$home_relative_wd
    fi
  fi

  echo "%F{$current_directory_color}$displayed_wd"
}

get_left_prefix() {
  local prefix=""

  if [[ -n $PROMPT_LEFT_PREFIX || -n $PROMPT_LEFT_PREFIX_FUNCTION ]]; then
    prefix="%F{$colors[left_prompt_prefix]}"
  fi

  if [[ -n $PROMPT_LEFT_PREFIX ]]; then
    prefix="$prefix$PROMPT_LEFT_PREFIX "
  fi

  if [[ -n $PROMPT_LEFT_PREFIX_FUNCTION ]]; then
    local value
    value=$($PROMPT_LEFT_PREFIX_FUNCTION 2>/dev/null)
    if [[ -n $value ]]; then
      prefix="$prefix$value "
    fi
  fi

  echo $prefix
}

get_right_prefix() {
  local prefix=""

  if [[ -n $PROMPT_RIGHT_PREFIX || -n $PROMPT_RIGHT_PREFIX_FUNCTION ]]; then
    prefix="%F{$colors[right_prompt_prefix]}"
  fi

  if [[ -n $PROMPT_RIGHT_PREFIX ]]; then
    prefix="$prefix$PROMPT_RIGHT_PREFIX "
  fi

  if [[ -n $PROMPT_RIGHT_PREFIX_FUNCTION ]]; then
    local value
    value=$($PROMPT_RIGHT_PREFIX_FUNCTION 2>/dev/null)
    if [[ -n $value ]]; then
      prefix="$prefix$value "
    fi
  fi

  echo $prefix
}

redraw() {
  local displayed_wd="$(get_displayed_wd)"
  local full_prompt="$(get_virtual_env)$(get_left_prefix)$prompt_line"

  local layout="$PROMPT_LAYOUT"

  # The worktree tag now lives on the directory segment (see
  # get_displayed_wd); the git segment itself is just branch + status.
  local git_info="$prompt_data[git_branch]$prompt_data[git_status]"

  if [[ "$layout" == "half_pure" ]]; then
    PROMPT="$PROMPT_BREAK_LINE%F{$git_branch_color}$git_info$PROMPT_BREAK_LINE$full_prompt"
    RPROMPT="$(get_right_prefix)$displayed_wd"
  else
    local git_arrow_info=""
    if [[ -n "$git_info" ]]; then
      git_arrow_info=" $arrow %F{$git_branch_color}$git_info"
    fi

    local right_prefix="$(get_right_prefix)"

    PROMPT="$full_prompt"
    RPROMPT="$right_prefix$displayed_wd$git_arrow_info"

    if [[ "$layout" == "pure" ]]; then
      PROMPT="$PROMPT_BREAK_LINE$displayed_wd$git_arrow_info$PROMPT_BREAK_LINE$full_prompt"
      RPROMPT=""
    fi

    if [[ "$layout" == "pure_verbose" ]]; then
      PROMPT="$PROMPT_BREAK_LINE$user_host $displayed_wd$git_arrow_info$PROMPT_BREAK_LINE$full_prompt"
      RPROMPT=""
    fi

    if [[ "$layout" == "singleline_verbose" ]]; then
      PROMPT="$user_host $full_prompt"
      RPROMPT="$right_prefix$displayed_wd$git_arrow_info"
    fi

    if [[ "$layout" == "multiline" ]]; then
      PROMPT="$PROMPT_BREAK_LINE$user_host$PROMPT_BREAK_LINE$full_prompt"
      RPROMPT="$right_prefix$displayed_wd$git_arrow_info"
    fi
  fi
}

update_git_info() {
  typeset -gA prompt_data

  local current_pwd="$PWD"
  local git_hide_status
  git_hide_status="$(git config --get oh-my-zsh.hide-status 2>/dev/null)"

  if [[ "$git_hide_status" != "1" ]]; then
    if ! git_fetch_info; then
      prompt_data[git_home]=
      prompt_data[current_pwd]="$current_pwd"
      return
    fi

    local git_toplevel="$prompt_data[git_toplevel]"

    if [[ "$PROMPT_RELATIVE_PATH" == "git" || "$PROMPT_RELATIVE_PATH" == "adaptive" ]]; then
      prompt_data[git_home]="$(git_home $current_pwd $git_toplevel)"
    else
      prompt_data[git_home]=
    fi

    prompt_data[current_pwd]="$current_pwd"
    prompt_data[git_status]="$(git_status_summary "$prompt_data[git_dir]")"
  else
    prompt_data[git_branch]=
    prompt_data[git_worktree]=
    prompt_data[git_status]=
  fi
}

prompt_precmd() {
  update_git_info
  redraw
}

# prompt cursor fix when exiting vim
prompt_fix_cursor() {
  local cursor="\e[3 q"
  if [[ "$PROMPT_CURSOR" == "block" ]]; then
    cursor="\e[1 q"
  elif [[ "$PROMPT_CURSOR" == "beam" ]]; then
    cursor="\e[5 q"
  fi
  echo -ne "$cursor"
}

prompt_setup() {
  autoload -Uz add-zsh-hook
  if [[ "$PROMPT_CURSOR" != "terminal" ]]; then
    add-zsh-hook precmd prompt_fix_cursor
  fi
  add-zsh-hook precmd prompt_precmd

  PROMPT="$prompt_line"
}
prompt_setup

zle_highlight=( default:fg=$colors[prompt] )
