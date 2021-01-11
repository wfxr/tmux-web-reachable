#!/usr/bin/env bash

SDIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "$SDIR/helpers.sh"

refresh_status() {
    local rt url
    url=$(get_tmux_option '@web_reachable_url' 'google.com')
    rt=$(curl -fsm "$1" -w '%{time_total}' "$url" -o /dev/null) || rt=-1
    rt=$(echo "($rt/1000)/1" | bc)
    set_tmux_option '@web_reachable_rt' "$rt"
}

update_status() {
    local pre cur refresh_interval timeout rt
    cur=$(date +%s)
    pre=$(get_tmux_option "@web_reachable_ts" "0")
    refresh_interval=$(get_tmux_option "@web_reachable_refresh_interval" "10")
    timeout=$(( (thresholds[1] - 1) / 1000 + 1 ))

    rt=$(get_tmux_option "@web_reachable_rt" "-1")
    if  (( rt < 0 || cur - pre > refresh_interval)); then
        refresh_status "$timeout"
        set_tmux_option '@web_reachable_ts' "$cur"
        rt=$(get_tmux_option "@web_reachable_rt" "-1")
    fi
    if (( rt < 0 )); then
        symbol_id=3
    elif (( rt < thresholds[0] )); then
        symbol_id=1
    elif (( rt < thresholds[1] )); then
        symbol_id=2
    else
        symbol_id=3
    fi
    set_tmux_option '@web_reachable_status' "${symbols[$symbol_id]}"
}

initialized() {
    [ "$(get_tmux_option "@web_reachable_initialized")" == 'true' ]
}

initialize() {
    set_tmux_option '@web_reachable_initialized' "true"
    set_tmux_option '@web_reachable_status' "${symbols[0]}"
    set_tmux_option '@web_reachable_ts' "-1"
    set_tmux_option '@web_reachable_rt' "-1"
}

main() {
    IFS="|" read -ra symbols    <<<"$(get_tmux_option '@web_reachable_symbols'    '🔵|🟢|🟡|🔴')"
    IFS=" " read -ra thresholds <<<"$(get_tmux_option '@web_reachable_thresholds' '500 750')"
    if initialized; then update_status; else initialize; fi

    case $1 in
        rt )
            printf "%s" "$(get_tmux_option "@web_reachable_rt")"
            ;;
        status )
            printf "%s" "$(get_tmux_option "@web_reachable_status")"
    esac
}

main "$@"
