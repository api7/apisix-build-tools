#
# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

version=0
checkout=0
app=0
type=0
image_base="registry.access.redhat.com/ubi8/ubi"
image_tag="8.6"
iteration=0
local_code_path=0
openresty="apisix-runtime"
artifact="0"
runtime_version="0"
apisix_repo="https://github.com/apache/apisix"
apisix_runtime_repo="https://github.com/api7/apisix-build-tools.git"
dashboard_repo="https://github.com/apache/apisix-dashboard"

### set the default image for deb package
ifeq ($(type), deb)
image_base="ubuntu"
image_tag="20.04"
endif
# Set arch to linux/amd64 if it's not defined
arch ?= linux/amd64
buildx=0
cache_from=type=local,src=/tmp/.buildx-cache
cache_to=type=local,dest=/tmp/.buildx-cache
### function for building
### $(1) is name
### $(2) is dockerfile filename
### $(3) is package type
### $(4) is code path
ifneq ($(buildx), True)
define build
	docker build -t apache/$(1)-$(3):$(version) \
		--build-arg checkout_v=$(checkout) \
		--build-arg PACKAGE_TYPE=$(3) \
		--build-arg VERSION=$(version) \
		--build-arg RUNTIME_VERSION=$(runtime_version) \
		--build-arg IMAGE_BASE=$(image_base) \
		--build-arg IMAGE_TAG=$(image_tag) \
		--build-arg CODE_PATH=$(4) \
		--platform $(arch) \
		-f ./dockerfiles/Dockerfile.$(2).$(3) .
endef
else
define build
	docker buildx build -t apache/$(1)-$(3):$(version) \
		--build-arg checkout_v=$(checkout) \
		--build-arg PACKAGE_TYPE=$(3) \
		--build-arg VERSION=$(version) \
		--build-arg RUNTIME_VERSION=$(runtime_version) \
		--build-arg IMAGE_BASE=$(image_base) \
		--build-arg IMAGE_TAG=$(image_tag) \
		--build-arg CODE_PATH=$(4) \
		--load \
		--cache-from=$(cache_from) \
		--cache-to=$(cache_to) \
    --platform $(arch) \
		-f ./dockerfiles/Dockerfile.$(2).$(3) .
endef
endif

### function for building apisix-runtime
### $(1) is name
### $(2) is dockerfile filename
### $(3) is package type
### $(4) is code path
ifneq ($(buildx), True)
define build_runtime
	docker build -t apache/$(1)-$(3):$(runtime_version) \
		--build-arg checkout_v=$(checkout) \
		--build-arg VERSION=$(version) \
		--build-arg RUNTIME_VERSION=$(runtime_version) \
		--build-arg IMAGE_BASE=$(image_base) \
		--build-arg IMAGE_TAG=$(image_tag) \
		--build-arg CODE_PATH=$(4) \
    --platform $(arch) \
		-f ./dockerfiles/Dockerfile.$(2).$(3) .
endef
else
define build_runtime
	docker buildx build -t apache/$(1)-$(3):$(runtime_version) \
		--build-arg checkout_v=$(checkout) \
		--build-arg VERSION=$(version) \
		--build-arg RUNTIME_VERSION=$(runtime_version) \
		--build-arg IMAGE_BASE=$(image_base) \
		--build-arg IMAGE_TAG=$(image_tag) \
		--build-arg CODE_PATH=$(4) \
		--load \
		--cache-from=$(cache_from) \
		--cache-to=$(cache_to) \
    --platform $(arch) \
		-f ./dockerfiles/Dockerfile.$(2).$(3) .
endef
endif

### function for building image
### $(1) is name
### $(2) is dockerfile filename
### $(3) is package type
### $(4) is openresty image name
### $(5) is openresty image version
### $(6) is code path
ifneq ($(buildx), True)
define build-image
	docker build -t apache/$(1)-$(3):$(version) \
		--build-arg OPENRESTY_NAME=$(4) \
		--build-arg OPENRESTY_VERSION=$(5) \
		--build-arg CODE_PATH=$(6) \
    --platform $(arch) \
		-f ./dockerfiles/Dockerfile.$(2).$(3) .
endef
else
define build-image
	docker buildx build -t apache/$(1)-$(3):$(version) \
		--build-arg OPENRESTY_NAME=$(4) \
		--build-arg OPENRESTY_VERSION=$(5) \
		--build-arg CODE_PATH=$(6) \
		--load \
		--cache-from=$(cache_from) \
		--cache-to=$(cache_to) \
    --platform $(arch) \
		-f ./dockerfiles/Dockerfile.$(2).$(3) .
endef
endif

### function for packing
### $(1) is name
### $(2) is package type
define package
	docker build -t apache/$(1)-packaged-$(2):$(version) \
		--build-arg VERSION=$(version) \
		--build-arg ITERATION=$(iteration) \
		--build-arg PACKAGE_VERSION=$(version) \
		--build-arg RUNTIME_VERSION=$(runtime_version) \
		--build-arg PACKAGE_TYPE=$(2) \
		--build-arg OPENRESTY=$(openresty) \
		--build-arg ARTIFACT=$(artifact) \
    --platform $(arch) \
		-f ./dockerfiles/Dockerfile.package.$(1) .
	docker run -d --rm --name output --net="host" apache/$(1)-packaged-$(2):$(version)
	docker cp output:/output ${PWD}
	docker stop output
	docker system prune -a -f
endef

### function for packing
### $(1) is name
### $(2) is package type
define package_runtime
	docker build -t apache/$(1)-packaged-$(2):$(runtime_version) \
		--build-arg VERSION=$(version) \
		--build-arg ITERATION=$(iteration) \
		--build-arg PACKAGE_VERSION=$(version) \
		--build-arg RUNTIME_VERSION=$(runtime_version) \
		--build-arg PACKAGE_TYPE=$(2) \
		--build-arg OPENRESTY=$(openresty) \
		--build-arg ARTIFACT=$(artifact) \
    --platform $(arch) \
		-f ./dockerfiles/Dockerfile.package.$(1) .
	docker run -d --rm --name output --net="host" apache/$(1)-packaged-$(2):$(runtime_version)
	docker cp output:/output ${PWD}
	docker stop output
	docker system prune -a -f
endef

### build apisix:
.PHONY: build-apisix-rpm
build-apisix-rpm:
ifeq ($(local_code_path), 0)
	git clone -b $(checkout) $(apisix_repo) ./apisix
	$(call build,apisix,apisix,rpm,"./apisix")
	rm -fr ./apisix
else
	$(call build,apisix,apisix,rpm,$(local_code_path))
endif

.PHONY: build-apisix-deb
build-apisix-deb:
ifeq ($(local_code_path), 0)
	git clone -b $(checkout) $(apisix_repo) ./apisix
	$(call build,apisix,apisix,deb,"./apisix")
	rm -fr ./apisix
else
	$(call build,apisix,apisix,deb,$(local_code_path))
endif

### build rpm for apisix:
.PHONY: package-apisix-rpm
package-apisix-rpm:
	$(call package,apisix,rpm)

.PHONY: package-apisix-deb
package-apisix-deb:
	$(call package,apisix,deb)

### build dashboard:
.PHONY: build-dashboard-rpm
build-dashboard-rpm:
ifeq ($(local_code_path), 0)
	git clone -b $(checkout) $(dashboard_repo) ./apisix-dashboard
	$(call build,apisix-dashboard,dashboard,rpm,"./apisix-dashboard")
	rm -fr ./apisix-dashboard
else
	$(call build,apisix-dashboard,dashboard,rpm,$(local_code_path))
endif

.PHONY: build-dashboard-deb
build-dashboard-deb:
ifeq ($(local_code_path), 0)
	git clone -b $(checkout) $(dashboard_repo) ./apisix-dashboard
	$(call build,apisix-dashboard,dashboard,deb,"./apisix-dashboard")
	rm -fr ./apisix-dashboard
else
	$(call build,apisix-dashboard,dashboard,deb,$(local_code_path))
endif

### build rpm for apisix dashboard:
.PHONY: package-dashboard-rpm
package-dashboard-rpm:
	$(call package,apisix-dashboard,rpm)

### build deb for apisix dashboard:
.PHONY: package-dashboard-deb
package-dashboard-deb:
	$(call package,apisix-dashboard,deb)

### build apisix-runtime:
.PHONY: build-apisix-runtime-rpm
build-apisix-runtime-rpm:
ifeq ($(app),apisix)
	git clone -b apisix-runtime/$(runtime_version) $(apisix_runtime_repo) ./apisix-runtime
	$(call build_runtime,apisix-runtime,apisix-runtime,rpm,"./apisix-runtime")
	rm -fr ./apisix-runtime
else
	$(call build_runtime,apisix-runtime,apisix-runtime,rpm,"./")
endif

.PHONY: build-apisix-runtime-deb
build-apisix-runtime-deb:
ifeq ($(app),apisix)
	git clone -b apisix-runtime/$(runtime_version) $(apisix_runtime_repo) ./apisix-runtime
	$(call build_runtime,apisix-runtime,apisix-runtime,deb,"./apisix-runtime")
	rm -fr ./apisix-runtime
else
	$(call build_runtime,apisix-runtime,apisix-runtime,deb,"./")
endif

### build rpm for apisix-runtime:
.PHONY: package-apisix-runtime-rpm
package-apisix-runtime-rpm:
	$(call package_runtime,apisix-runtime,rpm)

### build deb for apisix-runtime:
.PHONY: package-apisix-runtime-deb
package-apisix-runtime-deb:
	$(call package_runtime,apisix-runtime,deb)

### build apisix-base:
.PHONY: build-apisix-base-rpm
build-apisix-base-rpm:
	$(call build,apisix-base,apisix-base,rpm,$(local_code_path))

.PHONY: build-apisix-base-deb
build-apisix-base-deb:
	$(call build,apisix-base,apisix-base,deb,$(local_code_path))

.PHONY: build-apisix-base-apk
build-apisix-base-apk:
	$(call build,apisix-base,apisix-base,apk,$(local_code_path))

### build rpm for apisix-base:
.PHONY: package-apisix-base-rpm
package-apisix-base-rpm:
	$(call package,apisix-base,rpm)

### build deb for apisix-base:
.PHONY: package-apisix-base-deb
package-apisix-base-deb:
	$(call package,apisix-base,deb)

### build fpm for packaging:
.PHONY: build-fpm
ifneq ($(buildx), True)
build-fpm:
	docker build --platform $(arch) -t api7/fpm - < ./dockerfiles/Dockerfile.fpm
else
build-fpm:
	docker buildx build \
	--load \
	--cache-from=$(cache_from) \
	--cache-to=$(cache_to) \
	--platform $(arch) \
	-t api7/fpm - < ./dockerfiles/Dockerfile.fpm
endif

ifeq ($(filter $(app),apisix dashboard apisix-base apisix-runtime),)
$(info  the app's value have to be apisix, dashboard, apisix-base and apisix-runtime!)

else ifeq ($(filter $(type),rpm deb apk),)
$(info  the type's value have to be rpm, deb or apk!)

else ifeq ($(app)_$(type),apisix-base_rpm)
package: build-fpm
package: build-apisix-base-rpm
package: package-apisix-base-rpm

else ifeq ($(app)_$(type),apisix-base_deb)
package: build-fpm
package: build-apisix-base-deb
package: package-apisix-base-deb

else ifeq ($(app)_$(type),apisix-runtime_deb)
package: build-fpm
package: build-apisix-runtime-deb
package: package-apisix-runtime-deb

else ifeq ($(app)_$(type),apisix-runtime_rpm)
package: build-fpm
package: build-apisix-runtime-rpm
package: package-apisix-runtime-rpm

else ifeq ($(app)_$(type),apisix-base_apk)
package: build-apisix-base-apk

else ifeq ($(checkout), 0)
$(info  you have to input a checkout value!)

else ifeq ($(app)_$(type),apisix_rpm)
package: build-fpm
package: build-apisix-runtime-rpm
package: build-apisix-rpm
package: package-apisix-rpm

else ifeq ($(app)_$(type),apisix_deb)
package: build-fpm
package: build-apisix-runtime-deb
package: build-apisix-deb
package: package-apisix-deb

else ifeq ($(app)_$(type),dashboard_rpm)
package: build-fpm
package: build-dashboard-rpm
package: package-dashboard-rpm

else ifeq ($(app)_$(type),dashboard_deb)
package: build-fpm
package: build-dashboard-deb
package: package-dashboard-deb

endif
