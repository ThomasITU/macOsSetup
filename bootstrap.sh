#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")" && pwd -P)"

#############################################
# Feature selection
#############################################
echo "Select features to install:"
echo ""
echo "  1) Core       — zsh, git, fzf, Homebrew packages"
echo "  2) Neovim     — config + plugins"
echo "  3) Tmux       — config"
echo "  4) Hammerspoon — window/keyboard automation"
echo "  5) Claude     — hooks, notifications, prompt approval"
echo "  6) VS Code    — Claude terminal focus extension"
echo "  7) GUI apps   — Rectangle, Scroll Reverser"
echo "  A) All"
echo ""
read -rp "Enter choices (e.g. 1235 or A): " choices

if [[ "$choices" == *"A"* || "$choices" == *"a"* ]]; then
  choices="1234567"
fi

has() { [[ "$choices" == *"$1"* ]]; }

#############################################
# Install Homebrew if missing
#############################################
if ! command -v brew &>/dev/null; then
  echo "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  eval "$(/opt/homebrew/bin/brew shellenv)" || true
fi

#############################################
# Core packages
#############################################
if has 1; then
  echo "Installing core packages..."
  brew install git fzf node python shfmt

  mkdir -p ~/.config

  link_file () {
    local src="$1" dest="$2"
    if [ -L "$dest" ]; then
      local current_target
      current_target=$(readlink "$dest")
      if [ "$current_target" = "$src" ]; then
        return
      fi
    elif [ -e "$dest" ]; then
      mv "$dest" "$dest.backup.$(date +%s)"
    fi
    ln -sf "$src" "$dest"
    echo "  Linked $dest"
  }

  link_file "$REPO_DIR/zsh/.zshrc" "$HOME/.zshrc"

  # Install fzf keybindings
  if [ ! -f ~/.fzf.zsh ]; then
    "$(brew --prefix)/opt/fzf/install" --key-bindings --completion --no-bash --no-fish
  fi
fi

# Make link_file available for other sections
link_file () {
  local src="$1" dest="$2"
  if [ -L "$dest" ]; then
    local current_target
    current_target=$(readlink "$dest")
    if [ "$current_target" = "$src" ]; then
      return
    fi
  elif [ -e "$dest" ]; then
    mv "$dest" "$dest.backup.$(date +%s)"
  fi
  ln -sf "$src" "$dest"
  echo "  Linked $dest"
}

#############################################
# Neovim
#############################################
if has 2; then
  echo "Setting up Neovim..."
  brew install neovim
  mkdir -p ~/.config/nvim
  link_file "$REPO_DIR/nvim/init.lua" "$HOME/.config/nvim/init.lua"
  nvim --headless "+Lazy! sync" +qa 2>/dev/null || true
fi

#############################################
# Tmux
#############################################
if has 3; then
  echo "Setting up Tmux..."
  brew install tmux
  link_file "$REPO_DIR/tmux/.tmux.conf" "$HOME/.tmux.conf"
fi

#############################################
# Hammerspoon
#############################################
if has 4; then
  echo "Setting up Hammerspoon..."
  brew install --cask hammerspoon
  mkdir -p ~/.hammerspoon
  link_file "$REPO_DIR/hammerspoon/init.lua" "$HOME/.hammerspoon/init.lua"
fi

#############################################
# Claude Code hooks & notifications
#############################################
if has 5; then
  echo "Setting up Claude hooks..."
  mkdir -p ~/.claude/hooks
  link_file "$REPO_DIR/claude/CLAUDE.md" "$HOME/.claude/CLAUDE.md"
  link_file "$REPO_DIR/claude/settings.json" "$HOME/.claude/settings.json"
  link_file "$REPO_DIR/claude/hooks/sounds" "$HOME/.claude/hooks/sounds"
  link_file "$REPO_DIR/claude/hooks/parse_hook.sh" "$HOME/.claude/hooks/parse_hook.sh"
  link_file "$REPO_DIR/claude/hooks/notification_notify.sh" "$HOME/.claude/hooks/notification_notify.sh"
  link_file "$REPO_DIR/claude/hooks/stop_notify.sh" "$HOME/.claude/hooks/stop_notify.sh"
  link_file "$REPO_DIR/claude/hooks/session_start.sh" "$HOME/.claude/hooks/session_start.sh"

  # Sync custom skills
  mkdir -p ~/.claude/skills
  for skill_dir in "$REPO_DIR"/claude/skills/*/; do
    skill_dir="${skill_dir%/}"
    skill_name="$(basename "$skill_dir")"
    link_file "$skill_dir" "$HOME/.claude/skills/$skill_name"
  done

  # Install graphify CLI
  if ! command -v graphify &>/dev/null; then
    echo "  Installing graphify..."
    if command -v uv &>/dev/null; then
      uv tool install graphifyy
    elif [ -x "$HOME/.local/bin/uv" ]; then
      "$HOME/.local/bin/uv" tool install graphifyy
    else
      pip3 install --user graphifyy
    fi
  fi

  echo "  Note: Claude hooks require Hammerspoon (option 4) for terminal notifications."
fi

#############################################
# VS Code extension
#############################################
if has 6; then
  echo "Setting up VS Code Claude terminal focus extension..."
  VSCODE_EXT_DIR="$HOME/.vscode/extensions/claude-terminal-focus"
  mkdir -p "$VSCODE_EXT_DIR"
  cp "$REPO_DIR/vscode/claude-terminal-focus/package.json" "$VSCODE_EXT_DIR/"
  cp "$REPO_DIR/vscode/claude-terminal-focus/extension.js" "$VSCODE_EXT_DIR/"
  echo "  Installed to $VSCODE_EXT_DIR"
  echo "  Restart VS Code to activate."
  echo "  Recommended VS Code setting: \"terminal.integrated.tabs.title\": \"\${sequence}\""
fi

#############################################
# GUI apps
#############################################
if has 7; then
  echo "Installing GUI apps..."
  brew install --cask rectangle scroll-reverser ghostty
  open -g -a Rectangle 2>/dev/null || true
  open -g -a "Scroll Reverser" 2>/dev/null || true
fi

echo ""
echo "Bootstrap complete."
