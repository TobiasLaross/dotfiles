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
    local fzf_height="50%"
    local project_list=$(get_project_list)

    # Apply filter if requested
    if [[ "$1" == "existing" ]]; then
        project_list=$(echo "$project_list" | filter_existing_sessions)
    fi

    echo "$project_list" | colorize_projects |
        fzf --ansi -m -1 --border=rounded --border-label="Repo" --color="border:#5A5F8C"
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
