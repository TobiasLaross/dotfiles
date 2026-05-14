function git_main_branch() {
  command git rev-parse --git-dir &>/dev/null || return
  local ref
  for ref in refs/heads/main refs/heads/master refs/remotes/origin/main refs/remotes/origin/master; do
    if command git show-ref -q --verify $ref; then
      echo ${ref:t}
      return
    fi
  done
  echo main
}

function git_develop_branch() {
  command git rev-parse --git-dir &>/dev/null || return
  local ref
  for ref in refs/heads/dev refs/heads/develop refs/heads/development refs/remotes/origin/dev refs/remotes/origin/develop; do
    if command git show-ref -q --verify $ref; then
      echo ${ref:t}
      return
    fi
  done
  echo develop
}

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

function gits2() {
    git status -s | while read mode file; do
        printf "\033[32m%-5s\033[0m %-40s %s\n" "$mode" "$file" "$(stat -f "%Sm" "$file")"
    done | column -t
}

function fzf-history() {
  local selected ret
  local preview_cmd='
    cmd=$(echo {} | awk "{print \$1}")
    if man "$cmd" &>/dev/null; then
      man "$cmd" | col -bx
    else
      echo {} | bat --style=plain --color=always --language=sh
    fi'

  # Use minimal local options for safety
  setopt localoptions noglob

  if zmodload -F zsh/parameter p:{commands,history} 2>/dev/null && (( ${+commands[perl]} )); then
    selected=$(printf '%s\t%s\0' "${(kv)history[@]}" |
      perl -0 -ne 'if (!$seen{(/^\s*[0-9]+\**\t(.*)/s, $1)}++) { s/\n/\n\t/g; print; }' |
      fzf --read0 --query="$LBUFFER" --height=40% --preview "$preview_cmd" --preview-window=top:0% --bind="ctrl-r:toggle-sort")
  else
    selected=$(fc -rl 1 | awk '{
      cmd=$0; 
      sub(/^[ \t]*[0-9]+\**[ \t]+/, "", cmd); 
      if (!seen[cmd]++) print $0 
    }' | fzf --query="$LBUFFER" --height=40%  --preview "$preview_cmd" --preview-window=top:0% --bind="ctrl-r:toggle-sort")
  fi

  ret=$?

  if [ -n "$selected" ]; then
    if [[ $(awk '{print $1; exit}' <<< "$selected") =~ ^[1-9][0-9]* ]]; then
      zle vi-fetch-history -n $MATCH
    else
      LBUFFER="$selected"
    fi
  fi

  zle reset-prompt
  return $ret
}

zle -N fzf-history
bindkey '^r' fzf-history

function memtop() {
    trap 'tput cnorm; return' INT
    tput civis
    while true; do
        local output
        output=$(ps -Axo rss=,%cpu=,comm= | awk -v total="$(sysctl -n hw.memsize)" '
          BEGIN { tgb = total / 1073741824 }
          {
            mb = $1 / 1024
            cpu = $2 + 0
            p = $3; for (i = 4; i <= NF; i++) p = p " " $i
            n = split(p, a, "/")
            name = a[n]
            for (i = 1; i <= n; i++)
              if (a[i] ~ /\.app$/) { gsub(/\.app$/, "", a[i]); name = a[i]; break }
            m[name] += mb; cp[name] += cpu
          }
          END {
            for (n in m)
              printf "%-20s %7.2f %5.1f%% %5.1f%%\n", n, m[n]/1024, m[n]/1024/tgb*100, cp[n]
          }' | sort -rn -k2 | head -10 | \
        awk 'BEGIN {
            printf "%-20s %7s %5s %5s\n", "APPLICATION", "GB", "%MEM", "%CPU"
            printf "%-20s %7s %5s %5s\n", "--------------------", "-------", "-----", "-----"
          }
          { print; sum_gb += $2; sum_mem += $3; sum_cpu += $4 }
          END {
            printf "%-20s %7s %5s %5s\n", "--------------------", "-------", "-----", "-----"
            printf "%-20s %7.2f %5.1f%% %5.1f%%\n", "TOTAL (top 10)", sum_gb, sum_mem, sum_cpu
          }')
        clear
        echo "$output"
        echo ""
        echo "Press q or Ctrl-C to exit"
        if read -t 1 -k 1 key 2>/dev/null && [[ "$key" == "q" ]]; then
            break
        fi
    done
    tput cnorm
}

# Build Lilium from the current directory (or the main repo) and install+launch
# it on Tobias's iPhone 17 Pro. Two UUIDs per device:
#   - provisioning UDID (xcodebuild): 00008150-00124D500108401C
#   - CoreDevice UUID (devicectl):    911101B1-0BE6-5943-A15E-E2F78F289A00
lilaDevice() {
  local proj
  if [[ -f "./Lilium.xcodeproj/project.pbxproj" ]]; then
    proj="$(pwd)/Lilium.xcodeproj"
  else
    proj="$HOME/Developer/personal/lilium/Lilium.xcodeproj"
  fi
  local provisioning_udid="00008150-00124D500108401C"
  local coredevice_uuid="911101B1-0BE6-5943-A15E-E2F78F289A00"
  local bundle_id="se.laross.lila"

  echo "Building $proj for Tobias's iPhone 17 Pro…"
  xcodebuild -project "$proj" -scheme Lilium -configuration Debug \
    -destination "id=$provisioning_udid" -allowProvisioningUpdates build || return $?

  local app_path
  app_path=$(ls -td "$HOME"/Library/Developer/Xcode/DerivedData/Lilium-*/Build/Products/Debug-iphoneos/Lilium.app 2>/dev/null | head -1)
  if [[ -z "$app_path" ]]; then
    echo "Could not locate built Lilium.app"
    return 1
  fi

  echo "Installing $app_path…"
  xcrun devicectl device install app --device "$coredevice_uuid" "$app_path" || return $?

  echo "Launching $bundle_id…"
  xcrun devicectl device process launch --device "$coredevice_uuid" "$bundle_id"
}

# Stream Lilium logs from Tobias's iPhone 17 Pro over the network.
lilaLogs() {
  idevicesyslog -n -q -u 00008150-00124D500108401C -m Lilium "$@"
}

# ---------------------------------------------------------------------------
# Autonomous user-agent helpers (Agentic-QA backend)
#
# The harness lives at ~/Developer/personal/Agentic-QA and is installed via
# `pipx install -e ~/Developer/personal/Agentic-QA`, putting `agentic-qa` on
# PATH. Per-project config (bundle id, scheme, persona clones, …) lives at
# ~/.agentic-qa/config.yml and is merged from lilium/.agentic-qa.yml via
# `agentic-qa init lilium --from-repo ~/Developer/personal/lilium`.
#
# Each persona has its own dedicated iPhone simulator clone, named exactly
# "Emily" / "Jonas" / "Lina" (no prefix). `lila<Persona>` builds Lilium for
# the simulator, installs on the clone, and runs a session.
# `lila<Persona>Log` tails the persona's most recent `events.ndjson` (last
# 25 lines, then live).
# ---------------------------------------------------------------------------

# Persona launchers. The build / sim-boot / install / run logic lives in
# `agentic-qa run` (see scripts/launch-persona.sh in the Agentic-QA repo).
lilaEmily() { agentic-qa run --project lilium --persona emily "$@" }
lilaJonas() { agentic-qa run --project lilium --persona jonas "$@" }
lilaLina()  { agentic-qa run --project lilium --persona lina  "$@" }

# Internal: tail the persona's most recent agent session, showing the
# last 25 lines first, then following new events. Pretty-prints each
# line with `jq` so the timeline is readable instead of raw NDJSON.
_lilaAgentLog() {
  local persona="$1"
  local sessions_root="$HOME/.agentic-qa/lilium/sessions"
  if [[ ! -d "$sessions_root" ]]; then
    echo "No sessions yet under $sessions_root" >&2
    return 1
  fi

  # Match folder names that end in -<persona> (each session dir is
  # `<utc-timestamp>-<persona>`).
  local latest
  latest=$(ls -t "$sessions_root" 2>/dev/null | grep -- "-${persona}\$" | head -1)
  if [[ -z "$latest" ]]; then
    echo "No session found for persona '$persona' under $sessions_root" >&2
    return 1
  fi

  local events="$sessions_root/$latest/events.ndjson"
  echo "Tailing $events"
  if (( ${+commands[jq]} )); then
    tail -n 25 -f "$events" \
      | jq -c '{ts: .ts, kind: .kind, summary: (.tool // .text // .message // .title // null)}'
  else
    tail -n 25 -f "$events"
  fi
}

lilaEmilyLog() { _lilaAgentLog emily }
lilaJonasLog() { _lilaAgentLog jonas }
lilaLinaLog()  { _lilaAgentLog lina }

# Restart the multi-persona dashboard so it picks up source changes.
#
# The dashboard runs as a launchd-managed always-on service (installed via
# `agentic-qa serve --project lilium --install-launchd`). Editable pipx
# means *.py changes are on disk immediately, but the running interpreter
# has the old code in memory until the process restarts. `kickstart -k`
# stops the current PID; launchd respawns it within ~3 s with the latest
# code. Browser tab survives via Tailscale and reconnects on next poll.
#
# Dashboard URL: http://mbp1/agentic-qa/ (or http://127.0.0.1:8765/agentic-qa/).
lilaReport() {
  local label="com.tobiaslaross.agentic-qa.dashboard.lilium"
  local domain="gui/$UID"
  if ! launchctl print "$domain/$label" >/dev/null 2>&1; then
    echo "lilaReport: launchd agent not installed. Run once:" >&2
    echo "  agentic-qa serve --project lilium --install-launchd" >&2
    return 1
  fi
  launchctl kickstart -k "$domain/$label"
  # Wait for the new pid to start serving.
  local i=0
  while (( i < 30 )); do
    if curl -sf -o /dev/null --max-time 1 http://127.0.0.1:8765/agentic-qa/api/status; then
      break
    fi
    sleep 0.1
    i=$((i + 1))
  done
  local pid=$(launchctl print "$domain/$label" 2>/dev/null | awk -F'= ' '/^[[:space:]]*pid =/ { print $2; exit }')
  echo "lilaReport: dashboard restarted (pid $pid) on http://mbp1/agentic-qa/ + http://127.0.0.1:8765/agentic-qa/"
  if [[ "${LILA_OPEN:-1}" == "1" ]] && command -v open >/dev/null 2>&1; then
    open "http://127.0.0.1:8765/agentic-qa/"
  fi
}
