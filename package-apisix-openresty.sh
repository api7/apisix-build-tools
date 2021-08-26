#!/usr/bin/env bash
set -euo pipefail
set -x
mkdir /output
dist=$(cat /tmp/dist)

# Determine the name of artifact
# The defaut is apisix-openresty
artifact="apisix-openresty"
if [ "$ARTIFACT" != "0" ]
then
	artifact=${ARTIFACT}
fi

fpm -f -s dir -t rpm \
	--"$PACKAGE_TYPE"-dist "$dist" \
	-n "$artifact" \
	-a "$(uname -i)" \
	-v "$PACKAGE_VERSION" \
	--iteration "$ITERATION" \
	-x openresty/zlib \
	-x openresty/openssl111 \
	-x openresty/pcre \
	-d 'openresty-zlib >= 1.2.11-3' \
	-d 'openresty-openssl111 >= 1.1.1h-1' \
	-d 'openresty-pcre >= 8.44-1' \
	--post-install post-install-apisix-openresty.sh \
	--description "APISIX's OpenResty distribution." \
	--license "ASL 2.0" \
	-C /tmp/build/output \
	-p /output \
	--url 'http://apisix.apache.org/' \
	--conflicts openresty \
	--config-files usr/lib/systemd/system/openresty.service \
	--prefix=/usr/local