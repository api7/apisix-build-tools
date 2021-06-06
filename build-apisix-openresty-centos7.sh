#!/usr/bin/env bash
set -euo pipefail
set -x

yum-config-manager --add-repo https://openresty.org/package/centos/openresty.repo
yum -y install pcre-devel openssl-devel gcc curl gcc-c++ patch
yum -y install openresty-openssl111-devel

export openssl_prefix=/usr/local/openresty/openssl111
export cc_opt="-I${openssl_prefix}/include"
export ld_opt="-L${openssl_prefix}/lib -Wl,-rpath,${openssl_prefix}/lib"

./build-apisix-openresty.sh