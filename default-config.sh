#!/usr/bin/env bash

set -Eeuo pipefail

# To override any of these defaults, create a new script in this directory
# called "user-config.sh" and re-export the environment variables you want
# to override.

export LXQ_DISTRO="ubuntu"
export LXQ_RELEASE="xenial"
export LXQ_ARCH="amd64"
export LXQ_CONTAINER_USER="sandboxed"
export LXQ_PATH="/var/lib/lxq/${USER}"

# Configure LXC backing store. Options are "dir", "lvm", "loop", "btrfs",
# "zfs", "rbd", or "best". See the --bdev parameter in `man lxc-create` for
# more information. The default is "dir" because that will work on any machine,
# no matter how it's configured. However if you can use Btrfs or ZFS, that is
# more ideal.
export LXQ_BACKING_STORE="dir"
