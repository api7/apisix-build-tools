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
branch=master
iteration=0

### build apisix:
.PHONY: build-apisix
build-apisix:
	mkdir -p ${PWD}/build/rpm
	docker build -t apache/apisix:master .
	docker run -d --name dockerInstance --net="host" apache/apisix:master
	docker cp dockerInstance:/tmp/build/output/ ${PWD}/build/rpm
	docker system prune -a -f

### build dashboard:
.PHONY: build-dashboard
build-dashboard:
	docker exec dockerInstance bash -c "/tmp/build/build.sh install_dependencies_dashboard"
	docker exec dockerInstance bash -c "/tmp/build/build.sh build_dashboard $(branch)"

### build rpm for apisix:
.PHONY: build-rpm-apisix
build-rpm-apisix: build-apisix
	fpm -f -s dir -t rpm \
		-n apisix \
		-a `uname -i` \
		-v $(version) \
		--iteration $(iteration) \
		-d 'openresty >= 1.15.8.1' \
		--description 'Apache APISIX is a distributed gateway for APIs and Microservices, focused on high performance and reliability.' \
		--license "ASL 2.0" \
		-C ${PWD}/build/rpm/output/ \
		-p ${PWD}/output/ \
		--url 'http://apisix.apache.org/'

	rm -rf ${PWD}/build/rpm

