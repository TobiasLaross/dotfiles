# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
# ZSH_THEME="robbyrussell"
ZSH_THEME="powerlevel10k/powerlevel10k"

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in $ZSH/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment one of the following lines to change the auto-update behavior
# zstyle ':omz:update' mode disabled  # disable automatic updates
# zstyle ':omz:update' mode auto      # update automatically without asking
# zstyle ':omz:update' mode reminder  # just remind me to update when it's time

# Uncomment the following line to change how often to auto-update (in days).
# zstyle ':omz:update' frequency 13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# You can also set it to another string to have that shown instead of the default red dots.
# e.g. COMPLETION_WAITING_DOTS="%F{yellow}waiting...%f"
# Caution: this setting can cause issues with multiline prompts in zsh < 5.7.1 (see #5765)
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(git ssh-agent zsh-autosuggestions)

source $ZSH/oh-my-zsh.sh

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# Needed for artemis/phoenix
export MATCH_PASSWORD="j/>9qmhix+AKURAFYk%EmGM2gsoD4T6mGwihn(Tm8bJ6K,e9]DKr2a>63BVLc{k^"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='mvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"
#
alias vim="nvim"

alias gitdiffnameonly="git diff --name-status develop"
alias gitl="git log"
alias gits="git status"
alias gitwatch="git checkout develop August.xcodeproj/xcshareddata/xcschemes/AugustWatchApp.xcscheme; git checkout develop August.xcodeproj/xcshareddata/xcschemes/YaleWatchApp\ Extension.xcscheme;git status;"
alias gitwatchlocal="git restore August.xcodeproj/xcshareddata/xcschemes/AugustWatchApp.xcscheme; git restore August.xcodeproj/xcshareddata/xcschemes/YaleWatchApp\ Extension.xcscheme;git status;"
alias gits="git status"
alias gitbranch="git branch -vvv"
alias gitcheckoutback="git checkout -"
alias gitcommitamend="git commit --amend --no-edit"
alias gitaddpv="git add -pv"
alias gitdifftodoprint="git diff develop | grep -i todo; git diff develop | grep -i print\(" 
function git-stats() {
  # ANSI color codes
  BOLD="\033[1m"
  GREEN="\033[32m"
  CYAN="\033[36m"
  RESET="\033[0m"

  author_name=$(git config user.name)
  total_lines=$(git ls-files | xargs wc -l | tail -n 1 | awk '{print $1}')
  my_lines=$(git ls-files | parallel -j+0 "git blame --line-porcelain {} | grep -E '^author ${author_name}$' | wc -l" | awk '{sum += $1} END {print sum}')
  total_commits=$(git rev-list --count HEAD)
  my_commits=$(git rev-list --count HEAD --author="$author_name")
  lines_percentage=$(echo "scale=2; $my_lines / $total_lines * 100" | bc)
  commits_percentage=$(echo "scale=2; $my_commits / $total_commits * 100" | bc)

  echo -e "${BOLD}${GREEN}Git Repository Statistics:${RESET}"
  echo -e "${BOLD}${CYAN}Total lines in repo:${RESET} $total_lines"
  echo -e "${BOLD}${CYAN}Lines added by you:${RESET} $my_lines"
  echo -e "${BOLD}${CYAN}Total commits:${RESET} $total_commits"
  echo -e "${BOLD}${CYAN}Your commits:${RESET} $my_commits"
  echo -e "${BOLD}${CYAN}Your lines (percentage):${RESET} $lines_percentage%"
  echo -e "${BOLD}${CYAN}Your commits (percentage):${RESET} $commits_percentage%"
}
function gits2 () {
  git status -s | while read mode file; do
      printf "\033[32m%-5s\033[0m %-40s %s\n" "$mode" "$file" "$(stat -f "%Sm" "$file")"
  done | column -t
}

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# Add RVM to PATH for scripting. Make sure this is the last PATH variable change.
export PATH="$PATH:$HOME/.rvm/bin"

# To customize prompt, run `p10k configure` or edit ~/dotfiles/p10k/p10k.zsh.
[[ ! -f ~/dotfiles/p10k/p10k.zsh ]] || source ~/dotfiles/p10k/p10k.zsh
