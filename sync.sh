#!/usr/bin/env bash
# sync.sh — re-link all dotfiles after a git pull (no installs, no prompts)
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")" && pwd -P)"

link_file() {
  local src="$1" dest="$2"
  if [ -L "$dest" ]; then
    local current_target
    current_target=$(readlink "$dest")
    if [ "$current_target" = "$src" ]; then
      echo "  ok    $dest"
      return
    fi
    echo "  relink $dest"
  elif [ -e "$dest" ]; then
    mv "$dest" "$dest.backup.$(date +%s)"
    echo "  backup $dest"
  else
    echo "  link  $dest"
  fi
  ln -sf "$src" "$dest"
}

echo "Syncing dotfiles from $REPO_DIR..."
echo ""

# ── zsh ──────────────────────────────────────────────────────────────────────
if [ -f "$REPO_DIR/zsh/.zshrc" ]; then
  echo "[zsh]"
  link_file "$REPO_DIR/zsh/.zshrc" "$HOME/.zshrc"
fi

# ── neovim ───────────────────────────────────────────────────────────────────
if [ -f "$REPO_DIR/nvim/init.lua" ]; then
  echo "[neovim]"
  mkdir -p ~/.config/nvim
  link_file "$REPO_DIR/nvim/init.lua" "$HOME/.config/nvim/init.lua"
fi

# ── tmux ─────────────────────────────────────────────────────────────────────
if [ -f "$REPO_DIR/tmux/.tmux.conf" ]; then
  echo "[tmux]"
  link_file "$REPO_DIR/tmux/.tmux.conf" "$HOME/.tmux.conf"
fi

# ── hammerspoon ──────────────────────────────────────────────────────────────
if [ -f "$REPO_DIR/hammerspoon/init.lua" ]; then
  echo "[hammerspoon]"
  mkdir -p ~/.hammerspoon
  link_file "$REPO_DIR/hammerspoon/init.lua" "$HOME/.hammerspoon/init.lua"
fi

# ── claude ───────────────────────────────────────────────────────────────────
if [ -d "$REPO_DIR/claude" ]; then
  echo "[claude]"
  mkdir -p ~/.claude/hooks

  [ -f "$REPO_DIR/claude/CLAUDE.md" ]                        && link_file "$REPO_DIR/claude/CLAUDE.md"                        "$HOME/.claude/CLAUDE.md"
  [ -f "$REPO_DIR/claude/settings.json" ]                    && link_file "$REPO_DIR/claude/settings.json"                    "$HOME/.claude/settings.json"
  [ -f "$REPO_DIR/claude/hooks/parse_hook.sh" ]              && link_file "$REPO_DIR/claude/hooks/parse_hook.sh"              "$HOME/.claude/hooks/parse_hook.sh"
  [ -f "$REPO_DIR/claude/hooks/notification_notify.sh" ]     && link_file "$REPO_DIR/claude/hooks/notification_notify.sh"     "$HOME/.claude/hooks/notification_notify.sh"
  [ -f "$REPO_DIR/claude/hooks/stop_notify.sh" ]             && link_file "$REPO_DIR/claude/hooks/stop_notify.sh"             "$HOME/.claude/hooks/stop_notify.sh"
  [ -f "$REPO_DIR/claude/hooks/session_start.sh" ]           && link_file "$REPO_DIR/claude/hooks/session_start.sh"           "$HOME/.claude/hooks/session_start.sh"
  [ -d "$REPO_DIR/claude/hooks/sounds" ]                     && link_file "$REPO_DIR/claude/hooks/sounds"                    "$HOME/.claude/hooks/sounds"

  # Skills — auto-discover: any new skill folder gets linked
  mkdir -p ~/.claude/skills
  for skill_dir in "$REPO_DIR"/claude/skills/*/; do
    skill_dir="${skill_dir%/}"
    skill_name="$(basename "$skill_dir")"
    link_file "$skill_dir" "$HOME/.claude/skills/$skill_name"
  done
fi

# ── claude plugins ───────────────────────────────────────────────────────────
if [ -f "$REPO_DIR/claude/plugins.txt" ] && command -v claude &>/dev/null; then
  echo "[claude plugins]"

  # Ensure known marketplaces are registered
  claude plugin marketplace add github:anthropics/claude-plugins-official 2>/dev/null || true
  claude plugin marketplace add github:hkuds/cli-anything                 2>/dev/null || true
  claude plugin marketplace add github:anthropics/skills                  2>/dev/null || true

  # Get currently installed plugins (names only)
  installed=$(claude plugin list 2>/dev/null | grep '❯' | awk '{print $2}' || true)

  while IFS= read -r line || [ -n "$line" ]; do
    # Skip comments and blank lines
    [[ "$line" =~ ^#.*$ || -z "$line" ]] && continue
    plugin="$line"
    if echo "$installed" | grep -qF "$plugin"; then
      echo "  ok    $plugin"
    else
      echo "  install $plugin"
      claude plugin install "$plugin" 2>&1 | sed 's/^/    /'
    fi
  done < "$REPO_DIR/claude/plugins.txt"
fi

# ── VS Code extension (copy, not symlink — VS Code doesn't follow deep symlinks)
if [ -d "$REPO_DIR/vscode/claude-terminal-focus" ]; then
  echo "[vscode]"
  VSCODE_EXT_DIR="$HOME/.vscode/extensions/claude-terminal-focus"
  mkdir -p "$VSCODE_EXT_DIR"
  cp "$REPO_DIR/vscode/claude-terminal-focus/package.json" "$VSCODE_EXT_DIR/"
  cp "$REPO_DIR/vscode/claude-terminal-focus/extension.js" "$VSCODE_EXT_DIR/"
  echo "  copied vscode extension (restart VS Code to pick up changes)"
fi

echo ""
echo "Sync complete."
echo ""
echo "Tip: source ~/.zshrc   (or open a new shell) to pick up zsh changes."
