#!/usr/bin/env bash
set -euo pipefail
set -x

ARCH=${ARCH:-`(uname -m | tr '[:upper:]' '[:lower:]')`}

install_apisix_dependencies_deb() {
    install_dependencies_deb
    install_openresty_deb
    install_luarocks
}

install_apisix_dependencies_rpm() {
    install_dependencies_rpm
    install_openresty_rpm
    install_luarocks
}

install_dependencies_rpm() {
    # install basic dependencies
    if [[ $IMAGE_BASE == "registry.access.redhat.com/ubi8/ubi" ]]; then
        yum install -y --disablerepo=* --enablerepo=ubi-8-appstream-rpms --enablerepo=ubi-8-baseos-rpms wget tar gcc automake autoconf libtool make curl git which unzip sudo
        yum install -y --disablerepo=* --enablerepo=ubi-8-appstream-rpms --enablerepo=ubi-8-baseos-rpms yum-utils
    else
        yum install -y wget tar gcc automake autoconf libtool make curl git which unzip sudo
        yum install -y yum-utils
    fi
}

install_dependencies_deb() {
    # install basic dependencies
    DEBIAN_FRONTEND=noninteractive apt-get update
    DEBIAN_FRONTEND=noninteractive apt-get install -y wget tar gcc automake autoconf libtool make curl git unzip sudo libreadline-dev lsb-release gawk
}

install_openresty_deb() {
    DEBIAN_FRONTEND=noninteractive apt-get update
    DEBIAN_FRONTEND=noninteractive apt-get install -y libreadline-dev lsb-release libpcre3 libpcre3-dev libldap2-dev perl build-essential
    DEBIAN_FRONTEND=noninteractive apt-get -y install --no-install-recommends wget gnupg ca-certificates
}

install_openresty_rpm() {
    yum install -y pcre pcre-devel openldap-devel
}

install_luarocks() {
    wget https://raw.githubusercontent.com/apache/apisix/master/utils/linux-install-luarocks.sh
    chmod +x linux-install-luarocks.sh
    ./linux-install-luarocks.sh
}

install_etcd() {
    ETCD_ARCH="amd64"
    if [[ $ARCH == "arm64" ]] || [[ $ARCH == "aarch64" ]]; then
        ETCD_ARCH="arm64"
    fi
    wget https://github.com/etcd-io/etcd/releases/download/"${RUNNING_ETCD_VERSION}"/etcd-"${RUNNING_ETCD_VERSION}"-linux-"${ETCD_ARCH}".tar.gz
    tar -zxvf etcd-"${RUNNING_ETCD_VERSION}"-linux-"${ETCD_ARCH}".tar.gz
}

version_gt() { test "$(echo "$@" | tr " " "\n" | sort -V | head -n 1)" != "$1"; }

is_newer_version() {
    if [ "${checkout_v}" = "master" -o "${checkout_v:0:7}" = "release" ];then
        return 0
    fi

    if [ "${checkout_v:0:1}" = "v" ];then
        version_gt "${checkout_v:1}" "2.2"
    else
        version_gt "${checkout_v}" "2.2"
    fi
}

install_rust() {
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sudo sh -s -- -y
    source "$HOME/.cargo/env"
}

install_apisix() {
    mkdir -p /tmp/build/output/apisix/usr/bin/
    cd /apisix

    # patch rockspec file to install with local repo
    sed -re '/^\s*source\s*=\s*\{$/{:src;n;s/^(\s*url\s*=).*$/\1".\/apisix",/;/\}/!bsrc}' \
         -e '/^\s*source\s*=\s*\{$/{:src;n;/^(\s*branch\s*=).*$/d;/\}/!bsrc}' \
         -i apisix-master-${iteration}.rockspec

    # install rust
    install_rust

    # build the lib and specify the storage path of the package installed
    luarocks make ./apisix-master-${iteration}.rockspec --tree=/tmp/build/output/apisix/usr/local/apisix/deps --local
    chown -R "$(whoami)":"$(whoami)" /tmp/build/output
    cd ..
    # copy the compiled files to the package install directory
    cp /tmp/build/output/apisix/usr/local/apisix/deps/lib64/luarocks/rocks-5.1/apisix/master-"${iteration}"/bin/apisix /tmp/build/output/apisix/usr/bin/ || true
    cp /tmp/build/output/apisix/usr/local/apisix/deps/lib/luarocks/rocks-5.1/apisix/master-"${iteration}"/bin/apisix /tmp/build/output/apisix/usr/bin/ || true
    # modify the apisix entry shell to be compatible with version 2.2 and 2.3
    if is_newer_version "${checkout_v}"; then
        echo 'use shell '
    else
        bin='#! /usr/local/openresty/luajit/bin/luajit\npackage.path = "/usr/local/apisix/?.lua;" .. package.path'
        sed -i "1s@.*@$bin@" /tmp/build/output/apisix/usr/bin/apisix
    fi
    cp -r /usr/local/apisix/* /tmp/build/output/apisix/usr/local/apisix/
    mv /tmp/build/output/apisix/usr/local/apisix/deps/share/lua/5.1/apisix /tmp/build/output/apisix/usr/local/apisix/
    if is_newer_version "${checkout_v}"; then
        bin='package.path = "/usr/local/apisix/?.lua;" .. package.path'
        sed -i "1s@.*@$bin@" /tmp/build/output/apisix/usr/local/apisix/apisix/cli/apisix.lua
    else
        echo ''
    fi
    sed -i '1i package.path = "/usr/local/apisix/deps/share/lua/5.1/?/init.lua;" .. package.path' /tmp/build/output/apisix/usr/local/apisix/apisix/cli/apisix.lua
    # delete unnecessary files
    rm -rf /tmp/build/output/apisix/usr/local/apisix/deps/lib64/luarocks
    rm -rf /tmp/build/output/apisix/usr/local/apisix/deps/lib/luarocks/rocks-5.1/apisix/master-"${iteration}"/doc
}

install_golang() {
    GO_VERSION="1.19.6"
    GO_ARCH="amd64"
    if [[ $ARCH == "arm64" ]] || [[ $ARCH == "aarch64" ]]; then
        GO_ARCH="arm64"
    fi
    wget https://dl.google.com/go/go"${GO_VERSION}".linux-"${GO_ARCH}".tar.gz
    tar -xzf go"${GO_VERSION}".linux-"${GO_ARCH}".tar.gz
    mv go /usr/local
}

install_dashboard_dependencies_rpm() {
    yum install -y wget curl git which gcc make
    curl --silent --location https://dl.yarnpkg.com/rpm/yarn.repo | tee /etc/yum.repos.d/yarn.repo
    sh -c "$(curl -fsSL https://rpm.nodesource.com/setup_14.x)"
    yum install -y nodejs yarn
    install_golang
}

install_dashboard_dependencies_deb() {
    DEBIAN_FRONTEND=noninteractive apt-get update
    DEBIAN_FRONTEND=noninteractive apt-get install -y wget curl git gcc make
    curl -fsSL https://deb.nodesource.com/setup_14.x | bash -
    DEBIAN_FRONTEND=noninteractive apt-get install -y nodejs
    npm install -g yarn
    install_golang
}

install_dashboard() {
    mkdir -p /tmp/build/output/apisix/dashboard/usr/bin/
    mkdir -p /tmp/build/output/apisix/dashboard/usr/local/apisix/dashboard/
    # config golang
    export GO111MODULE=on
    export GOROOT=/usr/local/go
    export GOPATH=$HOME/gopath
    export PATH=$PATH:$GOROOT/bin:$GOPATH/bin
    cd "$HOME"
    mkdir gopath
    go env -w GOPROXY="${goproxy}"
    cd /tmp/
    cd /apisix-dashboard
    # FIXME: when the certificate is valid
    yarn config set "strict-ssl" false -g
    make build
    # copy the compiled files to the specified directory for packaging
    cp -r output/* /tmp/build/output/apisix/dashboard/usr/local/apisix/dashboard
    # set the soft link for manager-api
    ln -s /usr/local/apisix/dashboard/manager-api /tmp/build/output/apisix/dashboard/usr/bin/manager-api
    # determine dist and write it into /tmp/dist file
    /determine-dist.sh
}

case_opt=$1
shift

case ${case_opt} in
install_apisix_dependencies_rpm)
    install_apisix_dependencies_rpm
    ;;
install_apisix_dependencies_deb)
    install_apisix_dependencies_deb
    ;;
install_openresty_deb)
    install_openresty_deb
    ;;
install_openresty_rpm)
    install_openresty_rpm
    ;;
install_etcd)
    install_etcd
    ;;
install_apisix)
    install_apisix
    ;;
install_dashboard_dependencies_rpm)
    install_dashboard_dependencies_rpm
    ;;
install_dashboard_dependencies_deb)
    install_dashboard_dependencies_deb
    ;;
install_dashboard)
    install_dashboard
    ;;
install_luarocks)
    install_luarocks
    ;;
esac
