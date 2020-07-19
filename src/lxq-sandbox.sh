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

readonly SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
readonly SCRIPT_NAME=$(basename "$0")
readonly DEPENDENCIES=()

function panic() {
    >&2 echo "Fatal: $*"
    exit 1
}

function installed() {
    command -v "$1" >/dev/null 2>&1
}

for dep in "${DEPENDENCIES[@]}"; do
    installed "${dep}" || panic "Missing '${dep}'"
done

function show_usage() {
    printf "Usage: lxq sandbox [command]\n" >&2
    printf "\n" >&2
    printf "Available commands:\n" >&2
    printf "  list\t\tList sandboxes\n" >&2
    printf "  create\tCreate a sandbox\n" >&2
    printf "  destroy\tDestroy a sandbox\n" >&2
    printf "  attach\tAttach a terminal to a sandbox\n" >&2
    printf "\n" >&2
    printf "Flags:\n">&2
    printf "  -h, --help\t\tShow help message then exit\n" >&2
}

function show_usage_and_exit() {
    show_usage
    exit 1
}

function is_set() {
    # Use this like so:
    #
    #     is_set "${VAR_NAME+x}" || show_usage_and_exit
    #
    # https://stackoverflow.com/a/13864829

    test ! -z "$1"
}

function parse_commandline() {

    if [ "${#}" -gt "0" ]; then
        case "$1" in
            list)
                LXQ_COMMAND="list"
            ;;
            create)
                LXQ_COMMAND="create"
            ;;
            destroy)
                LXQ_COMMAND="destroy"
            ;;
            attach)
                LXQ_COMMAND="attach"
            ;;
        esac

        if is_set "${LXQ_COMMAND+x}"; then
            return
        fi
    fi

    while [ "${#}" -gt "0" ]; do
        local consume=1

        case "$1" in
            -h|-\?|--help)
                ARG_HELP="true"
            ;;
            *)
                echo "Unrecognized argument: ${1}"
                show_usage_and_exit
            ;;
        esac

        shift ${consume}
    done
}

parse_commandline "$@"

if is_set "${LXQ_COMMAND+x}"; then

    export LXQ_SANDBOX_DIR="${LXQ_REPO_DIR}/sandboxes"

    if [ ! -d "${LXQ_SANDBOX_DIR}" ]; then
        mkdir --parent "${LXQ_SANDBOX_DIR}"
    fi

    shift 1
    "${SCRIPT_DIR}/lxq-sandbox-${LXQ_COMMAND}.sh" "$@"
    exit "${?}"
fi

if is_set "${ARG_HELP+x}"; then
    show_usage_and_exit
fi;

echo "No arguments specified."
show_usage_and_exit
