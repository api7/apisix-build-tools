#!/usr/bin/env bash
set -euo pipefail
set -x

install_openssl_3(){
    # required for openssl 3.x config
    cpanm IPC/Cmd.pm
    git clone https://github.com/openssl/openssl
    cd openssl
    ./config --prefix=/usr/local/openssl --openssldir=/usr/local/openssl
    make install
    ldconfig
    export PATH=/usr/local/openssl/bin:\$PATH
    export LD_LIBRARY_PATH=/usr/local/openssl/lib:/usr/local/openssl/lib64:\$LD_LIBRARY_PATH
    cd ..
}
yum-config-manager --add-repo https://openresty.org/package/centos/openresty.repo
yum -y install gcc gcc-c++ patch wget git make sudo
yum -y install openresty-pcre-devel openresty-zlib-devel
install_openssl_3

export openssl_prefix=/usr/local/openssl
export zlib_prefix=/usr/local/openresty/zlib
export pcre_prefix=/usr/local/openresty/pcre

export cc_opt="-DNGX_LUA_USE_ASSERT -DNGX_LUA_ABORT_AT_PANIC -I${zlib_prefix}/include -I${pcre_prefix}/include -I${openssl_prefix}/include -O0"
export ld_opt="-L${zlib_prefix}/lib -L${pcre_prefix}/lib -L${openssl_prefix}/lib -Wl,-rpath,${zlib_prefix}/lib:${pcre_prefix}/lib:${openssl_prefix}/lib"
export luajit_xcflags="-DLUAJIT_ASSERT -DLUAJIT_NUMMODE=2 -DLUAJIT_ENABLE_LUA52COMPAT -O0"
export OR_PREFIX=/usr/local/openresty-debug
export debug_args=--with-debug

./build-apisix-base.sh
