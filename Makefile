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

### function for building rpm
define build_rpm
	docker build -t apache/$(1):$(version) --build-arg checkout_v=$(checkout) \
		-f ./dockerfiles/Dockerfile.$(2).rpm .
endef

define package_rpm
	docker build -t apache/$(1)-packaged:$(version) \
		--build-arg VERSION=$(version) \
		--build-arg ITERATION=$(iteration) \
		--build-arg PACKAGE_VERSION=$(version) \
		-f ./dockerfiles/Dockerfile.package.$(1) .
	docker run -d --rm --name output --net="host" apache/$(1)-packaged:$(version)
	docker cp output:/output ${PWD}
	docker stop output
	docker system prune -a -f
endef

### build apisix:
.PHONY: build-apisix-rpm
build-apisix-rpm:
	$(call build_rpm,apisix,apisix)

### build rpm for apisix:
.PHONY: package-apisix-rpm
package-apisix-rpm:
	$(call package_rpm,apisix)

### build dashboard:
.PHONY: build-dashboard-rpm
build-dashboard-rpm:
	$(call build_rpm,apisix-dashboard,dashboard)

### build rpm for apisix dashboard:
.PHONY: package-dashboard-rpm
package-dashboard-rpm:
	$(call package_rpm,apisix-dashboard)

### build apisix-openresty:
.PHONY: build-apisix-openresty-rpm
build-apisix-openresty-rpm:
	$(call build_rpm,apisix-openresty,apisix-openresty)

### build rpm for apisix-openresty:
.PHONY: package-apisix-openresty-rpm
package-apisix-openresty-rpm:
	$(call package_rpm,apisix-openresty)

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

else ifeq ($(app)_$(type),dashboard_rpm)
package: build-fpm
package: build-dashboard-rpm
package: package-dashboard-rpm

endif
