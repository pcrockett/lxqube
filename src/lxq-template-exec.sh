#!/usr/bin/env bash
set -Eeuo pipefail

if lxq_is_set "${LXQ_SHORT_SUMMARY+x}"; then
    printf "\t\t\tExecute commands in a template"
    exit 0
fi

lxq_check_dependencies lxc-start lxc-wait lxc-attach lxc-stop lxc-copy lxc-destroy

function show_usage() {
    printf "Usage: lxq template exec [template-name] [flags] -- [command]\n" >&2
    printf "\n" >&2
    printf "Flags:\n">&2
    printf "  -b, --background\tRun in background using nohup\n" >&2
    printf "  -u, --user\t\tRun as sandboxed user\n" >&2
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
            -b|--background)
                ARG_BACKGROUND="true"
            ;;
            --)
                shift 1
                ARG_COMMAND="${*}"
                return
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

template_dir="${LXQ_TEMPLATES_ROOT_DIR}/${ARG_TEMPLATE_NAME}"
test -d "${template_dir}" || lxq_panic "Template ${ARG_TEMPLATE_NAME} does not exist."

template_cont_name="templ-${ARG_TEMPLATE_NAME}"

full_command=()
if lxq_is_set "${ARG_BACKGROUND+x}"; then
    full_command+=("nohup")
fi

full_command+=("bash" "-c")

if lxq_is_set "${ARG_USER+x}"; then
    full_command+=("sudo --user ${LXQ_CONTAINER_USER} ${ARG_COMMAND}")
else
    full_command+=("${ARG_COMMAND}")
fi

if lxq_is_set "${ARG_BACKGROUND+x}"; then
    full_command+=("&")
fi

lxc_command=(lxc-attach --name "${template_cont_name}" --clear-env --keep-var TERM -- "${full_command[@]}")

if lxq_is_set "${ARG_BACKGROUND+x}"; then
    "${lxc_command[@]}" 2&> /dev/null < /dev/stdin &
else
    "${lxc_command[@]}"
fi
