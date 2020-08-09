#!/usr/bin/env bash
set -Eeuo pipefail

readonly DEPENDENCIES=(lxc-create)
readonly LXQ_TEMPLATES_DIR="${LXQ_REPO_DIR}/templates"

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
fi

is_set "${ARG_TEMPLATE_NAME+x}" || panic "No template name specified."

container_name="templ-${ARG_TEMPLATE_NAME}"
new_lxc_config="${LXQ_PATH}/${container_name}/config"

lxq_template_root="${LXQ_TEMPLATES_DIR}/${ARG_TEMPLATE_NAME}"
test ! -d "${lxq_template_root}" ||  panic "${lxq_template_root} already exists."
lxq_template_config_dir="${lxq_template_root}/config.d"

if is_set "${ARG_CLONE+x}"; then

    parent_container_name="templ-${ARG_CLONE}"
    lxc-copy --name "${parent_container_name}" \
        --newname "${container_name}" \
        --foreground

    old_template_root="${LXQ_TEMPLATES_DIR}/${ARG_CLONE}"
    cp -r "${old_template_root}" "${lxq_template_root}"

    # In the LXC config file, replace old LXQ config path with new LXQ config path
    sed -i "s|${old_template_root}|${lxq_template_root}|g" "${new_lxc_config}"

    LXQ_TEMPLATE_NAME="${ARG_TEMPLATE_NAME}" \
        LXQ_TEMPLATE_CONFIG_DIR="${lxq_template_config_dir}" \
        LXQ_TEMPLATE_PARENT="${ARG_CLONE}" \
        lxq_hook "template/post-create"

else

    lxc-create --name "${container_name}" \
        --template download \
        --bdev "${LXQ_BACKING_STORE}" \
        -- \
        --dist "${LXQ_DISTRO}" \
        --arch "${LXQ_ARCH}" \
        --release "${LXQ_RELEASE}"

    mkdir --parent "${lxq_template_config_dir}"
    compile_config "${lxq_template_config_dir}" "${lxq_template_root}/config"

    # Tell LXC to include our custom LXQ config
    cat >> "${new_lxc_config}" << EOF

# LXQube configuration
lxc.include = ${lxq_template_root}/config
EOF

    start_lxc_net

    lxc-start --name "${container_name}"
    lxc-wait --name "${container_name}" \
        --state "RUNNING"

    lxc-attach --name "${container_name}" \
        --clear-env \
        --keep-var TERM \
        -- \
        /bin/bash << EOF
/usr/sbin/useradd --home-dir "/home/${LXQ_CONTAINER_USER}" \
    --create-home \
    --shell /bin/bash \
    "${LXQ_CONTAINER_USER}"
EOF

    lxc-stop --name "${container_name}"
    lxc-wait --name "${container_name}" \
        --state "STOPPED"

    LXQ_TEMPLATE_NAME="${ARG_TEMPLATE_NAME}" \
        LXQ_TEMPLATE_CONFIG_DIR="${lxq_template_config_dir}" \
        lxq_hook "template/post-create"

fi
