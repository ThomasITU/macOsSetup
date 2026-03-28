# Homebrew
eval "$(/opt/homebrew/bin/brew shellenv)"

# FZF
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

export FZF_DEFAULT_OPTS="
  --height 40%
  --layout=reverse
  --info=inline
"

stty -ixon

# Aliases
alias ll="ls -la"
alias gs="git status"
alias v="nvim"

# Machine-specific overrides (not tracked in git)
[ -f ~/.zshrc.local ] && source ~/.zshrc.local
