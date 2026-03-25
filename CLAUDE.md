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

| Directory / File | Target | Notes |
|------------------|--------|-------|
| `nvim/` | `~/.config/nvim/` | Neovim — primary editor |
| `aerospace/` | `~/.config/aerospace/` | Window manager |
| `zsh/.zshenv` | `~/.zshenv` | Shell environment variables |
| `zsh/.zshrc` | `~/.zshrc` | Shell config |
| `tmux/tmux.conf` | `~/.tmux.conf` | Sources `tmux/conf/` modules |
| `tmux/conf/` | `~/.config/tmux/` | Tmux modular configs |
| `ghostty/config` | `~/Library/Application Support/com.mitchellh.ghostty/config` | Terminal |
| `p10k/p10k.zsh` | `~/.p10k.zsh` | Powerlevel10k prompt |
| `OneDark.xccolortheme` | `~/Library/Developer/Xcode/UserData/FontAndColorThemes/` | Xcode theme |

`symlinks.sh` also initialises git submodules and validates that `agentic/CLAUDE.md` and `agentic/copilot-instructions.md` have identical content (ignoring YAML frontmatter).

### Neovim (`nvim/`)

Plugin manager: **Lazy.nvim**. Entry point: `nvim/init.lua` → `lua/config/init.lua`.

Structure:
- `lua/config/` — `keymaps.lua`, `options.lua`, `icons.lua`, `init.lua` (lazy bootstrap)
- `lua/plugins/` — one file per plugin (41 plugins total)
- `lua/util/` — shared utilities: `lsp.lua`, `terminal.lua`, `file-finder.lua`, `keycmd.lua`, `word-logger.lua`
- `lsp/` — per-LSP config files: `lua_ls.lua`, `rust_analyzer.lua`, `vtsls.lua`

Notable plugin choices:
- Completion: **blink.cmp** (replaced nvim-cmp)
- Formatting/linting: **conform.nvim** + **nvim-lint**
- LSP tooling: **mason** + **mason-lspconfig**
- Fuzzy finding: **telescope** (most complex config, ~268 lines)
- File explorer: **oil.nvim** (primary, floating) + nvim-tree
- Git: **fugitive** + **gitsigns** + **diffview**
- Testing: **neotest**
- Debugging: **nvim-dap** + **nvim-dap-ui** + codelldb (for Swift/C/C++)
- iOS/macOS dev: **xcodebuild.nvim**
- UI: **lualine**, **noice**, **fidget**, **trouble**, **lspsaga**
- Themes: **kanagawa** (primary), onedarkpro

Key options (`lua/config/options.lua`): tabs=4, `colorcolumn=140`, spell enabled, line numbers.

Leader key: `<Space>`. Key bindings are in `lua/config/keymaps.lua`. LSP keymaps are applied on attach via `lua/util/lsp.lua`.

Linting config files: `.luacheckrc`, `.luarc.json` (root of repo).

### Tmux (`tmux/`)

`tmux.conf` sources modular files from `tmux/conf/`:
- `tmux.opts.conf` — options (256color, history=1,000,000, base-index=1, vi mode)
- `tmux.keybind.conf` — keybindings
- `tmux.skin.conf` / `tmux.skin_shared.conf` — theme/styling
- `tmux.copy.conf` — copy/paste settings

Plugins (via TPM): `tmux-cpu`, `tmux-sensible`, `tmux-mode-indicator`, `tmux-compile`.

### Zsh (`zsh/`)

Oh My Zsh with plugins: `fzf`, `git`, `ssh-agent`, `zsh-autosuggestions`, `zsh-vi-mode`, `zsh-syntax-highlighting`, `powerlevel10k`.

Environment variables set in `.zshenv`:
```sh
PERSONAL="$HOME/Developer/personal"
WORK="$HOME/Developer/work"
DOTFILES="$HOME/dotfiles"
```

Notable aliases: `vim` → `nvim`, `sess` → `scripts/sessionizer.sh`, git shortcuts (`gcb`, `gcm`, `gcd`, `gd`, `gds`), `brewski` (brew update+cleanup), `reload`.

Lazy-loaded: `gcloud`/`bq`/`gsutil` (GCP SDK), `nvm`.

Additional functions in `zsh/config/functions.zsh`:
- `git_main_branch` / `git_develop_branch` — detect branch names
- `git-stats` — contribution statistics
- `gits2` — git status with file timestamps
- `fzf-history` — fuzzy shell history search with man-page preview

### Scripts (`scripts/`)

**`sessionizer.sh`** — advanced FZF-based tmux session switcher:
- Lists projects from `$WORK`, `$PERSONAL`, and `$DOTFILES` with color coding (green/yellow/magenta)
- By default shows only repos with open tmux sessions; `Ctrl-A` toggles to all repos
- On selection, creates a tmux session with windows: Code, Test, Lazygit (Dotfiles gets Code + Test only)
- Session name: directory basename converted to kebab-case then capitalised
- Special shortcuts: `sess dotfiles`, `sess notes`, `sess existing`

### Aerospace (`aerospace/`)

**`aerospace.toml`** — tiling window manager (283 lines):
- Gaps: 8px inner and outer
- 7 numbered workspaces + 4 named (`p` Postman, `m` MongoDB, `g` ChatGPT, `w` WhatsApp)
- App → workspace rules (Chrome→1, Ghostty→2, Slack/Mail→3, Xcode→4, Docker/Figma→5, etc.)
- Vim-like focus/move with `alt-h/j/k/l`; workspace switch `alt-1..7`; resize `ctrl-alt-h/j/k/l`
- `alt-space` opens Ghostty; `alt-r` reloads config; `alt-f` fullscreen; `alt-c` toggle float

### Ghostty (`ghostty/`)

Terminal config: FiraCode Nerd Font Mono 16pt, Catppuccin Mocha theme, 80% background opacity, hidden titlebar.

### Agentic setup (`agentic/`)

Config for Claude Code, GitHub Copilot Chat, and opencode. Symlinked by `symlinks.sh`:

| Source | Target | Notes |
|--------|--------|-------|
| `agentic/CLAUDE.md` | `~/.claude/CLAUDE.md` | Global Claude instructions |
| `agentic/settings.json` | `~/.claude/settings.json` | Permissions, model, plugins |
| `agentic/copilot-instructions.md` | `~/.copilot/copilot-instructions.md` | Copilot global instructions |
| `agentic/opencode.json` | `~/.config/opencode/opencode.json` | opencode config |
| `agentic/skills/*/` | `~/.claude/skills/` and `~/.copilot/skills/` | Shared skills for Claude and Copilot |

Skills and global instructions are **shared** between Claude and Copilot. `symlinks.sh` warns if `CLAUDE.md` and `copilot-instructions.md` diverge in content (ignoring YAML frontmatter).

opencode auto-discovers skills from `~/.claude/skills/` (it scans `~/.claude` for `skills/**/SKILL.md`) so no separate skill symlinks are needed for it.

**`settings.json`** sets the default model to `opus`, enables the `swift-lsp` plugin, and pre-allows common read-only and git commands so Claude doesn't prompt for them. It also grants access to `~/Developer/work` and `~/Developer/personal`.

**`opencode.json`** sets the model to `anthropic/claude-opus-4-6`, points instructions at `~/.claude/CLAUDE.md` (the shared global instructions), and pre-allows read, glob, grep, list, webfetch, websearch, skill, and bash tools.

**Skills** (invoked as `/skill-name`):

| Skill | Description |
|-------|-------------|
| `/feature-plan` | Draft a user story, create `~/.claude/features/<name>/` folder and files |
| `/feature-impl-plan` | Break a feature into tasks with dependency analysis and parallel execution waves |
| `/feature-implement` | Execute tasks from the impl plan in dependency order |
| `/feature-code-review` | Review implemented feature code from 7 perspectives in parallel |
| `/feature-done` | Verify all tasks are complete, then move feature to `done/` |
| `/review-plan` | Review an implementation plan from 6 perspectives in parallel |
| `/review-code` | Review any code from 7 perspectives in parallel |
| `/bugfix` | Investigate a bug, write a failing test, implement and review a fix |
| `/explain-code` | Explain code with diagrams and analogies |
| `/repo-context` | Scan repos in `~/Developer/` and write per-repo context files to `~/.claude/repo-context/` |

**Vendor skills** (git submodules under `agentic/vendor/`): `swift-concurrency-skill`, `swiftui-skill`, `swift-testing-skill` — also symlinked into `~/.claude/skills/`.

**Global instructions** (`agentic/CLAUDE.md`) define:
- Feature tracking lifecycle under `~/.claude/features/` (active → `done/` when complete)
- Repo context workflow: read `~/.claude/repo-context/<repo>.md` before source code when available
- Work repos live in `~/Developer/work/`; personal repos in `~/Developer/personal/`

### Other files

- `keeb/` / `vial/` — keyboard firmware and layout backups (Vial `.vil` JSON, ZMK Studio `.zip`)
- `fonts/` — Nerd Font files (not symlinked; installed manually or via Homebrew)
- `iterm2/` — legacy iTerm2 color scheme (superseded by Ghostty)
- `.github/copilot-instructions.md` — Copilot instructions for GitHub web context
- `.gitmodules` — three Swift agent skill submodules from tobiaslaross

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

## What NOT to do

- Do not run `brew bundle` or `./symlinks.sh` unless the user explicitly requests a full setup
- Do not modify `agentic/CLAUDE.md` and `agentic/copilot-instructions.md` independently — keep them in sync (content identical, only frontmatter may differ)
- Do not commit `nvim/lazy-lock.json` (excluded via `.gitignore`)
- Do not add font binaries or large binary blobs to git
