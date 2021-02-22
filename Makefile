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
code_tag=0
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
	docker build -t apache/apisix:$(code_tag) --build-arg apisix_tag=$(code_tag) -f ./dockerfiles/Dockerfile.apisix.rpm .
	docker run -d --name dockerInstance --net="host" apache/apisix:$(code_tag)
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
		--url 'http://apisix.apache.org/'
	rm -rf ${PWD}/build

.PHONY: smoketest-apisix-rpm
smoketest-apisix-rpm:
	docker run -itd --rm \
		-v ${PWD}/output/:/tmp/output \
		-v ${PWD}/smoketest_apisix.sh:/tmp/smoketest_apisix.sh \
		--name smoketestInstance \
		--net="host" \
		docker.io/centos:7 /bin/bash
	docker exec smoketestInstance bash -c "/tmp/smoketest_apisix.sh $(shell find ${PWD}/output/ -name *.rpm -not -name apisix-dashboard* |sed 's#.*/##')"
	docker rm -f smoketestInstance

ifeq ($(filter $(app),apisix dashboard),)
$(info  the app's value have to be apisix or dashboard!)

else ifeq ($(filter $(type),rpm deb),)
$(info  the type's value have to be rpm or deb!)

else ifeq ($(version), 0)
$(info  you have to input a version value!)

else ifeq ($(code_tag), 0)
$(info  you have to input a code_tag value!)

else ifeq ($(app)_$(type),apisix_rpm)
package: build-apisix-rpm
package: package-apisix-rpm
package: smoketest-apisix-rpm

endif
