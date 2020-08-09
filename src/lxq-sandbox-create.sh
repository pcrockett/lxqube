#!/usr/bin/env bash
set -Eeuo pipefail

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
fi

is_set "${ARG_TEMPLATE_NAME+x}" || panic "No template name specified."
is_set "${ARG_SANDBOX_NAME+x}" || panic "No sandbox name specified."

template_dir="${LXQ_REPO_DIR}/templates/${ARG_TEMPLATE_NAME}"
test -d "${template_dir}" || panic "Template ${ARG_TEMPLATE_NAME} does not exist."

sandbox_dir="${LXQ_SANDBOXES_ROOT_DIR}/${ARG_SANDBOX_NAME}"
test ! -d "${sandbox_dir}" || panic "Sandbox ${ARG_SANDBOX_NAME} already exists."
mkdir --parent "${sandbox_dir}/config.d"
compile_config "${template_dir}/config.d" "${sandbox_dir}/config.d" "${sandbox_dir}/config"

sandbox_meta_script="${sandbox_dir}/meta.sh"
cat > "${sandbox_meta_script}" << EOF
#!/usr/bin/env bash
set -Eeuo pipefail

export LXQ_TEMPLATE_NAME="${ARG_TEMPLATE_NAME}"
EOF

chmod u+x "${sandbox_meta_script}"

LXQ_SANDBOX_NAME="${ARG_SANDBOX_NAME}" \
    LXQ_TEMPLATE_NAME="${ARG_TEMPLATE_NAME}" \
    lxq_hook "sandbox/post-create"
