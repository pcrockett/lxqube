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

[[ "${BASH_VERSINFO[0]}" -lt 4 ]] && echo "Bash >= 4 required" && exit 1

readonly LXQ_SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
export LXQ_SCRIPT_DIR

readonly LXQ_REPO_DIR=$(dirname "${LXQ_SCRIPT_DIR}")
export LXQ_REPO_DIR

readonly LXQ_PLUGIN_DIR="${LXQ_REPO_DIR}/plugins"
export LXQ_PLUGIN_DIR

function lxq_panic() {
    >&2 echo "Fatal: $*"
    exit 1
}
export -f lxq_panic

function lxq_check_dependencies() {

    lxq_is_set "${1+x}" || lxq_panic "Expecting array of dependencies as single argument."

    function installed() {
        command -v "$1" >/dev/null 2>&1
    }

    for dep in "${1[@]}"; do
        installed "${dep}" || lxq_panic "Missing '${dep}'"
    done
}

function lxq_is_set() {
    # Use this like so:
    #
    #     lxq_is_set "${VAR_NAME+x}" || show_usage_and_exit
    #
    # https://stackoverflow.com/a/13864829

    test ! -z "$1"
}
export -f lxq_is_set

function lxq_start_net_svc() {
    if [ "$(systemctl is-active lxc-net)" != "active" ]; then
        echo "Starting lxc-net service..."
        sudo systemctl start lxc-net
    fi
}
export -f lxq_start_net_svc

function lxq_hook() {

    lxq_is_set "${1+x}" || lxq_panic "Expecting hook name as parameter, i.e. 'sandbox/pre-start'"
    HOOK_NAME="${1}"

    hook_path="${LXQ_REPO_DIR}/hooks/${HOOK_NAME}.sh"
    if [ -e "${hook_path}" ]; then
        "${hook_path}"
    fi

    readarray -d "" plugin_dirs < <(find -L "${LXQ_PLUGIN_DIR}" -maxdepth 1 -mindepth 1 -type d -print0)
    for plugin_dir in "${plugin_dirs[@]}"
    do
        hook_path="${plugin_dir}/hooks/${HOOK_NAME}.sh"
        if [ -e "${hook_path}" ]; then

            default_config_path="${plugin_dir}/default-config.sh"
            if [ -e "${default_config_path}" ]; then
                # shellcheck source=/dev/null
                . "${default_config_path}"
            fi

            user_config_path="${plugin_dir}/user-config.sh"
            if [ -e "${user_config_path}" ]; then
                # shellcheck source=/dev/null
                . "${user_config_path}"
            fi

            util_path="${plugin_dir}/src/_util.sh"
            if [ -e "${util_path}" ]; then
                # shellcheck source=/dev/null
                . "${util_path}"
            fi

            "${hook_path}"
        fi
    done
}
export -f lxq_hook

function lxq_compile_config() {

    test "${#}" -ge 2 || lxq_panic "Usage: lxq_compile_config [config-dirs...] [output-config-file]"

    ARG_CONFIG_DIRS=()
    while [ "${#}" -gt "0" ]; do

        if [ "${#}" -gt "1" ]; then
            config_dir="${1}"
            if [ -d "${config_dir}" ]; then
                ARG_CONFIG_DIRS+=("${config_dir}")
            else
                lxq_panic "${config_dir} is not a directory."
            fi
        else
            ARG_DEST_CONFIG_FILE="${1}"
        fi

        shift 1
    done

    declare -A all_config_files
    for config_dir in "${ARG_CONFIG_DIRS[@]}"
    do
        readarray -d '' config_files < <(find "${config_dir}" -maxdepth 1 -mindepth 1 -type f -name "*.conf" -print0)
        for config_file in "${config_files[@]}"
        do
            config_name=$(basename "${config_file}")
            all_config_files[${config_name}]="${config_file}"
        done
    done

    function config_names() {
        for name in "${!all_config_files[@]}";
        do
            echo "${name}"
        done
    }

    cat > "${ARG_DEST_CONFIG_FILE}" << EOF
###############################################################################
#    This file is auto-generated. Any changes you make here will be lost.     #
###############################################################################
EOF

    readarray -t sorted_config_names < <(config_names | sort)
    for config_name in "${sorted_config_names[@]}"
    do
        config_file="${all_config_files[${config_name}]}"
        cat "${config_file}" >> "${ARG_DEST_CONFIG_FILE}"
    done
}
export -f lxq_compile_config

function lxq_populate_subcommands() {

    lxq_is_set "${1+x}" || lxq_panic "Expecting single script name regex argument."
    ARG_SCRIPT_REGEX="${1}"

    readarray -d "" local_subcommand_scripts < <(find "${LXQ_SCRIPT_DIR}" -maxdepth 1 -mindepth 1 -print0)
    for subcommand_script in "${local_subcommand_scripts[@]}"
    do
        if [[ "${subcommand_script}" =~ ${ARG_SCRIPT_REGEX} ]]; then
            subcommand="${BASH_REMATCH[1]}"
            LXQ_SUBCOMMANDS["${subcommand}"]="${subcommand_script}"
        fi
    done

    readarray -d "" plugin_dirs < <(find -L "${LXQ_PLUGIN_DIR}" -maxdepth 1 -mindepth 1 -type d -print0)
    for plugin_dir in "${plugin_dirs[@]}"
    do
        plugin_src_dir="${plugin_dir}/src"
        if [ ! -d "${plugin_src_dir}" ]; then
            continue
        fi

        readarray -d "" plugin_subcommand_scripts < <(find -L "${plugin_src_dir}" -maxdepth 1 -mindepth 1 -print0)
        for subcommand_script in "${plugin_subcommand_scripts[@]}"
        do
            if [[ "${subcommand_script}" =~ ${ARG_SCRIPT_REGEX} ]]; then
                subcommand="${BASH_REMATCH[1]}"
                LXQ_SUBCOMMANDS["${subcommand}"]="${subcommand_script}"
            fi
        done
    done
}
export -f lxq_populate_subcommands

function lxq_print_subcommand_summaries() {

    function get_subcommands() {
        for s in "${!LXQ_SUBCOMMANDS[@]}"
        do
            echo "${s}"
        done
    }

    readarray -t sorted_subcommands < <(get_subcommands | sort)

    for subcommand in "${sorted_subcommands[@]}"
    do
        full_script_path="${LXQ_SUBCOMMANDS["${subcommand}"]}"
        summary=$(LXQ_SHORT_SUMMARY=1 "${full_script_path}")
        printf "  %s%s\n" "${subcommand}" "${summary}" >&2
    done
}
export -f lxq_print_subcommand_summaries
