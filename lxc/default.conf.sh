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
readonly OUTPUT="${SCRIPT_DIR}/default.conf"

regex="^${USER}:([[:digit:]]+):([[:digit:]]+)\$"
# Matches strings like "phil:100000:65536"

uid_maps=$(grep --extended-regex "${regex}" /etc/subuid)
for map in ${uid_maps}; do
    if [[ "${map}" =~ ${regex} ]]; then
        uid_start="${BASH_REMATCH[1]}"
        uid_count="${BASH_REMATCH[2]}"
    fi
done

gid_maps=$(grep --extended-regex "${regex}" /etc/subgid)
for map in ${gid_maps}; do
    if [[ "${map}" =~ ${regex} ]]; then
        gid_start="${BASH_REMATCH[1]}"
        gid_count="${BASH_REMATCH[2]}"
    fi
done

cat > "${OUTPUT}" << EOF
lxc.net.0.type = veth
lxc.net.0.link = lxcbr0
lxc.net.0.flags = up
lxc.net.0.hwaddr = 00:16:3e:xx:xx:xx
lxc.idmap = u 0 ${uid_start} ${uid_count}
lxc.idmap = g 0 ${gid_start} ${gid_count}
EOF
