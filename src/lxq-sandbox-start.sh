#!/usr/bin/env bash
set -Eeuo pipefail

if lxq_is_set "${LXQ_SHORT_SUMMARY+x}"; then
    printf "\t\t\tStart a sandbox"
    exit 0
fi

lxq_check_dependencies lxc-start lxc-wait lxc-attach lxc-stop lxc-copy lxc-destroy

function show_usage() {
    printf "Usage: lxq sandbox start [sandbox-name]\n" >&2
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
                if lxq_is_set "${ARG_SANDBOX_NAME+x}"; then
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

if lxq_is_set "${ARG_HELP+x}"; then
    show_usage_and_exit
fi

lxq_is_set "${ARG_SANDBOX_NAME+x}" || lxq_panic "No sandbox name specified."

lxq_start_net_svc

lxq_sandbox_dir="${LXQ_SANDBOXES_ROOT_DIR}/${ARG_SANDBOX_NAME}"
test -d "${lxq_sandbox_dir}" || lxq_panic "Sandbox ${ARG_SANDBOX_NAME} does not exist."

sandbox_config_file="${lxq_sandbox_dir}/config"
sandbox_config_dir="${lxq_sandbox_dir}/config.d"
sandbox_meta="${lxq_sandbox_dir}/meta.sh"

# shellcheck source=/dev/null
. "${sandbox_meta}" # This gives us variables like LXQ_TEMPLATE_NAME

template_cont_name="templ-${LXQ_TEMPLATE_NAME}"
sandbox_cont_name="sbox-${ARG_SANDBOX_NAME}"

lxc-copy --name "${template_cont_name}" \
    --newname "${sandbox_cont_name}" \
    --foreground \
    --tmpfs

lxq_template_root="${LXQ_REPO_DIR}/templates/${LXQ_TEMPLATE_NAME}"
lxq_template_config_file="${lxq_template_root}/config"
lxc_config="${LXQ_PATH}/${sandbox_cont_name}/config"
sed -i "s|${lxq_template_config_file}|${sandbox_config_file}|g" "${lxc_config}"

LXQ_SANDBOX_NAME="${ARG_SANDBOX_NAME}" \
    lxq_hook "sandbox/pre-start"

lxq_template_config_dir="${lxq_template_root}/config.d"
lxq_compile_config "${lxq_template_config_dir}" "${sandbox_config_dir}" "${sandbox_config_file}"

lxc-start "${sandbox_cont_name}"
lxc-wait --name "${sandbox_cont_name}" \
    --state RUNNING

LXQ_SANDBOX_NAME="${ARG_SANDBOX_NAME}" \
    lxq_hook "sandbox/post-start"
