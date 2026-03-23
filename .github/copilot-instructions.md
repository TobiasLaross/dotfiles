# Copilot Instructions

macOS dotfiles managed via symlinks (no stow). `symlinks.sh` links config directories directly into `~/.config/` and home.

## Setup

```sh
brew bundle          # Install all Homebrew packages from Brewfile
./symlinks.sh        # Create all symlinks into ~/.config/ and home directory
```

After `symlinks.sh`, reload the shell or run `. ~/.zshrc`.

For Tmux plugins, install TPM manually and run `<prefix>+I` inside a tmux session.

## Symlink Map

| Source | Target |
|--------|--------|
| `nvim/` | `~/.config/nvim/` |
| `aerospace/` | `~/.config/aerospace/` |
| `zsh/.zshrc` | `~/.zshrc` |
| `tmux/tmux.conf` | `~/.tmux.conf` |
| `tmux/conf/` | `~/.config/tmux/conf/` |
| `ghostty/config` | `~/Library/Application Support/com.mitchellh.ghostty/config` |
| `p10k/p10k.zsh` | `~/.p10k.zsh` |
| `agentic/CLAUDE.md` | `~/.claude/CLAUDE.md` |
| `agentic/copilot-instructions.md` | `~/.copilot/copilot-instructions.md` |
| `agentic/settings.json` | `~/.claude/settings.json` |
| `agentic/skills/*/` | `~/.claude/skills/` and `~/.copilot/skills/` |

## Neovim (`nvim/`)

Plugin manager: **Lazy.nvim**. Entry point: `nvim/init.lua` → `lua/config/init.lua`.

- `lua/config/` — `keymaps.lua`, `options.lua`, `icons.lua`, `init.lua` (lazy bootstrap)
- `lua/plugins/` — one file per plugin
- `lua/util/` — shared utilities (`lsp.lua`, `terminal.lua`, `file-finder.lua`, etc.)
- `lsp/` — per-LSP config files loaded by nvim-lspconfig

Notable plugin choices:
- Completion: **blink.cmp**
- Formatting/linting: **conform.nvim** + **nvim-lint**
- LSP tooling: **mason** + **mason-lspconfig**
- Fuzzy finding: **telescope**
- File explorer: **oil.nvim** (primary) + nvim-tree
- Git: **fugitive** + **gitsigns** + **diffview**
- Testing: **neotest**
- Debugging: **nvim-dap** + **nvim-dap-ui** + codelldb (Swift/C/C++)
- iOS/macOS dev: **xcodebuild.nvim**

Lua linting is configured via `nvim/.luacheckrc` and `nvim/.luarc.json`.

## Tmux (`tmux/`)

`tmux.conf` sources modular files from `tmux/conf/`: `tmux.opts.conf`, `tmux.keybind.conf`, `tmux.skin.conf`, `tmux.copy.conf`.

## Zsh (`zsh/`)

Oh My Zsh with plugins: `fzf`, `git`, `ssh-agent`, `zsh-autosuggestions`, `zsh-vi-mode`, `zsh-syntax-highlighting`, `powerlevel10k`. Additional functions in `zsh/config/functions.zsh`. The `sess` alias runs `scripts/sessionizer.sh` (tmux session switcher).

## Agentic Setup (`agentic/`)

Claude Code and Copilot CLI share the **same skills and global instructions**. `symlinks.sh` warns if `agentic/CLAUDE.md` and `agentic/copilot-instructions.md` diverge in content (ignoring YAML frontmatter) — keep them in sync.

Skills live in `agentic/skills/` and are symlinked to both `~/.claude/skills/` and `~/.copilot/skills/`.

## Commit Messages

Short, single-line, capitalised past-tense verb, no period:

```
Added <thing>
Updated <thing>
Fixed <thing>
Improved <thing>
Removed <thing>
```
