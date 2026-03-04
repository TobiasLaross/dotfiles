# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Setup

Install dependencies and link configs:

```sh
brew bundle          # Install all Homebrew packages from Brewfile
./symlinks.sh        # Create all symlinks into ~/.config/ and home directory
```

After `symlinks.sh`, reload the shell or run `. ~/.zshrc`.

For Tmux plugins, install TPM manually and run `<prefix>+I` inside a tmux session.

## Architecture

This is a macOS dotfiles repo managed via **symlinks** (no stow). `symlinks.sh` links config directories directly into `~/.config/` and home.

### Key configs

| Directory | Target | Notes |
|-----------|--------|-------|
| `nvim/` | `~/.config/nvim/` | Neovim — primary editor |
| `aerospace/` | `~/.config/aerospace/` | Window manager |
| `zsh/.zshrc` | `~/.zshrc` | Shell config |
| `tmux/tmux.conf` | `~/.tmux.conf` | Sources `tmux/conf/` modules |
| `ghostty/config` | `~/Library/Application Support/com.mitchellh.ghostty/config` | Terminal |
| `p10k/p10k.zsh` | `~/.p10k.zsh` | Powerlevel10k prompt |

### Neovim (`nvim/`)

Plugin manager: **Lazy.nvim**. Entry point: `nvim/init.lua` → `lua/config/init.lua`.

Structure:
- `lua/config/` — `keymaps.lua`, `options.lua`, `icons.lua`, `init.lua` (lazy bootstrap)
- `lua/plugins/` — one file per plugin (~41 plugins)
- `lua/util/` — shared utilities (`lsp.lua`, `terminal.lua`, `file-finder.lua`, etc.)
- `lsp/` — per-LSP config files loaded by nvim-lspconfig

Notable plugin choices:
- Completion: **blink.cmp** (replaced nvim-cmp)
- Formatting/linting: **conform.nvim** + **nvim-lint**
- LSP tooling: **mason** + **mason-lspconfig**
- Fuzzy finding: **telescope**
- File explorer: **oil.nvim** (primary) + nvim-tree
- Git: **fugitive** + **gitsigns** + **diffview**
- Testing: **neotest**
- Debugging: **nvim-dap** + **nvim-dap-ui** + codelldb (for Swift/C/C++)
- iOS/macOS dev: **xcodebuild.nvim**

### Tmux (`tmux/`)

`tmux.conf` sources modular files from `tmux/conf/`:
- `tmux.opts.conf`, `tmux.keybind.conf`, `tmux.skin.conf`, `tmux.copy.conf`

### Zsh (`zsh/`)

Oh My Zsh with plugins: `fzf`, `git`, `ssh-agent`, `zsh-autosuggestions`, `zsh-vi-mode`, `zsh-syntax-highlighting`, `powerlevel10k`.

Additional functions in `zsh/config/functions.zsh`. The `sess` alias runs `scripts/sessionizer.sh` (tmux session switcher).

## Commit messages

Use short, single-line messages starting with a capitalised past-tense verb. No period at the end.

```
Added <thing>
Updated <thing>
Fixed <thing>
Improved <thing>
Removed <thing>
```

Examples from this repo: `Fixed swift lsp`, `Improved nvim startup time`, `Updated blink`.

## Code quality files

- `.luacheckrc` / `.luarc.json` — Lua linting for Neovim config
- `.swiftformat` / `.swiftlint.yml` — Swift formatting/linting (used by xcodebuild.nvim)
