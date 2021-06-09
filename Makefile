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
	mkdir -p ${PWD}/build/rpm
	docker build -t apache/apisix:$(version) --build-arg checkout_v=$(checkout) -f ./dockerfiles/Dockerfile.apisix.rpm .
	docker run -d --name dockerInstance --net="host" apache/apisix:$(version)
	docker cp dockerInstance:/tmp/build/output/ ${PWD}/build/rpm
	docker system prune -a -f

### build rpm for apisix:
.PHONY: package-apisix-rpm
package-apisix-rpm:
	fpm -f -s dir -t rpm \
		-n apisix \
		-a `uname -i` \
		-v $(version) \
		--iteration $(iteration) \
		-d 'openresty >= 1.17.8.2' \
		--description 'Apache APISIX is a distributed gateway for APIs and Microservices, focused on high performance and reliability.' \
		--license "ASL 2.0" \
		-C ${PWD}/build/rpm/output/apisix/ \
		-p ${PWD}/output/ \
		--url 'http://apisix.apache.org/' \
		--config-files usr/lib/systemd/system/apisix.service
	rm -rf ${PWD}/build

### build dashboard:
.PHONY: build-dashboard-rpm
build-dashboard-rpm:
	mkdir -p ${PWD}/build/rpm
	docker build -t apache/apisix-dashboard:$(version) --build-arg checkout_v=$(checkout) -f ./dockerfiles/Dockerfile.dashboard.rpm .
	docker run -d --name dockerInstance --net="host" apache/apisix-dashboard:$(version)
	docker cp dockerInstance:/tmp/build/output/ ${PWD}/build/rpm
	docker system prune -a -f

### build rpm for apisix dashboard:
.PHONY: package-dashboard-rpm
package-dashboard-rpm:
	fpm -f -s dir -t rpm \
		-n apisix-dashboard \
		-a `uname -i` \
		-v $(version) \
		--iteration $(iteration) \
		--description 'Apache APISIX Dashboard is designed to make it as easy as possible for users to operate Apache APISIX through a frontend interface.'  \
		--license "ASL 2.0" \
		-C ${PWD}/build/rpm/output/apisix/dashboard/ \
		-p ${PWD}/output/ \
		--url 'https://github.com/apache/apisix-dashboard'

	rm -rf ${PWD}/build

### build apisix-openresty:
.PHONY: build-apisix-openresty-rpm
build-apisix-openresty-rpm:
	mkdir -p ${PWD}/build/rpm
	docker build -t apache/apisix-openresty:$(version) -f ./dockerfiles/Dockerfile.apisix-openresty.rpm .
	docker run -d --name dockerInstance --net="host" apache/apisix-openresty:$(version)
	docker cp dockerInstance:/usr/local/openresty/ ${PWD}/build/rpm
	docker system prune -a -f

### build rpm for apisix-openresty:
.PHONY: package-apisix-openresty-rpm
package-apisix-openresty-rpm:
	fpm -f -s dir -t rpm \
		-n apisix-openresty \
		-a `uname -i` \
		-v $(version) \
		--iteration $(iteration) \
		-x openresty/zlib \
		-x openresty/openssl111 \
		-x openresty/pcre \
		-d 'openresty-zlib >= 1.2.11-3' \
		-d 'openresty-openssl111 >= 1.1.1h-1' \
		-d 'openresty-pcre >= 8.44-1' \
		--description "APISIX's OpenResty distribution." \
		--license "ASL 2.0" \
		-C ${PWD}/build/rpm \
		-p ${PWD}/output/ \
		--url 'http://apisix.apache.org/' \
		--conflicts openresty \
		--config-files usr/lib/systemd/system/openresty.service \
		--prefix=/usr/local
	rm -rf ${PWD}/build

ifeq ($(filter $(app),apisix dashboard apisix-openresty),)
$(info  the app's value have to be apisix or dashboard!)

else ifeq ($(filter $(type),rpm deb),)
$(info  the type's value have to be rpm or deb!)

else ifeq ($(version), 0)
$(info  you have to input a version value!)

else ifeq ($(app)_$(type),apisix-openresty_rpm)
package: build-apisix-openresty-rpm
package: package-apisix-openresty-rpm

else ifeq ($(checkout), 0)
$(info  you have to input a checkout value!)

else ifeq ($(app)_$(type),apisix_rpm)
package: build-apisix-rpm
package: package-apisix-rpm

else ifeq ($(app)_$(type),dashboard_rpm)
package: build-dashboard-rpm
package: package-dashboard-rpm

endif
