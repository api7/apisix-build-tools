ARG VERSION
ARG PACKAGE_TYPE

FROM apache/apisix-base-${PACKAGE_TYPE}:${VERSION} AS APISIX-BASE
FROM api7/fpm

ARG ITERATION
ARG PACKAGE_VERSION
ARG PACKAGE_TYPE
ARG ARTIFACT

ENV ITERATION=${ITERATION}
ENV PACKAGE_VERSION=${PACKAGE_VERSION}
ENV PACKAGE_TYPE=${PACKAGE_TYPE}
ENV ARTIFACT=${ARTIFACT}

COPY --from=APISIX-BASE /usr/local/openresty /tmp/build/output/openresty
COPY --from=APISIX-BASE /tmp/dist /tmp/dist
COPY package-apisix-base.sh /package-apisix-base.sh
COPY post-install-apisix-base.sh /post-install-apisix-base.sh
COPY usr /usr

RUN /package-apisix-base.sh