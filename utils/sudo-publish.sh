#!/usr/bin/env bash

# Run the publish scripts as root with the env vars they read.
#
# sudo-rs (Ubuntu 25.10+) ignores `sudo -E` and resets the environment, so the
# scripts abort on `set -u`. An explicit --preserve-env list is honoured by both
# sudo and sudo-rs, and unlike `sudo env VAR=val` it keeps secrets out of argv.
#
# Matched by prefix rather than an explicit list, so a new VAR_* in the
# workflows does not have to be mirrored here.

set -euo pipefail

preserve='^(TENCENT_[A-Z_]+|VAR_[A-Z_]+|TAG_[A-Z_]+|ARCH|GPG_MAIL|DEB_GPG_MAIL|UPLOAD_TARGET_FILE)='

names=$(env | grep -E "${preserve}" | cut -d= -f1 | sort | paste -sd, - || true)

if [ -z "${names}" ]; then
    exec sudo "$@"
fi

exec sudo --preserve-env="${names}" "$@"
