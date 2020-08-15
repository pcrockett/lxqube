#!/usr/bin/env bash
set -Eeuo pipefail

if lxq_is_set "${LXQ_SHORT_SUMMARY+x}"; then
    printf "\t\tGet the status of a sandbox"
    exit 0
fi

lxq_check_dependencies lxc-info

function show_usage() {
    printf "Usage: lxq sandbox status [sandbox-name]\n" >&2
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
                if lxq_is_set "${ARG_SANDBOX_NAME+x}"; then
                    echo "Unrecognized argument: ${1}"
                    show_usage_and_exit
                else
                    ARG_SANDBOX_NAME="${1}"
                fi
            ;;
        esac

        shift ${consume}
    done
}

parse_commandline "$@"

if lxq_is_set "${ARG_HELP+x}"; then
    show_usage_and_exit
fi

lxq_is_set "${ARG_SANDBOX_NAME+x}" || lxq_panic "No sandbox name specified."
test -d "${LXQ_REPO_DIR}/sandboxes/${ARG_SANDBOX_NAME}" || panic "Sandbox \"${ARG_SANDBOX_NAME}\" does not exist."

container_name="sbox-${ARG_SANDBOX_NAME}"
if lxc-info --state --no-humanize "${container_name}" 2&> /dev/null; then
    lxc-info --state --no-humanize "${container_name}"
else
    # When a sandbox is not running, its LXC container is deleted. LXC is
    # reporting the container doesn't exist, yet know we've set up a sandbox.
    # By our definition, the sandbox just hasn't been started yet.
    echo "STOPPED"
fi
