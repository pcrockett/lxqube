#!/usr/bin/env bash
set -Eeuo pipefail

if lxq_is_set "${LXQ_SHORT_SUMMARY+x}"; then
    printf "\t\tCreate a sandbox"
    exit 0
fi

function show_usage() {
    printf "Usage: lxq sandbox create [sandbox-name] [flags]\n" >&2
    printf "\n" >&2
    printf "Flags:\n">&2
    printf "  -p, --persist-home\tNever discard the home directory\n" >&2
    printf "  -t, --template\tTemplate on which the sandbox should be based\n" >&2
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
            -p|--persist-home)
                ARG_PERSIST_HOME="true"
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

lxq_is_set "${ARG_TEMPLATE_NAME+x}" || lxq_panic "No template name specified."
lxq_is_set "${ARG_SANDBOX_NAME+x}" || lxq_panic "No sandbox name specified."

template_dir="${LXQ_REPO_DIR}/templates/${ARG_TEMPLATE_NAME}"
test -d "${template_dir}" || lxq_panic "Template ${ARG_TEMPLATE_NAME} does not exist."

sandbox_dir="${LXQ_SANDBOXES_ROOT_DIR}/${ARG_SANDBOX_NAME}"
test ! -d "${sandbox_dir}" || lxq_panic "Sandbox ${ARG_SANDBOX_NAME} already exists."
config_dir="${sandbox_dir}/config.d"
mkdir --parent "${config_dir}"

lxq_compile_config "${template_dir}/config.d" "${sandbox_dir}/config.d" "${sandbox_dir}/config"

sandbox_meta_script="${sandbox_dir}/meta.sh"
cat > "${sandbox_meta_script}" << EOF
#!/usr/bin/env bash
set -Eeuo pipefail

export LXQ_TEMPLATE_NAME="${ARG_TEMPLATE_NAME}"
EOF
chmod u+x "${sandbox_meta_script}"

if lxq_is_set "${ARG_PERSIST_HOME+x}"; then
    lxq sandbox persist "${ARG_SANDBOX_NAME}" /home
fi

LXQ_SANDBOX_NAME="${ARG_SANDBOX_NAME}" \
    LXQ_TEMPLATE_NAME="${ARG_TEMPLATE_NAME}" \
    lxq_hook "sandbox/post-create"
