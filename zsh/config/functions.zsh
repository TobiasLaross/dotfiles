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
# Autonomous user-agent helpers
#
# Each persona has its own dedicated iPhone simulator clone, named
# exactly "Sara" / "Jonas" / "Lina" (no prefix). The agent harness lives
# at ~/Developer/personal/lilium/agent/ as a Python package using the
# Claude Agent SDK.
#
# `lila<Persona>` rebuilds Lilium for the simulator, installs the fresh
# build on that persona's clone, and launches `python -m agent --persona
# <name>`. `lila<Persona>Log` tails the persona's most recent
# `events.ndjson` (last 25 lines, then live).
# ---------------------------------------------------------------------------

# Resolve a simulator clone's UDID by name. Echoes the UDID on success,
# returns non-zero with a message if the named clone doesn't exist.
_lilaPersonaUDID() {
  local name="$1"
  local udid
  udid=$(xcrun simctl list devices --json 2>/dev/null \
    | jq -r --arg name "$name" \
        '[.devices[] | .[] | select(.name == $name and .isAvailable)] | .[0].udid // empty')
  if [[ -z "$udid" ]]; then
    echo "Could not find a simulator clone named '$name'." >&2
    echo "Available agent clones:" >&2
    xcrun simctl list devices --json 2>/dev/null \
      | jq -r '.devices[] | .[] | select(.name == "Sara" or .name == "Jonas" or .name == "Lina") | "  \(.name) — \(.udid) (\(.state))"' >&2
    return 1
  fi
  echo "$udid"
}

# Internal: build Lilium for the simulator destination, install the .app
# on the named persona's clone, then launch the agent for that persona.
# All steps fail fast and return the offending command's exit code.
_lilaAgentRun() {
  local persona="$1"
  local proj_root="$HOME/Developer/personal/lilium"
  local proj="$proj_root/Lilium.xcodeproj"
  local bundle_id="se.laross.lila"

  if [[ ! -f "$proj/project.pbxproj" ]]; then
    echo "Could not find Lilium.xcodeproj at $proj" >&2
    return 1
  fi

  # Map persona slug to the simulator clone's display name.
  local clone_name
  case "$persona" in
    sara)  clone_name="Sara" ;;
    jonas) clone_name="Jonas" ;;
    lina)  clone_name="Lina" ;;
    *) echo "Unknown persona '$persona' (expected: sara | jonas | lina)" >&2; return 2 ;;
  esac

  local udid
  udid=$(_lilaPersonaUDID "$clone_name") || return 1

  echo "Building Lilium for $clone_name simulator ($udid)…"
  xcodebuild build \
    -project "$proj" \
    -scheme Lilium \
    -configuration Debug \
    -destination "platform=iOS Simulator,id=$udid" \
    CODE_SIGNING_ALLOWED=NO \
    > /tmp/lilium-build-$persona.log 2>&1 \
    || { echo "xcodebuild failed; see /tmp/lilium-build-$persona.log" >&2; return $?; }

  local app_path
  app_path=$(ls -td "$HOME"/Library/Developer/Xcode/DerivedData/Lilium-*/Build/Products/Debug-iphonesimulator/Lilium.app 2>/dev/null | head -1)
  if [[ -z "$app_path" ]]; then
    echo "Could not locate built Lilium.app under DerivedData" >&2
    return 1
  fi

  # Lina's clone is erased every session by the agent, so installing
  # before the agent runs is wasted work for her — the agent will boot
  # her into a freshly-erased state without Lilium present. We skip
  # the install for Lina; the agent's first restart_app will fail and
  # the agent should be launched manually once on Lina to install via
  # the App Store flow (or the user can install after the agent erases).
  if [[ "$persona" != "lina" ]]; then
    echo "Booting $clone_name (if shutdown) and installing $(basename "$app_path")…"
    xcrun simctl boot "$udid" >/dev/null 2>&1   # idempotent
    xcrun simctl install "$udid" "$app_path" || return $?
  else
    echo "Skipping pre-install for Lina — her clone is erased every session by the agent."
    echo "If this is the first run after a reset, install Lilium manually after the agent erases."
  fi

  echo "Launching python -m agent --persona $persona…"
  local agent_rc=0
  ( cd "$proj_root" && "$proj_root/agent/.venv/bin/python" -m agent --persona "$persona" )
  agent_rc=$?

  # Print the post-session token / cost summary unconditionally — even
  # on early exits, the partial events.ndjson is worth seeing. The
  # `--usage` flag was added in feat/token-usage; on older agent
  # checkouts it'll exit with `unrecognized arguments`, which we
  # swallow so the alias keeps working.
  if [[ $agent_rc -eq 0 ]] || [[ $agent_rc -eq 1 ]]; then
    echo
    ( cd "$proj_root" && "$proj_root/agent/.venv/bin/python" -m agent --usage "latest:$persona" 2>/dev/null ) || true
  fi
  return $agent_rc
}

lilaSara()  { _lilaAgentRun sara  "$@" }
lilaJonas() { _lilaAgentRun jonas "$@" }
lilaLina()  { _lilaAgentRun lina  "$@" }

# Internal: tail the persona's most recent agent session, showing the
# last 25 lines first, then following new events. Pretty-prints each
# line with `jq` so the timeline is readable instead of raw NDJSON.
_lilaAgentLog() {
  local persona="$1"
  local sessions_root="$HOME/Developer/personal/lilium/.agentic-user-sessions"
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

lilaSaraLog()  { _lilaAgentLog sara }
lilaJonasLog() { _lilaAgentLog jonas }
lilaLinaLog()  { _lilaAgentLog lina }
