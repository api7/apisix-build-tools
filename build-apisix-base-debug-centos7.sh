#!/usr/bin/env bash
set -euo pipefail
set -x

yum-config-manager --add-repo https://openresty.org/package/centos/openresty.repo
yum -y install gcc gcc-c++ patch wget git make sudo
yum -y install openresty-openssl111-debug-devel openresty-pcre-devel openresty-zlib-devel

export openssl_prefix=/usr/local/openssl
export zlib_prefix=/usr/local/openresty/zlib
export pcre_prefix=/usr/local/openresty/pcre

export cc_opt="-DNGX_LUA_USE_ASSERT -DNGX_LUA_ABORT_AT_PANIC -I${zlib_prefix}/include -I${pcre_prefix}/include -I${openssl_prefix}/include -O0"
export ld_opt="-L${zlib_prefix}/lib -L${pcre_prefix}/lib -L${openssl_prefix}/lib -Wl,-rpath,${zlib_prefix}/lib:${pcre_prefix}/lib:${openssl_prefix}/lib"
export luajit_xcflags="-DLUAJIT_ASSERT -DLUAJIT_NUMMODE=2 -DLUAJIT_ENABLE_LUA52COMPAT -O0"
export OR_PREFIX=/usr/local/openresty-debug
export debug_args=--with-debug

./build-apisix-base.sh
