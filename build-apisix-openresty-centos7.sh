#!/usr/bin/env bash
set -euo pipefail
set -x

sed -i '/--prefix="$OR_PREFIX"/a\    --with-cc-opt="-I$openssl_prefix/include" \\\n    --with-ld-opt="-L$openssl_prefix/lib -Wl,-rpath,$openssl_prefix/lib" \\' build-apisix-openresty.sh

yum-config-manager --add-repo https://openresty.org/package/centos/openresty.repo
yum -y install pcre-devel openssl-devel gcc curl gcc-c++ patch
yum -y install openresty-openssl111-devel.x86_64

export openssl_prefix=/usr/local/openresty/openssl111

chmod +x ./build-apisix-openresty.sh

./build-apisix-openresty.sh