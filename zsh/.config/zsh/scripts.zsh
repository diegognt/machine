#!/bin/zsh

# Removes all the "node_module" folder in a recursive way in all the subfolder,
# In addition, show the removed folders path
#  ────────────────── Explanation ──────────────────
#
# ○ find is used to list files.
#   ◆ -name "node_modules" stipulates that we search for files named node_modules.
#   ◆ -type d stipulates that we search for directories.
#   ◆ -prune stipulates that we do not descend into the directories we find.
#   ◆ -exec rm -rf '{}' + executes the command rm -rf '{}' for each file found.
#     ◇ rm is used to remove files.
#       ▪ -r means we remove directories recursively.
#       ▪ -f means we do not ask for confirmation.
#     ◇ '{}' is replaced by the file name.
#     ◇ + means that we pass multiple file names to each invocation of rm.
#   ◆ -print prints the file names to the terminal.

remove-node-modules () {
  find . -name "node_modules" -type d -prune -exec rm -rf '{}' + -print;
}

