#!/bin/zsh

# Define color codes for different project types
typeset -A colors=(
    personal $'\e[32m'
    work $'\e[33m'
    dotfiles $'\e[35m'
    reset $'\e[0m'
)

filter_existing_sessions() {
    local project_dir
    local session_name
    local existing_sessions=$(tmux list-sessions -F "#{session_name}" 2>/dev/null)

    while read -r project_dir; do
        # Convert directory name to session name using the same logic as in main()
        local directory=$(basename "$project_dir")
        local session_name="${directory//:/_}"
        session_name="${session_name// /_}"
        session_name="${session_name//./_}"
        session_name=${(L)session_name}    # Convert to lowercase
        session_name=${(C)session_name}    # Capitalize first letter

        # Check if this session exists
        if echo "$existing_sessions" | grep -q "^${session_name}$"; then
            echo "$project_dir"
        fi
    done
}

# Fetch all available project directories
get_project_list() {
    local current_dir=$(tmux display-message -p -F "#{pane_current_path}" 2>/dev/null)
    if [[ "$DOTFILES" != "$current_dir" ]]; then
        echo $DOTFILES
    fi
    find $WORK $PERSONAL -mindepth 1 -maxdepth 1 \( -type d -o -type l \) | grep -v "^$current_dir$" | sort
}

# Colorize project directories for display in fzf
colorize_projects() {
    awk -v work=$WORK -v personal=$PERSONAL -v dotfiles=$DOTFILES \
        -v workColor="${colors[work]}" -v personalColor="${colors[personal]}" \
        -v dotfilesColor="${colors[dotfiles]}" -v reset="${colors[reset]}" '
    {
        if ($0 == dotfiles)
            printf "%s%s%s\n", dotfilesColor, $0, reset
        else if (index($0, work) == 1)
            printf "%s%s%s\n", workColor, $0, reset
        else if (index($0, personal) == 1)
            printf "%s%s%s\n", personalColor, $0, reset
    }'
}

# Use fzf to select a project directory
select_project() {
    local project_list=$(get_project_list)
    local border_label="Repo"
    local header="All Repos"
    local all_projects_colored=$(echo "$project_list" | colorize_projects)

    if [[ "$1" == "existing" ]]; then
        local filtered=$(echo "$project_list" | filter_existing_sessions)
        if [[ -n "$filtered" ]]; then
            project_list="$filtered"
            border_label="Open Sessions"
            header="Open Sessions  (Ctrl-A: show all)"
        else
            # No open sessions matched — fall back to full list seamlessly
            border_label="All Repos"
            header="All Repos  (no open sessions)"
        fi
    fi

    echo "$project_list" | colorize_projects |
        fzf --ansi -1 \
            --border=rounded \
            --border-label="$border_label" \
            --color="border:#5A5F8C" \
            --header="$header" \
            --preview='git -C {} log --oneline --color=always -10 2>/dev/null || echo "Not a git repo"' \
            --preview-window=right:40%:wrap \
            --bind "ctrl-a:reload(echo \"$all_projects_colored\")+change-header(All Repos)+change-border-label(Repo)"
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

    local directory=$(basename "$project_dir")
    local session_name="${directory//:/_}"
    session_name="${session_name// /_}"
    session_name="${session_name//./_}"
    session_name=${(L)session_name}    # Convert to lowercase
    session_name=${(C)session_name}    # Capitalize first letter

    manage_tmux_session "$project_dir" "$session_name"
}

main "$@"
