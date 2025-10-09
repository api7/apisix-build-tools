#!/usr/bin/env bash
set -euo pipefail
set -x
mkdir /output
dist=$(cat /tmp/dist)
codename=$(cat /tmp/codename)

# Determine the name of artifact
# The default is apisix-base
artifact="apisix-base"
if [ "$ARTIFACT" != "0" ]; then
    artifact=${ARTIFACT}
fi

ARCH=${ARCH:-`(uname -m | tr '[:upper:]' '[:lower:]')`}

openresty_zlib_version="1.2.12-1"
openresty_openssl111_version="1.1.1n-1"
openresty_pcre_version="8.45-1"
if [ "$PACKAGE_TYPE" == "deb" ]; then
    pkg_suffix="${codename}1"
    openresty_zlib_version="$openresty_zlib_version~$pkg_suffix"
    openresty_openssl111_version="$openresty_openssl111_version~$pkg_suffix"
    openresty_pcre_version="$openresty_pcre_version~$pkg_suffix"
fi

fpm -f -s dir -t "$PACKAGE_TYPE" \
    --"$PACKAGE_TYPE"-dist "$dist" \
    -n "$artifact" \
    -a "$(uname -i)" \
    -v "$PACKAGE_VERSION" \
    --iteration "$ITERATION" \
    -x openresty/zlib \
    -x openresty/openssl111 \
    -x openresty/pcre \
    -d "openresty-zlib >= $openresty_zlib_version" \
    -d "openresty-openssl111 >= $openresty_openssl111_version" \
    -d "openresty-pcre >= $openresty_pcre_version" \
    --post-install post-install-apisix-base.sh \
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
    mv /output/apisix-base_"${PACKAGE_VERSION}"-"${ITERATION}"_"${PACKAGE_ARCH}".deb /output/apisix-base_"${PACKAGE_VERSION}"-"${ITERATION}"~"${dist}"_"${PACKAGE_ARCH}".deb
fi
