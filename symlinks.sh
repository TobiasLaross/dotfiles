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

# Claude + Copilot CLI share the same skills and global instructions
mkdir -p ~/.claude/skills ~/.copilot/skills
for skill in "$ROOT_DIR"/claude/skills/*/; do
    ln -sf "$skill" ~/.claude/skills/
    ln -sf "$skill" ~/.copilot/skills/
done

ln -sf "$ROOT_DIR/claude/CLAUDE.md" ~/.claude/CLAUDE.md
ln -sf "$ROOT_DIR/claude/CLAUDE.md" ~/.copilot/copilot-instructions.md
ln -sf "$ROOT_DIR/claude/settings.json" ~/.claude/settings.json

. ~/.zshrc
