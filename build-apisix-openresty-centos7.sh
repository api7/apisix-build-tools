#!/usr/bin/env bash
set -euo pipefail
set -x

yum-config-manager --add-repo https://openresty.org/package/centos/openresty.repo
yum -y install gcc gcc-c++ patch wget git make sudo
yum -y install openresty-openssl111-devel openresty-pcre-devel openresty-zlib-devel

export openssl_prefix=/usr/local/openresty/openssl111
export zlib_prefix=/usr/local/openresty/zlib
export pcre_prefix=/usr/local/openresty/pcre

export cc_opt="-DNGX_LUA_ABORT_AT_PANIC -I${zlib_prefix}/include -I${pcre_prefix}/include -I${openssl_prefix}/include"
export ld_opt="-L${zlib_prefix}/lib -L${pcre_prefix}/lib -L${openssl_prefix}/lib -Wl,-rpath,${zlib_prefix}/lib:${pcre_prefix}/lib:${openssl_prefix}/lib"

./build-apisix-openresty.sh
