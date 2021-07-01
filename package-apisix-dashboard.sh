#!/usr/bin/env bash
set -euo pipefail
set -x
fpm -f -s dir -t rpm \
	-n apisix-dashboard \
	-a "$(uname -i)" \
	-v "$PACKAGE_VERSION" \
	--iteration "$ITERATION" \
	--description 'Apache APISIX Dashboard is designed to make it as easy as possible for users to operate Apache APISIX through a frontend interface.'  \
	--license "ASL 2.0" \
	-C /tmp/build/output/apisix/dashboard/ \
	-p /output \
	--url 'https://github.com/apache/apisix-dashboard'