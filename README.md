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

# Syncing After a Pull

After pulling updates from the repo, run:

```bash
./sync.sh
```

This re-links all dotfiles and installs any missing Claude plugins — no prompts, no package installs. If you ran `bootstrap.sh` at least once, this also fires **automatically** after every `git pull` via a post-merge hook.

---

# Claude Code Plugins

The following plugins are tracked in `claude/plugins.txt` and auto-installed by `sync.sh` on any machine:

| Plugin | Marketplace | Description |
|--------|-------------|-------------|
| `superpowers` | claude-plugins-official | Skills framework — brainstorming, TDD, debugging workflows |
| `frontend-design` | claude-plugins-official | High-quality UI generation skill |
| `code-review` | claude-plugins-official | PR review skill |
| `code-simplifier` | claude-plugins-official | Code cleanup and refactor skill |
| `context7` | claude-plugins-official | Fetches up-to-date library docs during coding |
| `security-guidance` | claude-plugins-official | Security best-practice guidance |
| `cli-anything` | cli-anything | Run any CLI tool as a Claude agent |

To add a plugin, append it to `claude/plugins.txt` using the format `plugin-name@marketplace` and run `./sync.sh`.

Registered marketplaces (added automatically by `sync.sh`):
- `github:anthropics/claude-plugins-official`
- `github:hkuds/cli-anything`
- `github:anthropics/skills`

---

# Claude Code Skills

Custom skills live in `claude/skills/` and are symlinked to `~/.claude/skills/` by `sync.sh`. Any new folder added there is picked up automatically on next sync.

| Skill | Description |
|-------|-------------|
| `caveman` | Ultra-compressed communication mode (~75% fewer tokens) |
| `caveman-commit` | Compressed conventional commit message generator |
| `caveman-review` | Compressed PR review comments |
| `compress` | Compresses CLAUDE.md / memory files into caveman format |
| `graphify` | Converts any input into an interactive knowledge graph |

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
