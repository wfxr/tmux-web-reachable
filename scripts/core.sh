#!/usr/bin/env bash

SDIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "$SDIR/helpers.sh"

refresh_status() {
    local rt url
    url=$(get_tmux_option '@web_reachable_url' 'www.google.com')

    rt=$(httping "$url" -sc1 -t "$1" 2>/dev/null | grep -Po '(?<=time=)\d+') || rt=-1
    set_tmux_option '@web_reachable_rt' "$rt"
}

update_status() {
    local pre cur refresh_interval
    cur=$(date +%s)
    pre=$(get_tmux_option "@web_reachable_ts" "0")
    refresh_interval=$(get_tmux_option "@web_reachable_refresh_interval" "10")

    read -ra symbols    <<<"$(get_tmux_option '@web_reachable_symbols'    '🟢 🟡 🔴')"
    read -ra thresholds <<<"$(get_tmux_option '@web_reachable_thresholds' '500 750')"
    timeout=$(( (thresholds[1] - 1) / 1000 + 1 ))

    rt=$(get_tmux_option "@web_reachable_rt" "-1")
    if (( rt == -1 )); then
        symbol_id=2
    elif (( rt < thresholds[0] )); then
        symbol_id=0
    elif (( rt < thresholds[1] )); then
        symbol_id=1
    else
        symbol_id=2
    fi
    if  (( rt == -1 || cur - pre > refresh_interval)); then
        refresh_status "$timeout"
        set_tmux_option '@web_reachable_ts' "$cur"
    fi
    set_tmux_option '@web_reachable_status' "${symbols[$symbol_id]}"
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
