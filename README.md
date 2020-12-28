
## build apisix RPM for CentOS 7

### install Luarocks
https://github.com/luarocks/luarocks/wiki/Installation-instructions-for-Unix

### install OpenResty
https://openresty.org/en/installation.html

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

### run build tool script:
The version of APISIX is hard-code in `run.sh` now, you can change it by yourself.

```
./run.sh
```

The RPM package will be in `/tmp/rpm`.


## build apisix-dashboard RPM for CentOS 7

### install Yarn、nodejs
```
curl --silent --location https://dl.yarnpkg.com/rpm/yarn.repo | sudo tee /etc/yum.repos.d/yarn.repo
curl --silent --location https://rpm.nodesource.com/setup_10.x | sudo bash -
sudo yum install –y nodejs yarn
```

### install golang
```
wget https://dl.google.com/go/go1.15.2.linux-amd64.tar.gz 
tar -xzf go1.15.2.linux-amd64.tar.gz
sudo mv go /usr/local
```

### gdjust the Path Variable for golang
appending the following line to the `/etc/profile` file
```
export GO111MODULE=on
export GOROOT=/usr/local/go 
export GOPATH=/home/gopath
export PATH=$PATH:$GOROOT/bin:$GOPATH/bin
```

### create the workspace directory for golang
```
cd /home
sudo mkdir gopath
```

### run build tool script for apisix-dashboard:
```
sudo ./run.sh
```
