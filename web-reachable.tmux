#!/usr/bin/env bash

SDIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "$SDIR/scripts/helpers.sh"

web_status_interpolation="\#{web_reachable_status}"
web_status="#($SDIR/scripts/core.sh status)"

web_status_rt_interpolation="\#{web_reachable_rt}"
web_status_rt="#($SDIR/scripts/core.sh rt)"

do_interpolation() {
    local result=$1
    result="${result/$web_status_interpolation/$web_status}"
    result="${result/$web_status_rt_interpolation/$web_status_rt}"
    echo "$result"
}

update_tmux_option() {
    local option option_value
    option=$1
    option_value=$(get_tmux_option "$option")
    set_tmux_option "$option" "$(do_interpolation "$option_value")"
}

main() {
    update_tmux_option "status-right"
    update_tmux_option "status-left"
}
main
