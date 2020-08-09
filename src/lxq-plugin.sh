#!/usr/bin/env bash
set -Eeuo pipefail

if is_set "${LXQ_SHORT_SUMMARY+x}"; then
    printf "\t\tManage plugins"
    exit 0
fi

subcommand_regex="/lxq-plugin-([a-z]+)\\.sh$"
readarray -t subcommand_scripts < <(find_subcommand_scripts "${subcommand_regex}")

function print_subcommand_summary() {
    full_script_path="${1}"
    if [[ $full_script_path =~ ${subcommand_regex} ]]; then
        command_name="${BASH_REMATCH[1]}"
        summary=$(LXQ_SHORT_SUMMARY=1 "${full_script_path}")
        printf "  %s%s\n" "${command_name}" "${summary}" >&2
    else
        panic "${full_script_path} did not match regex as expected."
    fi
}

function show_usage() {
    printf "Usage: lxq plugin [command]\n" >&2
    printf "\n" >&2
    printf "Available commands:\n" >&2

    for s in "${subcommand_scripts[@]}"
    do
        print_subcommand_summary "${s}"
    done

    printf "\n" >&2
    printf "Flags:\n">&2
    printf "  -h, --help\t\tShow help message then exit\n" >&2
}

function show_usage_and_exit() {
    show_usage
    exit 1
}

function parse_commandline() {

    if [ "${#}" -gt "0" ]; then

        for s in "${subcommand_scripts[@]}"
        do
            if [ "${LXQ_SCRIPT_DIR}/lxq-plugin-${1}.sh" == "${s}" ]; then
                LXQ_COMMAND="${1}"
            fi
        done

        if is_set "${LXQ_COMMAND+x}"; then
            return
        fi
    fi

    while [ "${#}" -gt "0" ]; do
        local consume=1

        case "$1" in
            -h|-\?|--help)
                ARG_HELP="true"
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

if is_set "${LXQ_COMMAND+x}"; then
    shift 1
    "${LXQ_SCRIPT_DIR}/lxq-plugin-${LXQ_COMMAND}.sh" "$@"
    exit "${?}"
fi

if is_set "${ARG_HELP+x}"; then
    show_usage_and_exit
fi

echo "No arguments specified."
show_usage_and_exit
