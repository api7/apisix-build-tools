#!/usr/bin/env bash
set -euo pipefail
set -x

dist="el7"
if [ "${IMAGE_BASE}" == "centos" ]
then
    dist="el${IMAGE_TAG}"
elif [ "${IMAGE_BASE}" == "ubuntu" ]
then
    dist="${IMAGE_TAG}1"
fi

echo "${dist}" > /tmp/dist
