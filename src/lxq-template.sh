#!/usr/bin/env bash
set -Eeuo pipefail

if is_set "${LXQ_SHORT_SUMMARY+x}"; then
    printf "\t\tManage sandbox templates"
    exit 0
fi

function show_usage() {
    printf "Usage: lxq template [command]\n" >&2
    printf "\n" >&2
    printf "Available commands:\n" >&2
    printf "  list\t\tList templates\n" >&2
    printf "  create\tCreate a template\n" >&2
    printf "  destroy\tDestroy a template\n" >&2
    printf "  attach\tAttach a terminal to a template\n" >&2
    printf "  edit\t\tEdit LXC config for a template\n" >&2
    printf "\n" >&2
    printf "Flags:\n">&2
    printf "  -h, --help\t\tShow help message then exit\n" >&2
}

function show_usage_and_exit() {
    show_usage
    exit 1
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
            edit)
                LXQ_COMMAND="edit"
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

    shift 1
    LXQ_HOOK_DIR="${LXQ_REPO_DIR}/hooks/template" \
        "${LXQ_SCRIPT_DIR}/lxq-template-${LXQ_COMMAND}.sh" "$@"
    exit "${?}"
fi

if is_set "${ARG_HELP+x}"; then
    show_usage_and_exit
fi

echo "No arguments specified."
show_usage_and_exit
