
## RPM for CentOS 7

### install fpm
```
sudo yum -y install autoconf automake libtool pcre-devel gcc-c++ ruby ruby-devel rubygems gcc rpm-build lua-devel cmake3
```

If your server in China mainland, please add source for Ruby:
```
gem sources --add https://gems.ruby-china.com/ --remove https://rubygems.org/
```

Then you can install `fpm`:
```
gem install --no-ri --no-rdoc fpm
```

### run build tool script:
The version of APISIX is hard-code in `run.sh` now, you can change it by yourself.

```
./run.sh
```

The RPM package will be in `/tmp/rpm`.
