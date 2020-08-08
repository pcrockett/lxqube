#!/usr/bin/env bash
set -Eeuo pipefail
[[ "${BASH_VERSINFO[0]}" -lt 4 ]] && echo "Bash >= 4 required" && exit 1

function show_usage() {
    printf "Usage: lxq sandbox [command]\n" >&2
    printf "\n" >&2
    printf "Available commands:\n" >&2
    printf "  list\t\tList sandboxes\n" >&2
    printf "  create\tCreate a sandbox\n" >&2
    printf "  start\t\tStart a sandbox\n" >&2
    printf "  attach\tAttach a terminal to a sandbox\n" >&2
    printf "  stop\t\tStop a sandbox\n" >&2
    printf "  destroy\tDestroy a sandbox\n" >&2
    printf "\n" >&2
    printf "Flags:\n">&2
    printf "  -h, --help\tShow help message then exit\n" >&2
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
            start)
                LXQ_COMMAND="start"
            ;;
            attach)
                LXQ_COMMAND="attach"
            ;;
            stop)
                LXQ_COMMAND="stop"
            ;;
            destroy)
                LXQ_COMMAND="destroy"
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
            --short-summary)
                # This argument intentionally undocumented in usage. Only used internally.
                ARG_SHORT_SUMMARY="true"
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

if is_set "${ARG_SHORT_SUMMARY+x}"; then
    printf "\t\tManage sandboxes"
    exit 0
fi

if is_set "${LXQ_COMMAND+x}"; then

    export LXQ_SANDBOXES_ROOT_DIR="${LXQ_REPO_DIR}/sandboxes"

    if [ ! -d "${LXQ_SANDBOXES_ROOT_DIR}" ]; then
        mkdir --parent "${LXQ_SANDBOXES_ROOT_DIR}"
    fi

    shift 1
    LXQ_HOOK_DIR="${LXQ_REPO_DIR}/hooks/sandbox" \
        "${LXQ_SCRIPT_DIR}/lxq-sandbox-${LXQ_COMMAND}.sh" "$@"
    exit "${?}"
fi

if is_set "${ARG_HELP+x}"; then
    show_usage_and_exit
fi;

echo "No arguments specified."
show_usage_and_exit
