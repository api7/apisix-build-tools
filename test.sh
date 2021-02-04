#!/usr/bin/env bash
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

install_rpm() {
    cd /tmp/output
    check_results=`find . -name "*.rpm"`
    yum install -y $check_results
}

install_deb() {
    cd /tmp/output
    check_results=`find . -name "*.deb"`
    apt install -y $check_results
}

create_route() {
    curl http://127.0.0.1:9080/apisix/admin/routes/1 \
    -H 'X-API-KEY: edd1c9f034335f136f87ad84b625c8f1' -X PUT -d '
    {
        "uri": "/get",
        "upstream": {
            "type": "roundrobin",
            "nodes": {
                "httpbin.org:80": 1
            }
        }
    }'
}

test_route() {
    result=`curl -I -m 10 -o /dev/null -s -w %{http_code} 127.0.0.1:9080/get`
    if [ $result != 200 ];then
        printf "fail: result: %s\n" "$result"
        exit 125
    fi
}

case_opt=$1
case $case_opt in
    (install_rpm)
        install_rpm
        ;;
    (create_route)
        create_route
        ;;
    (test_route)
        test_route
        ;;
esac
