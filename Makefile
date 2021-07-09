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

# todo: optimize the code, too much duplicate code now.

### build apisix:
.PHONY: build-apisix-rpm
build-apisix-rpm:
	docker build -t apache/apisix:$(version) --build-arg checkout_v=$(checkout) \
		-f ./dockerfiles/Dockerfile.apisix.rpm .

### build rpm for apisix:
.PHONY: package-apisix-rpm
package-apisix-rpm:
	docker build -t apache/apisix-packaged:$(version) \
		--build-arg VERSION=$(version) \
		--build-arg ITERATION=$(iteration) \
		--build-arg PACKAGE_VERSION=$(version) \
		-f ./dockerfiles/Dockerfile.package.apisix .
	docker run -d --rm --name output --net="host" apache/apisix-packaged:$(version)
	docker cp output:/output ${PWD}
	docker stop output
	docker system prune -a -f

### build dashboard:
.PHONY: build-dashboard-rpm
build-dashboard-rpm:
	docker build -t apache/apisix-dashboard:$(version) --build-arg checkout_v=$(checkout) \
		-f ./dockerfiles/Dockerfile.dashboard.rpm .

### build rpm for apisix dashboard:
.PHONY: package-dashboard-rpm
package-dashboard-rpm:
	docker build -t apache/apisix-dashboard-packaged:$(version) \
		--build-arg VERSION=$(version) \
		--build-arg ITERATION=$(iteration) \
		--build-arg PACKAGE_VERSION=$(version) \
		-f ./dockerfiles/Dockerfile.package.apisix-dashboard .
	docker run -d --rm --name output --net="host" apache/apisix-dashboard-packaged:$(version)
	docker cp output:/output ${PWD}/output
	docker stop output
	docker system prune -a -f

### build apisix-openresty:
.PHONY: build-apisix-openresty-rpm
build-apisix-openresty-rpm:
	docker build -t apache/apisix-openresty:$(version) --build-arg version=$(version) \
		-f ./dockerfiles/Dockerfile.apisix-openresty.rpm .

### build rpm for apisix-openresty:
.PHONY: package-apisix-openresty-rpm
package-apisix-openresty-rpm:
	docker build -t apache/apisix-openresty-packaged:$(version) \
		--build-arg VERSION=$(version) \
		--build-arg ITERATION=$(iteration) \
		--build-arg PACKAGE_VERSION=$(version) \
		-f ./dockerfiles/Dockerfile.package.apisix-openresty .
	docker run -d --rm --name output --net="host" apache/apisix-openresty-packaged:$(version)
	docker cp output:/output ${PWD}
	docker stop output
	docker system prune -a -f


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
