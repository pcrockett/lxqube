#!/usr/bin/env bash
set -Eeuo pipefail

if lxq_is_set "${LXQ_SHORT_SUMMARY+x}"; then
    printf "\t\tAttach a terminal to a template"
    exit 0
fi

readonly DEPENDENCIES=(lxc-start lxc-wait lxc-attach lxc-stop)
lxq_check_dependencies "${DEPENDENCIES[@]}"

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

container_name="templ-${ARG_TEMPLATE_NAME}"
lxq_template_root="${LXQ_REPO_DIR}/templates/${ARG_TEMPLATE_NAME}"
lxq_template_config_dir="${lxq_template_root}/config.d"
test -d "${lxq_template_config_dir}" || mkdir --parent "${lxq_template_config_dir}"

LXQ_TEMPLATE_NAME="${ARG_TEMPLATE_NAME}" \
    lxq_hook "template/pre-start"

lxq_compile_config "${lxq_template_config_dir}" "${lxq_template_root}/config"

lxc-start "${container_name}"
lxc-wait --name "${container_name}" \
    --state RUNNING

LXQ_TEMPLATE_NAME="${ARG_TEMPLATE_NAME}" \
    lxq_hook "template/post-start"

lxc-attach --name "${container_name}" \
    --clear-env \
    --keep-var TERM

LXQ_TEMPLATE_NAME="${ARG_TEMPLATE_NAME}" \
    lxq_hook "template/pre-stop"

lxc-stop "${container_name}"
lxc-wait --name "${container_name}" \
    --state STOPPED

LXQ_TEMPLATE_NAME="${ARG_TEMPLATE_NAME}" \
    lxq_hook "template/post-stop"
