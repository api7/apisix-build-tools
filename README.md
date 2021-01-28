## Prerequisites

- Docker
- fpm
- Make

### Parameters
|Parameter      |Required   |Description        |Example|
|---------|---------|----|-----------|
|type     |True |it can be `deb` or `rpm` |type=rpm|
|app      |True |it can be `apisix` or `dashboard` |app=apisix|
|branch   |True |the code branch of the app which you want to package, it can not be `master`|branch=2.1|
|version  |True |the version of the package|version=10.10|
|image_base|False |the environment for packaging, it's value can be `centos|ubuntu` , default value is `centos` |image_base=centos|
|image_tag|False |the environment for packaging, it's value can be `xenial|bionic|focal|6|7|8` , default value is `7`|image_tag=7|

### Example
Packaging a Centos 7 package of Apache APISIX
```sh
make package type=rpm app=apisix version=10.10 branch=2.2
ls output/
apisix-10.10-0.x86_64.rpm
```

Packaging an Ubuntu bionic package of Apache APISIX Dashboard
```sh
make package type=deb app=dashboard version=11.11 branch=2.3
ls output/
apisix-dashboard_11.11-0_amd64.deb
```

### Details

- `Makefile` the entrance of the packager
- `dockerfiles` directory for dockerfiles
- `output` directory for packages
