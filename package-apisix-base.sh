#!/usr/bin/env bash
set -euo pipefail
set -x
mkdir /output
dist=$(cat /tmp/dist)

# Determine the name of artifact
# The defaut is apisix-base
artifact="apisix-base"
if [ "$ARTIFACT" != "0" ]; then
    artifact=${ARTIFACT}
fi

openresty_zlib_version="1.2.11-3"
openresty_openssl111_version="1.1.1h-1"
openresty_pcre_version="8.44-1"
if [ "$PACKAGE_TYPE" == "deb" ]; then
    openresty_zlib_version="1.2.11-3~focal1"
    openresty_pcre_version="8.44-1~focal1"
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

if [ "$PACKAGE_TYPE" == "deb" ]; then
    # Rename deb file with adding $DIST section
    mv /output/apisix-base_"${PACKAGE_VERSION}"-"${ITERATION}"_amd64.deb /output/apisix-base_"${PACKAGE_VERSION}"-"${ITERATION}"~"${dist}"_amd64.deb
fi
