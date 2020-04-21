
## RPM for CentOS 7

### install Luarocks
https://github.com/luarocks/luarocks/wiki/Installation-instructions-for-Unix

### install OpenResty

### install fpm
```
sudo yum -y install git autoconf automake libtool pcre-devel gcc-c++ ruby ruby-devel rubygems gcc rpm-build lua-devel cmake3
```

If your server in China mainland, please add source for Ruby:
```
gem sources --add https://gems.ruby-china.com/ --remove https://rubygems.org/
```

Then you can install `fpm`:
```
gem install --no-ri --no-rdoc fpm
```

### install yarn for build dashboard
```
curl --silent --location https://dl.yarnpkg.com/rpm/yarn.repo | sudo tee /etc/yum.repos.d/yarn.repo
curl -sL https://rpm.nodesource.com/setup_12.x | sudo bash -
sudo yum clean all && sudo yum makecache fast
sudo yum install -y nodejs
sudo yum install yarn
```

### run build tool script:
The version of APISIX is hard-code in `run.sh` now, you can change it by yourself.

```
./run.sh
```

The RPM package will be in `/tmp/rpm`.
