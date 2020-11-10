#!/usr/bin/env bash

SDIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "$SDIR/helpers.sh"

refresh_status() {
    local rt timeout
    timeout=$(get_tmux_option '@web_reachable_timeout' '3000')


    if rt=$(httping www.google.com -sc1 -t "$timeout" 2>/dev/null | grep -Po '(?<=time=)\d+'); then
        set_tmux_option '@web_reachable_status' "$(get_tmux_option '@web_reachable_symbol' '✓')"
        set_tmux_option '@web_reachable_rt' "$rt"
    else
        set_tmux_option '@web_reachable_status' "$(get_tmux_option '@web_unreachable_symbol' '✕')"
        set_tmux_option '@web_reachable_rt' "-"
    fi
}

update_status() {
    local pre cur refresh_interval
    cur=$(date +%s)
    pre=$(get_tmux_option "@web_reachable_ts" "0")
    refresh_interval=$(get_tmux_option "@web_reachable_refresh_interval" "10")
    if (( cur - pre > refresh_interval)); then
        refresh_status
        set_tmux_option '@web_reachable_ts' "$cur"
    fi
}

main() {
    update_status
    case $1 in
        rt )
            printf "%s" "$(get_tmux_option "@web_reachable_rt")"
            ;;
        status )
            printf "%s" "$(get_tmux_option "@web_reachable_status")"
    esac
}

main "$@"
