#!/usr/bin/env bash
set -Eeuo pipefail

# Expected environment variables:
#
# * LXQ_HOOK_DIR
#

readonly DEPENDENCIES=(lxc-start lxc-wait lxc-attach lxc-stop)

for dep in "${DEPENDENCIES[@]}"; do
    installed "${dep}" || panic "Missing '${dep}'"
done

function show_usage() {
    printf "Usage: lxq template attach [template-name]\n" >&2
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
                if is_set "${ARG_TEMPLATE_NAME+x}"; then
                    echo "Unrecognized argument: ${1}"
                    show_usage_and_exit
                else
                    ARG_TEMPLATE_NAME="${1}"
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

is_set "${ARG_TEMPLATE_NAME+x}" || panic "No template name specified."

start_lxc_net

container_name="lxq-templ-${ARG_TEMPLATE_NAME}"

LXQ_TEMPLATE_NAME="${ARG_TEMPLATE_NAME}" \
    lxq_hook "pre-start"

lxc-start "${container_name}"
lxc-wait --name "${container_name}" \
    --state RUNNING
lxc-attach --name "${container_name}" \
    --clear-env \
    --keep-var TERM
lxc-stop "${container_name}"
lxc-wait --name "${container_name}" \
    --state STOPPED
