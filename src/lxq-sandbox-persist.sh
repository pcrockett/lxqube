#!/usr/bin/env bash
set -Eeuo pipefail

if lxq_is_set "${LXQ_SHORT_SUMMARY+x}"; then
    printf "\t\tMake a directory persist across reboots"
    exit 0
fi

function show_usage() {
    printf "Usage: lxq sandbox persist [sandbox-name] [full-path]\n" >&2
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
                    if lxq_is_set "${ARG_FULL_PATH+x}"; then
                        echo "Unrecognized argument: ${1}"
                        show_usage_and_exit
                    else
                        ARG_FULL_PATH="${1}"
                    fi
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
lxq_is_set "${ARG_FULL_PATH+x}" || lxq_panic "No path specified."

sandbox_dir="${LXQ_SANDBOXES_ROOT_DIR}/${ARG_SANDBOX_NAME}"
test -d "${sandbox_dir}" || lxq_panic "Sandbox ${ARG_SANDBOX_NAME} does not exist."
config_dir="${sandbox_dir}/config.d"
test -d "${config_dir}" || mkdir "${config_dir}"
persist_config="${config_dir}/99_persistence.conf"
test -f "${persist_config}" || echo "# Persistent mount points" > "${persist_config}"

lxc_sandbox_path="${LXQ_PATH}/sbox-${ARG_SANDBOX_NAME}/rootfs${ARG_FULL_PATH}"

sandbox_status=$(lxq sandbox status "${ARG_SANDBOX_NAME}")
if [ "${sandbox_status}" == "RUNNING" ]; then
    source_path="${lxc_sandbox_path}"
else
    meta_script="${sandbox_dir}/meta.sh"
    # shellcheck source=/dev/null
    . "${meta_script}"
    source_path="${LXQ_PATH}/templ-${LXQ_TEMPLATE_NAME}/rootfs${ARG_FULL_PATH}"
fi

dest_rootfs="${sandbox_dir}/rootfs"
test -d "${dest_rootfs}" || mkdir "${dest_rootfs}"
dest_path="${dest_rootfs}${ARG_FULL_PATH}"

if [ -f "${dest_path}" ] || [ -d "${dest_path}" ]; then
    lxq_panic "${dest_path} is already being persisted."
fi

if [ -d "${source_path}" ]; then

    parent_dir=$(dirname "${dest_path}")
    test -d "${parent_dir}" || mkdir --parent "${parent_dir}"

    echo "Copying ${source_path} to ${dest_path}..."
    sudo cp --preserve=mode,ownership,timestamps \
        --recursive \
        "${source_path}" "${dest_path}"

elif [ -f "${source_path}" ]; then

    echo "Copying ${source_path} to ${dest_path}..."
    cp --preserve=mode,ownership,timestamps \
        "${source_path}" "${dest_path}"

fi

cat >> "${persist_config}" << EOF
lxc.mount.entry = ${dest_path} ${lxc_sandbox_path} none bind 0 0
EOF

if [ "${sandbox_status}" == "RUNNING" ]; then
    echo "Restart sandbox to see changes."
fi
