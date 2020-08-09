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

readonly LXQ_PLUGIN_DIR="${LXQ_REPO_DIR}/plugins"
export LXQ_PLUGIN_DIR

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

function lxq_hook() {

    is_set "${1+x}" || panic "Expecting hook name as parameter, i.e. 'sandbox/pre-start'"
    HOOK_NAME="${1}"

    hook_path="${LXQ_REPO_DIR}/hooks/${HOOK_NAME}.sh"
    if [ -e "${hook_path}" ]; then
        "${hook_path}"
    fi

    plugin_dirs=$(find -L "${LXQ_PLUGIN_DIR}" -maxdepth 1 -mindepth 1 -type d)
    for plugin_dir in $plugin_dirs
    do
        hook_path="${plugin_dir}/hooks/${HOOK_NAME}.sh"
        if [ -e "${hook_path}" ]; then
            "${hook_path}"
        fi
    done
}
export -f lxq_hook

function compile_config() {

    is_set "${1+x}" || panic "Expecting source dir, i.e. 'LXQ_REPO_DIR/templates/default/config.d'."
    is_set "${2+x}" || panic "Expecting dest config file, i.e. 'LXQ_REPO_DIR/templates/default/config'."

    ARG_CONFIG_DIRS=()
    while [ "${#}" -gt "0" ]; do

        if [ "${#}" -gt "1" ]; then
            ARG_CONFIG_DIRS+=("${1}")
        else
            ARG_DEST_CONFIG_FILE="${1}"
        fi

        shift 1
    done

    cat > "${ARG_DEST_CONFIG_FILE}" << EOF
###############################################################################
#    This file is auto-generated. Any changes you make here will be lost.     #
###############################################################################
EOF

    for dir in "${ARG_CONFIG_DIRS[@]}"
    do
        if [ -d "${dir}" ]; then

            config_files=$(find "${dir}" -maxdepth 1 -mindepth 1 -type f -name "*.conf" | sort)
            for c in $config_files
            do
                cat "${c}" >> "${ARG_DEST_CONFIG_FILE}"
            done
        fi
    done
}
export -f compile_config
