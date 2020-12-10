#!/bin/bash

set -ex

#version=2.1
version=master
iteration=0

sudo luarocks remove apisix || true
sudo rm -rf /usr/local/apisix/
sudo rm -rf /tmp/apisix

wget https://github.com/apache/apisix/raw/master/rockspec/apisix-$version-$iteration.rockspec
sudo luarocks install apisix-$version-$iteration.rockspec --tree=/tmp/apisix/usr/local/apisix/deps --local
sudo chown -R $USER:$USER /tmp/apisix

mkdir -p /tmp/apisix/usr/bin/
mkdir -p /tmp/rpm/

cp /tmp/apisix/usr/local/apisix/deps/lib64/luarocks/rocks/apisix/$version-$iteration/bin/apisix /tmp/apisix/usr/bin/
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

# install epel
wget http://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
sudo rpm -ivh epel-release-latest-7.noarch.rpm
# add OpenResty source
sudo yum install yum-utils
sudo yum-config-manager --add-repo https://openresty.org/package/centos/openresty.repo
install OpenResty and some compilation tools
sudo yum install -y openresty
cp -r /usr/local/openresty /tmp/apisix/usr/local/openresty

# install etcd
mkdir ~/etcd
wget https://github.com/etcd-io/etcd/releases/download/v3.4.13/etcd-v3.4.13-linux-amd64.tar.gz
tar -xvf etcd-v3.4.13-linux-amd64.tar.gz -C ~/etcd  && cd ~/etcd/etcd-v3.4.13-linux-amd64 && sudo cp -a etcd etcdctl /tmp/apisix/usr/bin/

rm -rf /tmp/apisix/usr/local/apisix/deps/lib64/luarocks
rm -rf /tmp/apisix/usr/local/apisix/deps/lib/luarocks/rocks-5.1/apisix/$version-$iteration/doc

fpm -f -s dir -t rpm -n apisix -a `uname -i` -v $version --iteration $iteration --description 'APISEVEN is a distributed gateway for APIs and Microservices, focused on high performance and reliability.'  -C /tmp/apisix/ -p /tmp/rpm/ --url 'https://www.apiseven.com/'
