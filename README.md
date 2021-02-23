## Prerequisites

- Docker
- fpm
- Make
- rpm (if your host system is Ubuntu, should install rpmbuild by `sudo apt-get install rpm`)

## Parameters
|Parameter      |Required   |Description        |Example|
|---------|---------|----|-----------|
|type     |True |it can be `deb` or `rpm` |type=rpm|
|app      |True |it can be `apisix` or `dashboard` |app=apisix|
|code_tag   |True |the code tag of the app which you want to package, it can not be `master`|code_tag=2.1|
|version  |True |the version of the package|version=10.10|
|image_base|False |the environment for packaging, if type is `rpm` the default image_base is `centos`, if type is `deb` the default image_base is `ubuntu`|image_base=centos|
|image_tag|False |the environment for packaging, it's value can be `xenial\|bionic\|focal\|6\|7\|8` , if type is `rpm` the default image_tag is `7`, if type is `deb` the default image_tag is `bionic`|image_tag=7|

## Example
Packaging a Centos 7 package of Apache APISIX
```sh
make package type=rpm app=apisix version=2.2 code_tag=2.2
ls output/
apisix-2.2-0.x86_64.rpm
```

## Details

- `Makefile` the entrance of the packager
- `dockerfiles` directory for dockerfiles
- `output` directory for packages
