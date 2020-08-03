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
readonly DEPENDENCIES=()

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
    printf "Usage: lxq sandbox create [sandbox-name] --template [template-name]\n" >&2
    printf "\n" >&2
    printf "Flags:\n">&2
    printf "  -t, --template\t\tTemplate on which the sandbox should be based"
    printf "  -h, --help\t\tShow help message then exit\n" >&2
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
            -t|--template)
                shift 1
                if [ "${#}" -gt "0" ]; then
                    ARG_TEMPLATE_NAME="${1}"
                else
                    echo "No template name specified."
                    show_usage_and_exit
                fi
            ;;
            *)
                if is_set "${ARG_SANDBOX_NAME+x}"; then
                    echo "Unrecognized argument: ${1}"
                    show_usage_and_exit
                else
                    ARG_SANDBOX_NAME="${1}"
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

is_set "${ARG_TEMPLATE_NAME+x}" || panic "No template name specified."

if is_set "${ARG_SANDBOX_NAME+x}"; then

    sandbox_file="${LXQ_SANDBOXES_ROOT_DIR}/${ARG_SANDBOX_NAME}"
    if [ -f "${sandbox_file}" ]; then
        panic "Sandbox ${ARG_SANDBOX_NAME} already exists."
    fi

    cat > "${sandbox_file}" << EOF
#!/usr/bin/env bash

set -Eeuo pipefail

export LXQ_TEMPLATE_NAME="${ARG_TEMPLATE_NAME}"
EOF

    chmod u+x "${sandbox_file}"

else
    echo "No sandbox name specified."
    show_usage_and_exit
fi
