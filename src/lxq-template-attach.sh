#!/usr/bin/env bash
set -Eeuo pipefail

if lxq_is_set "${LXQ_SHORT_SUMMARY+x}"; then
    printf "\t\tAttach a terminal to a template"
    exit 0
fi

lxq_check_dependencies lxc-attach

function show_usage() {
    printf "Usage: lxq template attach [template-name]\n" >&2
    printf "\n" >&2
    printf "Flags:\n">&2
    printf "  -u, --user\t\tLogin as sandboxed user\n" >&2
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
            -u|--user)
                ARG_USER="true"
            ;;
            *)
                if lxq_is_set "${ARG_TEMPLATE_NAME+x}"; then
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

if lxq_is_set "${ARG_HELP+x}"; then
    show_usage_and_exit
fi

lxq_is_set "${ARG_TEMPLATE_NAME+x}" || lxq_panic "No template name specified."

lxq_start_net_svc

template_dir="${LXQ_TEMPLATES_ROOT_DIR}/${ARG_TEMPLATE_NAME}"
test -d "${template_dir}" || lxq_panic "Template ${ARG_TEMPLATE_NAME} does not exist."

template_cont_name="templ-${ARG_TEMPLATE_NAME}"

if lxq_is_set "${ARG_USER+x}"; then
    lxc-attach --name "${template_cont_name}" \
        --clear-env \
        --keep-var TERM \
        -- \
        sudo --login --user "${LXQ_CONTAINER_USER}" || true # "|| true" to disregard exit code
else
    lxc-attach --name "${template_cont_name}" \
        --clear-env \
        --keep-var TERM || true # "|| true" to disregard exit code
fi
