#!/usr/bin/env bash
set -euo pipefail
set -x

version=${version:-0.0.0}
grpc_client_nginx_module_ver="main"

if ([ $# -gt 0 ] && [ "$1" == "latest" ]) || [ "$version" == "latest" ]; then
    ngx_multi_upstream_module_ver="master"
    mod_dubbo_ver="master"
    apisix_nginx_module_ver="main"
    wasm_nginx_module_ver="main"
    lua_var_nginx_module_ver="master"
    debug_args="--with-debug --add-module=../grpc-client-nginx-module-${grpc_client_nginx_module_ver} "
    OR_PREFIX=${OR_PREFIX:="/usr/local/openresty-debug"}
else
    ngx_multi_upstream_module_ver="1.1.1"
    mod_dubbo_ver="1.0.2"
    apisix_nginx_module_ver="1.9.0"
    wasm_nginx_module_ver="0.6.2"
    lua_var_nginx_module_ver="v0.5.3"
    debug_args=${debug_args:-}
    OR_PREFIX=${OR_PREFIX:="/usr/local/openresty"}
fi

prev_workdir="$PWD"
repo=$(basename "$prev_workdir")
workdir=$(mktemp -d)
cd "$workdir" || exit 1

or_ver="1.21.4.1"
wget --no-check-certificate https://openresty.org/download/openresty-${or_ver}.tar.gz
tar -zxvpf openresty-${or_ver}.tar.gz > /dev/null

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

if [ "$repo" == grpc-client-nginx-module ]; then
    cp -r "$prev_workdir" ./grpc-client-nginx-module-${grpc_client_nginx_module_ver}
else
    git clone --depth=1 -b $grpc_client_nginx_module_ver \
        https://github.com/api7/grpc-client-nginx-module \
        grpc-client-nginx-module-${grpc_client_nginx_module_ver}
fi

cd ngx_multi_upstream_module-${ngx_multi_upstream_module_ver} || exit 1
./patch.sh ../openresty-${or_ver}
cd ..

cd apisix-nginx-module-${apisix_nginx_module_ver}/patch || exit 1
./patch.sh ../../openresty-${or_ver}
cd ../..

cd wasm-nginx-module-${wasm_nginx_module_ver} || exit 1
./install-wasmtime.sh
cd ..

cc_opt=${cc_opt:-}
ld_opt=${ld_opt:-}
luajit_xcflags=${luajit_xcflags:="-DLUAJIT_NUMMODE=2 -DLUAJIT_ENABLE_LUA52COMPAT"}
no_pool_patch=${no_pool_patch:-}

cd openresty-${or_ver} || exit 1
./configure --prefix="$OR_PREFIX" \
    --with-cc-opt="-DAPISIX_BASE_VER=$version $cc_opt" \
    --with-ld-opt="-Wl,-rpath,$OR_PREFIX/wasmtime-c-api/lib $ld_opt" \
    $debug_args \
    --add-module=../mod_dubbo-${mod_dubbo_ver} \
    --add-module=../ngx_multi_upstream_module-${ngx_multi_upstream_module_ver} \
    --add-module=../apisix-nginx-module-${apisix_nginx_module_ver} \
    --add-module=../apisix-nginx-module-${apisix_nginx_module_ver}/src/stream \
    --add-module=../apisix-nginx-module-${apisix_nginx_module_ver}/src/meta \
    --add-module=../wasm-nginx-module-${wasm_nginx_module_ver} \
    --add-module=../lua-var-nginx-module-${lua_var_nginx_module_ver} \
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

cd apisix-nginx-module-${apisix_nginx_module_ver} || exit 1
sudo OPENRESTY_PREFIX="$OR_PREFIX" make install
cd ..

cd wasm-nginx-module-${wasm_nginx_module_ver} || exit 1
sudo OPENRESTY_PREFIX="$OR_PREFIX" make install
cd ..

cd grpc-client-nginx-module-${grpc_client_nginx_module_ver} || exit 1
cat  > Makefile <<_EOC_;
OPENRESTY_PREFIX ?= /usr/local/openresty
INSTALL ?= install

.PHONY: install
install:
	if [ ! -f /usr/local/go/bin/go ]; then ./install-util.sh install_go; fi 
	cd ./grpc-engine && PATH=\$PATH:/usr/local/go/bin go build -o libgrpc_engine.so -buildmode=c-shared main.go
	\$(INSTALL) -m 664 ./grpc-engine/libgrpc_engine.so \$(OPENRESTY_PREFIX)/
_EOC_

cat  > install-util.sh <<_EOC_;
#!/usr/bin/env bash
set -euo pipefail
set -x


arch=\$(uname -m | tr '[:upper:]' '[:lower:]')
if [ "\$arch" = "x86_64" ]; then
    arch="amd64"
fi
if [ "\$arch" = "aarch64" ]; then
    arch="arm64"
fi

install_go() {
    GO_VER=1.19
    wget https://go.dev/dl/go\${GO_VER}.linux-\$arch.tar.gz > /dev/null
    rm -rf /usr/local/go && tar -C /usr/local -xzf go\${GO_VER}.linux-\$arch.tar.gz
    /usr/local/go/bin/go version
}

case_opt=\$1
case "\${case_opt}" in
    "install_go")
        install_go
    ;;
    *)
        echo "Unsupported method: \${case_opt}"
    ;;
esac
_EOC_

sudo OPENRESTY_PREFIX="$OR_PREFIX" make install
cd ..
test -f $OR_PREFIX/libgrpc_engine.so && echo "found"
