#!/bin/bash

set -ex

# set the code branch
version=master
curdir=$(pwd)

# clear the environment
rm -rf /tmp/apisix/
rm -rf /tmp/apisix-dashboard/

mkdir -p /tmp/rpm/
mkdir -p /tmp/apisix/dashboard/usr/bin/
mkdir -p /tmp/apisix/dashboard/usr/local/apisix/dashboard/

# build dashboard
cd /tmp/
git clone -b $version https://github.com/apache/apisix-dashboard.git
cd apisix-dashboard
make build

cp -r output/* /tmp/apisix/dashboard/usr/local/apisix/dashboard
ln -s /usr/local/apisix/dashboard/manager-api /tmp/apisix/dashboard/usr/bin/manager-api
cd ../..
rm -rf apisix-dashboard

# build the rpm for dashboard
cd $curdir
fpm -f \
    -s dir \
    -t rpm \
    -n apisix-dashboard -a `uname -i` -v $version  \
    --description 'Apache APISIX Dashboard is designed to make it as easy as possible for users to operate Apache APISIX through a frontend interface.'  \
    -C /tmp/apisix/dashboard/ \
    -p ./output/ \
    --url 'https://github.com/apache/apisix-dashboard'
