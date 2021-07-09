#!/usr/bin/env bash
set -euo pipefail
set -x
mkdir /output
fpm -f -s dir -t "$PACKAGE_TYPE" \
	-n apisix \
	-a "$(uname -i)" \
	-v "$PACKAGE_VERSION" \
	--iteration "$ITERATION" \
	-d 'openresty >= 1.17.8.2' \
	--description 'Apache APISIX is a distributed gateway for APIs and Microservices, focused on high performance and reliability.' \
	--license "ASL 2.0" \
	-C /tmp/build/output/apisix \
	-p /output \
	--url 'http://apisix.apache.org/' \
	--config-files usr/lib/systemd/system/apisix.service
