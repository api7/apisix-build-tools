ARG RESTY_IMAGE_BASE="centos"
ARG RESTY_IMAGE_TAG="7"
ARG APISIX_BRANCH="master"
ARG ITERATION="0"
ARG APISIX_REPOSITORY="https://github.com/apache/apisix"

FROM ${RESTY_IMAGE_BASE}:${RESTY_IMAGE_TAG}

ARG APISIX_BRANCH
LABEL apisix_branch="${APISIX_BRANCH}"


RUN yum -y install wget tar gcc automake autoconf libtool make \
  curl git which 

RUN wget http://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm \
    && rpm -ivh epel-release-latest-7.noarch.rpm \
    && yum install -y luarocks lua-devel

RUN yum install -y yum-utils\
    && yum-config-manager --add-repo https://openresty.org/package/centos/openresty.repo \
    && yum install -y openresty

ARG APISIX_BRANCH
ARG ITERATION
ARG APISIX_REPOSITORY
RUN set -x \
    && mkdir -p /tmp/build/output/apisix/usr/bin/ \
    && git clone -b ${APISIX_BRANCH} ${APISIX_REPOSITORY} \
    && sed -i 's/url.*/url = ".\/apisix",/'  apisix/rockspec/apisix-${APISIX_BRANCH}-${ITERATION}.rockspec \
    && sed -i 's/branch.*//' apisix/rockspec/apisix-${APISIX_BRANCH}-${ITERATION}.rockspec \
    && cd ./apisix \
    && luarocks make ./rockspec/apisix-${APISIX_BRANCH}-${ITERATION}.rockspec --tree=/tmp/build/output/apisix/usr/local/apisix/deps --local \
    && chown -R $USER:$USER /tmp/build/output \
    && cd .. \
    && cp /tmp/build/output/apisix/usr/local/apisix/deps/lib64/luarocks/rocks/apisix/${APISIX_BRANCH}-${ITERATION}/bin/apisix /tmp/build/output/apisix/usr/bin/ || true \
    && cp /tmp/build/output/apisix/usr/local/apisix/deps/lib/luarocks/rocks/apisix/${APISIX_BRANCH}-${ITERATION}/bin/apisix /tmp/build/output/apisix/usr/bin/ || true \
    && bin='#! /usr/local/openresty/luajit/bin/luajit\npackage.path = "/usr/local/apisix/?.lua;" .. package.path' \
    && sed -i "1s@.*@$bin@" /tmp/build/output/apisix/usr/bin/apisix \
    && cp -r /usr/local/apisix/* /tmp/build/output/apisix/usr/local/apisix/ \
    && mv /tmp/build/output/apisix/usr/local/apisix/deps/share/lua/5.1/apisix /tmp/build/output/apisix/usr/local/apisix/

