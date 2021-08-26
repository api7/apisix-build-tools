## Prerequisites

- Docker
- fpm
- Make
- rpm (if your host system is Ubuntu, should install rpmbuild by `sudo apt-get install rpm`)

## Parameters
|Parameter      |Required   |Description        |Example|
|---------|---------|----|-----------|
|type     |True |it can be `deb` or `rpm` |type=rpm|
|app      |True |it can be `apisix`, `dashboard` or `apisix-openresty`|app=apisix|
|checkout   |True |the code branch or tag of the app which you want to package|checkout=2.1 or checkout=v2.1|
|version  |True |the version of the package|version=10.10|
|local_code_path  |False | the path of local code diretory of apisix or dashboard, which depends on the app parameter|local_code_path=/home/vagrant/apisix|
|openresty  |False |the openresty type that apisix depends on, it's value can be `openresty` or `apisix-openresty`, the default is `openresty`|openresty=apisix-openresty|
|image_base|False |the environment for packaging, if type is `rpm` the default image_base is `centos`, if type is `deb` the default image_base is `ubuntu`|image_base=centos|
|image_tag|False |the environment for packaging, it's value can be `16.04\|18.04\|20.04\|6\|7\|8`, if type is `rpm` the default image_tag is `7`, if type is `deb` the default image_tag is `20.04`|image_tag=7|

## Example
Packaging a Centos 7 package of Apache APISIX
```sh
make package type=rpm app=apisix version=2.2 checkout=2.2 image_base=centos image_tag=7
ls output/
apisix-2.2-0.el7.x86_64.rpm
```
or just leave `image_base` and `image_tag` as the default values.
```
make package type=rpm app=apisix version=2.2 checkout=2.2
ls output/
apisix-2.2-0.el7.x86_64.rpm
```

Packaging a Centos 8 package of Apache APISIX
```sh
make package type=rpm app=apisix version=2.2 checkout=2.2 image_base=centos image_tag=8
ls output/
apisix-2.2-0.el8.x86_64.rpm
```

Packaging a Centos 7 package of Apache APISIX Dashboard
```sh
make package type=rpm app=dashboard version=2.4 checkout=v2.4 image_base=centos image_tag=7
ls output/
apisix-dashboard-2.4-0.el7.x86_64.rpm
```

Packaging a Centos 7 package of APISIX's OpenResty distribution
```sh
make package type=rpm app=apisix-openresty version=1.0.0 image_base=centos image_tag=7
ls output/
apisix-openresty-1.0.0-0.el7.x86_64.rpm
```

## Details

- `Makefile` the entrance of the packager
- `dockerfiles` directory for dockerfiles
- `output` directory for packages

## build apisix's OpenResty

```shell
OR_PREFIX=/tmp ./build-apisix-openresty.sh
```

The default `OR_PREFIX` is `/usr/local/openresty`
