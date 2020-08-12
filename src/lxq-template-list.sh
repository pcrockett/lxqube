#!/usr/bin/env bash
set -Eeuo pipefail

if lxq_is_set "${LXQ_SHORT_SUMMARY+x}"; then
    printf "\t\t\tList templates"
    exit 0
fi

lxq_check_dependencies lxc-start lxc-wait lxc-attach lxc-stop

function show_usage() {
    printf "Usage: lxq template list\n" >&2
    printf "\n" >&2
    printf "Flags:\n">&2
    printf "  -h, --help\t\tShow help message then exit\n" >&2
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
            *)
                echo "Unrecognized argument: ${1}"
                show_usage_and_exit
            ;;
        esac

        shift ${consume}
    done
}

parse_commandline "$@"

if lxq_is_set "${ARG_HELP+x}"; then
    show_usage_and_exit
fi

lxc-ls --fancy --filter "^templ-.+$"
