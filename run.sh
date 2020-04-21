version=1.2
# version=master
iteration=0

sudo luarocks remove apisix --local
sudo rm -rf /usr/local/apisix/
rm -rf /tmp/apisix

wget https://github.com/apache/incubator-apisix/raw/master/rockspec/apisix-$version-0.rockspec
sudo luarocks install apisix-$version-0.rockspec --tree=/tmp/apisix/usr/local/apisix/deps --local
sudo chown -R $USER:$USER /tmp/apisix

mkdir -p /tmp/apisix/usr/bin/
mkdir -p /tmp/rpm/

cp /tmp/apisix/usr/local/apisix/deps/lib/luarocks/rocks-5.1/apisix/$version-0/bin/apisix /tmp/apisix/usr/bin/
bin='#! /usr/local/openresty/luajit/bin/luajit\npackage.path = "/usr/local/apisix/?.lua;" .. package.path'
sed -i "1s@.*@$bin@" /tmp/apisix/usr/bin/apisix

# for conf, log
cp -r /usr/local/apisix/* /tmp/apisix/usr/local/apisix/

# for dashboard
git clone https://github.com/apache/incubator-apisix.git
cd incubator-apisix
git checkout tags/$version -b $version
git submodule update --init --recursive
cd dashboard
yarn && yarn build:prod

mkdir /tmp/apisix/usr/local/apisix/dashboard
cp -r dist/* /tmp/apisix/usr/local/apisix/dashboard
cd ../..
rm -rf incubator-apisix

# code base
mv /tmp/apisix/usr/local/apisix/deps/share/lua/5.1/apisix /tmp/apisix/usr/local/apisix/

rm -rf /tmp/apisix/usr/local/apisix/deps/lib64/luarocks

fpm -f -s dir -t rpm -n apisix -a all -v $version --iteration $iteration -d 'openresty >= 1.15.8.1' --description 'Apache APISIX is a distributed gateway for APIs and Microservices, focused on high performance and reliability.' --license "ASL 2.0"  -C /tmp/apisix/ -p /tmp/rpm/ --url 'https://www.iresty.com'
