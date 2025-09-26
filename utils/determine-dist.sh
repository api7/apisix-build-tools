#!/usr/bin/env bash
set -euo pipefail
set -x

if [ "${IMAGE_BASE}" == "ubuntu" ]
then
    dist="${IMAGE_BASE}${IMAGE_TAG}"
elif [ "${IMAGE_BASE}" == "debian" ]
then
    dist="${IMAGE_BASE}${IMAGE_TAG}"
elif [ "${IMAGE_BASE}" == "registry.access.redhat.com/ubi9/ubi" ]
then
    dist="ubi${IMAGE_TAG}"
fi

echo "${dist}" > /tmp/dist

echo `cat /etc/os-release |grep VERSION_CODENAME|awk -F '=' '{print $2}'` > /tmp/codename
