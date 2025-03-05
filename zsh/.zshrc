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

if [ -f ~/gcr-docker.env ]; then
  source ~/gcr-docker.env
fi
# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# Needed for artemis/phoenix
export MATCH_PASSWORD="j/>9qmhix+AKURAFYk%EmGM2gsoD4T6mGwihn(Tm8bJ6K,e9]DKr2a>63BVLc{k^"

# You may need to manually set your language environment
export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
export EDITOR='nvim'
# fi

# Sessionizer
export PERSONAL="$HOME/Developer/personal"
export WORK="$HOME/Developer/work"
export DOTFILES="$HOME/dotfiles"

# enable vi mode
bindkey -v

for conf_file in "$HOME/dotfiles/zsh/config/"*.zsh; do
  source "${conf_file}"
done
unset conf_file

alias vim="nvim"
alias sess="$DOTFILES/scripts/sessionizer.sh"
alias ag='ag 2>/dev/null'
alias pip='pip3'
alias brewski="brew doctor; brew update && brew upgrade && brew cleanup -s"
alias reload='source ~/.zshrc'
alias :q='exit'

alias ll="ls -lah"
alias notes="glow ~/notes"
alias gitdiffnameonly="git diff --name-status develop"
alias gitlv="git log"
alias gitl='git log --pretty=format:"%Cred%H - %C(yellow)%D%n%Cgreen%an - %ad%n%s%n"'
alias gits="git status"
alias githash="git rev-parse HEAD | tr -d '\n' | pbcopy"
alias gitbranch="git branch --show-current -vvv"
alias gitcheckoutback="git checkout - && gitbranch"
alias gitcommitamend="git commit --amend --no-edit"
alias gitaddpv="git add -pv"
alias gitdifftodoprint="git diff develop | grep -i todo; git diff develop | grep -i print\(" 
alias gitrelease='if [[ $(basename $(pwd)) = "IntelliNest" ]]; then
    current_version=$(grep -o "CURRENT_PROJECT_VERSION = [0-9]*;" IntelliNest.xcodeproj/project.pbxproj | head -1 | awk -F " " "{ print \$3 }" | sed "s/;//");
    new_version=$((current_version + 1));
    sed -i "" "s/CURRENT_PROJECT_VERSION = [0-9]*;/CURRENT_PROJECT_VERSION = $new_version;/g" IntelliNest.xcodeproj/project.pbxproj;
    today=$(date "+%Y.%m.%d");
    sed -i "" "s/MARKETING_VERSION = [0-9.]*;/MARKETING_VERSION = $today;/g" IntelliNest.xcodeproj/project.pbxproj;
    echo "All instances of project and marketing versions updated";
else
    echo "Not in IntelliNest directory";
fi'
alias gittagrelease='if [[ $(git rev-parse --abbrev-ref HEAD) = "main" ]]; then
    current_version=$(grep -o "CURRENT_PROJECT_VERSION = [0-9]*;" IntelliNest.xcodeproj/project.pbxproj | head -1 | awk -F " " "{ print \$3 }" | sed "s/;//");
    today=$(date "+%Y.%m.%d");
    git tag "$today-$current_version";
    git push origin "$today-$current_version";
else
    echo "Please switch to the main branch before running gittag.";
fi'

alias deployLilaStage='npm install && npx jest && \
docker build --platform linux/amd64 -t gcr.io/$GCP_PROJECT_ID/lila:latest . --build-arg NODE_ENV=stage && \
docker push gcr.io/$GCP_PROJECT_ID/lila:latest && \
gcloud run deploy lila --image gcr.io/$GCP_PROJECT_ID/lila:latest --platform managed --region $GCP_REGION \
--update-secrets=MONGODB_URI=projects/$GCP_PROJECT_NUMBER/secrets/mongodb-uri:latest \
--set-env-vars=NODE_ENV=stage,GCLOUD_PROJECT_ID=$GCP_PROJECT_ID,GCLOUD_PROJECT_NUMBER=$GCP_PROJECT_NUMBER'

alias deployLilaStageNoTests='npm install &&  \
docker build --platform linux/amd64 -t gcr.io/$GCP_PROJECT_ID/lila:latest . --build-arg NODE_ENV=stage && \
docker push gcr.io/$GCP_PROJECT_ID/lila:latest && \
gcloud run deploy lila --image gcr.io/$GCP_PROJECT_ID/lila:latest --platform managed --region $GCP_REGION \
--update-secrets=MONGODB_URI=projects/$GCP_PROJECT_NUMBER/secrets/mongodb-uri:latest \
--set-env-vars=NODE_ENV=stage,GCLOUD_PROJECT_ID=$GCP_PROJECT_ID,GCLOUD_PROJECT_NUMBER=$GCP_PROJECT_NUMBER'
alias deployLilaDev='npm install && npx jest && docker compose up --build' # && docker compose logs -f app'

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
[[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm"
# Add RVM to PATH for scripting. Make sure this is the last PATH variable change.
export PATH="$PATH:$HOME/.rvm/bin"

# To customize prompt, run `p10k configure` or edit ~/dotfiles/p10k/p10k.zsh.
[[ ! -f ~/dotfiles/p10k/p10k.zsh ]] || source ~/dotfiles/p10k/p10k.zsh
if which rbenv > /dev/null; then eval "$(rbenv init -)"; fi

# The next line updates PATH for the Google Cloud SDK.
if [ -f '/Users/tobias/Developer/personal/Lila/google-cloud-sdk/path.zsh.inc' ]; then . '/Users/tobias/Developer/personal/Lila/google-cloud-sdk/path.zsh.inc'; fi

# The next line enables shell command completion for gcloud.
if [ -f '/Users/tobias/Developer/personal/Lila/google-cloud-sdk/completion.zsh.inc' ]; then . '/Users/tobias/Developer/personal/Lila/google-cloud-sdk/completion.zsh.inc'; fi

# Created by `pipx` on 2024-11-07 12:28:47
export PATH="$PATH:/Users/tobias/.local/bin"

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# pnpm
export PNPM_HOME="/Users/tobias/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end
