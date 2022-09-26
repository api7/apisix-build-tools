#!/usr/bin/env bash
set -euo pipefail
set -x
mkdir /output
dist=$(cat /tmp/dist)

ARCH=${ARCH:-`(uname -m | tr '[:upper:]' '[:lower:]')`}

# Determine the dependencies
dep_ldap="openldap-devel"
if [ "$PACKAGE_TYPE" == "deb" ]
then
    # the pkg contains the so library could be libldap-2.5 or libldap-2.4-2
	dep_ldap="libldap2-dev"
fi
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
if [ "$OPENRESTY" == "apisix-base" ]
then
    min_or_version="1.21.4.1.2"
    max_or_version="1.21.5"
elif [ "$OPENRESTY" == "apisix-base-latest" ]
then
    # For CI
    OPENRESTY="apisix-base"
    min_or_version="latest"
    max_or_version="latest-1"
else
    min_or_version="1.19.3.2"
    max_or_version="1.21.5"
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
	-d "$OPENRESTY >= $min_or_version" \
	-d "$OPENRESTY < $max_or_version" \
	-d "$dep_ldap" \
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

PACKAGE_ARCH="amd64"
if [[ $ARCH == "arm64" ]] || [[ $ARCH == "aarch64" ]]; then
    PACKAGE_ARCH="arm64"
fi

# Rename deb file with adding $DIST section
if [ "$PACKAGE_TYPE" == "deb" ]
then
	mv /output/apisix_${PACKAGE_VERSION}-${ITERATION}_"${PACKAGE_ARCH}".deb /output/apisix_${PACKAGE_VERSION}-${ITERATION}~${dist}_"${PACKAGE_ARCH}".deb
fi
