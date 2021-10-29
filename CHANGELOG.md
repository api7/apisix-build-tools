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

- [2.5.0](#250)
- [2.4.0](#240)
- [2.3.0](#230)
- [2.2.1](#221)
- [2.2.0](#220)
- [2.1.0](#210)
- [2.0.0](#200)

## 2.5.0

This release contains serveral new features and important bugfixes.

### New Feature
- feat: Update apisix-build-tools workflow: add parameter "timeout-minutes: 60" in all files [#124](https://github.com/api7/apisix-build-tools/pull/124)
- ci: auto build and push apisix-base image [#118](https://github.com/api7/apisix-build-tools/pull/118)
- ci(workflow): auto build and publish rpm package [#115](https://github.com/api7/apisix-build-tools/pull/115)
- feat: build apisix-base docker image [#114](https://github.com/api7/apisix-build-tools/pull/114)
- feat: release wasm-nginx-module 0.1.0 [#116](https://github.com/api7/apisix-build-tools/pull/116)
- chore: Use apache apisix rpm repository [#111](https://github.com/api7/apisix-build-tools/pull/111)

### Bugfix
- ci: Fix incorrect shebang in rpm package for 2.10.x [#125](https://github.com/api7/apisix-build-tools/pull/125)
- fix: Add ldap dev dependency for building apisix [#112](https://github.com/api7/apisix-build-tools/pull/112)

## 2.4.0

This release mainly contains several new features.

### New Feature
- ci: Disable CI for doc changes [#106](https://github.com/api7/apisix-build-tools/pull/106)
- feat: add wasm-nginx-module [#98](https://github.com/api7/apisix-build-tools/pull/98)
- chore: Ignore cert check when downloading openresty [#105](https://github.com/api7/apisix-build-tools/pull/105)

## 2.3.0

This release mainly contains two new features.

### New Feature
- chore: Rename apisix-openresty to apisix-base [#103](https://github.com/api7/apisix-build-tools/pull/103)
- ci: Upload apisix-openresty/apisix/dashboard artifact [#102](https://github.com/api7/apisix-build-tools/pull/102)

## 2.2.1

This release mainly contains two important bugfixes, as well as a feature.

### New Feature
- feat: add apisix-openresty deb support [#92](https://github.com/api7/apisix-build-tools/pull/92)

### Bugfix
- ci: Fix no setting config files [95](https://github.com/api7/apisix-build-tools/pull/95)
- fix: failed to get metalink from epel [#93](https://github.com/api7/apisix-build-tools/pull/93)

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
