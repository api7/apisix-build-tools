### CentOS
sudo yum -y install autoconf automake libtool pcre-devel gcc-c++ ruby ruby-devel rubygems gcc rpm-build

gem sources --add https://gems.ruby-china.com/ --remove https://rubygems.org/
gem install --no-ri --no-rdoc fpm

cp /media/psf/Home/work/apisix/conf/nginx.conf /tmp/apisix/usr/share/lua/5.1/apisix/conf/nginx.conf
cp -r /media/psf/Home/work/apisix/lua/ /tmp/apisix/usr/share/lua/5.1/apisix/

fpm -f -s dir -t rpm -n apisix -a all -v 0.1 --iteration 2 -d 'openresty >= 1.15.8.1' -d 'etcd >= 3.3' --description 'APISix is a distributed gateway for APIs and Microservices, focused on high performance and reliability.' --license "ASL 2.0"  -C /tmp/apisix/ -p /tmp/rpm/ --url 'https://www.iresty.com'
