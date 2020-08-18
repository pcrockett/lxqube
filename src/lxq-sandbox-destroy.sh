#!/usr/bin/env bash
set -Eeuo pipefail

if lxq_is_set "${LXQ_SHORT_SUMMARY+x}"; then
    printf "\t\tDestroy a sandbox"
    exit 0
fi

lxq_check_dependencies lxc-usernsexec

function show_usage() {
    printf "Usage: lxq sandbox destroy [sandbox-name]\n" >&2
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

sandbox_dir="${LXQ_SANDBOXES_ROOT_DIR}/${ARG_SANDBOX_NAME}"
test -d "${sandbox_dir}" || lxq_panic "Sandbox ${ARG_SANDBOX_NAME} does not exist."

rm --recursive -- "${sandbox_dir}"

persisted_dir="${LXQ_PERSISTED_DIR}/${ARG_SANDBOX_NAME}"
persisted_rootfs="${persisted_dir}/rootfs"

function delete_rootfs() {
    chmod go+rw "${persisted_dir}"
    lxc-usernsexec -- rm --recursive -- "${persisted_rootfs}"
}

test ! -d "${persisted_rootfs}" || delete_rootfs
test ! -d "${persisted_dir}" || rm --recursive -- "${persisted_dir}"

LXQ_SANDBOX_NAME="${ARG_SANDBOX_NAME}" \
    lxq_hook "sandbox/post-destroy"
