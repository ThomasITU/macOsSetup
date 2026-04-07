# macOS Development Setup

Scripts and configuration files to set up a clean development environment on macOS.

---

# Quick Start

## One-liner install (repo must be public):

```bash
curl -fsSL https://raw.githubusercontent.com/ThomasITU/macOsSetup/main/install.sh | bash
```

## Or clone and run manually:

```bash
git clone https://github.com/ThomasITU/macOsSetup.git
cd macOsSetup
./bootstrap.sh
```

The bootstrap script will:

- Install Homebrew (if missing)
- Install all packages from the Brewfile
- Symlink configs for Neovim, tmux, zsh, Ghostty, Hammerspoon, and Claude Code
- Back up any existing config files before replacing them
- Install Neovim plugins via Lazy
- Set up fzf keybindings
- Launch Rectangle and Scroll Reverser

The script is idempotent — safe to run multiple times.

---

# Tools Included

## Terminal
- **Ghostty** — terminal emulator
- **tmux** — terminal multiplexer
- **fzf** — fuzzy finder
- **zsh** — shell config with aliases and fzf integration

## Editor
- **Neovim** with:
  - LSP servers (pyright, lua_ls, bashls, marksman, jsonls, yamlls)
  - Formatters (black, isort, shfmt, prettier)
  - AI completions (Copilot, Codeium, Supermaven) with toggle keys
  - Treesitter, nvim-cmp, fzf-lua

## Automation
- **Hammerspoon** — double-tap Ctrl to approve Claude Code notifications

## Window Management
- **Rectangle** — keyboard-driven window tiling

## Claude Code
- Custom hooks with notification sounds
- Permission allow-lists
- Global guidelines (CLAUDE.md)

## Other
- Scroll Reverser, Node, Python, shfmt

---

# Config Locations

| Config | Path |
|--------|------|
| Neovim | `nvim/init.lua` |
| tmux | `tmux/.tmux.conf` |
| zsh | `zsh/.zshrc` |
| Hammerspoon | `hammerspoon/init.lua` |
| Claude Code | `claude/settings.json`, `claude/CLAUDE.md` |

Leader key = `Space`
`<leader>w` — Save
`<leader>q` — Quit

---

# Learning Resources

## Neovim / Vim

- [Vim cheat sheet](https://vim.rtorr.com/)
- [Vim Adventures](https://vim-adventures.com/) — learn motions like a game
- [Neovim docs](https://neovim.io/doc/)
- Run `vimtutor` in your terminal

## tmux

- [tmux cheat sheet](https://tmuxcheatsheet.com/)
- [tmux wiki](https://github.com/tmux/tmux/wiki)

## fzf Keybindings

| Key | Action |
|-----|--------|
| `Ctrl+T` | Fuzzy file search |
| `Ctrl+R` | Fuzzy history search |
| `Alt+C` | Fuzzy directory jump |

[fzf repo](https://github.com/junegunn/fzf)

---

# Re-running Setup

To reinstall Neovim plugins:

```bash
nvim --headless "+Lazy! sync" +qa
```

To re-run the full setup:

```bash
./bootstrap.sh
```
