#!/usr/bin/env bash
set -euo pipefail
set -x

mkdir /output
dist=$(cat /tmp/dist)
fpm -f -s dir -t "$PACKAGE_TYPE" \
	--"$PACKAGE_TYPE"-dist "$dist" \
	-n apisix-dashboard \
	-a "$(uname -i)" \
	-v "$PACKAGE_VERSION" \
	--iteration "$ITERATION" \
	--description 'Apache APISIX Dashboard is designed to make it as easy as possible for users to operate Apache APISIX through a frontend interface.'  \
	--license "ASL 2.0" \
	-C /tmp/build/output/apisix/dashboard/ \
	-p /output/ \
	--url 'https://github.com/apache/apisix-dashboard'

# Rename deb file with adding $DIST section
if [ "$PACKAGE_TYPE" == "deb" ]
then
	mv /output/apisix-dashboard_"${PACKAGE_VERSION}"-"${ITERATION}"_amd64.deb /output/apisix-dashboard_"${PACKAGE_VERSION}"-"${ITERATION}"~"${dist}"_amd64.deb
fi
