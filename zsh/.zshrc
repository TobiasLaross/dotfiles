# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# --- Environment ---
export LANG=en_US.UTF-8
export EDITOR='nvim'
export DOTFILES="$HOME/dotfiles"

# --- Homebrew ---
export HOMEBREW_PREFIX="/opt/homebrew"
export HOMEBREW_CELLAR="/opt/homebrew/Cellar"
export HOMEBREW_REPOSITORY="/opt/homebrew"

# --- Path ---
export RBENV_ROOT="$HOME/.rbenv"

typeset -U path PATH
path=(
  "./node_modules/.bin"
  "$HOME/.local/bin"
  "$HOME/.cargo/bin"
  "$HOME/.nvm/versions/node/v20.19.0/bin"
  "/opt/homebrew/bin"
  "/opt/homebrew/sbin"
  "$RBENV_ROOT/bin"
  "$RBENV_ROOT/shims"
  "/usr/local/bin"
  "/usr/bin"
  "/bin"
  "/usr/sbin"
  "/sbin"
  $path
)

export RBENV_SHELL=zsh
[ -z "${MANPATH-}" ] || export MANPATH=":${MANPATH#:}"
export INFOPATH="/opt/homebrew/share/info:${INFOPATH:-}"

# --- History ---
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt HIST_IGNORE_DUPS HIST_IGNORE_ALL_DUPS SHARE_HISTORY HIST_REDUCE_BLANKS

# --- fpath for completions ---
fpath[1,0]="/opt/homebrew/share/zsh/site-functions"

# --- Config files (some add to fpath — must be before compinit) ---
for conf_file in "$HOME/dotfiles/zsh/config/"*.zsh; do
  source "${conf_file}"
done
unset conf_file

# --- Completion ---
autoload -Uz compinit
compinit

# --- Plugins ---
[[ -f /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh ]] && \
  source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
[[ -f /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]] && \
  source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
zvm_config() {
  ZVM_INSERT_MODE_CURSOR=$ZVM_CURSOR_BEAM
  ZVM_NORMAL_MODE_CURSOR=$ZVM_CURSOR_BLOCK
}
[[ -f /opt/homebrew/opt/zsh-vi-mode/share/zsh-vi-mode/zsh-vi-mode.plugin.zsh ]] && \
  source /opt/homebrew/opt/zsh-vi-mode/share/zsh-vi-mode/zsh-vi-mode.plugin.zsh

# --- fzf shell integration ---
[[ -f /opt/homebrew/opt/fzf/shell/completion.zsh ]] && source /opt/homebrew/opt/fzf/shell/completion.zsh
[[ -f /opt/homebrew/opt/fzf/shell/key-bindings.zsh ]] && source /opt/homebrew/opt/fzf/shell/key-bindings.zsh

# --- p10k theme ---
source /opt/homebrew/share/powerlevel10k/powerlevel10k.zsh-theme

# --- Optional env ---
[[ -f ~/gcr-docker.env ]] && source ~/gcr-docker.env

# --- Aliases ---
alias vim="nvim"
alias sess="$DOTFILES/scripts/sessionizer.sh"
alias tasker="$DOTFILES/scripts/tasker.sh"
alias ralph="$DOTFILES/scripts/ralph.sh"
alias ag='ag 2>/dev/null'
alias pip='pip3'
alias brewski="brew doctor; brew update && brew upgrade && brew cleanup -s"
alias reload='source ~/.zshrc'
alias :q='exit'

alias -- -='cd -'
alias ..='cd ..'

alias ll="ls -lah"
alias notes="glow ~/notes"
alias gitdiffnameonly="git diff --name-status develop"
alias gitlv="git log"
alias gitl='git log --pretty=format:"%Cred%H - %C(yellow)%D%n%Cgreen%an - %ad%n%s%n"'
alias gcb='git checkout -b'
alias gcm='git checkout $(git_main_branch)'
alias gcd='git checkout $(git_develop_branch)'
alias gd='git diff'
alias gds='git diff --staged'
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

alias releaseBookNotes='f() {
  local version="$1"
  if [[ -z "$version" ]]; then echo "Usage: releaseBookNotes <version>"; return 1; fi
  local proj="$HOME/Developer/personal/lilium/Lilium.xcodeproj/project.pbxproj"
  local marketing=$(grep "MARKETING_VERSION" "$proj" | grep -v "2024" | head -1 | sed "s/.*= \(.*\);/\1/" | tr -d "[:space:]")
  local build=$(grep "CURRENT_PROJECT_VERSION" "$proj" | grep -v "56" | head -1 | sed "s/.*= \(.*\);/\1/" | tr -d "[:space:]")
  local xcode_version="${marketing}.${build}"
  git -C "$HOME/Developer/personal/lilium" tag "v$version" && \
  git -C "$HOME/Developer/personal/lilium" push origin "v$version" && \
  echo "Tagged and pushed v$version"
}; f'

# --- Grafana Loki (logcli) ---
export LOKI_ADDR=https://logs-prod-025.grafana.net
export LOKI_USERNAME=1547415
export LOKI_PASSWORD=$([ -f ~/.config/grafana-loki-token ] && cat ~/.config/grafana-loki-token)
lila-logs() {
  local limit=100 since=12h severity="" others_only=false
  for arg in "$@"; do
    if [[ "$arg" == "-o" ]]; then
      others_only=true
    elif [[ "$arg" =~ ^[0-9]+$ ]]; then
      limit="$arg"; since="336h"
    elif [[ "$arg" =~ ^[0-9]+[hmd]$ ]]; then
      since="$arg"
    else
      severity="$arg"
    fi
  done
  local sev_pattern=""
  if [[ -n "$severity" ]]; then
    sev_pattern=$(echo "$severity" | tr '[:lower:]|' '[:upper:]|')
  fi
  local logql='{app="BookNotes"}'
  if [[ "$others_only" == true ]]; then
    logql='{app="BookNotes"} !~ `Tobias`'
  fi
  logcli query "$logql" --limit="$limit" --since="$since" --quiet \
    | sed 's/^[^ ]* *{[^}]*} *//' \
    | jq -r --arg sev "$sev_pattern" '
      (if $sev != "" then select(.severity | test("^(\($sev))$")) else . end) |
      def color(s; code): "\u001b[\(code)m\(s)\u001b[0m";
      def severity_color:
        if .severity == "WARNING" then color(.severity; "33")
        elif .severity == "ERROR" then color(.severity; "31")
        else color(.severity; "36") end;
      [
        (.timestamp.seconds | todate | sub("T"; " ") | sub("Z$"; "")),
        severity_color,
        .message,
        (if .path then "[\(.method) \(.path)]" else empty end),
        (if .statusCode then "\(.statusCode) \(.durationMs)ms" else empty end),
        (if .query then "q:" + (.query | tostring) else empty end),
        (if .body then "body:" + (.body | tostring) else empty end),
        (if .err.message then color("err: \(.err.message)"; "31") else empty end)
      ] | join("  ")'
}

alias deployLilaStage='npm install && tsc && npm run test && \
docker build --no-cache --platform linux/amd64 -t gcr.io/$GCP_PROJECT_ID/lila:latest . --build-arg NODE_ENV=stage && \
docker push gcr.io/$GCP_PROJECT_ID/lila:latest && \
gcloud run deploy lila --image gcr.io/$GCP_PROJECT_ID/lila:latest --platform managed --region $GCP_REGION \
--update-secrets=GRAFANA_LOKI_HOST=grafana-loki-host:latest,GRAFANA_LOKI_USER=grafana-loki-user:latest,GRAFANA_LOKI_TOKEN=grafana-loki-token:latest
 \
--set-env-vars=NODE_ENV=stage,GCLOUD_PROJECT_ID=$GCP_PROJECT_ID,GCLOUD_PROJECT_NUMBER=$GCP_PROJECT_NUMBER'

alias deployLilaStageNoTests='npm install && \
docker build --platform linux/amd64 -t gcr.io/$GCP_PROJECT_ID/lila:latest . --build-arg NODE_ENV=stage && \
docker push gcr.io/$GCP_PROJECT_ID/lila:latest && \
gcloud run deploy lila --image gcr.io/$GCP_PROJECT_ID/lila:latest --platform managed --region $GCP_REGION \
--update-secrets=GRAFANA_LOKI_HOST=grafana-loki-host:latest,GRAFANA_LOKI_USER=grafana-loki-user:latest,GRAFANA_LOKI_TOKEN=grafana-loki-token:latest
 \
--set-env-vars=NODE_ENV=stage,GCLOUD_PROJECT_ID=$GCP_PROJECT_ID,GCLOUD_PROJECT_NUMBER=$GCP_PROJECT_NUMBER'

alias deployLilaDev='npm install && npm run test && docker compose up --build'

# --- Lazy-load gcloud SDK ---
_gcloud_sdk_root='/Users/tobias/Developer/personal/Lila/google-cloud-sdk'
_gcloud_lazy_init() {
  unfunction gcloud bq gsutil 2>/dev/null
  [[ -f "$_gcloud_sdk_root/path.zsh.inc" ]] && source "$_gcloud_sdk_root/path.zsh.inc"
  [[ -f "$_gcloud_sdk_root/completion.zsh.inc" ]] && source "$_gcloud_sdk_root/completion.zsh.inc"
  unset _gcloud_sdk_root
}
if [[ -d "$_gcloud_sdk_root" ]]; then
  gcloud()  { _gcloud_lazy_init; gcloud  "$@"; }
  bq()      { _gcloud_lazy_init; bq      "$@"; }
  gsutil()  { _gcloud_lazy_init; gsutil  "$@"; }
fi

# --- Lazy-load nvm ---
export NVM_DIR="$HOME/.nvm"
nvm() { unfunction nvm node npm npx; [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" && [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"; nvm "$@"; }
node() { unfunction nvm node npm npx; [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"; node "$@"; }
npm() { unfunction nvm node npm npx; [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"; npm "$@"; }
npx() { unfunction nvm node npm npx; [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"; npx "$@"; }

# To customize prompt, run `p10k configure` or edit ~/dotfiles/p10k/p10k.zsh.
[[ ! -f ~/dotfiles/p10k/p10k.zsh ]] || source ~/dotfiles/p10k/p10k.zsh

# opencode
export PATH=/Users/tobias/.opencode/bin:$PATH
