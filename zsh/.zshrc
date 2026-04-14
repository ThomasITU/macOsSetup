# FZF, fuzzy find
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

export FZF_DEFAULT_OPTS="
  --height 40%
  --layout=reverse
  --info=inline
"

stty -ixon

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

# Backlog.md setup
fpath=($HOME/.zsh/completions $fpath)
autoload -Uz compinit && compinit

# Aliases
alias ll="ls -la"
alias gs="git status"
alias v="nvim"
alias gaa="git add ."
alias gc="git commit -m"
alias gca="git commit -am"

# Docker: allow both old (docker-compose) and new (docker compose) notation
alias docker-compose="docker-compose"

# Environment variables
# Created by `pipx` on 2026-02-23 15:24:13
export PATH="$PATH:$HOME/.local/bin"

export OLLAMA_HOST=0.0.0.0:8000
export OLLAMA_FLASH_ATTENTION=1
export OLLAMA_KV_CACHE_TYPE=q8_0
export OLLAMA_CONTEXT_LENGTH=256000

# For Local Agentic work
# export ANTHROPIC_BASE_URL="http://localhost:8000"
# export CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1

# Homebrew
eval "$(/opt/homebrew/bin/brew shellenv)"

