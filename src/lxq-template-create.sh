#!/usr/bin/env bash

# This script is based on the template here:
#
#     https://gist.github.com/pcrockett/8e04641f8473081c3a93de744873f787
#
# It was copy/pasted here into this file and then modified extensively.
#
# Useful links when writing a script:
#
# Shellcheck: https://github.com/koalaman/shellcheck
# vscode-shellcheck: https://github.com/timonwong/vscode-shellcheck
#
# I stole many of my ideas here from:
#
# https://blog.yossarian.net/2020/01/23/Anybody-can-write-good-bash-with-a-little-effort
# https://dave.autonoma.ca/blog/2019/05/22/typesetting-markdown-part-1/
#

# https://vaneyckt.io/posts/safer_bash_scripts_with_set_euxo_pipefail/
set -Eeuo pipefail

readonly SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
readonly SCRIPT_NAME=$(basename "$0")
readonly DEPENDENCIES=(lxc-create)

function panic() {
    >&2 echo "Fatal: $*"
    exit 1
}

function installed() {
    command -v "$1" >/dev/null 2>&1
}

for dep in "${DEPENDENCIES[@]}"; do
    installed "${dep}" || panic "Missing '${dep}'"
done

function show_usage() {
    printf "Usage: lxq template create [template-name]\n" >&2
    printf "\n" >&2
    printf "Flags:\n">&2
    printf "  -h, --help\t\tShow help message then exit\n" >&2
    printf "  -c, --clone <templ>\tClone an existing template\n" >&2
}

function show_usage_and_exit() {
    show_usage
    exit 1
}

function is_set() {
    # Use this like so:
    #
    #     is_set "${VAR_NAME+x}" || show_usage_and_exit
    #
    # https://stackoverflow.com/a/13864829

    test ! -z "$1"
}

function parse_commandline() {

    while [ "${#}" -gt "0" ]; do
        local consume=1

        case "${1}" in
            -h|-\?|--help)
                ARG_HELP="true"
            ;;
            -c|--clone)
                shift 1
                if [ "${#}" -gt "0" ]; then
                    ARG_CLONE="${1}"
                else
                    echo "Must specify a template name to clone from."
                    show_usage_and_exit
                fi
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
fi;

if is_set "${ARG_TEMPLATE_NAME+x}"; then

    test "$(id -u)" -eq 0 || panic "Must run this script as root."

    container_name="lxq-templ-${ARG_TEMPLATE_NAME}"

    if is_set "${ARG_CLONE+x}"; then

        parent_container_name="lxq-templ-${ARG_CLONE}"
        lxc-copy --name "${parent_container_name}" \
            --newname "${container_name}" \
            --foreground \
            --logpriority "${LXQ_LOG_PRIORITY}"

    else

        lxc-create --name "${container_name}" \
            --template download \
            --logpriority "${LXQ_LOG_PRIORITY}" \
            -- \
            --dist "${LXQ_DISTRO}" \
            --arch "${LXQ_ARCH}" \
            --release "${LXQ_RELEASE}"

        lxc-start --name "${container_name}" \
            --logpriority "${LXQ_LOG_PRIORITY}"
        lxc-wait --name "${container_name}" \
            --state "RUNNING" \
            --logpriority "${LXQ_LOG_PRIORITY}"

        lxc-attach --name "${container_name}" \
            --clear-env \
            --keep-var TERM \
            --logpriority "${LXQ_LOG_PRIORITY}" \
            -- \
            /bin/bash  << EOF
/usr/sbin/useradd --home-dir "/home/${LXQ_CONTAINER_USER}" \
    --create-home \
    --shell /bin/bash \
    "${LXQ_CONTAINER_USER}"
EOF

        lxc-stop --name "${container_name}" \
            --logpriority "${LXQ_LOG_PRIORITY}"
        lxc-wait --name "${container_name}" \
            --state "STOPPED" \
            --logpriority "${LXQ_LOG_PRIORITY}"

    fi

else
    echo "No template name specified."
    show_usage_and_exit
fi
