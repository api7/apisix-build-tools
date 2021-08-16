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

### set the default image for deb package
ifeq ($(type), deb)
image_base="ubuntu"
image_tag="20.04"
endif

### function for building
### $(1) is name
### $(2) is dockerfile filename
### $(3) is package type
define build
	docker build -t apache/$(1)-$(3):$(version) \
		--build-arg checkout_v=$(checkout) \
		--build-arg IMAGE_BASE=$(image_base) \
		--build-arg IMAGE_TAG=$(image_tag) \
		-f ./dockerfiles/Dockerfile.$(2).$(3) .
endef

### function for packing
### $(1) is name
### $(2) is package type
define package
	docker build -t apache/$(1)-packaged-$(2):$(version) \
		--build-arg VERSION=$(version) \
		--build-arg ITERATION=$(iteration) \
		--build-arg PACKAGE_VERSION=$(version) \
		--build-arg PACKAGE_TYPE=$(2) \
		-f ./dockerfiles/Dockerfile.package.$(1) .
	docker run -d --rm --name output --net="host" apache/$(1)-packaged-$(2):$(version)
	docker cp output:/output ${PWD}
	docker stop output
	docker system prune -a -f
endef

### build apisix:
.PHONY: build-apisix-rpm
build-apisix-rpm:
	$(call build,apisix,apisix,rpm)

.PHONY: build-apisix-deb
build-apisix-deb:
	$(call build,apisix,apisix,deb)

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
	$(call build,apisix-dashboard,dashboard,rpm)

### build rpm for apisix dashboard:
.PHONY: package-dashboard-rpm
package-dashboard-rpm:
	$(call package,apisix-dashboard,rpm)

### build apisix-openresty:
.PHONY: build-apisix-openresty-rpm
build-apisix-openresty-rpm:
	docker build -t apache/apisix-openresty-rpm:$(version) \
		--build-arg version=$(version) \
		--build-arg IMAGE_BASE=$(image_base) \
		--build-arg IMAGE_TAG=$(image_tag) \
		-f ./dockerfiles/Dockerfile.apisix-openresty.rpm .

### build rpm for apisix-openresty:
.PHONY: package-apisix-openresty-rpm
package-apisix-openresty-rpm:
	$(call package,apisix-openresty,rpm)

### build fpm for packaging:
.PHONY: build-fpm
build-fpm:
	docker build -t api7/fpm - < ./dockerfiles/Dockerfile.fpm

ifeq ($(filter $(app),apisix dashboard apisix-openresty),)
$(info  the app's value have to be apisix or dashboard!)

else ifeq ($(filter $(type),rpm deb),)
$(info  the type's value have to be rpm or deb!)

else ifeq ($(version), 0)
$(info  you have to input a version value!)

else ifeq ($(app)_$(type),apisix-openresty_rpm)
package: build-fpm
package: build-apisix-openresty-rpm
package: package-apisix-openresty-rpm

else ifeq ($(checkout), 0)
$(info  you have to input a checkout value!)

else ifeq ($(app)_$(type),apisix_rpm)
package: build-fpm
package: build-apisix-rpm
package: package-apisix-rpm

else ifeq ($(app)_$(type),apisix_deb)
package: build-fpm
package: build-apisix-deb
package: package-apisix-deb

else ifeq ($(app)_$(type),dashboard_rpm)
package: build-fpm
package: build-dashboard-rpm
package: package-dashboard-rpm

endif
