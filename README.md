## Prerequisites

- Docker
- fpm
- Make

### Packaging a Centos 7 package of Apache APISIX

```sh
make build-rpm-apisix
ls output/
apisix-0.0-0.x86_64.rpm
```

### Packaging an Ubuntu bionic package of Apache APISIX

```sh
make build-deb-apisix
ls output/
apisix_1.0-0_amd64.deb
```

### Packaging a Centos 7 package of Apache APISIX Dashboard

```sh
make build-rpm-dashboard
ls output/
apisix-dashboard-0.0-0.x86_64.rpm
```

### Packaging an Ubuntu bionic package of Apache APISIX Dashboard

```sh
make build-deb-dashboard
ls output/
apisix-dashboard_1.0-0_amd64.deb
```

### Details

- `Makefile` the entrance of the packager
- `build` used to store the compiled temporary files generated during the packaging process
- `build-deb.sh & build-rpm.sh` they are mapped to the docker image to perform the compilation action
- `output` directory for packages 