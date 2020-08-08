#!/usr/bin/env bash
set -Eeuo pipefail

if is_set "${LXQ_SHORT_SUMMARY+x}"; then
    printf "\t\tInstall a plugin"
    exit 0
fi

function show_usage() {
    printf "Usage: lxq plugin install [--dir <directory> | --clone <git-url>]\n" >&2
    printf "\n" >&2
    printf "Available options:\n" >&2
    printf "  -d, --dir\t\tInstall from a directory on your computer\n" >&2
    printf "  -c, --clone\t\tInstall from a  Git repository\n" >&2
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
            -d|--dir)
                if is_set "${ARG_CLONE+x}"; then
                    panic "Cannot use --dir and --clone arguments together."
                fi

                shift 1
                if [ "${#}" -lt "1" ]; then
                    panic "No directory path specified."
                fi

                ARG_DIR="${1}"
            ;;
            -c|--clone)
                if is_set "${ARG_DIR+x}"; then
                    panic "Cannot use --dir and --clone arguments together."
                fi

                shift 1
                if [ "${#}" -lt "1" ]; then
                    panic "No Git URL specified."
                fi

                ARG_CLONE="${1}"
            ;;
            *)
                echo "Unrecognized argument: ${1}"
                show_usage_and_exit
            ;;
        esac

        shift ${consume}
    done
}

parse_commandline "$@"

if is_set "${ARG_HELP+x}"; then
    show_usage_and_exit
fi

test -d "${LXQ_PLUGIN_DIR}" || mkdir --parent "${LXQ_PLUGIN_DIR}"

if is_set "${ARG_DIR+x}"; then

    test -d "${ARG_DIR}" || panic "${ARG_DIR} is not a valid directory."
    ARG_DIR=$(readlink -f "${ARG_DIR}")
    manifest="${ARG_DIR}/lxq-manifest.sh"
    test -e "${manifest}" || panic "No valid lxq-manifest.sh found in ${ARG_DIR}."

    # shellcheck source=/dev/null
    . "${manifest}"

    is_set "${LXQ_PLUGIN_NAME+x}" || panic "Expected LXQ_PLUGIN_NAME environment variable to be exported from manifest."

    dest_plugin_dir="${LXQ_PLUGIN_DIR}/${LXQ_PLUGIN_NAME}"
    test ! -d "${dest_plugin_dir}" || panic "A plugin called \"${LXQ_PLUGIN_NAME}\" is already installed."
    ln --symbolic "${ARG_DIR}" "${dest_plugin_dir}"

elif is_set "${ARG_CLONE+x}"; then

    panic "Not implemented yet."

fi

# TODO: Run install script in plugin dir?
