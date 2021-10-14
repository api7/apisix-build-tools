#!/usr/bin/env bash
set -euo pipefail
set -x

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
    yum -y install wget tar gcc automake autoconf libtool make curl git which unzip
    yum -y install epel-release
    yum install -y yum-utils readline-dev readline-devel

    # install lua 5.1 for compatible with openresty 1.17.8.2
    install_lua
}

install_dependencies_deb() {
    # install basic dependencies
    DEBIAN_FRONTEND=noninteractive apt-get update
    DEBIAN_FRONTEND=noninteractive apt-get install -y wget tar gcc automake autoconf libtool make curl git unzip libreadline-dev lsb-release

    # install lua 5.1 for compatible with openresty 1.17.8.2
    install_lua
}

install_lua() {
    wget http://www.lua.org/ftp/lua-5.1.4.tar.gz
    tar -zxvf lua-5.1.4.tar.gz
    cd lua-5.1.4/
    make linux
    make install
}

install_openresty_deb() {
    # install openresty and openssl111
    DEBIAN_FRONTEND=noninteractive apt-get update
    DEBIAN_FRONTEND=noninteractive apt-get install -y libreadline-dev lsb-release libpcre3 libpcre3-dev libldap2-dev libssl-dev perl build-essential
    DEBIAN_FRONTEND=noninteractive apt-get -y install --no-install-recommends wget gnupg ca-certificates
    wget -O - https://openresty.org/package/pubkey.gpg | apt-key add -
    echo "deb http://openresty.org/package/ubuntu $(lsb_release -sc) main" | tee /etc/apt/sources.list.d/openresty.list
    DEBIAN_FRONTEND=noninteractive apt-get update
    DEBIAN_FRONTEND=noninteractive apt-get install -y openresty-openssl111-dev openresty
}

install_openresty_rpm() {
    # install openresty and openssl111
    yum-config-manager --add-repo https://openresty.org/package/centos/openresty.repo
    yum install -y openresty openresty-openssl111-devel pcre pcre-devel openldap-devel
}

install_luarocks() {
    # install luarocks
    wget https://github.com/luarocks/luarocks/archive/v3.4.0.tar.gz
    tar -xf v3.4.0.tar.gz
    cd luarocks-3.4.0 || exit
    ./configure --with-lua=/usr/local --with-lua-include=/usr/local/include >build.log 2>&1 || (cat build.log && exit 1)
    make build >build.log 2>&1 || (cat build.log && exit 1)
    make install >build.log 2>&1 || (cat build.log && exit 1)
    cd .. || exit
    rm -rf luarocks-3.4.0
    mkdir ~/.luarocks || true
    luarocks config variables.OPENSSL_LIBDIR /usr/local/openresty/openssl111/lib
    luarocks config variables.OPENSSL_INCDIR /usr/local/openresty/openssl111/include
}

install_etcd() {
    wget https://github.com/etcd-io/etcd/releases/download/${RUNNING_ETCD_VERSION}/etcd-${RUNNING_ETCD_VERSION}-linux-amd64.tar.gz
    tar -zxvf etcd-"${RUNNING_ETCD_VERSION}"-linux-amd64.tar.gz
}

install_apisix() {
    mkdir -p /tmp/build/output/apisix/usr/bin/
    cd /apisix
    # remove useless code for build
    sed -i 's/url.*/url = ".\/apisix",/' rockspec/apisix-master-${iteration}.rockspec
    sed -i 's/branch.*//' rockspec/apisix-master-${iteration}.rockspec
    # build the lib and specify the storage path of the package installed
    luarocks make ./rockspec/apisix-master-${iteration}.rockspec --tree=/tmp/build/output/apisix/usr/local/apisix/deps --local
    chown -R "$(whoami)":"$(whoami)" /tmp/build/output
    cd ..
    # copy the compiled files to the package install directory
    cp /tmp/build/output/apisix/usr/local/apisix/deps/lib64/luarocks/rocks-5.1/apisix/master-${iteration}/bin/apisix /tmp/build/output/apisix/usr/bin/ || true
    cp /tmp/build/output/apisix/usr/local/apisix/deps/lib/luarocks/rocks-5.1/apisix/master-${iteration}/bin/apisix /tmp/build/output/apisix/usr/bin/ || true
    # modify the apisix entry shell to be compatible with version 2.2 and 2.3
    if [ "${checkout_v}" = "master" ] || [ "${checkout_v:0:1}" != "v" -a "${checkout_v}" \> "2.2" ] || [ "${checkout_v:0:1}" = "v" -a "${checkout_v:1}" \> "2.2" ]; then
        echo 'use shell '
    else
        bin='#! /usr/local/openresty/luajit/bin/luajit\npackage.path = "/usr/local/apisix/?.lua;" .. package.path'
        sed -i "1s@.*@$bin@" /tmp/build/output/apisix/usr/bin/apisix
    fi
    cp -r /usr/local/apisix/* /tmp/build/output/apisix/usr/local/apisix/
    mv /tmp/build/output/apisix/usr/local/apisix/deps/share/lua/5.1/apisix /tmp/build/output/apisix/usr/local/apisix/
    if [ "${checkout_v}" = "master" ] || [ "${checkout_v:0:1}" != "v" -a "${checkout_v}" \> "2.2" ] || [ "${checkout_v:0:1}" = "v" -a "${checkout_v:1}" \> "2.2" ]; then
        bin='package.path = "/usr/local/apisix/?.lua;" .. package.path'
        sed -i "1s@.*@$bin@" /tmp/build/output/apisix/usr/local/apisix/apisix/cli/apisix.lua
    else
        echo ''
    fi
    # delete unnecessary files
    rm -rf /tmp/build/output/apisix/usr/local/apisix/deps/lib64/luarocks
    rm -rf /tmp/build/output/apisix/usr/local/apisix/deps/lib/luarocks/rocks-5.1/apisix/master-${iteration}/doc
}

install_golang() {
    wget https://dl.google.com/go/go1.16.linux-amd64.tar.gz
    tar -xzf go1.16.linux-amd64.tar.gz
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
    go env -w GOPROXY=https://goproxy.cn,direct
    cd /tmp/
    cd /apisix-dashboard
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
esac
