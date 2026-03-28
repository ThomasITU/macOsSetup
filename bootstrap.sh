#!/usr/bin/env bash
set -euo pipefail

echo "🚀 Bootstrapping macOS development environment..."

#############################################
# Install Homebrew if missing
#############################################
if ! command -v brew &>/dev/null; then
  echo "🍺 Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  eval "$(/opt/homebrew/bin/brew shellenv)" || true
else
  echo "✅ Homebrew already installed"
fi

#############################################
# Install packages from Brewfile
#############################################
echo "📦 Installing packages from Brewfile..."
brew bundle --file=./Brewfile

#############################################
# Create config directories
#############################################
mkdir -p ~/.config/nvim
mkdir -p ~/.claude/hooks
mkdir -p ~/.hammerspoon

#############################################
# Symlink configs (safe + idempotent)
#############################################
link_file () {
  local src="$1"
  local dest="$2"

  if [ -L "$dest" ]; then
    local current_target
    current_target=$(readlink "$dest")
    if [ "$current_target" = "$src" ]; then
      echo "🔗 $dest already symlinked"
    else
      echo "🔄 Updating symlink $dest"
      ln -sf "$src" "$dest"
    fi
  elif [ -e "$dest" ]; then
    echo "⚠️  Backing up existing $dest"
    mv "$dest" "$dest.backup.$(date +%s)"
    ln -s "$src" "$dest"
  else
    ln -s "$src" "$dest"
    echo "🔗 Linked $dest"
  fi
}

echo "🔗 Linking config files..."

REPO_DIR="$(cd "$(dirname "$0")" && pwd -P)"

link_file "$REPO_DIR/nvim/init.lua" "$HOME/.config/nvim/init.lua"
link_file "$REPO_DIR/tmux/.tmux.conf" "$HOME/.tmux.conf"
link_file "$REPO_DIR/zsh/.zshrc" "$HOME/.zshrc"
link_file "$REPO_DIR/hammerspoon/init.lua" "$HOME/.hammerspoon/init.lua"
link_file "$REPO_DIR/claude/CLAUDE.md" "$HOME/.claude/CLAUDE.md"
link_file "$REPO_DIR/claude/settings.json" "$HOME/.claude/settings.json"
link_file "$REPO_DIR/claude/hooks/sounds" "$HOME/.claude/hooks/sounds"
link_file "$REPO_DIR/claude/hooks/parse_hook.sh" "$HOME/.claude/hooks/parse_hook.sh"
link_file "$REPO_DIR/claude/hooks/notification_notify.sh" "$HOME/.claude/hooks/notification_notify.sh"
link_file "$REPO_DIR/claude/hooks/stop_notify.sh" "$HOME/.claude/hooks/stop_notify.sh"

#############################################
# Install fzf keybindings (if not present)
#############################################
if [ ! -f ~/.fzf.zsh ]; then
  $(brew --prefix)/opt/fzf/install --key-bindings --completion --no-bash --no-fish
fi

#############################################
# Install Neovim plugins
#############################################
echo "⚙️ Installing Neovim plugins..."
nvim --headless "+Lazy! sync" +qa || true

#############################################
# Launch GUI apps once
#############################################
open -g -a Rectangle || true
open -g -a "Scroll Reverser" || true

echo "🎉 Bootstrap complete."
