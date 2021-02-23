#!/usr/bin/env bash
set -euo pipefail
set -x

OR_PREFIX=${OR_PREFIX:="/usr/local/openresty"}

workdir=$(mktemp -d)
cd "$workdir" || exit 1

wget https://openresty.org/download/openresty-1.19.3.1.tar.gz
tar -zxvpf openresty-1.19.3.1.tar.gz

git clone --depth=1 -b 1.0.0 https://github.com/api7/ngx_multi_upstream_module.git
cd ngx_multi_upstream_module || exit 1
./patch.sh ../openresty-1.19.3.1

git clone --depth=1 -b 1.0.0 https://github.com/api7/mod_dubbo.git ../mod_dubbo

cd ../openresty-1.19.3.1 || exit 1
./configure --prefix="$OR_PREFIX" \
    --add-module=../mod_dubbo --add-module=../ngx_multi_upstream_module \
    --with-debug \
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
    --with-luajit-xcflags='-DLUAJIT_NUMMODE=2 -DLUAJIT_ENABLE_LUA52COMPAT'
make
sudo make install
