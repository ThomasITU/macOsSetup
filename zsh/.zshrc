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

# Export the shell's TTY so child processes (e.g. Claude Code hooks) can write to it
export SHELL_TTY=$(tty 2>/dev/null)

# VS Code: name each terminal by TTY ID and reset it after every command
# (Claude hooks rename the tab; this restores it when Claude exits)
if [[ "$TERM_PROGRAM" == "vscode" || "$TERM_PROGRAM" == "vscode-insiders" ]]; then
  _tty_num="${SHELL_TTY##*/}"
  _vscode_reset_title() { printf '\033]0;%s\007' "$_tty_num" }
  precmd_functions+=(_vscode_reset_title)
fi

# Machine-specific overrides (not tracked in git)
[ -f ~/.zshrc.local ] && source ~/.zshrc.local
