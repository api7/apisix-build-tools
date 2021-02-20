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
package=$2

rpm() {
    yum install https://extras.getpagespeed.com/release-el7-latest.rpm
    yum install -y curl wrk
    yum install yum-utils
    yum-config-manager --add-repo https://openresty.org/package/centos/openresty.repo
    yum install -y which wget unzip
    yum install -y /tmp/output/$package
}

deb() {
    apt-get update
    apt-get install -y software-properties-common curl wrk wget
    wget -qO - https://openresty.org/package/pubkey.gpg | apt-key add -
    add-apt-repository -y "deb http://openresty.org/package/ubuntu $(lsb_release -sc) main"
    apt-get update
    apt-get install -y /tmp/output/$package
}

other(){
    wget https://github.com/etcd-io/etcd/releases/download/v3.4.13/etcd-v3.4.13-linux-amd64.tar.gz
    tar -xvf etcd-v3.4.13-linux-amd64.tar.gz && \
        cd etcd-v3.4.13-linux-amd64 && \
        cp -a etcd etcdctl /usr/bin/
    nohup etcd &
    apisix start

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

    result_code=`curl -I -m 10 -o /dev/null -s -w %{http_code} http://127.0.0.1:9080/get`
    if [[ $result_code -ne 200 ]];then
            printf "result_code: %s\n" "$result_code"
            exit 125
    fi
}

case_opt=$1
case $case_opt in
    (rpm)
        rpm
        other
        ;;
    (deb)
        deb
        other
        ;;
esac
