#!/usr/bin/env bash
set -euo pipefail
set -x
mkdir /output
dist=$(cat /tmp/dist)
codename=$(cat /tmp/codename)

# Determine the name of artifact
# The defaut is api7ee-runtime-runtime
artifact="api7ee-runtime"
if [ "$ARTIFACT" != "0" ]; then
    artifact=${ARTIFACT}
fi

ARCH=${ARCH:-`(uname -m | tr '[:upper:]' '[:lower:]')`}

openresty_zlib_version="1.2.12-1"
openresty_pcre_version="8.45-1"
if [ "$PACKAGE_TYPE" == "deb" ]; then
    pkg_suffix="${codename}1"
    openresty_zlib_version="$openresty_zlib_version~$pkg_suffix"
    openresty_pcre_version="$openresty_pcre_version~$pkg_suffix"
fi

fpm -f -s dir -t "$PACKAGE_TYPE" \
    --"$PACKAGE_TYPE"-dist "$dist" \
    -n "$artifact" \
    -a "$(uname -i)" \
    -v "$RUNTIME_VERSION" \
    --iteration "$ITERATION" \
    --post-install post-install-api7ee-runtime.sh \
    --description "APISIX's OpenResty distribution." \
    --license "ASL 2.0" \
    -C /tmp/build/output \
    -p /output \
    --url 'http://apisix.apache.org/' \
    --conflicts openresty \
    --config-files usr/lib/systemd/system/openresty.service \
    --prefix=/usr/local

PACKAGE_ARCH="amd64"
if [[ $ARCH == "arm64" ]] || [[ $ARCH == "aarch64" ]]; then
    PACKAGE_ARCH="arm64"
fi

if [ "$PACKAGE_TYPE" == "deb" ]; then
    # Rename deb file with adding $DIST section
    mv /output/api7ee-runtime_"${RUNTIME_VERSION}"-"${ITERATION}"_"${PACKAGE_ARCH}".deb /output/api7ee-runtime_"${RUNTIME_VERSION}"-"${ITERATION}"~"${dist}"_"${PACKAGE_ARCH}".deb
fi
