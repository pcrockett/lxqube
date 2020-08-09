#!/usr/bin/env bash
set -Eeuo pipefail

if is_set "${LXQ_SHORT_SUMMARY+x}"; then
    printf "\t\tDestroy a template"
    exit 0
fi

readonly DEPENDENCIES=(lxc-destroy)
readonly TEMPLATES_CONFIG_DIR="${LXQ_REPO_DIR}/templates"

for dep in "${DEPENDENCIES[@]}"; do
    installed "${dep}" || panic "Missing '${dep}'"
done

function show_usage() {
    printf "Usage: lxq template destroy [template-name]\n" >&2
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

lxc-destroy --name "templ-${ARG_TEMPLATE_NAME}"
rm -r "${TEMPLATES_CONFIG_DIR:?}/${ARG_TEMPLATE_NAME:?}"

LXQ_TEMPLATE_NAME="${ARG_TEMPLATE_NAME}" \
    lxq_hook "template/post-destroy"
