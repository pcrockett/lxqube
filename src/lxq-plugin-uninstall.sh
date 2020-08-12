#!/usr/bin/env bash
set -Eeuo pipefail

if lxq_is_set "${LXQ_SHORT_SUMMARY+x}"; then
    printf "\t\tUninstall a plugin"
    exit 0
fi

function show_usage() {
    printf "Usage: lxq plugin uninstall [plugin-name]\n" >&2
    printf "\n" >&2
    printf "Flags:\n" >&2
    printf "  -h, --help\t\tShow help message then exit\n" >&2
}

function show_usage_and_exit() {
    show_usage
    exit 1
}

function parse_commandline() {

    while [ "${#}" -gt "0" ]; do
        local consume=1

        case "$1" in
            -h|-\?|--help)
                ARG_HELP="true"
            ;;
            *)
                if lxq_is_set "${ARG_PLUGIN_NAME+x}"; then
                    echo "Unrecognized argument: ${1}"
                    show_usage_and_exit
                else
                    ARG_PLUGIN_NAME="${1}"
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

lxq_is_set "${ARG_PLUGIN_NAME+x}" || lxq_panic "No plugin name specified."
test -d "${LXQ_PLUGIN_DIR}" || lxq_panic "Plugin \"${ARG_PLUGIN_NAME}\" is not installed."

plugin_dir="${LXQ_PLUGIN_DIR}/${ARG_PLUGIN_NAME}"
test -d "${plugin_dir}" || lxq_panic "Plugin \"${ARG_PLUGIN_NAME}\" is not installed."
rm -rf "${plugin_dir}"
