#!/usr/bin/env bash
set -euo pipefail
set -x

cd $1
source .requirements
if [ -z "${APISIX_DASHBOARD_COMMIT:-}" ]; then
    echo "Error: APISIX_DASHBOARD_COMMIT is not set or empty"
    exit 1
fi
git clone --no-checkout --filter=blob:none https://github.com/apache/apisix-dashboard.git
git -C apisix-dashboard fetch --depth 1 origin "${APISIX_DASHBOARD_COMMIT}"
git -C apisix-dashboard checkout --detach FETCH_HEAD
pushd apisix-dashboard
# compile
pnpm install --frozen-lockfile
pnpm run build
popd
# copy the dist files to the ui directory
mkdir ui
cp -r apisix-dashboard/dist/* ui/
rm -rf apisix-dashboard
