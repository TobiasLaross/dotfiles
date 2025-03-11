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

