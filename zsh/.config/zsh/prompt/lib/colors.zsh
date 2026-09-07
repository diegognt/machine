# colors.zsh — color palette for the prompt
# Pure zsh, no external dependencies.
#
# Two env vars allow overriding colors without touching this file:
#   PROMPT_COLOR_MAPPINGS="primary:#ff00ff;notice:yellow"
#   PROMPT_COLORS="git_branch:cyan;symbol_error:9"

declare -Ag color_mappings=(
  "foreground"      "default"
  "primary"         "magenta"
  "secondary"       "blue"
  "notice"          "yellow"
  "accent"          "default"

  "info_positive"   "green"
  "info_negative"   "red"
  "info_neutral_1"  "yellow"
  "info_neutral_2"  "blue"
  "info_special"    "cyan"
)

if [[ $PROMPT_COLOR_MAPPINGS =~ ^[#_0-9a-zA-Z]+:[#_0-9a-zA-Z]+(\;[#_0-9a-zA-Z]+:[#_0-9a-zA-Z]+)*$ ]]; then
  color_mapping_values=($(echo $PROMPT_COLOR_MAPPINGS | tr ";" "\n"))
  for color_mapping_value in $color_mapping_values; do
    color_mapping_definition=($(echo $color_mapping_value | tr ":" "\n"))
    color_mappings[$color_mapping_definition[1]]=$color_mapping_definition[2]
  done
elif [[ -n $PROMPT_COLOR_MAPPINGS ]]; then
  echo "PROMPT_COLOR_MAPPINGS is not formatted correctly.
Format it like so: \"value:#009090;value:red\", etc."
fi

declare -Ag colors=(
  "prompt"              $color_mappings[foreground]
  "current_directory"   $color_mappings[primary]
  "symbol"              $color_mappings[secondary]
  "symbol_root"         $color_mappings[notice]

  "arrow"                 $color_mappings[accent]
  "right_prompt_prefix"   $color_mappings[accent]
  "left_prompt_prefix"    $color_mappings[accent]
  "virtual_env"           $color_mappings[accent]

  "symbol_error"   $color_mappings[info_negative]
  "error_code"     $color_mappings[info_negative]

  "host_user_connector"   $color_mappings[accent]
  "host"                  $color_mappings[info_neutral_1]
  "user"                  $color_mappings[info_neutral_1]

  "git_branch"             $color_mappings[primary]
  "git_worktree"           $color_mappings[info_special]
  "git_rebasing"           $color_mappings[primary]
  "git_status_deleted"     $color_mappings[info_negative]
  "git_status_staged"      $color_mappings[info_positive]
  "git_status_stash"       $color_mappings[info_neutral_1]
  "git_status_modified"    $color_mappings[info_neutral_1]
  "git_status_new"         $color_mappings[info_neutral_2]
  "git_status_diverged"    $color_mappings[info_neutral_2]
  "git_status_ahead"       $color_mappings[info_neutral_2]
  "git_status_behind"      $color_mappings[info_neutral_2]
  "git_status_renamed"     $color_mappings[info_special]
  "git_status_unmerged"    $color_mappings[info_special]
)

if [[ $PROMPT_COLORS =~ ^[#_0-9a-zA-Z]+:[#_0-9a-zA-Z]+(\;[#_0-9a-zA-Z]+:[#_0-9a-zA-Z]+)*$ ]]; then
  color_values=($(echo $PROMPT_COLORS | tr ";" "\n"))
  for color_value in $color_values; do
    color_value_definition=($(echo $color_value | tr ":" "\n"))
    colors[$color_value_definition[1]]=$color_value_definition[2]
  done
elif [[ -n $PROMPT_COLORS ]]; then
  echo "PROMPT_COLORS is not formatted correctly.
Format it like so: \"value:#009090;value:red\", etc."
fi
