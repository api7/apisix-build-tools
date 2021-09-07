<!--
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
-->


## Table of Contents

- [2.2.0](#220)
  - [New Feature](#new-feature)
  - [Bugfix](#bugfix)
- [2.1.0](#210)
  - [New Feature](#new-feature)
- [2.0.0](#200)


## 2.2.0

This release mainly contains several new features, as well as a bugfix.

### New Feature
- ci: Using Buildx as Docker builder [#74](https://github.com/api7/apisix-build-tools/pull/74)
- feat: add apisix dashboard deb support [#82](https://github.com/api7/apisix-build-tools/pull/82)
- feat: Reduce CI files with combined test [#86](https://github.com/api7/apisix-build-tools/pull/86)
- docs: update the recommened way to build APISIX OpenResty [#85](https://github.com/api7/apisix-build-tools/pull/85)

### Bugfix
- fix: failed to get metalink from epel [#88](https://github.com/api7/apisix-build-tools/pull/88)

## 2.1.0

This release mainly contains several new features.

### New Feature
- feat: Support setting artifact name [#83](https://github.com/api7/apisix-build-tools/pull/83)
- feat: upgrade apisix_nginx_module_ver [#81](https://github.com/api7/apisix-build-tools/pull/81)
- feat: Support packaging apisix which depends on apisix-openresty [#80](https://github.com/api7/apisix-build-tools/pull/80)
- feat: Support use local code for packaging [#79](https://github.com/api7/apisix-build-tools/pull/79)


## 2.0.0

This release is the initial release, which is mainly to support building apisix,
apisix-dashboard and apisix-openrestyboth for rpm and deb artifacts.


[Back to TOC](#table-of-contents)
