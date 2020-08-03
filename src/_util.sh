#!/usr/bin/env bash

# This script is based on the template here:
#
#     https://gist.github.com/pcrockett/8e04641f8473081c3a93de744873f787
#
# It was copy/pasted here into this file and then modified extensively.
#
# Useful links when writing a script:
#
# Shellcheck: https://github.com/koalaman/shellcheck
# vscode-shellcheck: https://github.com/timonwong/vscode-shellcheck
#
# I stole many of my ideas here from:
#
# https://blog.yossarian.net/2020/01/23/Anybody-can-write-good-bash-with-a-little-effort
# https://dave.autonoma.ca/blog/2019/05/22/typesetting-markdown-part-1/
#

# https://vaneyckt.io/posts/safer_bash_scripts_with_set_euxo_pipefail/
set -Eeuo pipefail

[[ "${BASH_VERSINFO[0]}" -lt 4 ]] && echo "Bash >= 4 required" && exit 1

readonly LXQ_SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
export LXQ_SCRIPT_DIR

readonly LXQ_REPO_DIR=$(dirname "${LXQ_SCRIPT_DIR}")
export LXQ_REPO_DIR

function panic() {
    >&2 echo "Fatal: $*"
    exit 1
}
export -f panic

function installed() {
    command -v "$1" >/dev/null 2>&1
}
export -f installed

function is_set() {
    # Use this like so:
    #
    #     is_set "${VAR_NAME+x}" || show_usage_and_exit
    #
    # https://stackoverflow.com/a/13864829

    test ! -z "$1"
}
export -f is_set

function start_lxc_net() {
    if [ "$(systemctl is-active lxc-net)" != "active" ]; then
        echo "Starting lxc-net service..."
        sudo systemctl start lxc-net
    fi
}
export -f start_lxc_net
