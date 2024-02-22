[![macOS](https://img.shields.io/badge/macOS-000000?logo=apple&logoColor=white&style=for-the-badge)](https://www.apple.com/macos)
[![Neovim](https://img.shields.io/badge/Neovim-57A143?logo=neovim&logoColor=white&style=for-the-badge)](https://neovim.io)
[![Oh My Zsh](https://img.shields.io/badge/Oh_My_Zsh-1A2C34?logo=gnu-bash&logoColor=white&style=for-the-badge)](https://ohmyz.sh)
[![iTerm2](https://img.shields.io/badge/iTerm2-000000?logo=iterm2&logoColor=white&style=for-the-badge)](https://iterm2.com)
[![Yabai](https://img.shields.io/badge/Yabai-2980b9?style=for-the-badge)](https://github.com/koekeishiya/yabai)
[![skhd](https://img.shields.io/badge/skhd-16a085?style=for-the-badge)](https://github.com/koekeishiya/skhd)
[![Powerlevel10k](https://img.shields.io/badge/Powerlevel10k-1abc9c?style=for-the-badge)](https://github.com/romkatv/powerlevel10k)

## Installation

To install these dotfiles on a new machine, follow these steps:

1. Install [Homebrew](https://brew.sh/) if you haven't already:
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

```
2. Install [Oh My Zsh](https://ohmyz.sh/) framework:
```bash
sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

```
3. Install the dependencies listed in the `Brewfile`:
```bash
brew bundle
```

4. Nvim debugger
Download codelldb-aarch64-darwin.vsix from https://github.com/vadimcn/codelldb/releases
Unzip codelldb-aarch64-darwin and move into ~/Developer

5. Xcode
Install XCode using App Store

6. Create symbolic links for each file that you want to include in your dotfiles repository.
```bash
./symlinks.sh

### Iterm

0. Unzip the fonts in `/fonts` and install.

1. Open iTerm2.
2. Go to "iTerm2" in the menu bar > "Preferences".
3. Click on the "General" tab.
4. Check the box that says "Load preferences from a custom folder or URL".
5. Click on the "Browse" button and navigate to the `iterm2` folder in this dotfiles repository.
7. Close and reopen iTerm2 to apply the new settings.

