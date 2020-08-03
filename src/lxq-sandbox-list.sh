#!/usr/bin/env bash
set -Eeuo pipefail

function show_usage() {
    printf "Usage: lxq sandbox list\n" >&2
    printf "\n" >&2
    printf "Flags:\n">&2
    printf "  -h, --help\t\tShow help message then exit\n" >&2
    printf "  -r, --running\t\tList running sandboxes\n"
}

function show_usage_and_exit() {
    show_usage
    exit 1
}

function parse_commandline() {

    while [ "${#}" -gt "0" ]; do
        local consume=1

        case "${1}" in
            -h|-\?|--help)
                ARG_HELP="true"
            ;;
            -r|--running)
                ARG_RUNNING="true"
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

if is_set "${ARG_HELP+x}"; then
    show_usage_and_exit
fi

if is_set "${ARG_RUNNING+x}"; then
    lxc-ls --fancy --filter "^lxq-sbox-.+$"
else
    ls "${LXQ_SANDBOXES_ROOT_DIR}"
fi
