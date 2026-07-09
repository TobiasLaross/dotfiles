#!/bin/zsh

ROOT_DIR=${0:A:h}

ln -sf "$ROOT_DIR/nvim/" ~/.config/
ln -sf "$ROOT_DIR/aerospace/" ~/.config/
ln -sf "$ROOT_DIR/p10k/p10k.zsh" ~/.p10k.zsh
ln -sf "$ROOT_DIR/zsh/.zshenv" ~/.zshenv
ln -sf "$ROOT_DIR/zsh/.zshrc" ~/.zshrc
mkdir -p ~/.config/tmux
ln -sf "$ROOT_DIR/tmux/tmux.conf" ~/.tmux.conf
ln -sf "$ROOT_DIR/tmux/conf" ~/.config/tmux/
ln -sf "$ROOT_DIR/OneDark.xccolortheme" "$HOME/Library/Developer/Xcode/UserData/FontAndColorThemes"
ln -sf "$ROOT_DIR/ghostty/config" "$HOME/Library/Application Support/com.mitchellh.ghostty/config"

git -C "$ROOT_DIR" submodule update --init --recursive

# Patch tmux-cpu plugin to use memory_pressure instead of vm_stat
ln -sf "$ROOT_DIR/tmux/patches/ram_percentage.sh" "$ROOT_DIR/tmux/plugins/tmux-cpu/scripts/ram_percentage.sh"

# Claude + Codex + Copilot CLI + opencode share the same skills and global instructions
mkdir -p ~/.claude/skills ~/.codex/skills ~/.copilot/skills ~/.config/opencode
for skill in "$ROOT_DIR"/agentic/skills/*/; do
	resolved=${skill:A}
	ln -sf "$resolved" ~/.claude/skills/
	ln -sf "$resolved" ~/.codex/skills/
	ln -sf "$resolved" ~/.copilot/skills/
done

# Machine-local skills (gitignored, not shared across machines)
mkdir -p "$ROOT_DIR/agentic/skills-local"
for skill in "$ROOT_DIR"/agentic/skills-local/*(N/); do
	resolved=${skill:A}
	ln -sf "$resolved" ~/.claude/skills/
	ln -sf "$resolved" ~/.codex/skills/
	ln -sf "$resolved" ~/.copilot/skills/
done

# Remove dangling skill symlinks (from deleted skills)
for dir in ~/.claude/skills ~/.codex/skills ~/.copilot/skills; do
	for link in "$dir"/*(N@); do
		if [[ ! -e "$link" ]]; then
			rm "$link"
		fi
	done
done

ln -sf "$ROOT_DIR/agentic/CLAUDE.md" ~/.claude/CLAUDE.md
ln -sf "$ROOT_DIR/agentic/CLAUDE.md" ~/.codex/AGENTS.md
ln -sf "$ROOT_DIR/agentic/codex.config.toml" ~/.codex/config.toml
ln -sf "$ROOT_DIR/agentic/copilot-instructions.md" ~/.copilot/copilot-instructions.md
ln -sf "$ROOT_DIR/agentic/settings.json" ~/.claude/settings.json
ln -sf "$ROOT_DIR/agentic/opencode.json" ~/.config/opencode/opencode.json
ln -sf "$ROOT_DIR/agentic/tui.json" ~/.config/opencode/tui.json

# Warn if Claude and Copilot instructions diverge in content (ignoring YAML frontmatter)
_claude_body=$(cat "$ROOT_DIR/agentic/CLAUDE.md")
_copilot_body=$(awk 'BEGIN{skip=0; after=0} NR==1 && /^---$/{skip=1; next} skip && /^---$/{skip=0; after=1; next} !skip{if(after && /^$/){after=0; next} after=0; print}' "$ROOT_DIR/agentic/copilot-instructions.md")
if [[ "$_claude_body" != "$_copilot_body" ]]; then
	echo "\033[33m⚠  agentic/CLAUDE.md and agentic/copilot-instructions.md have diverged (ignoring frontmatter).\033[0m"
	diff --color <(echo "$_claude_body") <(echo "$_copilot_body") | head -20
fi
unset _claude_body _copilot_body

. ~/.zshrc
