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
image_base="centos"
image_tag="7"
iteration=0
local_code_path=0
openresty="openresty"
artifact="0"
apisix_repo="https://github.com/apache/apisix"
dashboard_repo="https://github.com/apache/apisix-dashboard"

### set the default image for deb package
ifeq ($(type), deb)
image_base="ubuntu"
image_tag="20.04"
endif

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
		--build-arg VERSION=$(version) \
		--build-arg IMAGE_BASE=$(image_base) \
		--build-arg IMAGE_TAG=$(image_tag) \
		--build-arg CODE_PATH=$(4) \
		-f ./dockerfiles/Dockerfile.$(2).$(3) .
endef
else
define build
	docker buildx build -t apache/$(1)-$(3):$(version) \
		--build-arg checkout_v=$(checkout) \
		--build-arg VERSION=$(version) \
		--build-arg IMAGE_BASE=$(image_base) \
		--build-arg IMAGE_TAG=$(image_tag) \
		--build-arg CODE_PATH=$(4) \
		--load \
		--cache-from=$(cache_from) \
		--cache-to=$(cache_to) \
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
		--build-arg PACKAGE_TYPE=$(2) \
		--build-arg OPENRESTY=$(openresty) \
		--build-arg ARTIFACT=$(artifact) \
		-f ./dockerfiles/Dockerfile.package.$(1) .
	docker run -d --rm --name output --net="host" apache/$(1)-packaged-$(2):$(version)
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

### build apisix_fedora:
.PHONY: build-apisix_fedora-rpm
build-apisix_fedora-rpm:
ifeq ($(local_code_path), 0)
	git clone -b $(checkout) $(apisix_repo) ./apisix
	$(call build,apisix,apisix_fedora,rpm,"./apisix")
	rm -fr ./apisix
else
    $(call build,apisix,apisix_fedora,rpm,$(local_code_path))
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

.PHONY: package-apisix_fedora-rpm
package-apisix_fedora-rpm:
	$(call package,apisix_fedora,rpm)	

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

### build apisix-base:
.PHONY: build-apisix-base-rpm
build-apisix-base-rpm:
	$(call build,apisix-base,apisix-base,rpm,$(local_code_path))

.PHONY: build-apisix-base-deb
build-apisix-base-deb:
	$(call build,apisix-base,apisix-base,deb,$(local_code_path))

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
	docker build -t api7/fpm - < ./dockerfiles/Dockerfile.fpm
else
build-fpm:
	docker buildx build \
	--load \
	--cache-from=$(cache_from) \
	--cache-to=$(cache_to) \
	-t api7/fpm - < ./dockerfiles/Dockerfile.fpm
endif

ifeq ($(filter $(app),apisix_fedora apisix dashboard apisix-base),)
$(info  the app's value have to be apisix_fedora, apisix or dashboard!)

else ifeq ($(filter $(type),rpm deb),)
$(info  the type's value have to be rpm or deb!)

else ifeq ($(version), 0)
$(info  you have to input a version value!)

else ifeq ($(app)_$(type),apisix-base_rpm)
package: build-fpm
package: build-apisix-base-rpm
package: package-apisix-base-rpm

else ifeq ($(app)_$(type),apisix-base_deb)
package: build-fpm
package: build-apisix-base-deb
package: package-apisix-base-deb

else ifeq ($(checkout), 0)
$(info  you have to input a checkout value!)

else ifeq ($(app)_$(type),apisix_rpm)
package: build-fpm
package: build-apisix-rpm
package: package-apisix-rpm


else ifeq ($(app)_$(type),apisix_fedora_rpm)
package: build-fpm
package: build-apisix_fedora-rpm
package: package-apisix_fedora-rpm

else ifeq ($(app)_$(type),apisix_deb)
package: build-fpm
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