#!/usr/bin/env bash
#
# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

#!/bin/bash

set -ex

branch=$2
apisix_repository=https://github.com/apache/apisix
dashboard_repository=https://github.com/apache/apisix-dashboard.git
iteration=0

install_dependencies() {
    # install epel, `luarocks` need it.
    yum install -y wget curl git which
    wget http://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm -O epel-release-latest-7.noarch.rpm
    rpm -ivh epel-release-latest-7.noarch.rpm

    # add OpenResty source
    yum install -y yum-utils || true
    yum-config-manager --add-repo https://openresty.org/package/centos/openresty.repo
    yum check-update || true

    # install OpenResty and some compilation tools
    yum install -y openresty gcc luarocks lua-devel make
}

build_apisix() {
    # clear the environment
    rm -rf /usr/local/apisix/
    rm -rf /tmp/build/output/apisix/*
    rm -rf apisix
    mkdir -p /tmp/build/output/apisix/usr/bin/

    git clone -b $branch $apisix_repository

    # set the code source
    if [ ${branch:0:1} = "v" ];then
        branch=${branch:1}
    fi
    sed -i 's/url.*/url = ".\/apisix",/'  apisix/rockspec/apisix-$branch-$iteration.rockspec
    sed -i 's/branch.*//' apisix/rockspec/apisix-$branch-$iteration.rockspec

    cd ./apisix
    luarocks make ./rockspec/apisix-$branch-$iteration.rockspec --tree=/tmp/build/output/apisix/usr/local/apisix/deps --local
    chown -R $USER:$USER /tmp/build/output
    cd ..

    cp /tmp/build/output/apisix/usr/local/apisix/deps/lib64/luarocks/rocks/apisix/$branch-$iteration/bin/apisix /tmp/build/output/apisix/usr/bin/ || true
    cp /tmp/build/output/apisix/usr/local/apisix/deps/lib/luarocks/rocks/apisix/$branch-$iteration/bin/apisix /tmp/build/output/apisix/usr/bin/ || true
    bin='#! /usr/local/openresty/luajit/bin/luajit\npackage.path = "/usr/local/apisix/?.lua;" .. package.path'
    sed -i "1s@.*@$bin@" /tmp/build/output/apisix/usr/bin/apisix

    # for conf, log
    cp -r /usr/local/apisix/* /tmp/build/output/apisix/usr/local/apisix/

    # code base
    mv /tmp/build/output/apisix/usr/local/apisix/deps/share/lua/5.1/apisix /tmp/build/output/apisix/usr/local/apisix/

    rm -rf /tmp/build/output/apisix/usr/local/apisix/deps/lib64/luarocks
    rm -rf /tmp/build/output/apisix/usr/local/apisix/deps/lib/luarocks/rocks-5.1/apisix/$version-$iteration/doc
}

install_dependencies_dashboard() {
    # install base dependencies, nodejs, yarn
    yum install -y wget curl git which gcc make
    curl --silent --location https://dl.yarnpkg.com/rpm/yarn.repo | tee /etc/yum.repos.d/yarn.repo
    sh -c "$(curl -fsSL https://rpm.nodesource.com/setup_10.x)"
    yum install -y nodejs yarn

    # install golang
    wget https://dl.google.com/go/go1.15.2.linux-amd64.tar.gz 
    tar -xzf go1.15.2.linux-amd64.tar.gz
    mv go /usr/local
}

build_dashboard() {
    # clear the environment
    rm -rf /tmp/build/output/apisix/*
    rm -rf /tmp/apisix-dashboard/

    mkdir -p /tmp/rpm/
    mkdir -p /tmp/build/output/apisix/dashboard/usr/bin/
    mkdir -p /tmp/build/output/apisix/dashboard/usr/local/apisix/dashboard/

    # set env for go
    export GO111MODULE=on
    export GOROOT=/usr/local/go 
    export GOPATH=$HOME/gopath
    export PATH=$PATH:$GOROOT/bin:$GOPATH/bin
    cd $HOME
    mkdir gopath
    go env -w GOPROXY=https://goproxy.cn,direct

    # build dashboard
    cd /tmp/
    git clone -b $branch $dashboard_repository
    cd apisix-dashboard
    make build

    cp -r output/* /tmp/build/output/apisix/dashboard/usr/local/apisix/dashboard
    ln -s /usr/local/apisix/dashboard/manager-api /tmp/build/output/apisix/dashboard/usr/bin/manager-api
    cd ../..
    rm -rf apisix-dashboard
}

case_opt=$1
case $case_opt in
    (install_dependencies)
        install_dependencies
        ;;
    (build_apisix)
        build_apisix
        ;;
    (install_dependencies_dashboard)
        install_dependencies_dashboard
        ;;
    (build_dashboard)
        build_dashboard
        ;;
esac
