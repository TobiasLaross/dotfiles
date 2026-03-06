#!/bin/zsh
zmodload zsh/files

# Define color codes for different project types
typeset -A colors=(
    personal $'\e[32m'
    work $'\e[33m'
    dotfiles $'\e[35m'
    reset $'\e[0m'
)

# Fetch all available project directories
get_project_list() {
    local current_dir=$PWD
    if [[ "$DOTFILES" != "$current_dir" ]]; then
        echo $DOTFILES
    fi
    find $WORK $PERSONAL -mindepth 1 -maxdepth 1 \( -type d -o -type l \) | grep -v "^$current_dir$" | sort
}

# Reads project paths from stdin, prints those with an open tmux session.
# Args: sessions_file
filter_existing_sessions() {
    local sessions_file="$1"

    # Load sessions into an associative array for O(1) lookup (avoids forking
    # a grep process per directory which causes multi-second delays)
    local -A session_set
    local sess
    while IFS= read -r sess; do
        session_set[$sess]=1
    done < "$sessions_file"

    local project_dir session_name directory
    while IFS= read -r project_dir; do
        directory="${project_dir:t}"
        session_name="${directory//:/_}"
        session_name="${session_name// /_}"
        session_name="${session_name//./_}"
        session_name=${(L)session_name}
        session_name=${(C)session_name}

        (( ${+session_set[$session_name]} )) && print -r -- "$project_dir"
    done
}

# Reads project paths from stdin, prints ANSI-colored lines for fzf.
colorize_projects() {
    local line
    while IFS= read -r line; do
        if [[ "$line" == "$DOTFILES" ]]; then
            print -r -- "${colors[dotfiles]}${line}${colors[reset]}"
        elif [[ "$line" == ${WORK}/* ]]; then
            print -r -- "${colors[work]}${line}${colors[reset]}"
        elif [[ "$line" == ${PERSONAL}/* ]]; then
            print -r -- "${colors[personal]}${line}${colors[reset]}"
        fi
    done
}

# Use fzf to select a project directory
select_project() {
    if [[ "$1" == "existing" ]]; then
        # Kick off tmux list-sessions in the background while find runs
        local sessions_file="/tmp/sessionizer_sessions_$$"
        tmux list-sessions -F "#{session_name}" 2>/dev/null > "$sessions_file" &
        local tmux_pid=$!

        local project_list
        project_list=$(get_project_list)
        wait $tmux_pid

        local all_projects_colored
        all_projects_colored=$(print -r -- "$project_list" | colorize_projects)

        local filtered
        filtered=$(print -r -- "$project_list" | filter_existing_sessions "$sessions_file")
        zf_rm -f "$sessions_file"

        local border_label header display_colored
        if [[ -n "$filtered" ]]; then
            display_colored=$(print -r -- "$filtered" | colorize_projects)
            border_label="Open Sessions"
            header="Open Sessions  (Ctrl-A: show all)"
        else
            # No open sessions matched — reuse already-colorized full list
            display_colored="$all_projects_colored"
            border_label="All Repos"
            header="All Repos  (no open sessions)"
        fi

        print -r -- "$display_colored" |
            fzf --ansi -1 \
                --border=rounded \
                --border-label="$border_label" \
                --color="border:#5A5F8C" \
                --header="$header" \
                --bind "ctrl-a:reload(echo \"$all_projects_colored\")+change-header(All Repos)+change-border-label(Repo)"
    else
        get_project_list | colorize_projects |
            fzf --ansi -1 \
                --border=rounded \
                --border-label="Repo" \
                --color="border:#5A5F8C" \
                --header="All Repos"
    fi
}

# Create a new tmux session or attach to an existing one
manage_tmux_session() {
    local project_dir="$1"
    local session_name="$2"

    if ! tmux has-session -t "$session_name" 2>/dev/null; then
        tmux new-session -d -s "$session_name" -n "Code" -c "$project_dir"
        tmux new-window -t "$session_name" -n "Test" -c "$project_dir"
        if [[ "$session_name" != "Dotfiles" ]]; then
            tmux new-window -t "$session_name" -n "Lazygit" -c "$project_dir"
        fi
    fi
    tmux select-window -t "$session_name:1"

    if [[ -z "$TMUX" ]]; then
        tmux attach-session -t "$session_name"
    else
        tmux switch-client -t "$session_name"
    fi
}

main() {
    local filter_mode="$1"

    # Go to dotfiles if arg equals 'dotfiles'
    if [[ "$filter_mode" == "dotfiles" ]]; then
        local current_session=$(tmux display-message -p "#S")
        if [[ "$current_session" == "Dotfiles" ]]; then
            tmux switch-client -l
            return
        fi

        manage_tmux_session "$DOTFILES" "Dotfiles"
        return
    fi

    # Go to notes if arg equals 'notes'
    if [[ "$filter_mode" == "notes" ]]; then
        local project_dir=""
        if [[ -d "$WORK/notes" ]]; then
            project_dir="$WORK/notes"
        elif [[ -d "$PERSONAL/notes" ]]; then
            project_dir="$PERSONAL/notes"
        else
            echo "Error: notes directory not found in WORK or PERSONAL"
            return 1
        fi

        local current_session=$(tmux display-message -p "#S")
        if [[ "$current_session" == "Notes" ]]; then
            tmux switch-client -l
            return
        fi

        manage_tmux_session "$project_dir" "Notes"
        return
    fi

    local project_dir=$(select_project "$filter_mode")
    if [[ -z "$project_dir" ]]; then
        return 0
    fi

    local directory="${project_dir:t}"
    local session_name="${directory//:/_}"
    session_name="${session_name// /_}"
    session_name="${session_name//./_}"
    session_name=${(L)session_name}    # Convert to lowercase
    session_name=${(C)session_name}    # Capitalize first letter

    manage_tmux_session "$project_dir" "$session_name"
}

main "$@"
