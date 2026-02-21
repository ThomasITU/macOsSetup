# MacOS Development Setup

This repository contains scripts and configuration files to set up a clean development environment on macOS, including:

Homebrew
Git
Neovim
tmux
fzf
Ghostty
LSP + formatting tools

---

# Quick Start

## Clone the repository

```bash
git clone <your-repo-url>
cd <your-repo-name>
```

## Run the setup script

```bash
chmod +x setup.sh
./setup.sh
```

The script will:

Install Homebrew (if missing)
Install required packages
Copy Neovim and tmux configs
Install Neovim plugins automatically

---

#  Tools Included

##  Terminal
Homebrew
Ghostty
tmux
fzf

---

# Learning the Hotkeys Faster

---

## Neovim / Vim Cheat Sheets

• Official Vim cheat sheet
[https://vim.rtorr.com/](https://vim.rtorr.com/)

• Interactive Vim tutorial (run inside terminal)

```bash
vimtutor
```

• Vim Adventure (learn Vim motions like a game)
[https://vim-adventures.com/](https://vim-adventures.com/)

• Neovim documentation
[https://neovim.io/doc/](https://neovim.io/doc/)

---

##  tmux Cheat Sheets

• tmux cheat sheet
[https://tmuxcheatsheet.com/](https://tmuxcheatsheet.com/)

• Practical tmux guide
[https://github.com/tmux/tmux/wiki](https://github.com/tmux/tmux/wiki)

• Interactive tmux tutorial
[https://leanpub.com/the-tao-of-tmux](https://leanpub.com/the-tao-of-tmux)

---

##  fzf Keybindings

Common defaults:

* `CTRL + T` → Fuzzy file search
* `CTRL + R` → Fuzzy history search
* `ALT + C` → Fuzzy directory jump
* `j / k` → Move up/down in results
* `Enter` → Select

Official repo:
[https://github.com/junegunn/fzf](https://github.com/junegunn/fzf)

---

# Recommended Learning Path

If you're new to Vim-style editing:

1. Run `vimtutor`
2. Practice `hjkl` navigation daily
3. Learn text objects (`ciw`, `di"`, `yaw`)
4. Learn motions (`w`, `b`, `e`, `gg`, `G`)
5. Add tmux navigation
6. Master fuzzy search

---

#  Config Locations

Neovim config:

```
~/.config/nvim/init.lua
```

tmux config:

```
~/.tmux.conf
```

---


Leader key = `Space`
`<leader>w` → Save
`<leader>q` → Quit
Use fuzzy search for fast file navigation
Stay on home row (hjkl)

---

# Re-running Setup

If you modify the Neovim plugin list, you can reinstall plugins with:

```bash
nvim --headless "+Lazy! sync" +qa
```
