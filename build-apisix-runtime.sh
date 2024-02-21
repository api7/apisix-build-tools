#!/usr/bin/env bash
set -euo pipefail
set -x

runtime_version=${runtime_version:-0.0.0}


debug_args=${debug_args:-}
ENABLE_FIPS=${ENABLE_FIPS:-"false"}
OPENSSL_CONF_PATH=${OPENSSL_CONF_PATH:-$PWD/conf/openssl3/openssl.cnf}


OR_PREFIX=${OR_PREFIX:="/usr/local/openresty"}
OPENSSL_PREFIX=${OPENSSL_PREFIX:=$OR_PREFIX/openssl3}
zlib_prefix=${OR_PREFIX}/zlib
pcre_prefix=${OR_PREFIX}/pcre

cc_opt=${cc_opt:-"-DNGX_LUA_ABORT_AT_PANIC -I$zlib_prefix/include -I$pcre_prefix/include -I$OPENSSL_PREFIX/include"}
ld_opt=${ld_opt:-"-L$zlib_prefix/lib -L$pcre_prefix/lib -L$OPENSSL_PREFIX/lib -Wl,-rpath,$zlib_prefix/lib:$pcre_prefix/lib:$OPENSSL_PREFIX/lib"}


# dependencies for building openresty
OPENSSL_VERSION=${OPENSSL_VERSION:-"3.2.0"}
OPENRESTY_VERSION="1.21.4.2"
ngx_multi_upstream_module_ver="1.1.1"
mod_dubbo_ver="1.0.2"
apisix_nginx_module_ver="1.15.0"
wasm_nginx_module_ver="0.6.5"
lua_var_nginx_module_ver="v0.5.3"
lua_resty_events_ver="0.2.0"


install_openssl_3(){
    local fips=""
    if [ "$ENABLE_FIPS" == "true" ]; then
        fips="enable-fips"
    fi
    # required for openssl 3.x config
    cpanm IPC/Cmd.pm
    wget --no-check-certificate https://www.openssl.org/source/openssl-${OPENSSL_VERSION}.tar.gz
    tar xvf openssl-${OPENSSL_VERSION}.tar.gz
    cd openssl-${OPENSSL_VERSION}/
    export LDFLAGS="-Wl,-rpath,$zlib_prefix/lib:$OPENSSL_PREFIX/lib"
    ./config $fips \
      shared \
      zlib \
	  enable-camellia enable-seed enable-rfc3779 \
	  enable-cms enable-md2 enable-rc5 \
	  enable-weak-ssl-ciphers \
      --prefix=$OPENSSL_PREFIX \
      --libdir=lib               \
      --with-zlib-lib=$zlib_prefix/lib \
      --with-zlib-include=$zlib_prefix/include
    make -j $(nproc) LD_LIBRARY_PATH= CC="gcc"
    sudo make install
    if [ -f "$OPENSSL_CONF_PATH" ]; then
        sudo cp "$OPENSSL_CONF_PATH" "$OPENSSL_PREFIX"/ssl/openssl.cnf
    fi
    if [ "$ENABLE_FIPS" == "true" ]; then
        $OPENSSL_PREFIX/bin/openssl fipsinstall -out $OPENSSL_PREFIX/ssl/fipsmodule.cnf -module $OPENSSL_PREFIX/lib/ossl-modules/fips.so
        sudo sed -i 's@# .include fipsmodule.cnf@.include '"$OPENSSL_PREFIX"'/ssl/fipsmodule.cnf@g; s/# \(fips = fips_sect\)/\1\nbase = base_sect\n\n[base_sect]\nactivate=1\n/g' $OPENSSL_PREFIX/ssl/openssl.cnf
    fi
    cd ..
}


if ([ $# -gt 0 ] && [ "$1" == "latest" ]) || [ "$runtime_version" == "0.0.0" ]; then
    debug_args="--with-debug"
fi

prev_workdir="$PWD"
repo=$(basename "$prev_workdir")
workdir=$(mktemp -d)
cd "$workdir" || exit 1


install_openssl_3

wget --no-check-certificate https://openresty.org/download/openresty-${OPENRESTY_VERSION}.tar.gz
tar -zxvpf openresty-${OPENRESTY_VERSION}.tar.gz > /dev/null

if [ "$repo" == lua-resty-events ]; then
    cp -r "$prev_workdir" ./lua-resty-events-${lua_resty_events_ver}
else
    git clone --depth=1 -b $lua_resty_events_ver \
        https://github.com/Kong/lua-resty-events.git \
        lua-resty-events-${lua_resty_events_ver}
fi

if [ "$repo" == ngx_multi_upstream_module ]; then
    cp -r "$prev_workdir" ./ngx_multi_upstream_module-${ngx_multi_upstream_module_ver}
else
    git clone --depth=1 -b $ngx_multi_upstream_module_ver \
        https://github.com/api7/ngx_multi_upstream_module.git \
        ngx_multi_upstream_module-${ngx_multi_upstream_module_ver}
fi

if [ "$repo" == mod_dubbo ]; then
    cp -r "$prev_workdir" ./mod_dubbo-${mod_dubbo_ver}
else
    git clone --depth=1 -b $mod_dubbo_ver \
        https://github.com/api7/mod_dubbo.git \
        mod_dubbo-${mod_dubbo_ver}
fi

if [ "$repo" == apisix-nginx-module ]; then
    cp -r "$prev_workdir" ./apisix-nginx-module-${apisix_nginx_module_ver}
else
    git clone --depth=1 -b $apisix_nginx_module_ver \
        https://github.com/api7/apisix-nginx-module.git \
        apisix-nginx-module-${apisix_nginx_module_ver}
fi

if [ "$repo" == wasm-nginx-module ]; then
    cp -r "$prev_workdir" ./wasm-nginx-module-${wasm_nginx_module_ver}
else
    git clone --depth=1 -b $wasm_nginx_module_ver \
        https://github.com/api7/wasm-nginx-module.git \
        wasm-nginx-module-${wasm_nginx_module_ver}
fi

if [ "$repo" == lua-var-nginx-module ]; then
    cp -r "$prev_workdir" ./lua-var-nginx-module-${lua_var_nginx_module_ver}
else
    git clone --depth=1 -b $lua_var_nginx_module_ver \
        https://github.com/api7/lua-var-nginx-module \
        lua-var-nginx-module-${lua_var_nginx_module_ver}
fi

cd ngx_multi_upstream_module-${ngx_multi_upstream_module_ver} || exit 1
./patch.sh ../openresty-${OPENRESTY_VERSION}
cd ..

cd apisix-nginx-module-${apisix_nginx_module_ver}/patch || exit 1
./patch.sh ../../openresty-${OPENRESTY_VERSION}
cd ../..

cd wasm-nginx-module-${wasm_nginx_module_ver} || exit 1
./install-wasmtime.sh
cd ..


luajit_xcflags=${luajit_xcflags:="-DLUAJIT_NUMMODE=2 -DLUAJIT_ENABLE_LUA52COMPAT"}
no_pool_patch=${no_pool_patch:-}

cd openresty-${OPENRESTY_VERSION} || exit 1

or_limit_ver=0.08
if [ ! -d "bundle/lua-resty-limit-traffic-$or_limit_ver" ]; then
    echo "ERROR: the official repository of lua-resty-limit-traffic has been updated, please sync to API7's repository." >&2
    exit 1
else
    rm -rf bundle/lua-resty-limit-traffic-$or_limit_ver
    limit_ver=1.0.0
    wget "https://github.com/api7/lua-resty-limit-traffic/archive/refs/tags/v$limit_ver.tar.gz" -O "lua-resty-limit-traffic-$limit_ver.tar.gz"
    tar -xzf lua-resty-limit-traffic-$limit_ver.tar.gz
    mv lua-resty-limit-traffic-$limit_ver bundle/lua-resty-limit-traffic-$or_limit_ver
fi


./configure --prefix="$OR_PREFIX" \
    --with-cc-opt="-DAPISIX_RUNTIME_VER=$runtime_version $cc_opt" \
    --with-ld-opt="-Wl,-rpath,$OR_PREFIX/wasmtime-c-api/lib $ld_opt" \
    $debug_args \
    --add-module=../mod_dubbo-${mod_dubbo_ver} \
    --add-module=../ngx_multi_upstream_module-${ngx_multi_upstream_module_ver} \
    --add-module=../apisix-nginx-module-${apisix_nginx_module_ver} \
    --add-module=../apisix-nginx-module-${apisix_nginx_module_ver}/src/stream \
    --add-module=../apisix-nginx-module-${apisix_nginx_module_ver}/src/meta \
    --add-module=../wasm-nginx-module-${wasm_nginx_module_ver} \
    --add-module=../lua-var-nginx-module-${lua_var_nginx_module_ver} \
    --add-module=../lua-resty-events-${lua_resty_events_ver} \
    --with-poll_module \
    --with-pcre-jit \
    --without-http_rds_json_module \
    --without-http_rds_csv_module \
    --without-lua_rds_parser \
    --with-stream \
    --with-stream_ssl_module \
    --with-stream_ssl_preread_module \
    --with-http_v2_module \
    --without-mail_pop3_module \
    --without-mail_imap_module \
    --without-mail_smtp_module \
    --with-http_stub_status_module \
    --with-http_realip_module \
    --with-http_addition_module \
    --with-http_auth_request_module \
    --with-http_secure_link_module \
    --with-http_random_index_module \
    --with-http_gzip_static_module \
    --with-http_sub_module \
    --with-http_dav_module \
    --with-http_flv_module \
    --with-http_mp4_module \
    --with-http_gunzip_module \
    --with-threads \
    --with-compat \
    --with-luajit-xcflags="$luajit_xcflags" \
    $no_pool_patch \
    -j`nproc`

make -j`nproc`
sudo make install
cd ..

cd lua-resty-events-${lua_resty_events_ver} || exit 1
sudo install -d "$OR_PREFIX"/lualib/resty/events/
sudo install -m 664 lualib/resty/events/*.lua "$OR_PREFIX"/lualib/resty/events/
sudo install -d "$OR_PREFIX"/lualib/resty/events/compat/
sudo install -m 644 lualib/resty/events/compat/*.lua "$OR_PREFIX"/lualib/resty/events/compat/
cd ..

cd apisix-nginx-module-${apisix_nginx_module_ver} || exit 1
sudo OPENRESTY_PREFIX="$OR_PREFIX" make install
cd ..

cd wasm-nginx-module-${wasm_nginx_module_ver} || exit 1
sudo OPENRESTY_PREFIX="$OR_PREFIX" make install
cd ..

# package etcdctl
ETCD_ARCH="amd64"
ETCD_VERSION=${ETCD_VERSION:-'3.5.4'}
ARCH=${ARCH:-$(uname -m | tr '[:upper:]' '[:lower:]')}

if [[ $ARCH == "arm64" ]] || [[ $ARCH == "aarch64" ]]; then
    ETCD_ARCH="arm64"
fi

wget -q https://github.com/etcd-io/etcd/releases/download/v${ETCD_VERSION}/etcd-v${ETCD_VERSION}-linux-${ETCD_ARCH}.tar.gz
tar xf etcd-v${ETCD_VERSION}-linux-${ETCD_ARCH}.tar.gz
# ship etcdctl under the same bin dir of openresty so we can package it easily
sudo cp etcd-v${ETCD_VERSION}-linux-${ETCD_ARCH}/etcdctl "$OR_PREFIX"/bin/
rm -rf etcd-v${ETCD_VERSION}-linux-${ETCD_ARCH}
