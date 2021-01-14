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

version=0.0
iteration=0

### run centos:
.PHONY: run-centos
run-centos:
	docker run -itd --rm \
		-v ${PWD}/build/rpm:/tmp/build/output \
		-v ${PWD}/build-rpm.sh:/tmp/build/build.sh \
		--name dockerInstance \
		--net="host" \
		docker.io/centos:7 /bin/bash

### run ubuntu:
.PHONY: run-ubuntu
run-ubuntu:
	docker run -itd --rm \
		-v ${PWD}/build/deb:/tmp/build/output \
		-v ${PWD}/build-deb.sh:/tmp/build/build.sh \
		--name dockerInstance \
		--net="host" \
		docker.io/ubuntu:18.04 /bin/bash

### build apisix:
.PHONY: build-apisix
build-apisix:
	docker exec dockerInstance bash -c "/tmp/build/build.sh install_dependencies"
	docker exec dockerInstance bash -c "/tmp/build/build.sh build_apisix"

### build dashboard:
.PHONY: build-dashboard
build-dashboard:
	docker exec dockerInstance bash -c "/tmp/build/build.sh install_dependencies_dashboard"
	docker exec dockerInstance bash -c "/tmp/build/build.sh build_dashboard"

### build rpm for apisix:
.PHONY: build-rpm-apisix
build-rpm-apisix: run-centos build-apisix
	fpm -f -s dir -t rpm \
		-n apisix \
		-a `uname -i` \
		-v $(version) \
		--iteration $(iteration) \
		-d 'openresty >= 1.15.8.1' \
		--description 'Apache APISIX is a distributed gateway for APIs and Microservices, focused on high performance and reliability.' \
		--license "ASL 2.0" \
		-C ${PWD}/build/rpm/apisix/ \
		-p ${PWD}/output/ \
		--url 'http://apisix.apache.org/'

	docker rm -f dockerInstance

### build deb for apisix: version can't be letter
.PHONY: build-deb-apisix
build-deb-apisix: run-ubuntu build-apisix
	fpm -f -s dir -t deb \
		-n apisix \
		-a `uname -i` \
		--iteration $(iteration) \
		-d 'openresty >= 1.15.8.1' \
		--description 'Apache APISIX is a distributed gateway for APIs and Microservices, focused on high performance and reliability.' \
		--license "ASL 2.0" \
		-C ${PWD}/build/deb/apisix/ \
		-p ${PWD}/output/ \
		--url 'http://apisix.apache.org/'

	docker rm -f dockerInstance

### build rpm for dasnboard:
.PHONY: build-rpm-dashboard
build-rpm-dashboard: run-centos build-dashboard
	fpm -f \
		-s dir \
		-t rpm \
		-n apisix-dashboard \
		-a `uname -i` \
		-v $(version)  \
		--iteration $(iteration) \
		--description 'Apache APISIX Dashboard is designed to make it as easy as possible for users to operate Apache APISIX through a frontend interface.'  \
		--license "ASL 2.0" \
		-C ${PWD}/build/rpm/apisix/dashboard/ \
		-p ${PWD}/output/ \
		--url 'https://github.com/apache/apisix-dashboard'

	docker rm -f dockerInstance

### build deb for dasnboard:
.PHONY: build-deb-dashboard
build-deb-dashboard: run-centos build-dashboard
	fpm -f \
		-s dir \
		-t deb \
		-n apisix-dashboard \
		-a `uname -i \
		--iteration $(iteration) \
		--description 'Apache APISIX Dashboard is designed to make it as easy as possible for users to operate Apache APISIX through a frontend interface.'  \
		--license "ASL 2.0" \
		-C ${PWD}/build/deb/apisix/dashboard/ \
		-p ${PWD}/output/ \
		--url 'https://github.com/apache/apisix-dashboard'

	docker rm -f dockerInstance
