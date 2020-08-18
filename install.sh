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

readonly SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
readonly SCRIPT_NAME=$(basename "$0")
readonly DEPENDENCIES=()

function lxq_panic() {
    >&2 echo "Fatal: $*"
    exit 1
}

function installed() {
    command -v "$1" >/dev/null 2>&1
}

for dep in "${DEPENDENCIES[@]}"; do
    installed "${dep}" || lxq_panic "Missing '${dep}'"
done

DEFAULT_CONFIG="${SCRIPT_DIR}/default-config.sh"
# shellcheck source=/dev/null
. "${DEFAULT_CONFIG}"

USER_CONFIG="${SCRIPT_DIR}/user-config.sh"
if [ -f "${USER_CONFIG}" ]; then
    # shellcheck source=/dev/null
    . "${USER_CONFIG}"
fi

BIN_DIR=~/.local/bin
if [ ! -d "${BIN_DIR}" ]; then
    mkdir "${BIN_DIR}" --parent
fi

LXQ_SCRIPT="${SCRIPT_DIR}/src/lxq"
ln --symbolic "${LXQ_SCRIPT}" "${BIN_DIR}/lxq" || true

LXC_CONFIG_DIR=~/.config/lxc
if [ ! -d "${LXC_CONFIG_DIR}" ]; then
    mkdir "${LXC_CONFIG_DIR}" --parent
fi

LXC_CONTAINER_CONF="${SCRIPT_DIR}/lxc/default.conf"
ln --symbolic "${LXC_CONTAINER_CONF}" "${LXC_CONFIG_DIR}/default.conf" || true

LXC_SYSTEM_CONF="${SCRIPT_DIR}/lxc/lxc.conf"
LXC_SYSTEM_CONF_SCRIPT="${LXC_SYSTEM_CONF}.sh"
$LXC_SYSTEM_CONF_SCRIPT

ln --symbolic "${LXC_SYSTEM_CONF}" "${LXC_CONFIG_DIR}/lxc.conf" || true

function create_owned_dir() {
    path="${1}"
    echo "Creating ${path}..."
    sudo mkdir "${path}" --parent
    sudo chown "${USER}:${USER}" "${path}"
    chmod +x "${path}"
    chmod o-rw "${path}"
}

if [ ! -d "${LXQ_PATH}" ]; then
    create_owned_dir "${LXQ_PATH}"
    create_owned_dir "${LXQ_PERSISTED_DIR}"
fi

echo "Symlinks in place. Run..."
echo ""
echo "    lxq --help"
echo ""
echo "... to get started."
