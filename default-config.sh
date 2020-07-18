#!/usr/bin/env bash

set -Eeuo pipefail

# To override any of these defaults, create a new script in this directory
# called "user-config.sh" and re-export the environment variables you want
# to override.

export LXQ_DISTRO="ubuntu"
export LXQ_RELEASE="xenial"
export LXQ_ARCH="amd64"
