#!/bin/zsh

# macOS defaults — run once per fresh machine.
# Log out and back in (or restart) for changes to take effect.

set -e

# Disable the press-and-hold accent popup so keys repeat in Vim/Neovim.
defaults write -g ApplePressAndHoldEnabled -bool false

# Key repeat speed once repeating starts (lower = faster; System Settings min is 15).
defaults write NSGlobalDomain KeyRepeat -int 2

# Delay before key repeat kicks in (lower = shorter; System Settings min is 25).
defaults write NSGlobalDomain InitialKeyRepeat -int 15

echo "macOS defaults applied. Log out and back in for changes to take effect."
