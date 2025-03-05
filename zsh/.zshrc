setopt histignorealldups sharehistory

# Use emacs keybindings even if our EDITOR is set to vi
bindkey -e

# Keep 1000 lines of history within the shell and save it to ~/.zsh_history:
HISTSIZE=1000
SAVEHIST=1000
HISTFILE=~/.zsh_history

# Use modern completion system
autoload -Uz compinit
compinit

zstyle ':completion:*' auto-description 'specify: %d'
zstyle ':completion:*' completer _expand _complete _correct _approximate
zstyle ':completion:*' format 'Completing %d'
zstyle ':completion:*' group-name ''
zstyle ':completion:*' menu select=2
zstyle ':completion:*:default' list-colors ${(s.:.)LS_COLORS}
zstyle ':completion:*' list-colors ''
zstyle ':completion:*' list-prompt %SAt %p: Hit TAB for more, or the character to insert%s
zstyle ':completion:*' matcher-list '' 'm:{a-z}={A-Z}' 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=* l:|=*'
zstyle ':completion:*' menu select=long
zstyle ':completion:*' select-prompt %SScrolling active: current selection at %p%s
zstyle ':completion:*' use-compctl false
zstyle ':completion:*' verbose true

zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#)*=0=01;31'
zstyle ':completion:*:kill:*' command 'ps -u $USER -o pid,%cpu,tty,cputime,cmd'

# Completions
fpath+=${ZDOTDIR:-~}/.zsh_functions

# Editor
export EDITOR='nvim'
export VISUAL='nvim'

# fnm
FNM_PATH="$HOME/.local/share/fnm"
if [ -d "$FNM_PATH" ]; then
  export PATH="$HOME/.local/share/fnm:$PATH"
  eval "`fnm env`"
fi

# Exporting local Binaries
export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$PATH"

# Sourcing scripts
source $HOME/.config/zsh/scripts.zsh

# Pyenv
export PYENV_ROOT="$HOME/.pyenv"
command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"
eval "$(pyenv virtualenv-init -)"

# Prompt theme
fpath+=$HOME/.zsh/typewritten
autoload -U promptinit; promptinit
prompt typewritten

#Customs
export TYPEWRITTEN_PROMPT_LAYOUT="singleline"

if [[ "$(uname)" == "Darwin" ]]; then
    # ZSH Highlighting
    source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

    # ZSH autosuggestions
    source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh# ZSH autosuggestions

elif [[ "$(uname)" == "Linux" ]]; then
    # ZSH autosuggestions
    source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh

    # ZSH Highlighting
    source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
fi
