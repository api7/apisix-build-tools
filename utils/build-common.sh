#!/usr/bin/env bash
set -euo pipefail
set -x

ARCH=${ARCH:-`(uname -m | tr '[:upper:]' '[:lower:]')`}
BUILD_PATH=${BUILD_PATH:-`pwd`}

build_api7ee_runtime_deb() {
    arch_path=""
    if [[ $ARCH == "arm64" ]] || [[ $ARCH == "aarch64" ]]; then
        arch_path="arm64/"
    fi
    DEBIAN_FRONTEND=noninteractive apt-get update --fix-missing
    DEBIAN_FRONTEND=noninteractive apt-get install -y sudo git libreadline-dev lsb-release libssl-dev perl build-essential gcc g++ xz-utils curl cpanminus
    DEBIAN_FRONTEND=noninteractive apt-get -y install --no-install-recommends wget gnupg ca-certificates 
    wget -O - https://openresty.org/package/pubkey.gpg | apt-key add -

    if [[ $IMAGE_BASE == "ubuntu" ]]; then
        echo "deb http://openresty.org/package/${arch_path}ubuntu $(lsb_release -sc) main" | tee /etc/apt/sources.list.d/openresty.list
    fi

    if [[ $IMAGE_BASE == "debian" ]]; then
        echo "deb http://openresty.org/package/${arch_path}debian $(lsb_release -sc) openresty" | tee /etc/apt/sources.list.d/openresty.list
    fi

    DEBIAN_FRONTEND=noninteractive apt-get update
    DEBIAN_FRONTEND=noninteractive apt-get install -y openresty-pcre-dev openresty-zlib-dev

    export_openresty_variables
    # fix OR_PREFIX
    if [[ $build_latest == "latest" ]]; then
        unset OR_PREFIX
    fi
    ${BUILD_PATH}/build-api7ee-runtime.sh ${build_latest}
}

export_openresty_variables() {
    export openssl_prefix=/usr/local/openresty/openssl3
    export zlib_prefix=/usr/local/openresty/zlib
    export pcre_prefix=/usr/local/openresty/pcre
    export OR_PREFIX=/usr/local/openresty

    export cc_opt="-DNGX_LUA_ABORT_AT_PANIC -I${zlib_prefix}/include -I${pcre_prefix}/include -I${openssl_prefix}/include"
    export ld_opt="-L${zlib_prefix}/lib -L${pcre_prefix}/lib -L${openssl_prefix}/lib -Wl,-rpath,${zlib_prefix}/lib:${pcre_prefix}/lib:${openssl_prefix}/lib"
}

export_apisix_base_openresty_variables() {
    export openssl_prefix=/usr/local/openresty/openssl111
    export zlib_prefix=/usr/local/openresty/zlib
    export pcre_prefix=/usr/local/openresty/pcre
    export OR_PREFIX=/usr/local/openresty

    export cc_opt="-DNGX_LUA_ABORT_AT_PANIC -I${zlib_prefix}/include -I${pcre_prefix}/include -I${openssl_prefix}/include"
    export ld_opt="-L${zlib_prefix}/lib -L${pcre_prefix}/lib -L${openssl_prefix}/lib -Wl,-rpath,${zlib_prefix}/lib:${pcre_prefix}/lib:${openssl_prefix}/lib"
}

case_opt=$1

case ${case_opt} in
build_api7ee_runtime_deb)
    build_api7ee_runtime_deb
    ;;
esac
