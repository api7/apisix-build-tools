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
branch=2.2
iteration=0

### build apisix:
.PHONY: build-apisix-rpm
build-apisix-rpm:
	mkdir -p ${PWD}/build/rpm
	docker build -t apache/apisix:$(branch) --build-arg apisix_branch=$(branch) -f ./dockerfiles/Dockerfile.apisix.rpm .
	docker run -d --name dockerInstance --net="host" apache/apisix:$(branch)
	docker cp dockerInstance:/tmp/build/output/ ${PWD}/build/rpm
	docker system prune -a -f

.PHONY: build-apisix-deb
build-apisix-deb:
	mkdir -p ${PWD}/build/deb
	docker build -t apache/apisix:$(branch) --build-arg apisix_branch=$(branch)  -f ./dockerfiles/Dockerfile.apisix.deb .
	docker run -d --name dockerInstance --net="host" apache/apisix:$(branch)
	docker cp dockerInstance:/tmp/build/output/ ${PWD}/build/deb
	docker system prune -a -f

### build dashboard:
.PHONY: build-dashboard-rpm
build-dashboard-rpm:
	mkdir -p ${PWD}/build/rpm
	docker build -t apache/apisix-dashboard:$(branch) --build-arg dashboard_branch=$(branch) -f ./dockerfiles/Dockerfile.dashboard.rpm .
	docker run -d --name dockerInstance --net="host" apache/apisix-dashboard:$(branch)
	docker cp dockerInstance:/tmp/build/output/ ${PWD}/build/rpm
	docker system prune -a -f

.PHONY: build-dashboard-deb
build-dashboard-deb:
	mkdir -p ${PWD}/build/deb
	docker build -t apache/apisix-dashboard:$(branch) --build-arg dashboard_branch=$(branch) -f ./dockerfiles/Dockerfile.dashboard.deb .
	docker run -d --name dockerInstance --net="host" apache/apisix-dashboard:$(branch)
	docker cp dockerInstance:/tmp/build/output/ ${PWD}/build/deb
	docker system prune -a -f

### build rpm for apisix:
.PHONY: package-apisix-rpm
package-apisix-rpm: build-apisix-rpm
	fpm -f -s dir -t rpm \
		-n apisix \
		-a `uname -i` \
		-v $(version) \
		--iteration $(iteration) \
		-d 'openresty >= 1.15.8.1' \
		--description 'Apache APISIX is a distributed gateway for APIs and Microservices, focused on high performance and reliability.' \
		--license "ASL 2.0" \
		-C ${PWD}/build/rpm/output/apisix/ \
		-p ${PWD}/output/ \
		--url 'http://apisix.apache.org/'

	rm -rf ${PWD}/build

### build deb for apisix: version can't be letter
.PHONY: package-apisix-deb
package-apisix-deb: build-apisix-deb
	fpm -f -s dir -t deb \
		-n apisix \
		-a `uname -i` \
		-v $(version) \
		--iteration $(iteration) \
		-d 'openresty >= 1.15.8.1' \
		--description 'Apache APISIX is a distributed gateway for APIs and Microservices, focused on high performance and reliability.' \
		--license "ASL 2.0" \
		-C ${PWD}/build/deb/output/apisix/ \
		-p ${PWD}/output/ \
		--url 'http://apisix.apache.org/'

	rm -rf ${PWD}/build

### build rpm for apisix dashboard:
.PHONY: package-dashboard-rpm
package-dashboard-rpm: build-dashboard-rpm
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

### build deb for apisix: version can't be letter
.PHONY: package-dashboard-deb
package-dashboard-deb: build-dashboard-deb
	fpm -f -s dir -t deb \
		-n apisix-dashboard \
		-a `uname -i` \
		-v $(version) \
		--iteration $(iteration) \
		-d 'openresty >= 1.15.8.1' \
		--description 'Apache APISIX Dashboard is designed to make it as easy as possible for users to operate Apache APISIX through a frontend interface.'  \
		--license "ASL 2.0" \
		-C ${PWD}/build/deb/output/apisix/dashboard/ \
		-p ${PWD}/output/ \
		--url 'https://github.com/apache/apisix-dashboard'

	rm -rf ${PWD}/build