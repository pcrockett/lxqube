#!/usr/bin/env bash
set -Eeuo pipefail

readonly DEPENDENCIES=(lxc-start lxc-wait lxc-attach lxc-stop lxc-copy lxc-destroy)

for dep in "${DEPENDENCIES[@]}"; do
    installed "${dep}" || panic "Missing '${dep}'"
done

function show_usage() {
    printf "Usage: lxq sandbox stop [sandbox-name]\n" >&2
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
                if is_set "${ARG_SANDBOX_NAME+x}"; then
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

if is_set "${ARG_HELP+x}"; then
    show_usage_and_exit
fi

is_set "${ARG_SANDBOX_NAME+x}" || panic "No sandbox name specified."

sandbox_file="${LXQ_SANDBOXES_ROOT_DIR}/${ARG_SANDBOX_NAME}"

test -e "${sandbox_file}" || panic "Sandbox ${ARG_SANDBOX_NAME} does not exist."

# shellcheck source=/dev/null
. "${sandbox_file}"

sandbox_cont_name="lxq-sbox-${ARG_SANDBOX_NAME}"

lxc-stop "${sandbox_cont_name}"
lxc-wait --name "${sandbox_cont_name}" \
    --state STOPPED

lxc-destroy --name "${sandbox_cont_name}"
