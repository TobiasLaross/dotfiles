#!/bin/zsh

# Define color codes for different project types
typeset -A colors=(
    personal $'\e[32m'
    work $'\e[33m'
    dotfiles $'\e[35m'
    reset $'\e[0m'
)

# Fetch all available project directories
get_project_list() {
    local current_dir=$(tmux display-message -p -F "#{pane_current_path}" 2>/dev/null)
    if [[ "$DOTFILES" != "$current_dir" ]]; then
        echo $DOTFILES
    fi
    find $WORK $PERSONAL -mindepth 1 -maxdepth 1 -type d | grep -v "^$current_dir$" | sort
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
            tmux new-window -t "$session_name" -n "Server" -c "$project_dir"
        fi
    fi
    tmux select-window -t "$session_name:1"

    if [[ -z "$TMUX" ]]; then
        tmux attach-session -t "$session_name"
    else
        tmux switch-client -t "$session_name"
    fi
}

# Main function to handle the overall flow
main() {
    local project_dir=$(select_project)

    if [[ -z "$project_dir" ]]; then
        return 0
    fi

    local directory=$(basename "$project_dir")
    local session_name="${directory//:/_}"
    session_name="${session_name// /_}"
    session_name="${session_name//./_}"
    session_name=${(L)session_name}    # Convert to lowercase
    session_name=${(C)session_name}    # Capitalize first letter
    # session_name=$(echo "$session_name" | tr '[:lower:]' '[:upper:]')

    manage_tmux_session "$project_dir" "$session_name"
}

main "$@"
