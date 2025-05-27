[![macOS](https://img.shields.io/badge/macOS-000000?logo=apple&logoColor=white&style=for-the-badge)](https://www.apple.com/macos)
[![Neovim](https://img.shields.io/badge/Neovim-57A143?logo=neovim&logoColor=white&style=for-the-badge)](https://neovim.io)
[![Oh My Zsh](https://img.shields.io/badge/Oh_My_Zsh-1A2C34?logo=gnu-bash&logoColor=white&style=for-the-badge)](https://ohmyz.sh)
[![iTerm2](https://img.shields.io/badge/iTerm2-000000?logo=iterm2&logoColor=white&style=for-the-badge)](https://iterm2.com)
[![Aerospace](https://img.shields.io/badge/Aerospace-2980b9?style=for-the-badge)](https://github.com/nikitabobko/aerospace)
[![Powerlevel10k](https://img.shields.io/badge/Powerlevel10k-1abc9c?style=for-the-badge)](https://github.com/romkatv/powerlevel10k)

## Installation

To install these dotfiles on a new machine, follow these steps:

1. Install [Homebrew](https://brew.sh/)
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

```
2. Install [Oh My Zsh](https://ohmyz.sh/) framework:
```bash
sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions

# zsh-syntax-highlighting
git clone https://github.com/zsh-users/zsh-syntax-highlighting ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting

# zsh-vi-mode
git clone https://github.com/jeffreytse/zsh-vi-mode ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-vi-mode

# powerlevel10k theme (if not already installed)
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/themes/powerlevel10k

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
```
7. Tmux
git clone https://github.com/tmux-plugins/tpm ~/.config/tmux/plugins/tpm
Open tmux, C-f I (capital i) to install plugins

### Fonts

Install fonts from `./fonts`.

