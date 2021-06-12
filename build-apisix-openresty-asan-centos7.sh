#!/usr/bin/env bash
set -euo pipefail
set -x

yum-config-manager --add-repo https://openresty.org/package/centos/openresty.repo
yum install centos-release-scl -y
yum -y install gcc gcc-c++ patch wget git make sudo libasan
yum -y install openresty-openssl111-asan openresty-pcre-asan openresty-zlib-asan

export openssl_prefix=/usr/local/openresty/openssl111
export zlib_prefix=/usr/local/openresty/zlib
export pcre_prefix=/usr/local/openresty/pcre

export ASAN_OPTIONS=detect_leaks=0
export OR_PREFIX="/usr/local/openresty-asan"
export cc_opt="-DNGX_LUA_ABORT_AT_PANIC -I${zlib_prefix}/include -I${pcre_prefix}/include -I${openssl_prefix}/include -O1"
export ld_opt="-L${zlib_prefix}/lib -L${pcre_prefix}/lib -L${openssl_prefix}/lib -Wl,-rpath,${zlib_prefix}/lib:${pcre_prefix}/lib:${openssl_prefix}/lib"
export cc='--with-cc="ccache gcc -fsanitize=address"'
export luajit_xcflags="-DLUAJIT_NUMMODE=2 -DLUAJIT_ENABLE_LUA52COMPAT -DLUAJIT_USE_VALGRIND -O1 -fno-omit-frame-pointer"
export nproc="-j`nproc`"
export no_pool_patch="--with-no-pool-patch"

./build-apisix-openresty.sh latest

ln -sf /usr/local/openresty-debug/nginx/sbin/nginx /usr/bin/openresty-asan