#!/usr/bin/env bash
set -Eeuo pipefail

if lxq_is_set "${LXQ_SHORT_SUMMARY+x}"; then
    printf "\t\tDestroy a template"
    exit 0
fi

readonly TEMPLATES_CONFIG_DIR="${LXQ_REPO_DIR}/templates"

lxq_check_dependencies lxc-destroy

function show_usage() {
    printf "Usage: lxq template destroy [template-name]\n" >&2
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
                if lxq_is_set "${ARG_TEMPLATE_NAME+x}"; then
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

if lxq_is_set "${ARG_HELP+x}"; then
    show_usage_and_exit
fi

lxq_is_set "${ARG_TEMPLATE_NAME+x}" || lxq_panic "No template name specified."

# I would use lxc-destroy, however it doesn't like to remove the rootfs unless
# it's specifically mounted with the "user_subvol_rm_allowed" option (for btrfs
# at least). That would require jumping through hoops like adding to /etc/fstab
# or manually calling `mount`, etc. Kind of silly if you're already mounting
# the _parent_ volume with that flag.
#
# So we'll just manually delete the container.

container_dir="${LXQ_PATH}/templ-${ARG_TEMPLATE_NAME}"
lxc-usernsexec -- rm --recursive -- "${container_dir}/rootfs"
rm --recursive -- "${container_dir}"
rm --recursive -- "${TEMPLATES_CONFIG_DIR:?}/${ARG_TEMPLATE_NAME:?}"

LXQ_TEMPLATE_NAME="${ARG_TEMPLATE_NAME}" \
    lxq_hook "template/post-destroy"
