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

readonly SCRIPT_NAME=$(basename "$0")
readonly DEPENDENCIES=(lxc-create)
readonly SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
readonly REPO_DIR=$(dirname "${SCRIPT_DIR}")
readonly TEMPLATES_CONFIG_DIR="${REPO_DIR}/templates"

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

    container_name="lxq-templ-${ARG_TEMPLATE_NAME}"
    new_lxc_config="${LXQ_PATH}/${container_name}/config"

    template_config_dir="${TEMPLATES_CONFIG_DIR}/${ARG_TEMPLATE_NAME}"
    if [ -d "${template_config_dir}" ]; then
        panic "${template_config_dir} already exists."
    fi

    if is_set "${ARG_CLONE+x}"; then

        parent_container_name="lxq-templ-${ARG_CLONE}"
        lxc-copy --name "${parent_container_name}" \
            --newname "${container_name}" \
            --foreground

        old_config_dir="${TEMPLATES_CONFIG_DIR}/${ARG_CLONE}"
        cp -r "${old_config_dir}" "${template_config_dir}"

        # In the LXC config file, replace old LXQ config path with new LXQ config path
        sed -i "s|${old_config_dir}|${template_config_dir}|g" "${new_lxc_config}"

    else

        lxc-create --name "${container_name}" \
            --template download \
            -- \
            --dist "${LXQ_DISTRO}" \
            --arch "${LXQ_ARCH}" \
            --release "${LXQ_RELEASE}"

        mkdir --parent "${template_config_dir}"
        echo "# No custom settings yet." > "${template_config_dir}/config"

        # Tell LXC to include our custom LXQ config
        echo "lxc.include = ${template_config_dir}/config" >> "${new_lxc_config}"

        if [ "$(systemctl is-active lxc-net)" != "active" ]; then
            sudo systemctl start lxc-net
        fi

        lxc-start --name "${container_name}"
        lxc-wait --name "${container_name}" \
            --state "RUNNING"

        lxc-attach --name "${container_name}" \
            --clear-env \
            --keep-var TERM \
            -- \
            /bin/bash  << EOF
/usr/sbin/useradd --home-dir "/home/${LXQ_CONTAINER_USER}" \
    --create-home \
    --shell /bin/bash \
    "${LXQ_CONTAINER_USER}"
EOF

        lxc-stop --name "${container_name}"
        lxc-wait --name "${container_name}" \
            --state "STOPPED"

    fi

else
    echo "No template name specified."
    show_usage_and_exit
fi
