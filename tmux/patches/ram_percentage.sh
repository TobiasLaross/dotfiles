#!/usr/bin/env bash

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=scripts/helpers.sh
source "$CURRENT_DIR/helpers.sh"

ram_percentage_format="%3.1f%%"

sum_macos_vm_stats() {
  grep -Eo '[0-9]+' |
    awk '{ a += $1 * 4096 } END { print a }'
}

print_ram_percentage() {
  ram_percentage_format=$(get_tmux_option "@ram_percentage_format" "$ram_percentage_format")

  if command_exists "free"; then
    cached_eval free | awk -v format="$ram_percentage_format" '$1 ~ /Mem/ {printf(format, 100*$3/$2)}'
  elif command_exists "memory_pressure"; then
    # Use memory_pressure instead of vm_stat to get actual memory pressure,
    # ignoring file cache that macOS releases on demand.
    free_pct=$(cached_eval memory_pressure | grep -o '[0-9]*%' | tr -d '%')
    used_pct=$((100 - free_pct))
    printf "$ram_percentage_format" "$used_pct"
  fi
}

main() {
  print_ram_percentage
}
main
