#!/bin/bash

set -ex

version=1.5
# version=master
iteration=0

sudo rm -rf /usr/local/apisix/
rm -rf /tmp/apisix

wget https://github.com/apache/apisix/raw/master/rockspec/apisix-$version-$iteration.rockspec -O apisix-$version-$iteration.rockspec
sudo luarocks config variables.OPENSSL_LIBDIR /usr/local/openresty/openssl/lib/
sudo luarocks config variables.OPENSSL_INCDIR /usr/local/openresty/openssl/include/
sudo luarocks install apisix-$version-$iteration.rockspec --tree=/tmp/apisix/usr/local/apisix/deps --local
sudo chown -R $USER:$USER /tmp/apisix

mkdir -p /tmp/apisix/usr/bin/
mkdir -p /tmp/rpm/

cp /tmp/apisix/usr/local/apisix/deps/lib/luarocks/rocks-5.1/apisix/$version-$iteration/bin/apisix /tmp/apisix/usr/bin/
bin='#! /usr/local/openresty/luajit/bin/luajit\npackage.path = "/usr/local/apisix/?.lua;" .. package.path'
sed -i "1s@.*@$bin@" /tmp/apisix/usr/bin/apisix

# for conf, log
cp -r /usr/local/apisix/* /tmp/apisix/usr/local/apisix/

# for dashboard
#git clone https://github.com/apache/incubator-apisix.git
#cd incubator-apisix
#git checkout tags/$version -b $version
#git submodule update --init --recursive
#cd dashboard
#yarn && yarn build:prod

#mkdir /tmp/apisix/usr/local/apisix/dashboard
#cp -r dist/* /tmp/apisix/usr/local/apisix/dashboard
#cd ../..
#rm -rf incubator-apisix

# code base
mv /tmp/apisix/usr/local/apisix/deps/share/lua/5.1/apisix /tmp/apisix/usr/local/apisix/

rm -rf /tmp/apisix/usr/local/apisix/deps/lib64/luarocks
rm -rf /tmp/apisix/usr/local/apisix/deps/lib/luarocks/rocks-5.1/apisix/$version-$iteration/doc

fpm -f -s dir -t rpm -n apisix -a `uname -i` -v $version --iteration $iteration \
    -d 'openresty >= 1.15.8.1' \
    -d 'openresty-openssl-devel' \
    --description 'Apache APISIX is a distributed gateway for APIs and Microservices, focused on high performance and reliability.' \
    --license "ASL 2.0"  -C /tmp/apisix/ -p /tmp/rpm/ --url 'http://apisix.apache.org/'
