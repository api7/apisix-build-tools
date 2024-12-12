## Prerequisites

- Docker
- fpm
- Make
- rpm (if your host system is Ubuntu, should install rpmbuild by `sudo apt-get install rpm`)

## Parameters
| Parameter       | Required | Description                                                                                                                                                                       | Example                              |
|-----------------|----------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|--------------------------------------|
| type            | True     | it can be `deb`                                                                                                                                               | type=rpm                             |
| app             | True     | it can be `api7ee-runtime`                                                                                                                | app=api7ee-runtime                           |
| checkout        | True     | the code branch or tag of the app which you want to package                                                                                                                       | checkout=2.1 or checkout=v2.1        |
| version         | True     | the version of the package                                                                                                                                                        | version=10.10                        |
| local_code_path | False    | the path of local code diretory of apisix or dashboard, which depends on the app parameter                                                                                        | local_code_path=/home/vagrant/apisix |
| openresty       | False    | the openresty type that apisix depends on, its value can be `api7ee-runtime`, the default is `openresty`                                            | openresty=api7ee-runtime                |
| artifact        | False    | the final name of the generated artifact, if not specified, this will be the same as `app`                                                                                        | artifact=apisix                      |
| image_base      | False    | the environment for packaging, if type is `rpm` the default image_base is `centos`, if type is `deb` the default image_base is `ubuntu`                                           | image_base=centos                    |
| image_tag       | False    | the environment for packaging, it's value can be `16.04\|18.04\|20.04\|6\|7\|8`, if type is `rpm` the default image_tag is `7`, if type is `deb` the default image_tag is `20.04` | image_tag=7                          |
| buildx          | False    | if `True`, use buildx to build docker images, which may speed up GitHub Actions                                                                                                   | buildx=True                          |

## Example

### build api7ee-runtime

Packaging a Centos 7 package of APISIX's OpenResty distribution

Packaging an Ubuntu 20.04 package of Apache APISIX's OpenResty distribution
```sh
make package type=deb app=api7ee-runtime version=1.0.0
ls output/
api7ee-runtime_1.0.0-0~ubuntu20.04_amd64.deb
```

## Details

- `Makefile` the entrance of the packager
- `dockerfiles` directory for dockerfiles
- `output` directory for packages
