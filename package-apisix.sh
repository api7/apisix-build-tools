#!/usr/bin/env bash
set -euo pipefail
set -x
mkdir /output
dist=$(cat /tmp/dist)

# Determine the dependencies
dep_pcre="pcre"
if [ "$PACKAGE_TYPE" == "deb" ]
then
	dep_pcre="libpcre3"
fi
dep_which="which"
if [ "$PACKAGE_TYPE" == "deb" ]
then
	dep_which="debianutils"
fi

# Determine the min version of openresty or apisix-base
or_version="1.17.8.2"
if [ "$OPENRESTY" == "apisix-base" ]
then
	or_version="1.19.9.1.0"
elif [ "$OPENRESTY" == "apisix-base-latest" ]
then
    # For CI
    OPENRESTY="apisix-base"
    or_version="latest"
fi

# Determine the name of artifact
# The defaut is apisix
artifact="apisix"
if [ "$ARTIFACT" != "0" ]
then
	artifact=${ARTIFACT}
fi

fpm -f -s dir -t "$PACKAGE_TYPE" \
	--"$PACKAGE_TYPE"-dist "$dist" \
	-n "$artifact" \
	-a "$(uname -i)" \
	-v "$PACKAGE_VERSION" \
	--iteration "$ITERATION" \
	-d "$OPENRESTY >= $or_version" \
	-d "$dep_pcre" \
	-d "$dep_which" \
	--description 'Apache APISIX is a distributed gateway for APIs and Microservices, focused on high performance and reliability.' \
	--license "ASL 2.0" \
	-C /tmp/build/output/apisix \
	-p /output \
	--url 'http://apisix.apache.org/' \
	--config-files usr/lib/systemd/system/apisix.service \
	--config-files usr/local/apisix/conf/config.yaml \
	--config-files usr/local/apisix/conf/config-default.yaml

# Rename deb file with adding $DIST section
if [ "$PACKAGE_TYPE" == "deb" ]
then
	mv /output/apisix_${PACKAGE_VERSION}-${ITERATION}_amd64.deb /output/apisix_${PACKAGE_VERSION}-${ITERATION}~${dist}_amd64.deb
fi
