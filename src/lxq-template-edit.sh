#!/usr/bin/env bash
set -Eeuo pipefail

if is_set "${LXQ_SHORT_SUMMARY+x}"; then
    printf "\t\t\tEdit LXC config for a template"
    exit 0
fi

readonly TEMPLATES_CONFIG_DIR="${LXQ_REPO_DIR}/templates"

function show_usage() {
    printf "Usage: lxq template edit [template-name]\n" >&2
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

CONFIG_PATH="${TEMPLATES_CONFIG_DIR}/${ARG_TEMPLATE_NAME}/config"
if [ ! -f "${CONFIG_PATH}" ]; then
    panic "${CONFIG_PATH} does not exist."
fi

if is_set "${EDITOR+x}"; then
    "${EDITOR}" "${CONFIG_PATH}"
elif installed "nano"; then
    nano "${CONFIG_PATH}"
else
    panic "No text editor defined. Set EDITOR environment variable to your desired text editor."
fi
