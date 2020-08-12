#!/usr/bin/env bash
set -Eeuo pipefail

if lxq_is_set "${LXQ_SHORT_SUMMARY+x}"; then
    printf "\t\tAttach a terminal to a sandbox"
    exit 0
fi

readonly DEPENDENCIES=(lxc-start lxc-wait lxc-attach lxc-stop lxc-copy lxc-destroy)
lxq_check_dependencies "${DEPENDENCIES[@]}"

function show_usage() {
    printf "Usage: lxq sandbox attach [sandbox-name]\n" >&2
    printf "\n" >&2
    printf "Flags:\n">&2
    printf "  -h, --help\t\tShow help message then exit\n" >&2
    printf "  -r, --root\t\tLogin as root\n" >&2
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
            -r|--root)
                ARG_ROOT="true"
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

lxq_start_net_svc

sandbox_dir="${LXQ_SANDBOXES_ROOT_DIR}/${ARG_SANDBOX_NAME}"
test -d "${sandbox_dir}" || lxq_panic "Sandbox ${ARG_SANDBOX_NAME} does not exist."

sandbox_cont_name="sbox-${ARG_SANDBOX_NAME}"

if lxq_is_set "${ARG_ROOT+x}"; then
    lxc-attach --name "${sandbox_cont_name}" \
        --clear-env \
        --keep-var TERM || true # "|| true" to disregard exit code
else
    lxc-attach --name "${sandbox_cont_name}" \
        --clear-env \
        --keep-var TERM \
        -- \
        sudo --login --user "${LXQ_CONTAINER_USER}" || true # "|| true" to disregard exit code
fi
