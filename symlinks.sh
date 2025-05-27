#!/bin/zsh

ln -sf $(pwd)/nvim/ ~/.config/
ln -sf $(pwd)/aerospace/ ~/.config/
ln -sf $(pwd)/p10k/p10k.zsh ~/.p10k.zsh
ln -sf $(pwd)/zsh/.zshrc ~/.zshrc
mkdir -p ~/.config/tmux
ln -sf $(pwd)/tmux/tmux.conf ~/.tmux.conf
ln -sf $(pwd)/tmux/conf ~/.config/tmux/
ln -sf $(pwd)/OneDark.xccolortheme $(pwd)/../Library/Developer/Xcode/UserData/FontAndColorThemes
ln -sf $(pwd)/ghostty/config /Users/tobias/Library/Application\ Support/com.mitchellh.ghostty/config

. ~/.zshrc
